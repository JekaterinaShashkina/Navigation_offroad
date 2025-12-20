import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:offroad_nav/features/routes/presentation/utils/route_math.dart';

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
    ? bearingDeg(cur, next)      // <-- ВПЕРЁД
    : (_prev == null ? 0.0 : bearingDeg(_prev!, cur));
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

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    await _ctrl.close();
  }
}
