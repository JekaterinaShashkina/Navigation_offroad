import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../design/colors.dart';
import '../../../../design/widgets/app_bar.dart';
import '../widgets/map_right_buttons.dart';
import '../widgets/navigation_bottom_panel.dart';
import 'route_tracking_page.dart';

class RouteDetailPage extends StatefulWidget {
  final String name;           // название маршрута
  final List<dynamic> points;  // список map-ов: { 'lat': double, 'lng': double }
  final String? groupId;

  const RouteDetailPage({
    super.key,
    required this.name,
    required this.points, 
    this.groupId,
  });

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  GoogleMapController? _mapController;

  late final List<LatLng> _routePoints;
  double _routeDistanceKm = 0; // длина маршрута в км

  @override
  void initState() {
    super.initState();

    // Преобразуем points в LatLng
    _routePoints = widget.points
        .map<LatLng>((p) {
          final m = p as Map;
          final lat = (m['lat'] as num).toDouble();
          final lng = (m['lng'] as num).toDouble();
          return LatLng(lat, lng);
        })
        .toList();

    // Считаем длину маршрута
    _routeDistanceKm = _computeRouteDistanceKm(_routePoints);
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

  // ----- работа с картой -----

  void _fitMapToPolyline() {
    if (_mapController == null || _routePoints.isEmpty) return;

    final bounds = _createBoundsFromLatLngList(_routePoints);
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 60),
    );
  }

  LatLngBounds _createBoundsFromLatLngList(List<LatLng> list) {
    double x0 = list.first.latitude, x1 = list.first.latitude;
    double y0 = list.first.longitude, y1 = list.first.longitude;

    for (LatLng latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }

    return LatLngBounds(
      northeast: LatLng(x1, y1),
      southwest: LatLng(x0, y0),
    );
  }

  // кнопка "центрировать" — центр на старте маршрута
  void _centerCamera() {
  if (_mapController == null) return;

  _mapController!.animateCamera(
    CameraUpdate.newCameraPosition(
      CameraPosition(
        target: _routePoints.first,
        zoom: 17,
        tilt: 60,      // если нужен наклон
        bearing: 0, // если есть расчёт курса
      ),
    ),
  );
  }


  // кнопка "на север"
  void _faceNorth() {
    if (_mapController == null || _routePoints.isEmpty) return;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _routePoints.first,
          zoom: 17,
          bearing: 0, // поворот на север
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ---------- расчёт времени и ETA ----------

    const double avgSpeedKmh = 5.0; // пока фикс: пешком 5 км/ч

    final distanceKm = _routeDistanceKm;
    final hours = avgSpeedKmh > 0 ? distanceKm / avgSpeedKmh : 0.0;
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;

    final timeText = distanceKm <= 0
        ? '0 min'
        : (h > 0
            ? '$h hr ${m.toString().padLeft(2, '0')} min'
            : '$m min');

    final distanceTextValue = distanceKm.toStringAsFixed(1);

    final eta = DateTime.now().add(Duration(minutes: totalMinutes));
    final etaStr =
        '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';

    final distanceText = '$distanceTextValue km · $etaStr';

    // ---------- UI ----------

    return Scaffold(
      appBar: NewAppBar(
        title: widget.name,
        onPressed: () => Navigator.of(context).pop(),
      ),
      body: Stack(
        children: [
          // 1. Карта
          GoogleMap(
            mapType: MapType.hybrid,
              padding: const EdgeInsets.only(
                bottom: 160, // поднимет "геометрический" центр карты выше низа
                top: 40,     // можно чуть-чуть, чтобы не упираться в appBar
              ),
            initialCameraPosition: CameraPosition(
              target: _routePoints.isNotEmpty
                  ? _routePoints.first
                  : const LatLng(59.0, 26.0),
              zoom: 13,
            ),
            polylines: {
              Polyline(
                polylineId: const PolylineId('route'),
                color: chipBgColor,
                width: 4,
                points: _routePoints,
              ),
            },
            markers: {
              if (_routePoints.isNotEmpty)
                Marker(
                  markerId: const MarkerId('start'),
                  position: _routePoints.first,
                  infoWindow: const InfoWindow(title: 'Start'),
                ),
            },
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              Future.delayed(
                const Duration(milliseconds: 300),
                _fitMapToPolyline,
              );
            },
          ),

          // 2. Кнопки справа (центр/север)
          Positioned(
            right: 16,
            top: 100,
            child: MapRightButtons(
              onCenter: _centerCamera,
              onNorth: _faceNorth,
            ),
          ),

          // 3. Нижняя панель с названием, временем, расстоянием и кнопкой GO
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: NavigationBottomPanel(
              timeText: timeText,
              distanceText: distanceText,
              // СИМУЛЯЦИЯ
              onGo: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RouteTrackingPage(
                      points: _routePoints,
                      mode: TrackingMode.simulated,
                      groupId: widget.groupId,
                      // mode: TrackingMode.live,
                    ),
                  ),
                );
              },
              onClose: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
