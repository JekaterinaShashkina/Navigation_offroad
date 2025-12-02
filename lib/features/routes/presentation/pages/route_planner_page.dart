import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:offroad_nav/features/routes/domain/entities/route_entity.dart';
import 'package:offroad_nav/features/routes/domain/repositories/routes_repository.dart';
import 'package:offroad_nav/features/routes/data/repositories/routes_repository_impl.dart';
import 'package:offroad_nav/features/routes/data/datasources/routes_remote_ds.dart';

import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/widgets/route_action_bar.dart';
import 'package:offroad_nav/utils/marker_dot.dart';

class RoutePlannerPage extends StatefulWidget {
  const RoutePlannerPage({super.key});

  @override
  State<RoutePlannerPage> createState() => _RoutePlannerPageState();
}

/// Контроллер: хранит точки и всю геометрию/логику редактирования.
class _RoutePlannerController {
  final List<LatLng> _points = [];
  bool _closed = false;

  List<LatLng> get points => List.unmodifiable(_points);
  bool get closed => _closed;

  // список точек для рисования polyline (если замкнуто — первая в конец)
  List<LatLng> get polylinePoints {
    final list = List<LatLng>.from(_points);
    if (_closed && _points.length >= 3) list.add(_points.first);
    return list;
  }

  // Haversine расстояние в км
  double _distKm(LatLng a, LatLng b) {
    const p = 0.017453292519943295; // pi/180
    final c = cos;
    final a1 = 0.5 -
        c((b.latitude - a.latitude) * p) / 2 +
        c(a.latitude * p) * c(b.latitude * p) *
            (1 - c((b.longitude - a.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a1)); // км
  }

  double _distanceMeters(LatLng a, LatLng b) => _distKm(a, b) * 1000.0;

  double get totalKm {
    if (_points.length < 2) return 0;
    double s = 0;
    for (int i = 0; i + 1 < _points.length; i++) {
      s += _distKm(_points[i], _points[i + 1]);
    }
    if (_closed && _points.length >= 3) {
      s += _distKm(_points.last, _points.first);
    }
    // округляем до 3 знаков
    return double.parse(s.toStringAsFixed(3));
  }

  /// Добавление точки.
  /// Если нажали рядом с первой точкой при >= 3 точках — просто замыкаем,
  /// а не добавляем новую.
  bool addPoint(LatLng p) {
    if (_points.isNotEmpty && _points.length >= 3) {
      final d = _distanceMeters(p, _points.first);
      if (d <= 15) {
        _closed = true;
        return false; // точку не добавляли
      }
    }
    _points.add(p);
    if (_points.length < 3) _closed = false;
    return true;
  }

  /// Клик по маркеру:
  /// - по первой точке переключаем замыкание
  /// - по другим точкам — удаляем их
  void onMarkerTap(int index) {
    if (index == 0 && _points.length >= 3) {
      _closed = !_closed;
    } else {
      removePoint(index);
    }
  }

  void removePoint(int index) {
    if (index < 0 || index >= _points.length) return;
    _points.removeAt(index);
    if (_points.length < 3) _closed = false;
  }

  void updatePoint(int index, LatLng p) {
    if (index < 0 || index >= _points.length) return;
    _points[index] = p;
  }

  void clear() {
    _points.clear();
    _closed = false;
  }
}

class _RoutePlannerPageState extends State<RoutePlannerPage> {
  GoogleMapController? _map;
  final _loc = Location();

  final _controllerLogic = _RoutePlannerController();

  // Стартовая позиция камеры
  LatLng _camera = const LatLng(59.0, 26.0);

  // Иконка точек
  BitmapDescriptor? _dotIcon;

  @override
  void initState() {
    super.initState();
    _initDot();
    _centerToMyLocation();
  }

  Future<void> _initDot() async {
    _dotIcon = await MarkerDot.get(size: 16);
    if (mounted) setState(() {});
  }

  Future<void> _centerToMyLocation() async {
    try {
      bool s = await _loc.serviceEnabled();
      if (!s) s = await _loc.requestService();
      var p = await _loc.hasPermission();
      if (p == PermissionStatus.denied) p = await _loc.requestPermission();
      if (p != PermissionStatus.granted) return;

      final l = await _loc.getLocation();
      if (l.latitude == null || l.longitude == null) return;

      setState(() => _camera = LatLng(l.latitude!, l.longitude!));
      _map?.animateCamera(CameraUpdate.newLatLngZoom(_camera, 15));
    } catch (_) {}
  }

  // Подогнать камеру под все точки
  void _fitBounds() {
    final points = _controllerLogic.points;
    if (points.length < 2 || _map == null) return;

    double minLat = points.first.latitude,
        maxLat = points.first.latitude,
        minLng = points.first.longitude,
        maxLng = points.first.longitude;

    for (final p in points) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    _map!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  void _onAddPoint(LatLng p) {
    final added = _controllerLogic.addPoint(p);
    setState(() {});
    if (added) _fitBounds();
  }

  void _onClear() {
    setState(() => _controllerLogic.clear());
  }

  Future<void> _save() async {
    final points = _controllerLogic.points;
    if (points.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least two points')),
      );
      return;
    }

    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save route'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Route name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final pts = _controllerLogic.polylinePoints
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList();

    await FirebaseFirestore.instance.collection('routes').add({
      'userId': uid,
      'name': name,
      'points': pts,
      'lengthKm': _controllerLogic.totalKm,
      'createdAt': DateTime.now(),
      'isPrivate': true,
      'closed': _controllerLogic.closed,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Route is saved')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final points = _controllerLogic.points;
    final polylinePoints = _controllerLogic.polylinePoints;
    final totalKm = _controllerLogic.totalKm;

    final markers = <Marker>{
      for (int i = 0; i < points.length; i++)
        Marker(
          markerId: MarkerId('p$i'),
          position: points[i],
          draggable: true,
          onDragEnd: (p) => setState(() => _controllerLogic.updatePoint(i, p)),
          onTap: () => setState(() => _controllerLogic.onMarkerTap(i)),
          icon: i == 0
              ? BitmapDescriptor.defaultMarker
              : (_dotIcon ?? BitmapDescriptor.defaultMarker),
          anchor: i == 0 ? const Offset(0.5, 1.0) : const Offset(0.5, 0.5),
          zIndex: i == 0 ? 20 : 10,
        ),
    };

    final polylines = <Polyline>{
      if (points.isNotEmpty)
        Polyline(
          polylineId: const PolylineId('planned'),
          color: Colors.blue,
          width: 6,
          points: polylinePoints,
        ),
    };

    return Scaffold(
      appBar: NewAppBar(
        title: 'Route planner',
        onPressed: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.hybrid,
            initialCameraPosition: CameraPosition(target: _camera, zoom: 12),
            onMapCreated: (c) => _map = c,
            markers: markers,
            polylines: polylines,
            onLongPress: _onAddPoint,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),

          // счётчик точек + длина
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Pts: ${points.length}  •  ${totalKm.toStringAsFixed(3)} km',
                  style: const TextStyle(
                    color: surfaceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // кнопка "центрировать на мне"
          Positioned(
            right: 16,
            top: 12,
            child: SafeArea(
              bottom: false,
              child: FloatingActionButton.small(
                backgroundColor: Colors.black87,
                onPressed: _centerToMyLocation,
                child: const Icon(Icons.my_location, color: surfaceColor),
              ),
            ),
          ),

          // нижняя панель
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: RouteActionBar(
                onSave: _save,
                onToggleGo: null,
                onDelete: points.isEmpty ? null : _onClear,
                canSave: points.length >= 2,
                canDelete: points.isNotEmpty,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
