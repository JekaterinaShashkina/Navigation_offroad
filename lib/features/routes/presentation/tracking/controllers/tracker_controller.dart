import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:offroad_nav/features/routes/presentation/utils/location_permissions.dart';
import 'package:offroad_nav/features/routes/presentation/utils/route_math.dart';

/// Контроллер трекинга: выдаёт текущую позицию, сглаженный курс маркера,
/// follow-режим, запись трека и уведомляет слушателей.
class TrackerController extends ChangeNotifier {
  // ----- публичные состояния -----
  LatLng? get currentPos => _currentPos;
  double get markerRot => _markerRot;     // сглажённый курс для стрелки
  bool get followMe => _followMe;
  set followMe(bool v) {
    if (_followMe == v) return;
    _followMe = v;
    notifyListeners();
  }

  bool get isRecording => _isRecording;
  final List<LatLng> track = <LatLng>[];

  // ----- приватные поля -----
  final Location _loc = Location();
  StreamSubscription<LocationData>? _locSub;
  StreamSubscription<CompassEvent>? _compassSub;

  LatLng? _currentPos;
  LatLng? _lastAcceptedPos;    // предыдущая принятая позиция (после фильтров)
  double _markerRot = 0;       // сглажённый курс, deg
  double _compassDeg = 0;      // последний heading компаса, deg
  double _lastCompassDeg = 0;  // heading компаса на прошлом тике
  double _lastHeadingDeg = 0;  // целевой heading на прошлом тике (после всех поправок)
  double _lastRawHeadingDeg = 0; // heading до докрутки PNG
  int _lastUpdateMs = 0;
  
  final List<double> _headingWindow = <double>[];
// 🔽 НОВОЕ
double _lastSpeedMps = 0;
double get speedMps => _lastSpeedMps;
double get speedKmh => _lastSpeedMps * 3.6;

  bool _followMe = true;
  bool _isRecording = false;

  // ----- константы фильтрации/сглаживания -----
  static const double _ACC_MAX_M = 50;      // макс. погрешность точки (м)
  static const int    _MIN_UPDATE_MS = 800; // мин. интервал между апдейтами
  static const double _MAX_JUMP_M = 40;     // отфильтровывать "прыжки" дальше этого
  static const double _MOVE_SPEED_MPS = 0.8;// "движемся", если скорость выше
  static const double _HEADING_STILL_SPEED = 1.5; // "почти стоим", не дёргать компас
  static const double _COMPASS_JITTER_DEG = 4;    // игнорировать мелкие изменения компаса
  static const double _TURN_ALPHA_MIN = 0.1;      // сглаживание вращения при низкой скорости
  static const double _TURN_ALPHA_MAX = 0.25;     // сглаживание вращения при высокой скорости
  static const double _TURN_ALPHA_SPEED_MAX = 5;  // скорость, на которой берём max alpha
  static const double _POS_MIN_STEP_M = 2;        // отбрасывать шаги меньше этого
  static const double _POS_SMOOTH_ALPHA = 0.35;   // сглаживание позиции (0..1)
  static const int _HEADING_WINDOW_SIZE = 5;
  /// Если PNG стрелки "смотрит вниз" — ставим false (докрутка +180°).
  static const bool _ARROW_POINTS_UP = true;

  // ----- публичные методы -----

  Future<void> start() async {
    // компас
    final first = await FlutterCompass.events?.first;
    if (first?.heading != null) _compassDeg = first!.heading!;
    _compassSub = FlutterCompass.events?.listen((e) {
      if (e.heading != null) _compassDeg = e.heading!;
    });

    // разрешения локации
    final ok = await ensureLocationPermissions(_loc);
    if (!ok) return;

    // точные апдейты
    await _loc.changeSettings(
      accuracy: LocationAccuracy.navigation,
      interval: 1000,
      distanceFilter: 6,
    );

    // текущая позиция (один раз, чтобы камера могла стартануть)
    try {
      final l = await _loc.getLocation();
      if (l.latitude != null && l.longitude != null) {
        _currentPos = LatLng(l.latitude!, l.longitude!);
        _lastAcceptedPos = _currentPos;
      }
    } catch (_) {}

    _locSub = _loc.onLocationChanged.listen(_onLocation);
    notifyListeners();
  }

@override
void dispose() {
  _loc.enableBackgroundMode(enable: false).catchError((_) {});
  _locSub?.cancel();
  _compassSub?.cancel();
  super.dispose();
}

  // запись
  Future<void> startRecording() async {
    if (_isRecording) return;
    debugPrint('OFFROAD 🔥🔥🔥startRecording pressed, isRecording=$_isRecording');
    // 1) СРАЗУ включаем запись (UI не должен ждать)
    _isRecording = true;
    notifyListeners();
    // 2) Дальше — фон (не должен ломать старт)
    try {
      final ok = await ensureLocationPermissions(_loc);
      if (!ok) {
        _isRecording = false;
        notifyListeners();
        return;
      }
      // удерживаем бодрствующее устройство
      await _loc.enableBackgroundMode(enable: true);
    } catch (e) {
      // если фон не включился — запись всё равно может работать на экране
      debugPrint('enableBackgroundMode failed: $e');
    }
  }

Future<void> pauseRecording() async {
  if (!_isRecording) return;
  debugPrint('pauseRecording pressed, isRecording=$_isRecording');
  _isRecording = false;

  await _loc.enableBackgroundMode(enable: false);

  notifyListeners();
}

Future<void> clearTrack() async {
  _isRecording = false;
  track.clear();

  await _loc.enableBackgroundMode(enable: false);

  notifyListeners();
}

  // ----- обработка локации -----

  void _onLocation(LocationData l) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastUpdateMs < _MIN_UPDATE_MS) return;
    _lastUpdateMs = now;

    final la = l.latitude, lo = l.longitude;
    if (la == null || lo == null) return;

    final acc = (l.accuracy ?? l.verticalAccuracy ?? 9999).toDouble();
    if (acc > _ACC_MAX_M) return;

    final pos = LatLng(la, lo);

    // отбрасываем «скачки»
    if (_lastAcceptedPos != null && distanceM(_lastAcceptedPos!, pos) > _MAX_JUMP_M) {
      return;
    }
        // --- позиция (сглаживание) ---
    final filteredPos = _filterPosition(pos);
    final prev = _lastAcceptedPos;

    // --- курс ---
    final speed = (l.speed ?? 0).toDouble(); // м/с
    _lastSpeedMps = speed;                   // 🔽 запоминаем скорость
    final locHeading = l.heading; // может быть null
    final compassDelta = _angleDeltaDeg(_compassDeg, _lastCompassDeg);
    _lastCompassDeg = _compassDeg;   

    double targetDeg = _compassDeg;      // по умолчанию — компас (стоит)
    double? moveBearing;

      if (speed > _MOVE_SPEED_MPS && locHeading != null && locHeading >= 0) {
      moveBearing = locHeading;          // идеал в движении
    } else if (prev != null) {
      moveBearing = bearingDeg(prev, filteredPos);
    }
        if (speed < _HEADING_STILL_SPEED &&
        compassDelta.abs() < _COMPASS_JITTER_DEG &&
        _headingWindow.isNotEmpty) {
      targetDeg = _lastRawHeadingDeg;    // стоим и компас не изменился — не дёргаем
    } else if (moveBearing != null) {
      targetDeg = moveBearing;
    }

    targetDeg = _smoothHeading(targetDeg);
    final rawHeading = targetDeg;

    if (!_ARROW_POINTS_UP) {
      targetDeg = (targetDeg + 180) % 360; // докрутка если PNG вниз
    }

     _markerRot = lerpAngle(_markerRot, targetDeg, _turnAlphaForSpeed(speed));

    _lastRawHeadingDeg = rawHeading;
    _lastHeadingDeg = targetDeg;

    // --- позиция ---
    _lastAcceptedPos = filteredPos;
    _currentPos = filteredPos;

    // запись трека — не чаще, чем каждые ~3м
    if (_isRecording) {
      final shouldAdd = track.isEmpty || distanceM(track.last, filteredPos) > 3;
      if (shouldAdd) track.add(filteredPos);
    }

    notifyListeners();
  }
 double _turnAlphaForSpeed(double speed) {
    final double clamped = speed.clamp(0, _TURN_ALPHA_SPEED_MAX).toDouble();
    final t = clamped / _TURN_ALPHA_SPEED_MAX;
    return _TURN_ALPHA_MIN + (_TURN_ALPHA_MAX - _TURN_ALPHA_MIN) * t;
  }

  double _angleDeltaDeg(double a, double b) {
    return (((a - b + 540) % 360) - 180);
  }

  double _unwrapHeading(double heading) {
    if (_headingWindow.isEmpty) return heading;
    final last = _headingWindow.last;
    final diff = _angleDeltaDeg(heading, last);
    return last + diff;
  }

  double _smoothHeading(double targetDeg) {
    final unwrapped = _unwrapHeading(targetDeg);
    _headingWindow.add(unwrapped);
    if (_headingWindow.length > _HEADING_WINDOW_SIZE) {
      _headingWindow.removeAt(0);
    }
    final sorted = List<double>.from(_headingWindow)..sort();
    final mid = sorted.length ~/ 2;
    final median = sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
    return median % 360;
  }

  LatLng _filterPosition(LatLng raw) {
    final prev = _lastAcceptedPos;
    if (prev == null) return raw;

    final dist = distanceM(prev, raw);
    if (dist < _POS_MIN_STEP_M) {
      return prev; // мелкая дрожь — оставляем старое
    }

    final lat = prev.latitude + (raw.latitude - prev.latitude) * _POS_SMOOTH_ALPHA;
    final lon = prev.longitude + (raw.longitude - prev.longitude) * _POS_SMOOTH_ALPHA;
    return LatLng(lat, lon);
  }
}
