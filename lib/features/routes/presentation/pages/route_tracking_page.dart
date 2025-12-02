import 'dart:async';
import 'dart:math' show cos, sqrt, asin, sin, atan2, pi;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import '../../../../design/widgets/app_bar.dart';
import '../../data/repositories/route_tracking_repository.dart';

class RouteTrackingPage extends StatefulWidget {
  final List<LatLng> points;

  const RouteTrackingPage({super.key, required this.points});

  @override
  State<RouteTrackingPage> createState() => _RouteTrackingPageState();
}

class _RouteTrackingPageState extends State<RouteTrackingPage> {
  GoogleMapController? _controller;
  Location _location = Location();
  LatLng? _currentPosition;
  double _bearing = 0.0;
  StreamSubscription<LocationData>? _locationSub;
  Timer? _simulationTimer;
  BitmapDescriptor? _customMarkerIcon;

  List<LatLng> traversedPoints = [];
  Duration eta = Duration.zero;
  double remainingDistance = 0.0;
  DateTime? _startTime;
  int _simulationIndex = 0;
  final bool simulate = true;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _initLocationTracking();
  }

  Future<void> _loadCustomMarker() async {
    final bitmap = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/navigation_arrow.png',
    );
    setState(() {
      _customMarkerIcon = bitmap;
    });
  }

  Future<void> _initLocationTracking() async {
    if (simulate) {
      _startTime = DateTime.now();
      _startSimulation(widget.points);
      return;
    }

  bool _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) return;
    }

  PermissionStatus _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) return;
    }

    _locationSub = _location.onLocationChanged.listen((loc) {
      final newPosition = LatLng(loc.latitude!, loc.longitude!);
      _updateBearing(_currentPosition, newPosition);
      setState(() => _currentPosition = newPosition);
      _updateCameraPosition();
      _updateRouteProgress(newPosition);
      _sendToFirebase(newPosition);
    });
  }

  void _startSimulation(List<LatLng> points) {
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_simulationIndex >= points.length) {
        timer.cancel();
        return;
      }

      final simulatedPos = points[_simulationIndex];
      final previousPos = _simulationIndex > 0 ? points[_simulationIndex - 1] : simulatedPos;
      _simulationIndex++;

      _updateBearing(previousPos, simulatedPos);
      setState(() => _currentPosition = simulatedPos);
      _updateCameraPosition();
      _updateRouteProgress(simulatedPos);
      _sendToFirebase(simulatedPos);
    });
  }

  void _updateBearing(LatLng? from, LatLng to) {
    if (from == null) return;
    final dLon = (to.longitude - from.longitude) * pi / 180;
    final y = sin(dLon) * cos(to.latitude * pi / 180);
    final x = cos(from.latitude * pi / 180) * sin(to.latitude * pi / 180) -
        sin(from.latitude * pi / 180) * cos(to.latitude * pi / 180) * cos(dLon);
    final bearingRad = atan2(y, x);
    final bearingDeg = (bearingRad * 180 / pi + 360) % 360;
    setState(() {
      _bearing = bearingDeg;
    });
  }

  LatLng _offsetFromPosition(LatLng position, double distanceMetersForward, double distanceMetersRight, double bearingDegrees) {
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

    double zoom = 18;

    // Смещаем камеру вперёд на 100м, и вправо 0 (можно менять для точной настройки)
    double forwardOffsetMeters = 140;  // сдвиг камеры вперед от позиции
    double rightOffsetMeters = 0;

    LatLng target = _offsetFromPosition(_currentPosition!, forwardOffsetMeters, rightOffsetMeters, _bearing);

    _controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: zoom,
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
    _locationSub?.cancel();
    _simulationTimer?.cancel();
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
                rotation: 0,
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