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
  int _lastUpdateMs = 0;
  
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
  static const double _TURN_ALPHA = 0.2;    // сглаживание вращения (0..1)

  /// Если PNG стрелки "смотрит вниз" — ставим false (докрутка +180°).
  static const bool _ARROW_POINTS_UP = false;

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
    // await _loc.enableBackgroundMode(enable: true);
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
    debugPrint('OFFROAD 🟢🟢🟢 onLocation tick lat=${l.latitude} lng=${l.longitude} acc=${l.accuracy}');
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
    final prev = _lastAcceptedPos;
    // --- курс ---
    final speed = (l.speed ?? 0).toDouble(); // м/с
    _lastSpeedMps = speed;                   // 🔽 запоминаем скорость
    final locHeading = l.heading;        // может быть null
    double targetDeg = _compassDeg;      // по умолчанию — компас (стоит)

    if (speed > _MOVE_SPEED_MPS) {
      if (locHeading != null && locHeading >= 0) {
        targetDeg = locHeading;          // идеал в движении
      } else if (prev != null) {
        targetDeg = bearingDeg(prev, pos);
      }
    }

    if (!_ARROW_POINTS_UP) {
      targetDeg = (targetDeg + 180) % 360; // докрутка если PNG вниз
    }

    _markerRot = lerpAngle(_markerRot, targetDeg, _TURN_ALPHA);

    // --- позиция ---
    _lastAcceptedPos = pos;
    _currentPos = pos;

    // запись трека — не чаще, чем каждые ~3м
    if (_isRecording) {
  final shouldAdd = track.isEmpty || distanceM(track.last, pos) > 3;
  debugPrint('OFFROAD 🔥REC isRecording=$_isRecording trackLen=${track.length} shouldAdd=$shouldAdd');
  if (shouldAdd) track.add(pos);
    }

    notifyListeners();
  }

}
