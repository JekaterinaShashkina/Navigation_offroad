import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/avatar_marker_factory.dart';
import 'package:offroad_nav/features/groups/presentation/models/live_user_view.dart';
import 'package:offroad_nav/features/routes/presentation/map/live_markers_builder.dart';
import 'package:offroad_nav/features/routes/presentation/map/map_icons_loader.dart';
import 'package:offroad_nav/features/routes/presentation/tracking/tracking_presence_service.dart';

import '../../../../design/widgets/app_bar.dart';
import 'package:offroad_nav/features/groups/application/providers/groups_providers.dart';

import '../tracking/live_tracking_source.dart';
import '../tracking/sim_tracking_source.dart';
import '../tracking/tracking_sample.dart';
import '../tracking/tracking_source.dart';
import '../utils/route_math.dart';

enum TrackingMode { simulated, live }

class RouteTrackingPage extends ConsumerStatefulWidget {
  final List<LatLng> points;
  final TrackingMode mode;

  /// Если null — одиночный режим (без live-участников).
  final String? groupId;

  const RouteTrackingPage({
    super.key,
    required this.points,
    this.mode = TrackingMode.simulated,
    this.groupId,
  });

  @override
  ConsumerState<RouteTrackingPage> createState() => _RouteTrackingPageState();
}

class _RouteTrackingPageState extends ConsumerState<RouteTrackingPage> {
  GoogleMapController? _controller;

  LatLng? _currentPosition;
  double _bearing = 0.0;
  BitmapDescriptor? _customMarkerIcon;
  BitmapDescriptor? _crownIcon;

  final List<LatLng> traversedPoints = [];
  Duration eta = Duration.zero;
  double remainingDistance = 0.0;
  DateTime? _startTime;

  late final ITrackingSource _source;
  StreamSubscription<TrackSample>? _sub;

  double? _distanceToStartM;
  String? _uid;
  bool _started = false;
  static const double _startRadiusM = 20;

  final _avatarIcons = <String, BitmapDescriptor>{};
  final _iconsLoader = MapIconsLoader();
  final _presence = TrackingPresenceService();

  bool get _showStartBanner =>
      widget.mode == TrackingMode.live &&
      !_started &&
      _distanceToStartM != null &&
      _distanceToStartM! > _startRadiusM;

  @override
  void initState() {
    super.initState();

    _uid = FirebaseAuth.instance.currentUser?.uid;

    _loadIcons();

    _source = widget.mode == TrackingMode.simulated
        ? SimTrackingSource(points: widget.points)
        : LiveTrackingSource(
            startPoint: widget.points.isNotEmpty ? widget.points.first : null,
            requireStartWithinM: 20,
          );

    _sub = _source.watch().listen((s) async {
      if (!mounted) return;

      // 1) позиция + bearing
      setState(() {
        _currentPosition = s.pos;
        _bearing = s.bearingDeg;
      });
      // если нужно писать location куда-то ещё (не в live группы)
      await _presence.send(
        ref: ref,
        pos: s.pos,
        groupId: widget.groupId,
        uid: _uid,
        bearing: _bearing,
      );

      // ✅ RTDB live (только если groupId есть)
     //_sendLiveToRtdb(s.pos);

      // 2) проверка старта (только live)
      if (widget.mode == TrackingMode.live &&
          !_started &&
          widget.points.isNotEmpty) {
        final dist = distanceM(s.pos, widget.points.first);
        setState(() => _distanceToStartM = dist);
        debugPrint('OFFROAD 🟡🟡🟡 START-GATE dist=$dist radius=$_startRadiusM started=$_started');
        if (dist > _startRadiusM) {
          debugPrint('OFFROAD ⛔⛔⛔ gate BLOCKED: move closer');
          _updateCameraPosition();
          return;
        }
        debugPrint('OFFROAD ✅✅✅ gate PASSED: START!');
        setState(() {
          _started = true;
          _distanceToStartM = null;
          _startTime = DateTime.now();
          traversedPoints.clear();
          remainingDistance = 0;
          eta = Duration.zero;
        });
      }
      // 3) прогресс и камера
      _startTime ??= DateTime.now();
      _updateCameraPosition();
      _updateRouteProgress(s.pos);
    });
    debugPrint('RouteTrackingPage mode=${widget.mode} groupId=${widget.groupId} uid=$_uid');
  }

Future<void> _loadIcons() async {
  final arrow = await _iconsLoader.loadArrow();
  final crown = await _iconsLoader.loadCrown();
  if (!mounted) return;
  setState(() {
    _customMarkerIcon = arrow;
    _crownIcon = crown;
  });
}

  void _updateCameraPosition() {
    if (_currentPosition == null || _controller == null) return;

    _controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition!,
          zoom: 18,
          tilt: 60,
          bearing: _bearing,
        ),
      ),
    );
  }

  void _updateRouteProgress(LatLng current) {
    if (widget.mode == TrackingMode.simulated || _started) {
      traversedPoints.add(current);
    }
    final hasStarted = widget.mode == TrackingMode.simulated || _started;
    final remainingPoints =
        hasStarted && _currentPosition != null && widget.points.isNotEmpty
            ? widget.points.sublist(_closestPointIndex(_currentPosition!))
            : widget.points;

    remainingDistance = 0.0;
    for (int i = 0; i < remainingPoints.length - 1; i++) {
      remainingDistance += distanceM(remainingPoints[i], remainingPoints[i + 1]);
    }
    final elapsed = _startTime != null
        ? DateTime.now().difference(_startTime!)
        : Duration.zero;
    double averageSpeed = (elapsed.inSeconds > 0 && traversedPoints.length > 1)
        ? traversedPoints
                .asMap()
                .entries
                .skip(1)
                .map((e) => distanceM(traversedPoints[e.key - 1], e.value))
                .reduce((a, b) => a + b) /
            elapsed.inSeconds
        : 0.0;
    eta = (averageSpeed > 0)
        ? Duration(seconds: (remainingDistance / averageSpeed).round())
        : Duration.zero;
  }

  int _closestPointIndex(LatLng pos) {
    double minDist = double.infinity;
    int index = 0;
    for (int i = 0; i < widget.points.length; i++) {
      final d = distanceM(pos, widget.points[i]);
      if (d < minDist) {
        minDist = d;
        index = i;
      }
    }
    return index;
  }

void _warmUpAvatars(List<LiveUserView> users) async {
bool changed = false;
    for (final u in users) {
      if (_avatarIcons.containsKey(u.userId)) continue;
      try {
        final icon = await AvatarMarkerFactory.I.get(
          userId: u.userId,
          photoUrlOrAsset: u.img,
          size: 240,
        );
        _avatarIcons[u.userId] = icon;
        changed = true;
        debugPrint('✅ avatar ready for ${u.name}');
      } catch (e) {
        debugPrint('❌ avatar failed for ${u.name}: $e');
      }
    }
    if (changed && mounted) {
      setState(() {});
    }
}

  @override
  void dispose() {
    // ✅ убрать live запись при выходе (если группа была)
    unawaited(_presence.stopSharing(ref: ref, groupId: widget.groupId, uid: _uid));
    _sub?.cancel();
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final traversed = (_started || widget.mode == TrackingMode.simulated)
        ? traversedPoints.toList()
        : <LatLng>[];

    final currentIndex = (_currentPosition != null)
        ? _closestPointIndex(_currentPosition!)
        : 0;

    final remaining =
        widget.points.isNotEmpty ? widget.points.sublist(currentIndex) : <LatLng>[];

    // ✅ live users из RTDB только если есть groupId
    final gid = widget.groupId;
    final AsyncValue<List<LiveUserView>> liveAsync = gid == null
        ? const AsyncValue.data(<LiveUserView>[])
        : ref.watch(liveUsersWithProfilesProvider(gid));
    final AsyncValue<String?> ownerAsync = gid == null
        ? const AsyncValue.data(null)
        : ref.watch(groupOwnerIdProvider(gid));
        
    final liveMarkers = liveAsync.when(
  data: (users) => buildLiveMarkers(
    users: users,
    warmUpAvatars: _warmUpAvatars,
    avatarIcons: _avatarIcons,
    myUid: _uid,
    leaderId: ownerAsync.asData?.value,
    crownIcon: _crownIcon,
  ),
  loading: () => <Marker>{},
  error: (e, st) {
    debugPrint('liveUsersWithProfilesProvider error: $e');
    debugPrintStack(stackTrace: st);
    return <Marker>{};
  },
);

    return Scaffold(
      appBar: NewAppBar(
        title: "Route tracking",
        onPressed: () => Navigator.of(context).pop(),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.hybrid,
            mapToolbarEnabled: false,
            initialCameraPosition: CameraPosition(
              target: widget.points.isNotEmpty ? widget.points.first : const LatLng(0, 0),
              zoom: 15,
            ),
            polylines: {
              Polyline(
                polylineId: const PolylineId('traversed'),
                color: Colors.green,
                width: 5,
                points: traversed,
              ),
              Polyline(
                polylineId: const PolylineId('remaining'),
                color: Colors.blue,
                width: 4,
                points: remaining,
              ),
            },
            markers: {
              if (widget.points.isNotEmpty)
                Marker(
                  markerId: const MarkerId('start'),
                  position: widget.points.first,
                  infoWindow: const InfoWindow(title: 'Start'),
                ),
              if (widget.points.isNotEmpty)
                Marker(
                  markerId: const MarkerId('end'),
                  position: widget.points.last,
                  infoWindow: const InfoWindow(title: 'Finish'),
                ),
              if (_currentPosition != null)
                Marker(
                  markerId: const MarkerId('me'),
                  position: _currentPosition!,
                  rotation: _normalize(_bearing),
                  icon: _customMarkerIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure),
                  anchor: const Offset(0.5, 0.5),
                  flat: true,
                ),

              // ✅ участники группы из RTDB
              ...liveMarkers,
            },
            onMapCreated: (controller) => _controller = controller,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
          ),

          if (_showStartBanner)
            Positioned(
              top: padding12,
              left: padding16,
              right: padding16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(radius12),
                ),
                child: Text(
                  'Move to the starting point: ${_distanceToStartM!.round()} m',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: surfaceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_started || widget.mode == TrackingMode.simulated)
            Positioned(
              top: padding16,
              left: padding16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(radius12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Distance remaining: ${(remainingDistance / 1000).toStringAsFixed(2)} km",
                      style: const TextStyle(color: surfaceColor, fontSize: fontSize16),
                    ),
                    Text(
                      "Time remaining: ${eta.inMinutes} min",
                      style: const TextStyle(color: surfaceColor, fontSize: fontSize16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _normalize(double deg) {
    deg %= 360;
    if (deg < 0) deg += 360;
    return deg;
  }
}
