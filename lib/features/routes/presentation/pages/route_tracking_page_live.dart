// lib/pages/routes/route_tracking_page_live.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import '../../../../design/widgets/app_bar.dart';

class RouteTrackingPageLive extends StatefulWidget {
  final List<LatLng> points; // Полилиния маршрута

  const RouteTrackingPageLive({super.key, required this.points});

  @override
  State<RouteTrackingPageLive> createState() => _RouteTrackingPageLiveState();
}

class _RouteTrackingPageLiveState extends State<RouteTrackingPageLive> {
  // ===== Карта / локация / компас =====
  GoogleMapController? _map;
  final _loc = Location();
  StreamSubscription<LocationData>? _locSub;
  StreamSubscription<CompassEvent>? _compassSub;

  // ===== Позиция / курс =====
  LatLng? _pos;             // последняя “принятая” позиция
  LatLng? _lastRaw;         // последняя сырая позиция (для анти-скачка)
  double _markerRot = 0;    // сглаженный поворот маркера (deg)
  double _compassDeg = 0;   // компасная “шапка” (deg)

  // ===== Иконка-стрелка =====
  BitmapDescriptor? _arrowIcon;

  // Если ваша PNG-стрелка нарисована “вверх” — true; если “вниз” — false (будет +180°)
  static const bool _ARROW_POINTS_UP = false;

  // ===== Параметры сглаживания / фильтра =====
  static const double _ACC_MAX_M = 50;     // max допустимая точность
  static const int _MIN_UPDATE_MS = 800;   // min интервал апдейтов
  static const double _MAX_JUMP_M = 40;    // отсечь скачки
  static const double _MOVE_SPEED_MPS = 0.8; // “едем”, если быстрее (м/с)
  static const double _TURN_ALPHA = 0.2;   // сглаживание угла [0..1]

  int _lastUpdateMs = 0;

  // ===== Follow camera =====
  bool _follow = true;

  // ===== Off-route =====
  bool _offRoute = false;
  LatLng? _offSnap; // ближайшая точка на линии
  static const double _OFF_ROUTE_THRESH_M = 30; // порог, м

  // ===== Прочее (ETA / осталось) — упрощённо =====
  double _remainingKm = 0;
  Duration _eta = Duration.zero;
  DateTime? _start;

  @override
  void initState() {
    super.initState();
    _loadArrow();
    _init();
  }

  @override
  void dispose() {
    _locSub?.cancel();
    _compassSub?.cancel();
    _map?.dispose();
    super.dispose();
  }

  // ---------------- Utils ----------------

  Future<void> _loadArrow() async {
    _arrowIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/navigation_arrow.png',
    );
    if (mounted) setState(() {});
  }

  double _lerpAngle(double from, double to, double t) {
    final diff = ((to - from + 540) % 360) - 180;
    return (from + diff * t) % 360;
  }

  double _bearingDeg(LatLng a, LatLng b) {
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  double _haversineM(LatLng a, LatLng b) {
    const R = 6378137.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final la1 = a.latitude * math.pi / 180;
    final la2 = b.latitude * math.pi / 180;
    final s1 = math.sin(dLat / 2);
    final s2 = math.sin(dLon / 2);
    final h = s1 * s1 + math.cos(la1) * math.cos(la2) * s2 * s2;
    final c = 2 * math.asin(math.min(1.0, math.sqrt(h)));
    return R * c;
  }

  // расстояние от точки до сегмента AB (метры) + найдем “снапнутую” точку
  ({double distM, LatLng snap}) _distToSegment(LatLng p, LatLng a, LatLng b) {
    // переведём в метровые локальные координаты (простая проекция)
    final mPerDegLat = 111320.0;
    final mPerDegLon = 111320.0 * math.cos(p.latitude * math.pi / 180);

    final px = (p.longitude - a.longitude) * mPerDegLon;
    final py = (p.latitude - a.latitude) * mPerDegLat;
    final bx = (b.longitude - a.longitude) * mPerDegLon;
    final by = (b.latitude - a.latitude) * mPerDegLat;

    final segLen2 = bx * bx + by * by;
    double t = segLen2 == 0 ? 0 : ((px * bx + py * by) / segLen2);
    t = t.clamp(0.0, 1.0);

    final sx = bx * t;
    final sy = by * t;
    final dx = px - sx;
    final dy = py - sy;
    final dist = math.sqrt(dx * dx + dy * dy);

    final snapLat = a.latitude + (sy / mPerDegLat);
    final snapLon = a.longitude + (sx / mPerDegLon);
    return (distM: dist, snap: LatLng(snapLat, snapLon));
  }

  ({double distM, LatLng snap}) _distToPolyline(LatLng p, List<LatLng> line) {
    double best = double.infinity;
    LatLng? bestSnap;
    for (int i = 0; i + 1 < line.length; i++) {
      final res = _distToSegment(p, line[i], line[i + 1]);
      if (res.distM < best) {
        best = res.distM;
        bestSnap = res.snap;
      }
    }
    return (distM: best, snap: bestSnap ?? line.first);
  }

  // ---------------- Init ----------------

  Future<void> _init() async {
    // компас (когда стоим)
    final first = await FlutterCompass.events?.first;
    if (first?.heading != null) _compassDeg = first!.heading!;
    _compassSub = FlutterCompass.events?.listen((e) {
      if (e.heading != null) _compassDeg = e.heading!;
    });

    // разрешения
    bool s = await _loc.serviceEnabled();
    if (!s) s = await _loc.requestService();
    var p = await _loc.hasPermission();
    if (p == PermissionStatus.denied) p = await _loc.requestPermission();
    if (p != PermissionStatus.granted) return;

    // high accuracy + частые апдейты
    _loc.changeSettings(
      accuracy: LocationAccuracy.navigation,
      interval: 800,
      distanceFilter: 2,
    );

    // старт времени для ETA
    _start = DateTime.now();

    _locSub = _loc.onLocationChanged.listen(_onLocation);
  }

  void _onLocation(LocationData l) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastUpdateMs < _MIN_UPDATE_MS) return;
    _lastUpdateMs = now;

    final la = l.latitude, lo = l.longitude;
    if (la == null || lo == null) return;

    final acc = (l.accuracy ?? l.verticalAccuracy ?? 9999).toDouble();
    if (acc > _ACC_MAX_M) return;

    final cur = LatLng(la, lo);

    if (_lastRaw != null && _haversineM(_lastRaw!, cur) > _MAX_JUMP_M) {
      // отбрасываем очевидный прыжок
      return;
    }
    _lastRaw = cur;

    // --- курс ---
    // 1) если GPS дал heading и есть скорость — используем
    // 2) иначе — компас
    double target = _compassDeg;
    final speed = (l.speed ?? 0); // м/с
    final locHeading = l.heading; // может быть null на iOS/Android
    if (speed > _MOVE_SPEED_MPS) {
      if (locHeading != null && locHeading >= 0) {
        target = locHeading;
      } else if (_pos != null) {
        target = _bearingDeg(_pos!, cur);
      }
    }
    if (!_ARROW_POINTS_UP) {
      target = (target + 180) % 360; // если PNG смотрит вниз
    }
    _markerRot = _lerpAngle(_markerRot, target, _TURN_ALPHA);

    // применяем позицию
    _pos = cur;

    // --- off-route ---
    if (widget.points.length >= 2 && _pos != null) {
      final res = _distToPolyline(_pos!, widget.points);
      _offRoute = res.distM > _OFF_ROUTE_THRESH_M;
      _offSnap = res.snap;
    }

    // --- осталось / ETA (упрощённо: оставшаяся длина по вершинам после ближайшей точки) ---
    if (_pos != null && widget.points.isNotEmpty) {
      int idx = _closestVertexIndex(_pos!);
      double rem = 0;
      for (int i = idx; i + 1 < widget.points.length; i++) {
        rem += _haversineM(widget.points[i], widget.points[i + 1]);
      }
      _remainingKm = rem / 1000.0;
      if (_start != null) {
        final elapsed = DateTime.now().difference(_start!);
        final coveredKm = (elapsed.inSeconds > 0)
            ? (rem > 0 ? 0 /* тут можно хранить накопление, если надо */ : 0)
            : 0;
        // без хранение истории делаем простую заглушку
        _eta = (_remainingKm > 0 && speed > 0.3)
            ? Duration(seconds: (_remainingKm * 1000 / speed).round())
            : Duration.zero;
      }
    }

    // --- камера ---
    if (_map != null && _follow && _pos != null) {
      _map!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _pos!,     // центр — прямо на вас
            zoom: 18,
            tilt: 60,
            bearing: _markerRot,
          ),
        ),
      );
    }

    if (mounted) setState(() {});
  }

  int _closestVertexIndex(LatLng p) {
    double best = double.infinity;
    int idx = 0;
    for (int i = 0; i < widget.points.length; i++) {
      final d = _haversineM(p, widget.points[i]);
      if (d < best) {
        best = d;
        idx = i;
      }
    }
    return idx;
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    // Полосы: “пройдено” до ближайшей вершины и “осталось” после
    final List<LatLng> passed, remaining;
    if (_pos == null || widget.points.isEmpty) {
      passed = const [];
      remaining = widget.points;
    } else {
      final idx = _closestVertexIndex(_pos!);
      passed = widget.points.sublist(0, idx + 1);
      remaining = widget.points.sublist(idx);
    }

    final polylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId('passed'),
        color: Colors.green,
        width: 5,
        points: passed,
      ),
      Polyline(
        polylineId: const PolylineId('remaining'),
        color: Colors.blue,
        width: 4,
        points: remaining,
      ),
      if (_offRoute && _pos != null && _offSnap != null)
        Polyline(
          polylineId: const PolylineId('off'),
          color: Colors.red,
          width: 3,
          points: [_pos!, _offSnap!],
          patterns: [PatternItem.dash(12), PatternItem.gap(6)],
        ),
    };

    final markers = <Marker>{
      if (widget.points.isNotEmpty)
        Marker(
          markerId: const MarkerId('start'),
          position: widget.points.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Start'),
        ),
      if (widget.points.length > 1)
        Marker(
          markerId: const MarkerId('finish'),
          position: widget.points.last,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Finish'),
        ),
      if (_pos != null)
        Marker(
          markerId: const MarkerId('me'),
          position: _pos!,
          rotation: _markerRot,
          icon: _arrowIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.5),
          zIndex: 10,
        ),
    };

    return Scaffold(
      appBar: NewAppBar(
        title: 'Route tracking',
        onPressed: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.hybrid,
            initialCameraPosition: CameraPosition(
              target: widget.points.isNotEmpty ? widget.points.first : const LatLng(59, 26),
              zoom: 15,
            ),
            onMapCreated: (c) => _map = c,
            polylines: polylines,
            markers: markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: false,
          ),

          // Чип с расстоянием/ETA
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Remaining: ${_remainingKm.toStringAsFixed(2)} km • ETA: ${_fmt(_eta)}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),

          // Кнопка “recenter/follow”
          Positioned(
            right: 16,
            top: 16,
            child: SafeArea(
              bottom: false,
              child: FloatingActionButton.small(
                backgroundColor: Colors.black87,
                onPressed: () {
                  setState(() => _follow = true);
                  if (_pos != null && _map != null) {
                    _map!.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: _pos!,
                          zoom: 18,
                          tilt: 60,
                          bearing: _markerRot,
                        ),
                      ),
                    );
                  }
                },
                child: Icon(_follow ? Icons.my_location : Icons.location_searching, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    if (d == Duration.zero) return '--:--';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }
}
