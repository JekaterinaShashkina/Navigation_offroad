import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/widgets/route_action_bar.dart';
import 'package:offroad_nav/utils/marker_dot.dart'; // helper для круглых точек

class RoutePlannerPage extends StatefulWidget {
  const RoutePlannerPage({super.key});

  @override
  State<RoutePlannerPage> createState() => _RoutePlannerPageState();
}

class _RoutePlannerPageState extends State<RoutePlannerPage> {
  GoogleMapController? _map;
  final _loc = Location();

  // Точки маршрута
  final List<LatLng> _points = [];
  bool _closed = false; // замкнут ли контур

  // Стартовая позиция камеры
  LatLng _camera = const LatLng(59.0, 26.0);

  // Иконка «точки»
  BitmapDescriptor? _dotIcon;

  @override
  void initState() {
    super.initState();
    _initDot();
    _centerToMyLocation();
  }

  Future<void> _initDot() async {
    // можно настроить размер/цвет
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

  // ========== ГЕОМЕТРИЯ ==========

  // список точек для рисования линии (если замкнуто — добавляем первую в конец)
  List<LatLng> get _polylinePoints {
    final list = List<LatLng>.from(_points);
    if (_closed && _points.length >= 3) list.add(_points.first);
    return list;
  }

  // Дистанция (км) между двумя точками (Haversine)
  double _distKm(LatLng a, LatLng b) {
    const p = 0.017453292519943295; // pi/180
    final c = cos;
    final a1 = 0.5 -
        c((b.latitude - a.latitude) * p) / 2 +
        c(a.latitude * p) * c(b.latitude * p) * (1 - c((b.longitude - a.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a1)); // км
  }

  // Общая длина маршрута (км)
  double get _totalKm {
    if (_points.length < 2) return 0;
    double s = 0;
    for (int i = 0; i + 1 < _points.length; i++) {
      s += _distKm(_points[i], _points[i + 1]);
    }
    if (_closed && _points.length >= 3) {
      s += _distKm(_points.last, _points.first);
    }
    return double.parse(s.toStringAsFixed(3));
  }

  // Небольшая утилита расстояния в метрах
  double _distanceMeters(LatLng a, LatLng b) => _distKm(a, b) * 1000.0;

  // ========== РЕДАКТИРОВАНИЕ ТОЧЕК ==========

  // Добавить точку (по long-press)
  void _addPoint(LatLng p) {
    // если тыкнули рядом со стартом — просто замкнём
    if (_points.isNotEmpty && _points.length >= 3) {
      final d = _distanceMeters(p, _points.first);
      if (d <= 15) {
        setState(() => _closed = true);
        return;
      }
    }
    setState(() {
      _points.add(p);
      if (_points.length < 3) _closed = false; // до 3 точек не замыкаем
    });
    _fitBounds();
  }

  // Клик по маркеру: для первой — переключить замыкание, для остальных — удалить
  void _onMarkerTap(int i) {
    if (i == 0 && _points.length >= 3) {
      setState(() => _closed = !_closed);
    } else {
      _removePoint(i);
    }
  }

  void _removePoint(int i) {
    if (i < 0 || i >= _points.length) return;
    setState(() {
      _points.removeAt(i);
      if (_points.length < 3) _closed = false;
    });
  }

  void _updatePoint(int i, LatLng p) {
    setState(() => _points[i] = p);
  }

  // Подогнать камеру
  void _fitBounds() {
    if (_points.length < 2 || _map == null) return;
    double minLat = _points.first.latitude,
        maxLat = _points.first.latitude,
        minLng = _points.first.longitude,
        maxLng = _points.first.longitude;

    for (final p in _points) {
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

  void _clear() {
    setState(() {
      _points.clear();
      _closed = false;
    });
  }

  // ========== СОХРАНЕНИЕ ==========

  Future<void> _save() async {
    if (_points.length < 2) {
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

    // Берём _polylinePoints — если _closed, первая точка уже добавлена в конец
    final pts = _polylinePoints
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList();

    await FirebaseFirestore.instance.collection('routes').add({
      'userId': uid,
      'name': name,
      'points': pts,           // замыкающий сегмент сохранён
      'lengthKm': _totalKm,
      'createdAt': DateTime.now(),
      'isPrivate': true,
      'closed': _closed,       // флаг тоже полезно хранить
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Route is saved')));
    Navigator.pop(context);
  }

  // ========== UI ==========

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{
      for (int i = 0; i < _points.length; i++)
        Marker(
          markerId: MarkerId('p$i'),
          position: _points[i],
          draggable: true,
          onDragEnd: (p) => _updatePoint(i, p),
          onTap: () => _onMarkerTap(i),
          icon: i == 0
              ? BitmapDescriptor.defaultMarker // первая — маркер
              : (_dotIcon ?? BitmapDescriptor.defaultMarker), // остальные — «точки»
          anchor: i == 0 ? const Offset(0.5, 1.0) : const Offset(0.5, 0.5),
          zIndex: i == 0 ? 20 : 10,
        ),
    };

    final polylines = <Polyline>{
      if (_points.isNotEmpty)
        Polyline(
          polylineId: const PolylineId('planned'),
          color: Colors.blue,
          width: 6,
          points: _polylinePoints, // учитываем замыкание
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
            onLongPress: _addPoint,       // добавление точки
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),

          // Cчётчик точек + длина
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
                  'Pts: ${_points.length}  •  ${_totalKm.toStringAsFixed(3)} km',
                  style: const TextStyle(color: surfaceColor, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),

          // Кнопка «центрировать на мне»
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

          // Нижняя панель действий (Save / Delete)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: RouteActionBar(
                onSave: _save,
                onToggleGo: null,   // в планировщике не нужна
                onDelete: _points.isEmpty ? null : _clear,
                canSave: _points.length >= 2,
                canDelete: _points.isNotEmpty,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
