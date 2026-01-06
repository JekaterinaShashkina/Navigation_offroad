import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/route_math.dart';

class RouteProgressState {
  final bool started;
  final LatLng? currentPos;
  final double bearingDeg;

  final int closestIndex; // индекс прогресса (монотонный)
  final double remainingMeters;
  final int maxIndexReached;
  final int startIndex; // где именно стартанули на линии (фикс)
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
    required this.startIndex,
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
    startIndex: 0,
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
    int? startIndex,
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
      startIndex: startIndex ?? this.startIndex,
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

  // Если GPS шумит, 20м может быть мало. Можешь поднять до 30-40.
  static const double startRadiusM = 20;

  // Насколько далеко от маршрута мы считаем, что "не на линии" (и не двигаем прогресс)
  static const double onRouteThresholdM = 60;

  // Ограничение продвижения по индексу за тик
  static const int maxJumpPoints = 1;

  // Ограничение продвижения по расстоянию за тик
  static const double maxJumpMeters = 300;

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

  int closestPointIndexWindow(
  List<LatLng> route,
  LatLng pos,
  int centerIdx,
) {
  const int window = 40; // 20–60 ок
  final int start = (centerIdx - window).clamp(0, route.length - 1).toInt();
  final int end   = (centerIdx + window).clamp(0, route.length - 1).toInt();

  double minDist = double.infinity;
  int best = centerIdx.clamp(0, route.length - 1);

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

    // 1) До старта — считаем расстояние до start point
    double? distToStartM = started ? null : distanceM(pos, route.first);

    // 2) Старт-гейт (одинаково для live/sim: подошла к первой точке — старт)
    //    Если хочешь: в симуляции стартовать сразу — можно отдельной веткой.
    if (!started && distToStartM != null && distToStartM <= startRadiusM) {
      started = true;
      startTime = DateTime.now();

      // фиксируем индекс старта на линии, чтобы окно поиска не было вокруг 0
      final si = closestPointIndex(route, pos);

      _state = _state.copyWith(
        started: true,
        startTime: startTime,
        distanceToStartM: null,
        startIndex: si,
        maxIndexReached: si,
        closestIndex: si,
        currentPos: pos,
        bearingDeg: bearingDeg,
        // оставшиеся/пройденные посчитаются на следующем тике
      );
      return;
    }

    // Если ещё не стартовали — обновляем только позицию + дистанцию до старта
    if (!started) {
      _state = _state.copyWith(
        started: false,
        //startTime: null,
        distanceToStartM: distToStartM,
        currentPos: pos,
        bearingDeg: bearingDeg,
        // не трогаем прогресс
      );
      return;
    }

    // 3) После старта — ищем ближайшую точку в окне вокруг текущего прогресса
    final prev = _state.maxIndexReached;
    final safePrev = prev.clamp(0, route.length - 1);

    final center = safePrev > 0 ? safePrev : _state.startIndex.clamp(0, route.length - 1);
    final rawIdx = closestPointIndexWindow(route, pos, center);

    // 4) Фильтр: если мы далеко от маршрута — не двигаем прогресс (убирает телепорты)
    final distToRoute = distanceM(pos, route[rawIdx]);
    int idx = safePrev;

    if (distToRoute <= onRouteThresholdM) {
      // монотонно (не назад)
      idx = rawIdx < safePrev ? safePrev : rawIdx;

      // ограничение скачка по точкам
      if (idx - safePrev > maxJumpPoints) idx = safePrev + maxJumpPoints;

      // ограничение скачка по метрам
      final jumpM = distanceM(route[safePrev], route[idx]);
      if (jumpM > maxJumpMeters) {
        idx = safePrev; // слишком большой прыжок — игнорируем этот тик
      }
    }

    // 5) remaining по маршруту
    double remaining = 0;
    for (int i = idx; i < route.length - 1; i++) {
      remaining += distanceM(route[i], route[i + 1]);
    }

    // 6) traversed по маршруту (с учётом startIndex, чтобы не считать кусок "до старта")
    final startIdx = _state.startIndex.clamp(0, route.length - 1);
    final traversedMeters = (idx <= startIdx)
        ? 0.0
        : _routeDistance(route.sublist(startIdx, idx + 1));

    // 7) elapsed/ETA
    final elapsed = startTime == null
        ? Duration.zero
        : DateTime.now().difference(startTime);

    final avgSpeed = elapsed.inSeconds > 5 && traversedMeters > 5
        ? traversedMeters / elapsed.inSeconds
        : 0.0;

    final eta = avgSpeed > 0
        ? Duration(seconds: (remaining / avgSpeed).round())
        : Duration.zero;

    _state = _state.copyWith(
      started: true,
      startTime: startTime,
      distanceToStartM: null,
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
