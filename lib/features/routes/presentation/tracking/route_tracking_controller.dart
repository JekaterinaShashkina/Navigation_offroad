import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/route_math.dart';

class RouteProgressState {
  final bool started;
  final LatLng? currentPos;
  final double bearingDeg;

  final int closestIndex;        // индекс на маршруте
  final double remainingMeters;
  final int maxIndexReached;
  final double traversedMeters;
  final Duration eta;

  final double? distanceToStartM; // для баннера "подойди к старту"
  final DateTime? startTime;


  const RouteProgressState({
    required this.started,
    required this.currentPos,
    required this.bearingDeg,
    required this.closestIndex,
    required this.remainingMeters,
    required this.maxIndexReached,
    required this.traversedMeters,
    required this.eta,
    required this.distanceToStartM,
    required this.startTime,
    
  });

  static const empty = RouteProgressState(
    started: false,
    currentPos: null,
    bearingDeg: 0,
    closestIndex: 0,
    remainingMeters: 0,
    maxIndexReached: 0,
    traversedMeters: 0,
    eta: Duration.zero,
    distanceToStartM: null,
    startTime: null,
  );

  RouteProgressState copyWith({
    bool? started,
    LatLng? currentPos,
    double? bearingDeg,
    int? closestIndex,
    double? remainingMeters,
    int? maxIndexReached,
    double? traversedMeters,
    Duration? eta,
    double? distanceToStartM,
    DateTime? startTime,
  }) {
    return RouteProgressState(
      started: started ?? this.started,
      currentPos: currentPos ?? this.currentPos,
      bearingDeg: bearingDeg ?? this.bearingDeg,
      closestIndex: closestIndex ?? this.closestIndex,
      remainingMeters: remainingMeters ?? this.remainingMeters,
      maxIndexReached: maxIndexReached ?? this.maxIndexReached,
      traversedMeters: traversedMeters ?? this.traversedMeters,
      eta: eta ?? this.eta,
      distanceToStartM: distanceToStartM ?? this.distanceToStartM,
      startTime: startTime ?? this.startTime,
    );
  }
}

class RouteTrackingController {
  RouteProgressState _state = RouteProgressState.empty;
  RouteProgressState get state => _state;

  static const double startRadiusM = 20;

  int closestPointIndex(List<LatLng> route, LatLng pos) {
    double minDist = double.infinity;
    int index = 0;
    for (int i = 0; i < route.length; i++) {
      final d = distanceM(pos, route[i]);
      if (d < minDist) {
        minDist = d;
        index = i;
      }
    }
    return index;
  }

  int closestPointIndexWindow(List<LatLng> route, LatLng pos, int prevIdx) {
  const window = 40; // можно 20–60
  final start = (prevIdx - window).clamp(0, route.length - 1);
  final end = (prevIdx + window).clamp(0, route.length - 1);

  double minDist = double.infinity;
  int best = prevIdx.clamp(0, route.length - 1);

  for (int i = start; i <= end; i++) {
    final d = distanceM(pos, route[i]);
    if (d < minDist) {
      minDist = d;
      best = i;
    }
  }
  return best;
}
  void updatePosition({
    required List<LatLng> route,
    required LatLng pos,
    required double bearingDeg,
    required bool isLiveMode,
  }) {
    if (route.isEmpty) return;

      bool started = _state.started;
      DateTime? startTime = _state.startTime;
      double? distToStartM = distanceM(pos, route.first);

    // start-gate logic для обоих режимов: фиксируем старт, когда подошли
    // к первой точке маршрута.
    if (!started) {
      if (distToStartM <= startRadiusM) {
        started = true;
        startTime = DateTime.now();
        distToStartM = null;
      }
    }

    // if (!isLiveMode && !started) {
    //   started = true;
    //   startTime = DateTime.now();
    //   distToStartM = null;
    // }
    final prev = _state.maxIndexReached;
    final rawIdx = closestPointIndexWindow(route, pos, prev);

    int idx = rawIdx < prev ? prev : rawIdx;

    const maxJump = 8;
    if (idx - prev > maxJump) idx = prev + maxJump;

    

    // remaining distance по маршруту (не по GPS)
    double remaining = 0;
    for (int i = idx; i < route.length - 1; i++) {
      remaining += distanceM(route[i], route[i + 1]);
    }

    // Простейшая ETA: средняя скорость = (пройденная по маршруту)/(time)
      final traversedMeters = _routeDistance(route.sublist(0, idx + 1));
    
    final elapsed = startTime == null
        ? Duration.zero
        : DateTime.now().difference(startTime);

    // Простейшая ETA: средняя скорость = (пройденная по маршруту)/(time)
    final avgSpeed = started && elapsed.inSeconds > 0
        ? traversedMeters / elapsed.inSeconds
        : 0.0;

    final eta = started && avgSpeed > 0
        ? Duration(seconds: (remaining / avgSpeed).round())
        : Duration.zero;

    _state = _state.copyWith(
      started: started,
      startTime: startTime,
      distanceToStartM: started ? null : distToStartM,
      currentPos: pos,
      bearingDeg: bearingDeg,
      closestIndex: idx,
      remainingMeters: remaining,
      maxIndexReached: idx,
      traversedMeters: traversedMeters,
      eta: eta,
      );
  }

  double _routeDistance(List<LatLng> pts) {
    if (pts.length < 2) return 0;
    double sum = 0;
    for (int i = 0; i < pts.length - 1; i++) {
      sum += distanceM(pts[i], pts[i + 1]);
    }
    return sum;
  }
}
