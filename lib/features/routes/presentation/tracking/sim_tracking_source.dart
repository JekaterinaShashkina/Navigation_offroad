import 'dart:async';
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'tracking_sample.dart';
import 'tracking_source.dart';

class SimTrackingSource implements ITrackingSource {
  final List<LatLng> points;
  final Duration tick;

  SimTrackingSource({
    required this.points,
    this.tick = const Duration(seconds: 2),
  });

  final _ctrl = StreamController<TrackSample>.broadcast();
  Timer? _timer;
  int _i = 0;
  LatLng? _prev;

  @override
  Stream<TrackSample> watch() {
    _timer ??= Timer.periodic(tick, (_) {
      if (points.isEmpty) return;

      if (_i >= points.length) {
        _timer?.cancel();
        _timer = null;
        return;
      }

      final cur = points[_i++];
      LatLng? next = (_i < points.length) ? points[_i] : null;

      final bearing = (next != null)
    ? _bearing(cur, next)      // <-- ВПЕРЁД
    : (_prev == null ? 0.0 : _bearing(_prev!, cur));
      _prev = cur;

      _ctrl.add(
        TrackSample(
          pos: cur,
          bearingDeg: bearing,
        ),
      );
    });

    return _ctrl.stream;
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
    _timer?.cancel();
    _timer = null;
    await _ctrl.close();
  }
}
