import 'package:google_maps_flutter/google_maps_flutter.dart';

class TrackSample {
  final LatLng pos;
  final double bearingDeg; // 0..360
  final double? accuracyM;

  const TrackSample({
    required this.pos,
    required this.bearingDeg,
    this.accuracyM,
  });
}