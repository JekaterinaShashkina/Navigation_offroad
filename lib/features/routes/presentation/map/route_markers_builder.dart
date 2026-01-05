import 'package:google_maps_flutter/google_maps_flutter.dart';

Set<Marker> buildRouteStartEndMarkers({
  required List<LatLng> points,
}) {
  if (points.isEmpty) return {};

  final start = points.first;
  final end = points.last;

  return {
    Marker(
      markerId: const MarkerId('route_start'),
      position: start,
      infoWindow: const InfoWindow(title: 'Start'),
    ),
    Marker(
      markerId: const MarkerId('route_end'),
      position: end,
      infoWindow: const InfoWindow(title: 'Finish'),
    ),
  };
}
