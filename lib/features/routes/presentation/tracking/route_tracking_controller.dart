import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/route_math.dart';

class RouteProgressState {
  final bool started;
  final LatLng? currentPos;
  final double bearingDeg;

  final int closestIndex;        // индекс на маршруте
  final double remainingMeters;
  final Duration eta;

  final double? distanceToStartM; // для баннера "подойди к старту"
  final DateTime? startTime;


  const RouteProgressState({
    required this.started,
    required this.currentPos,
    required this.bearingDeg,
    required this.closestIndex,
    required this.remainingMeters,
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
      eta: eta ?? this.eta,
      distanceToStartM: distanceToStartM,
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

  void updatePosition({
    required List<LatLng> route,
    required LatLng pos,
    required double bearingDeg,
    required bool isLiveMode,
  }) {
    if (route.isEmpty) return;

      bool started = _state.started;
      DateTime? startTime = _state.startTime;
      double? distToStartM = _state.distanceToStartM;

    // start-gate logic (только live)
      if (isLiveMode && !_state.started) {
        final dist = distanceM(pos, route.first);
        if (dist <= startRadiusM) {
            started = true;
            startTime = DateTime.now();
            distToStartM = null;
          } else {
            distToStartM = dist;
          }
        }

    // if (!isLiveMode && !started) {
    //   started = true;
    //   startTime = DateTime.now();
    //   distToStartM = null;
    // }

    final idx = closestPointIndex(route, pos);

    // remaining distance по маршруту (не по GPS)
    double remaining = 0;
    for (int i = idx; i < route.length - 1; i++) {
      remaining += distanceM(route[i], route[i + 1]);
    }

  final elapsed = startTime == null
      ? Duration.zero
      : DateTime.now().difference(startTime);

    // Простейшая ETA: средняя скорость = (пройденная по маршруту)/(time)
    final traversedMeters = idx > 0
      ? _routeDistance(route.sublist(0, idx + 1))
      : 0.0;

    final avgSpeed = elapsed.inSeconds > 0 
      ? traversedMeters / elapsed.inSeconds 
      : 0.0;

    final eta = avgSpeed > 0 
      ? Duration(seconds: (remaining / avgSpeed).round()) 
      : Duration.zero;

      print('****************idx=$idx remaining=$remaining started=$started elapsed=${elapsed.inSeconds}');
      print('isLiveMode=$isLiveMode idx=$idx started=$started');
    _state = _state.copyWith(
      started: started,
      startTime: startTime,
      distanceToStartM: distToStartM,
      currentPos: pos,
      bearingDeg: bearingDeg,
      closestIndex: idx,
      remainingMeters: remaining,
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
