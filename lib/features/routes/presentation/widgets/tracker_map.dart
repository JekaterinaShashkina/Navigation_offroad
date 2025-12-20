import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:offroad_nav/features/routes/presentation/tracking/tracker_controller.dart';

/// Карта для записи трека: рисует текущую позицию, трек, ведёт камеру.
class TrackerMap extends StatefulWidget {
  const TrackerMap({
    super.key,
    required this.controller,
    this.arrowIcon,
    this.bottomPadding = 0,
    this.lookAheadMeters = 140, // сколько "заглядывать" вперёд по курсу
  });

  final TrackerController controller;
  final BitmapDescriptor? arrowIcon;
  final double bottomPadding;
  final double lookAheadMeters;

  @override
  State<TrackerMap> createState() => _TrackerMapState();
}

class _TrackerMapState extends State<TrackerMap> {
  GoogleMapController? _map;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(covariant TrackerMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerUpdate);
      widget.controller.addListener(_onControllerUpdate);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _map?.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    final pos = widget.controller.currentPos;
    if (_map == null || pos == null) return;
    if (!widget.controller.followMe) return;

    final target = _offsetAhead(
      pos,
      widget.controller.markerRot,
      forwardMeters: widget.lookAheadMeters,
    );

    _map!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: 18,
          tilt: 60,
          bearing: widget.controller.markerRot,
        ),
      ),
    );
    // перерисовать маркеры/полилинии
    setState(() {});
  }

  LatLng _offsetAhead(
    LatLng p,
    double bearingDeg, {
    double forwardMeters = 140,
    double rightMeters = 0,
  }) {
    const R = 6378137.0;
    final br = bearingDeg * math.pi / 180;
    final right = br + math.pi / 2;

    final dN = forwardMeters * math.cos(br) + rightMeters * math.cos(right);
    final dE = forwardMeters * math.sin(br) + rightMeters * math.sin(right);

    final dLat = dN / R * (180 / math.pi);
    final dLon = dE / (R * math.cos(p.latitude * math.pi / 180)) * (180 / math.pi);
    return LatLng(p.latitude + dLat, p.longitude + dLon);
  }

    double _normalize(double deg) {
      deg %= 360;
      if (deg < 0) deg += 360;
      return deg;
    }
  @override
  Widget build(BuildContext context) {
    final pos = widget.controller.currentPos;

    final markers = <Marker>{
      if (pos != null)
        Marker(
          markerId: const MarkerId('me'),
          position: pos,
          flat: true,
          rotation: _normalize(widget.controller.markerRot),
          icon: widget.arrowIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.5),
          zIndex: 10,
        ),
        
    };

    final polylines = <Polyline>{
      if (widget.controller.track.isNotEmpty)
        Polyline(
          polylineId: const PolylineId('track'),
          color: Colors.orange,
          width: 6,
          points: widget.controller.track,
        ),
    };

    return GoogleMap(
      mapType: MapType.hybrid,
      initialCameraPosition: CameraPosition(
        target: pos ?? const LatLng(59.0, 26.0),
        zoom: 15,
      ),
      onMapCreated: (c) {
        _map = c;
        if (pos != null) {
          // сразу поставить камеру в адекватную позу
          final target = _offsetAhead(
            pos,
            widget.controller.markerRot,
            forwardMeters: widget.lookAheadMeters,
          );
          _map!.moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: target,
                zoom: 18,
                tilt: 60,
                bearing: widget.controller.markerRot,
              ),
            ),
          );
        }
      },
      markers: markers,
      polylines: polylines,
      padding: EdgeInsets.only(bottom: widget.bottomPadding),
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      compassEnabled: false,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomControlsEnabled: false,
    );
  }
}
