import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';

class CompetitionLiveMapPage extends StatefulWidget {
  const CompetitionLiveMapPage({
    super.key,
    required this.competitionId,
    required this.routePoints,
    required this.routeName,
  });

  final String competitionId;
  final List<LatLng> routePoints;
  final String routeName;

  @override
  State<CompetitionLiveMapPage> createState() => _CompetitionLiveMapPageState();
}

class _CompetitionLiveMapPageState extends State<CompetitionLiveMapPage> {
  StreamSubscription<DatabaseEvent>? _sub;
  final Map<String, Marker> _markers = {};

  @override
  void initState() {
    super.initState();

    final ref = FirebaseDatabase.instance.ref('competition_live/${widget.competitionId}');
    _sub = ref.onValue.listen((event) {
      final raw = event.snapshot.value;

      final now = DateTime.now().millisecondsSinceEpoch;
      const ttlMs = 30 * 1000;

      final next = <String, Marker>{};

      if (raw is Map) {
        raw.forEach((uid, v) {
          if (uid is! String || v is! Map) return;

          final lat = (v['lat'] as num?)?.toDouble();
          final lng = (v['lng'] as num?)?.toDouble();
          final bearing = (v['bearing'] as num?)?.toDouble() ?? 0;
          final updatedAtMs = (v['updatedAtMs'] as num?)?.toInt();

          if (lat == null || lng == null || updatedAtMs == null) return;
          if (now - updatedAtMs > ttlMs) return;

          next[uid] = Marker(
            markerId: MarkerId(uid),
            position: LatLng(lat, lng),
            rotation: bearing,
            flat: true,
            infoWindow: InfoWindow(title: 'User', snippet: uid),
          );
        });
      }

      if (!mounted) return;
      setState(() {
        _markers
          ..clear()
          ..addAll(next);
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.routePoints.isNotEmpty
        ? widget.routePoints.first
        : const LatLng(59.4370, 24.7536);

    final routePolyline = Polyline(
      polylineId: const PolylineId('route'),
      points: widget.routePoints,
      color: Colors.blue,
      width: 4,
    );

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: 'Live map',
        onPressed: () => Navigator.pop(context),
      ),
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: CameraPosition(target: start, zoom: 16),
        polylines: {routePolyline},
        markers: _markers.values.toSet(),
      ),
    );
  }
}
