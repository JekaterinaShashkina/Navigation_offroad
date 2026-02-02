import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../design/widgets/app_bar.dart';
import '../widgets/map_right_buttons.dart';
import '../widgets/navigation_bottom_panel.dart';

class CompletedRouteDetailPage extends StatefulWidget {
  final String name;

  /// Фактически пройденный трек: [{lat: ..., lng: ...}, ...]
final List<Map<String, double>> completedPoints;
final List<Map<String, double>>? plannedPoints;

  /// Доп. метаданные (опционально)
  final DateTime? completedAt;
  final Duration? duration;

  const CompletedRouteDetailPage({
    super.key,
    required this.name,
    required this.completedPoints,
    this.plannedPoints,
    this.completedAt,
    this.duration,
  });

  @override
  State<CompletedRouteDetailPage> createState() =>
      _CompletedRouteDetailPageState();
}

class _CompletedRouteDetailPageState extends State<CompletedRouteDetailPage> {
  GoogleMapController? _mapController;

  final List<LatLng> _completed = <LatLng>[];
  final List<LatLng> _planned = <LatLng>[];

  double _distanceKm = 0;

  @override
  void initState() {
    super.initState();
    
    _completed.addAll(
      widget.completedPoints.map((m) => LatLng(m['lat']!, m['lng']!)),
    );

      if (widget.plannedPoints != null) {
    _planned.addAll(
      widget.plannedPoints!
          .map((m) => LatLng(m['lat']!, m['lng']!)),
    );
    }

    // Дистанцию логичнее считать по фактическому треку.
    final baseForDistance = _completed.isNotEmpty ? _completed : _planned;
    _distanceKm = _computeRouteDistanceKm(baseForDistance);
  }

  // ----- расчёт дистанции -----

  double _computeRouteDistanceKm(List<LatLng> pts) {
    if (pts.length < 2) return 0;
    double sum = 0;
    for (var i = 1; i < pts.length; i++) {
      sum += _distM(pts[i - 1], pts[i]);
    }
    return sum / 1000.0;
  }

  double _distM(LatLng a, LatLng b) {
    const R = 6378137.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180.0;
    final dLon = (b.longitude - a.longitude) * math.pi / 180.0;
    final la1 = a.latitude * math.pi / 180.0;
    final la2 = b.latitude * math.pi / 180.0;
    final s1 = math.sin(dLat / 2);
    final s2 = math.sin(dLon / 2);
    final h = s1 * s1 + math.cos(la1) * math.cos(la2) * s2 * s2;
    final c = 2 * math.asin(math.min(1.0, math.sqrt(h)));
    return R * c;
  }

  // ----- bounds / camera -----

  void _fitMapToAll() {
    if (_mapController == null) return;

    final all = <LatLng>[..._planned, ..._completed];
    if (all.isEmpty) return;

    final bounds = _createBoundsFromLatLngList(all);
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 60),
    );
  }

  LatLngBounds _createBoundsFromLatLngList(List<LatLng> list) {
    double x0 = list.first.latitude, x1 = list.first.latitude;
    double y0 = list.first.longitude, y1 = list.first.longitude;

    for (final p in list) {
      if (p.latitude > x1) x1 = p.latitude;
      if (p.latitude < x0) x0 = p.latitude;
      if (p.longitude > y1) y1 = p.longitude;
      if (p.longitude < y0) y0 = p.longitude;
    }

    return LatLngBounds(
      northeast: LatLng(x1, y1),
      southwest: LatLng(x0, y0),
    );
  }

  LatLng _fallbackTarget() {
    if (_completed.isNotEmpty) return _completed.first;
    if (_planned.isNotEmpty) return _planned.first;
    return const LatLng(59.0, 26.0);
  }

  void _centerCamera() {
    if (_mapController == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _fallbackTarget(),
          zoom: 17,
          tilt: 60,
          bearing: 0,
        ),
      ),
    );
  }

  void _faceNorth() {
    if (_mapController == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _fallbackTarget(),
          zoom: 17,
          bearing: 0,
        ),
      ),
    );
  }

  // ----- formatting helpers -----

  String _formatDuration(Duration d) {
    final totalMin = d.inMinutes;
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    if (h > 0) return '$h hr ${m.toString().padLeft(2, '0')} min';
    return '$m min';
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final distanceTextValue = _distanceKm.toStringAsFixed(1);

    final timeText = widget.duration != null
        ? _formatDuration(widget.duration!)
        : (_distanceKm <= 0 ? '0 min' : '—');

    // например: "3.4 km · 18:25"
    final rightMeta = widget.completedAt != null
        ? _formatTime(widget.completedAt!)
        : '';
    final distanceText =
        rightMeta.isEmpty ? '$distanceTextValue km' : '$distanceTextValue km · $rightMeta';

    final markers = <Marker>{};
    if (_planned.isNotEmpty) {
      markers.add(
        Marker(
          markerId: const MarkerId('planned_start'),
          position: _planned.first,
          infoWindow: const InfoWindow(title: 'Planned start'),
        ),
      );
    }
    if (_completed.isNotEmpty) {
      markers.add(
        Marker(
          markerId: const MarkerId('completed_start'),
          position: _completed.first,
          infoWindow: const InfoWindow(title: 'Completed start'),
        ),
      );
      markers.add(
        Marker(
          markerId: const MarkerId('completed_finish'),
          position: _completed.last,
          infoWindow: const InfoWindow(title: 'Finish'),
        ),
      );
    }

    return Scaffold(
      appBar: NewAppBar(
        title: widget.name,
        onPressed: () => Navigator.of(context).pop(),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.hybrid,
            padding: const EdgeInsets.only(
              bottom: 160,
              top: 40,
            ),
            initialCameraPosition: CameraPosition(
              target: _fallbackTarget(),
              zoom: 13,
            ),
            polylines: {
              if (_planned.isNotEmpty)
                Polyline(
                  polylineId: const PolylineId('planned'),
                  // если хочешь другой цвет — поменяй на твой blue
                  color: Colors.blueAccent,
                  width: 4,
                  points: _planned,
                ),
              if (_completed.isNotEmpty)
                Polyline(
                  polylineId: const PolylineId('completed'),
                  color: Colors.greenAccent,
                  width: 5,
                  points: _completed,
                ),
            },
            markers: markers,
            onMapCreated: (controller) {
              _mapController = controller;
              Future.delayed(const Duration(milliseconds: 300), _fitMapToAll);
            },
          ),

          Positioned(
            right: 16,
            top: 100,
            child: MapRightButtons(
              onCenter: _centerCamera,
              onNorth: _faceNorth,
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: NavigationBottomPanel(
              timeText: timeText,
              distanceText: distanceText,

              // Для completed-route вместо GO логичнее сделать Close.
              // Если хочешь сохранить дизайн “кнопка справа” — пусть будет Close.
              //onGo: () => Navigator.pop(context),
              showPrimaryButton: false,
              // и крестик тоже close
              onClose: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
