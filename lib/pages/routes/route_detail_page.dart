import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/pages/routes/route_tracking_page_live.dart';
import 'package:offroad_nav/pages/routes/route_tracking_page.dart';

class RouteDetailPage extends StatefulWidget {
  final String name;
  final List<dynamic> points;

  const RouteDetailPage({super.key, required this.name, required this.points});

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  GoogleMapController? _mapController;

  List<LatLng> get routePoints => widget.points
      .map<LatLng>((p) => LatLng(p['lat'], p['lng']))
      .toList();

  @override
  void initState() {
    super.initState();
  }

  void _fitMapToPolyline() {
    if (_mapController == null || routePoints.isEmpty) return;

    final bounds = _createBoundsFromLatLngList(routePoints);
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  LatLngBounds _createBoundsFromLatLngList(List<LatLng> list) {
    double x0 = list.first.latitude, x1 = list.first.latitude;
    double y0 = list.first.longitude, y1 = list.first.longitude;

    for (LatLng latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }

    return LatLngBounds(
      northeast: LatLng(x1, y1),
      southwest: LatLng(x0, y0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NewAppBar(
        title: widget.name,
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              mapType: MapType.hybrid,
              initialCameraPosition: CameraPosition(
                target: routePoints.isNotEmpty
                    ? routePoints[0]
                    : const LatLng(59.0, 26.0),
                zoom: 13,
              ),
              polylines: {
                Polyline(
                  polylineId: const PolylineId('route'),
                  color: Colors.blue,
                  width: 4,
                  points: routePoints,
                ),
              },
              markers: {
                if (routePoints.isNotEmpty)
                  Marker(
                    markerId: const MarkerId('start'),
                    position: routePoints.first,
                    infoWindow: const InfoWindow(title: 'Start'),
                  ),
              },
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                // Zoom на весь маршрут
                Future.delayed(const Duration(milliseconds: 300), _fitMapToPolyline);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RouteTrackingPageLive(
                          points: routePoints,
                        ),
                      ),
                    );
                  },
                  child: const Text("Начать маршрут"),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RouteTrackingPage(
                          points: routePoints,
                        ),
                      ),
                    );
                  },
                  child: const Text("Симуляция маршрута"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}