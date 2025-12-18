import 'dart:async';
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import 'tracking_sample.dart';
import 'tracking_source.dart';

class LiveTrackingSource implements ITrackingSource {
  LiveTrackingSource({
    Location? location,
    this.accMaxM = 35,
    this.maxJumpM = 40,
  }) : _loc = location ?? Location();

  final Location _loc;
  final double accMaxM;
  final double maxJumpM;

  final _ctrl = StreamController<TrackSample>.broadcast();
  StreamSubscription<LocationData>? _sub;
  LatLng? _prev;

  @override
  Stream<TrackSample> watch() {
    _startIfNeeded();
    return _ctrl.stream;
  }

  Future<void> _startIfNeeded() async {
    if (_sub != null) return;

    bool serviceEnabled = await _loc.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _loc.requestService();
      if (!serviceEnabled) return;
    }

    var perm = await _loc.hasPermission();
    if (perm == PermissionStatus.denied) {
      perm = await _loc.requestPermission();
    }
    if (perm != PermissionStatus.granted) return;

    await _loc.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000,
      distanceFilter: 2,
    );

    _sub = _loc.onLocationChanged.listen((loc) {
      if (loc.latitude == null || loc.longitude == null) return;

      if (loc.accuracy != null && loc.accuracy! > accMaxM) return;

      final cur = LatLng(loc.latitude!, loc.longitude!);

      // jump filter
      if (_prev != null) {
        final jump = _distanceMeters(_prev!, cur);
        if (jump > maxJumpM) return;
      }

      final bearing = _prev == null ? 0.0 : _bearing(_prev!, cur);
      _prev = cur;

      _ctrl.add(
        TrackSample(
          pos: cur,
          bearingDeg: bearing,
          accuracyM: loc.accuracy?.toDouble(),
        ),
      );
    });
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const R = 6378137.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180.0;
    final dLon = (b.longitude - a.longitude) * math.pi / 180.0;
    final lat1 = a.latitude * math.pi / 180.0;
    final lat2 = b.latitude * math.pi / 180.0;

    final sinDLat = math.sin(dLat / 2);
    final sinDLon = math.sin(dLon / 2);

    final h = sinDLat * sinDLat +
        math.cos(lat1) * math.cos(lat2) * sinDLon * sinDLon;
    final c = 2 * math.asin(math.min(1.0, math.sqrt(h)));
    return R * c;
  }

  double _bearing(LatLng a, LatLng b) {
    final lat1 = a.latitude * math.pi / 180.0;
    final lat2 = b.latitude * math.pi / 180.0;
    final dLon = (b.longitude - a.longitude) * math.pi / 180.0;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    var brng = math.atan2(y, x) * 180.0 / math.pi;
    brng = (brng + 360.0) % 360.0;
    return brng;
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    await _ctrl.close();
  }
}
