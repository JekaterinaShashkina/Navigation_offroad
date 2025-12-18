import 'dart:async';
import 'dart:math' show cos, sqrt, asin, sin, atan2, pi;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:offroad_nav/features/routes/presentation/tracking/live_tracking_source.dart';
import 'package:offroad_nav/features/routes/presentation/tracking/sim_tracking_source.dart';
import 'package:offroad_nav/features/routes/presentation/tracking/tracking_sample.dart';
import 'package:offroad_nav/features/routes/presentation/tracking/tracking_source.dart';
import 'package:offroad_nav/features/routes/presentation/utils/marker_icon.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
   // _initLocationTracking();

  _source = widget.mode == TrackingMode.simulated
      ? SimTrackingSource(points: widget.points)
      : LiveTrackingSource();

  _sub = _source.watch().listen((s) {
    setState(() {
      _currentPosition = s.pos;
      _bearing = s.bearingDeg;
      _startTime ??= DateTime.now();
    });
    _updateCameraPosition();
    _updateRouteProgress(s.pos);
    _sendToFirebase(s.pos); // если хочешь отправлять и в симуляции тоже
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

  LatLng _offsetFromPosition(
    LatLng position, 
    double distanceMetersForward, 
    double distanceMetersRight, 
    double bearingDegrees) {
    const double earthRadius = 6378137.0; // Радиус Земли в метрах
    // Конвертация bearing в радианы
    double bearingRad = bearingDegrees * pi / 180;

    // Смещение вперед и вправо относительно текущего направления
    // bearingRad = 0 - направление на север

    // Рассчитываем угол для смещения (учитывая, что bearing - это направление камеры)
    double angleRight = bearingRad + pi / 2; // право относительно направления

    // Смещение в метрах по северу и востоку
    double deltaNorth = distanceMetersForward * cos(bearingRad) + distanceMetersRight * cos(angleRight);
    double deltaEast = distanceMetersForward * sin(bearingRad) + distanceMetersRight * sin(angleRight);

    // Переводим метры в градусы
    double deltaLat = deltaNorth / earthRadius * (180 / pi);
    double deltaLon = deltaEast / (earthRadius * cos(position.latitude * pi / 180)) * (180 / pi);

    return LatLng(position.latitude + deltaLat, position.longitude + deltaLon);
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
    traversedPoints.add(current);
    int currentIndex = _closestPointIndex(current);
    List<LatLng> remainingPoints = widget.points.sublist(currentIndex);

    remainingDistance = 0.0;
    for (int i = 0; i < remainingPoints.length - 1; i++) {
      remainingDistance += _calculateDistance(remainingPoints[i], remainingPoints[i + 1]);
    }

    final elapsed = _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero;
    double averageSpeed = (elapsed.inSeconds > 0 && traversedPoints.length > 1)
        ? traversedPoints
                .asMap()
                .entries
                .skip(1)
                .map((e) => _calculateDistance(traversedPoints[e.key - 1], e.value))
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
      final d = _calculateDistance(pos, widget.points[i]);
      if (d < minDist) {
        minDist = d;
        index = i;
      }
    }
    return index;
  }

  double _calculateDistance(LatLng a, LatLng b) {
    const double p = 0.017453292519943295;
    final double lat1 = a.latitude;
    final double lon1 = a.longitude;
    final double lat2 = b.latitude;
    final double lon2 = b.longitude;
    final double a1 = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a1));
  }

  @override
  void dispose() {
  _sub?.cancel();
  _source.dispose();
  super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<LatLng> traversed = traversedPoints.toList();
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
                rotation: _bearing,
                icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                anchor: const Offset(0.5, 0.5),
              ),
            },
            onMapCreated: (controller) => _controller = controller,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
          ),
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
                    "Осталось: ${remainingDistance.toStringAsFixed(2)} км",
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
}