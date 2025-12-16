// lib/features/routes/utils/route_math.dart
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

double calcDistanceKm(LatLng a, LatLng b) {
  const double p = 0.017453292519943295;
  final double lat1 = a.latitude;
  final double lon1 = a.longitude;
  final double lat2 = b.latitude;
  final double lon2 = b.longitude;
  final double a1 = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
      math.cos(lat1 * p) * math.cos(lat2 * p) *
          (1 - math.cos((lon2 - lon1) * p)) / 2;
  return 12742 * math.asin(math.sqrt(a1)); // км
}

double calcPathLengthKm(List<LatLng> points) {
  if (points.length < 2) return 0;
  double dist = 0;
  for (int i = 0; i < points.length - 1; i++) {
    dist += calcDistanceKm(points[i], points[i + 1]);
  }
  return dist;
}
