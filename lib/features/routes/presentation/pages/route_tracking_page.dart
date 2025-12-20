import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
//import 'package:offroad_nav/features/routes/presentation/tracking/tracker_controller.dart';
import 'package:offroad_nav/features/routes/presentation/tracking/live_tracking_source.dart';
import 'package:offroad_nav/features/routes/presentation/tracking/sim_tracking_source.dart';
import 'package:offroad_nav/features/routes/presentation/tracking/tracking_sample.dart';
import 'package:offroad_nav/features/routes/presentation/tracking/tracking_source.dart';
import 'package:offroad_nav/features/routes/presentation/utils/marker_icon.dart';
import 'package:offroad_nav/features/routes/presentation/utils/route_math.dart';

import '../../../../design/widgets/app_bar.dart';
import '../../data/repositories/route_tracking_repository.dart';

enum TrackingMode { simulated, live }

class RouteTrackingPage extends StatefulWidget {
  final List<LatLng> points;  
  final TrackingMode  mode;

  const RouteTrackingPage({super.key, required this.points, this.mode = TrackingMode.simulated,});

  @override
  State<RouteTrackingPage> createState() => _RouteTrackingPageState();
}
class _RouteTrackingPageState extends State<RouteTrackingPage> {
  GoogleMapController? _controller;
  LatLng? _currentPosition;
  double _bearing = 0.0;
  BitmapDescriptor? _customMarkerIcon;
  List<LatLng> traversedPoints = [];
  Duration eta = Duration.zero;
  double remainingDistance = 0.0;
  DateTime? _startTime;
  late final ITrackingSource _source;
StreamSubscription<TrackSample>? _sub;
//late final TrackerController _ctrl;
double? _distanceToStartM;

bool _started = false;              // маршрут реально начался
static const double _startRadiusM = 20; // порог старта (можешь 15/20)
bool get _showStartBanner =>
    widget.mode == TrackingMode.live &&
    !_started &&
    _distanceToStartM != null &&
    _distanceToStartM! > _startRadiusM;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    // _ctrl = TrackerController();
    // _ctrl.followMe = true;
  _source = widget.mode == TrackingMode.simulated
      ? SimTrackingSource(points: widget.points)
      : LiveTrackingSource(
          startPoint: widget.points.isNotEmpty ? widget.points.first : null,
          requireStartWithinM: 20,
      );

_sub = _source.watch().listen((s) {
  if (!mounted) return;

  // 1) всегда обновляем позицию + bearing (чтобы стрелка была)
  setState(() {
    _currentPosition = s.pos;
    _bearing = s.bearingDeg;
  });

  // 2) только для live: проверяем дистанцию до старта, пока не стартовали
  if (widget.mode == TrackingMode.live && !_started && widget.points.isNotEmpty) {
    final dist = distanceM(s.pos, widget.points.first);
    setState(() => _distanceToStartM = dist);

    // если далеко — просто показываем баннер и НЕ считаем прогресс
    if (dist > _startRadiusM) {
      _updateCameraPosition(); // можно оставить — чтобы камера следовала за тобой
      return;
    }

    // подошли к старту => фиксируем старт один раз
    setState(() {
      _started = true;
      _distanceToStartM = null;
      _startTime = DateTime.now();
      traversedPoints.clear();       // на всякий
      remainingDistance = 0;
      eta = Duration.zero;
    });
  }

  // 3) обычный режим: симуляция всегда "started", live — после старта
  _startTime ??= DateTime.now();
  _updateCameraPosition();
  _updateRouteProgress(s.pos);
  _sendToFirebase(s.pos);
});
  }

Future<void> _loadCustomMarker() async {
  final bitmap = await MarkerIcon.fromPngAsset(
    'assets/images/navigation_arrow.png',
    widthPx: 36,
    heightPx: 36,
  );

  if (!mounted) return;
  setState(() => _customMarkerIcon = bitmap);
  }

  void _updateCameraPosition() {
  if (_currentPosition == null || _controller == null) return;

  _controller!.animateCamera(
    CameraUpdate.newCameraPosition(
      CameraPosition(
        target: _currentPosition!,
        zoom: 18,
        tilt: 60,
        bearing: _bearing,
      ),
    ),
  );
  }

  void _sendToFirebase(LatLng pos) {
    RouteTrackingRepository.instance.sendLocation(
      lat: pos.latitude,
      lng: pos.longitude,
    );
  }

  void _updateRouteProgress(LatLng current) {
    if (widget.mode == TrackingMode.simulated || _started) {
      traversedPoints.add(current);
    }
    final hasStarted = widget.mode == TrackingMode.simulated || _started;
    final remainingPoints = hasStarted && _currentPosition != null
    ? widget.points.sublist(_closestPointIndex(_currentPosition!))
    : widget.points;

    remainingDistance = 0.0;
    for (int i = 0; i < remainingPoints.length - 1; i++) {
      remainingDistance += distanceM(remainingPoints[i], remainingPoints[i + 1]);
    }

    final elapsed = _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero;
    double averageSpeed = (elapsed.inSeconds > 0 && traversedPoints.length > 1)
        ? traversedPoints
                .asMap()
                .entries
                .skip(1)
                .map((e) => distanceM(traversedPoints[e.key - 1], e.value))
                .reduce((a, b) => a + b) /
            elapsed.inSeconds
        : 0.0;

    eta = (averageSpeed > 0)
        ? Duration(seconds: (remainingDistance / averageSpeed).round())
        : Duration.zero;
  }

  int _closestPointIndex(LatLng pos) {
    double minDist = double.infinity;
    int index = 0;
    for (int i = 0; i < widget.points.length; i++) {
      final d = distanceM(pos, widget.points[i]);
      if (d < minDist) {
        minDist = d;
        index = i;
      }
    }
    return index;
  }

  @override
  void dispose() {
  _sub?.cancel();
  _source.dispose();
  super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final traversed = (_started || widget.mode == TrackingMode.simulated)
    ? traversedPoints.toList()
    : <LatLng>[];

    int currentIndex = _currentPosition != null ? _closestPointIndex(_currentPosition!) : 0;
    List<LatLng> remaining = widget.points.sublist(currentIndex);

    return Scaffold(
      appBar: NewAppBar(
        title: "Прохождение маршрута",
        onPressed: () => Navigator.of(context).pop(),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.hybrid,
            initialCameraPosition: CameraPosition(
              target: widget.points.first,
              zoom: 15,
            ),
            polylines: {
              Polyline(
                polylineId: const PolylineId('traversed'),
                color: Colors.green,
                width: 5,
                points: traversed,
              ),
              Polyline(
                polylineId: const PolylineId('remaining'),
                color: Colors.blue,
                width: 4,
                points: remaining,
              ),
            },
            markers: {
              Marker(
                markerId: const MarkerId('start'),
                position: widget.points.first,
                infoWindow: const InfoWindow(title: 'Start'),
              ),
              Marker(
                markerId: const MarkerId('end'),
                position: widget.points.last,
                infoWindow: const InfoWindow(title: 'Finish'),
              ),
              if (_currentPosition != null)
              Marker(
                markerId: const MarkerId('me'),
                position: _currentPosition!,
                rotation: _normalize(_bearing),
                icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                anchor: const Offset(0.5, 0.5),
                flat: true,
                
              ),
            },
            onMapCreated: (controller) => _controller = controller,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
          ),
            if (_showStartBanner)
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Подойдите к старту: ${_distanceToStartM!.round()} м',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          if (_started || widget.mode == TrackingMode.simulated)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Осталось: ${(remainingDistance/1000).toStringAsFixed(2)} км",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    "ETA: ${eta.inMinutes} мин",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _normalize(double deg) {
  deg %= 360;
  if (deg < 0) deg += 360;
  return deg;
}
}