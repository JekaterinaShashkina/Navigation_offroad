import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:offroad_nav/features/routes/presentation/utils/route_math.dart';

import 'tracking_sample.dart';
import 'tracking_source.dart';

class LiveTrackingSource implements ITrackingSource {
  LiveTrackingSource({
    Location? location,
    this.accMaxM = 35,
    this.maxJumpM = 40,
    this.startPoint,
    this.requireStartWithinM = 20, // 10–20м обычно норм
  }) : _loc = location ?? Location();

  final Location _loc;
  final double accMaxM;
  final double maxJumpM;

  final LatLng? startPoint;
  final double requireStartWithinM;

  final _ctrl = StreamController<TrackSample>.broadcast();
  StreamSubscription<LocationData>? _sub;
  LatLng? _prev;

  double _bearingSmoothed = 0.0;

  bool _startGatePassed = false;

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

        // опционально: проверим текущую позицию один раз до подписки
    try {
      final first = await _loc.getLocation();
      if (first.latitude != null && first.longitude != null) {
        _prev = LatLng(first.latitude!, first.longitude!);
      }
    } catch (_) {}


    _sub = _loc.onLocationChanged.listen((loc) {
      if (loc.latitude == null || loc.longitude == null) return;

      if (loc.accuracy != null && loc.accuracy! > accMaxM) return;

      final cur = LatLng(loc.latitude!, loc.longitude!);

      // NEW: "подойти к старту" — gate
      if (!_startGatePassed && startPoint != null) {
        // final d = distanceM(cur, startPoint!);
          _startGatePassed = true;
          // сброс prev чтобы не было резкого bearing
          _prev = cur;
        
      }

      // jump filter
      if (_prev != null) {
        final jump = distanceM(_prev!, cur);
        if (jump > maxJumpM) return;
      }
      // bearing + smoothing
      final raw = _prev == null ? _bearingSmoothed : bearingDeg(_prev!, cur);
      _bearingSmoothed = lerpAngle(_bearingSmoothed, raw, 0.25);
      final bearing = _bearingSmoothed;

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

@override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    await _ctrl.close();
  }
}
