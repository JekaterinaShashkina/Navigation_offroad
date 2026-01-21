import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:offroad_nav/features/routes/presentation/tracking/settings/tracking_profile.dart';
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

  DateTime? _prevAt;
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

    await applyProfile(_profile);

    _sub = _loc.onLocationChanged.listen((loc) {
      if (loc.latitude == null || loc.longitude == null) return;

      // На авто accuracy иногда 10-60м, 35 может быть жестко — можно поднять
      if (loc.accuracy != null && loc.accuracy! > 60) return;

      final cur = LatLng(loc.latitude!, loc.longitude!);

      // jump filter (adaptive)
      final now = DateTime.now();
      if (_prev != null && _prevAt != null) {
        final dt = now.difference(_prevAt!).inMilliseconds / 1000.0;
        final jump = distanceM(_prev!, cur);
        final allowed = (50.0 * dt) + 20.0; // 180 км/ч + запас
        if (jump > allowed) return;
      }

      final raw = _prev == null ? _bearingSmoothed : bearingDeg(_prev!, cur);
      _bearingSmoothed = lerpAngle(_bearingSmoothed, raw, 0.25);

      _prev = cur;
      _prevAt = now;

      _ctrl.add(
        TrackSample(
          pos: cur,
          bearingDeg: _bearingSmoothed,
          accuracyM: loc.accuracy?.toDouble(),
        ),
      );
    });
  }

  TrackingProfile _profile = TrackingProfile.def;

Future<void> applyProfile(TrackingProfile p) async {
  _profile = p;

  // Если Auto — стартуем как walk, а дальше можно (опционально) авто-переключать по speed.
  if (p == TrackingProfile.walk) {
    await _loc.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000,
      distanceFilter: 3,
    );
    
  } else if (p == TrackingProfile.moto) {
    await _loc.changeSettings(
      accuracy: LocationAccuracy.navigation,
      interval: 650,
      distanceFilter: 2,
    );
  } else if (p == TrackingProfile.auto) {
    await _loc.changeSettings(
      accuracy: LocationAccuracy.navigation,
      interval: 500,
      distanceFilter: 2,
    );
  } else {
    // Auto — компромиссный базовый режим
    await _loc.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000,
      distanceFilter: 3,
    );
  }
}


  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    await _ctrl.close();
  }
}
