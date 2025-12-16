import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

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
    bool s = await _loc.serviceEnabled();
    if (!s) s = await _loc.requestService();
    var p = await _loc.hasPermission();
    if (p == PermissionStatus.denied) {
      p = await _loc.requestPermission();
    }
    if (p != PermissionStatus.granted) return;

    // точные апдейты
    await _loc.changeSettings(
      accuracy: LocationAccuracy.navigation,
      interval: 1000,
      distanceFilter: 2,
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

  void dispose() {
    _locSub?.cancel();
    _compassSub?.cancel();
    super.dispose();
  }

  // запись
  void startRecording() {
    if (_isRecording) return;
    _isRecording = true;
    notifyListeners();
  }

  void pauseRecording() {
    if (!_isRecording) return;
    _isRecording = false;
    notifyListeners();
  }

  void clearTrack() {
    _isRecording = false;
    track.clear();
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
    if (_lastAcceptedPos != null && _distM(_lastAcceptedPos!, pos) > _MAX_JUMP_M) {
      return;
    }

    // --- курс ---
    final speed = (l.speed ?? 0).toDouble(); // м/с
    _lastSpeedMps = speed;                   // 🔽 запоминаем скорость
    final locHeading = l.heading;        // может быть null
    double targetDeg = _compassDeg;      // по умолчанию — компас (стоит)

    if (speed > _MOVE_SPEED_MPS) {
      if (locHeading != null && locHeading >= 0) {
        targetDeg = locHeading;          // идеал в движении
      } else if (_lastAcceptedPos != null) {
        targetDeg = _bearingDeg(_lastAcceptedPos!, pos);
      }
    }

    if (!_ARROW_POINTS_UP) {
      targetDeg = (targetDeg + 180) % 360; // докрутка если PNG вниз
    }

    _markerRot = _lerpAngle(_markerRot, targetDeg, _TURN_ALPHA);

    // --- позиция ---
    _lastAcceptedPos = _currentPos;
    _currentPos = pos;

    // запись трека — не чаще, чем каждые ~3м
    if (_isRecording) {
      if (track.isEmpty || _distM(track.last, pos) > 3) {
        track.add(pos);
      }
    }

    notifyListeners();
  }

  // ----- математика -----

  double _distM(LatLng a, LatLng b) {
    const R = 6378137.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180.0;
    final dLon = (b.longitude - a.longitude) * math.pi / 180.0;
    final la1 = a.latitude * math.pi / 180.0;
    final la2 = b.latitude * math.pi / 180.0;
    final s1 = math.sin(dLat / 2);
    final s2 = math.sin(dLon / 2);
    final h = s1 * s1 + math.cos(la1) * math.cos(la2) * s2 * s2;
    final c = 2 * math.asin(math.min(1.0, math.sqrt(h)));
    return R * c;
  }

  double _bearingDeg(LatLng a, LatLng b) {
    final lat1 = a.latitude * (math.pi / 180);
    final lat2 = b.latitude * (math.pi / 180);
    final dLon = (b.longitude - a.longitude) * (math.pi / 180);
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  double _lerpAngle(double from, double to, double t) {
    final diff = ((to - from + 540) % 360) - 180; // [-180; +180]
    return (from + diff * t) % 360;
  }
}
