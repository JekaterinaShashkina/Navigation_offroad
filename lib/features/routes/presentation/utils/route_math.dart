// lib/features/routes/utils/route_math.dart
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

const _R = 6378137.0; // радиус Земли, м

/// расстояние в МЕТРАХ
double distanceM(LatLng a, LatLng b) {
  final dLat = (b.latitude - a.latitude) * math.pi / 180;
  final dLon = (b.longitude - a.longitude) * math.pi / 180;
  final lat1 = a.latitude * math.pi / 180;
  final lat2 = b.latitude * math.pi / 180;

  final s1 = math.sin(dLat / 2);
  final s2 = math.sin(dLon / 2);
  final h = s1 * s1 + math.cos(lat1) * math.cos(lat2) * s2 * s2;
  final c = 2 * math.asin(math.min(1.0, math.sqrt(h)));

  return _R * c;
}

/// длина маршрута в МЕТРАХ
double pathLengthM(List<LatLng> points) {
  if (points.length < 2) return 0;
  double sum = 0;
  for (int i = 0; i < points.length - 1; i++) {
    sum += distanceM(points[i], points[i + 1]);
  }
  return sum;
}

/// азимут 0..360 (СЕВЕР = 0)
double bearingDeg(LatLng from, LatLng to) {
  final lat1 = from.latitude * math.pi / 180;
  final lat2 = to.latitude * math.pi / 180;
  final dLon = (to.longitude - from.longitude) * math.pi / 180;

  final y = math.sin(dLon) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

/// плавный поворот стрелки
double lerpAngle(double from, double to, double t) {
  final diff = ((to - from + 540) % 360) - 180;
  return (from + diff * t) % 360;
}

/// расстояние между точками (км)
double distanceKm(LatLng a, LatLng b) {
  const p = math.pi / 180;
  final a1 = 0.5 -
      math.cos((b.latitude - a.latitude) * p) / 2 +
      math.cos(a.latitude * p) *
          math.cos(b.latitude * p) *
          (1 - math.cos((b.longitude - a.longitude) * p)) / 2;
  return 12742 * math.asin(math.sqrt(a1));
}

/// длина маршрута
double pathLengthKm(List<LatLng> points) {
  double sum = 0;
  for (int i = 0; i + 1 < points.length; i++) {
    sum += distanceKm(points[i], points[i + 1]);
  }
  return sum;
}

class SegmentSnap {
  final int segIndex;        // индекс сегмента [i -> i+1]
  final double t;            // 0..1, где проекция лежит на сегменте
  final double distToRouteM; // расстояние от pos до сегмента
  const SegmentSnap(this.segIndex, this.t, this.distToRouteM);
}

/// Быстрое приближение: LatLng -> локальные метры (equirectangular)
class _XY {
  final double x;
  final double y;
  const _XY(this.x, this.y);
}

_XY _toXY(LatLng p, double lat0Rad) {
  const R = 6371000.0;
  final lat = p.latitude * math.pi / 180.0;
  final lng = p.longitude * math.pi / 180.0;
  final x = R * (lng) * math.cos(lat0Rad);
  final y = R * (lat);
  return _XY(x, y);
}

/// Расстояние от точки pos до сегмента [a-b] + параметр проекции t (0..1)
SegmentSnap snapToSegmentMeters({
  required LatLng pos,
  required LatLng a,
  required LatLng b,
  required int segIndex,
}) {
  final lat0Rad = (pos.latitude * math.pi / 180.0);

  final p = _toXY(pos, lat0Rad);
  final A = _toXY(a, lat0Rad);
  final B = _toXY(b, lat0Rad);

  final vx = B.x - A.x;
  final vy = B.y - A.y;
  final wx = p.x - A.x;
  final wy = p.y - A.y;

  final vv = vx * vx + vy * vy;
  double t = vv == 0 ? 0.0 : (wx * vx + wy * vy) / vv;
  t = t.clamp(0.0, 1.0);

  final projX = A.x + t * vx;
  final projY = A.y + t * vy;

  final dx = p.x - projX;
  final dy = p.y - projY;

  final dist = math.sqrt(dx * dx + dy * dy);
  return SegmentSnap(segIndex, t, dist);
}