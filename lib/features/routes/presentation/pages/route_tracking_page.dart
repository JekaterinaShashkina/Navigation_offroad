import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:offroad_nav/design/widgets/avatar_marker_factory.dart';
import 'package:offroad_nav/features/groups/presentation/models/live_user_view.dart';

import '../../../../design/widgets/app_bar.dart';
import '../../data/repositories/route_tracking_repository.dart';
import 'package:offroad_nav/features/groups/application/providers/groups_providers.dart';

import '../tracking/live_tracking_source.dart';
import '../tracking/sim_tracking_source.dart';
import '../tracking/tracking_sample.dart';
import '../tracking/tracking_source.dart';
import '../utils/marker_icon.dart';
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

  bool get _showStartBanner =>
      widget.mode == TrackingMode.live &&
      !_started &&
      _distanceToStartM != null &&
      _distanceToStartM! > _startRadiusM;

  @override
  void initState() {
    super.initState();
    // debugWriteRtdb();

    _uid = FirebaseAuth.instance.currentUser?.uid;
    _loadCustomMarker();
    _loadCrown();

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
      // если тебе нужно писать location куда-то ещё (не в live группы)
      await _sendToFirebase(s.pos);

      // ✅ RTDB live (только если groupId есть)
     // _sendLiveToRtdb(s.pos);

      // 2) проверка старта (только live)
      if (widget.mode == TrackingMode.live &&
          !_started &&
          widget.points.isNotEmpty) {
        final dist = distanceM(s.pos, widget.points.first);
        setState(() => _distanceToStartM = dist);

        if (dist > _startRadiusM) {
          _updateCameraPosition();
          return;
        }

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

  Future<void> _loadCustomMarker() async {
    final bitmap = await MarkerIcon.fromPngAsset(
      'assets/images/navigation_arrow.png',
      widthPx: 36,
      heightPx: 36,
    );
    if (!mounted) return;
    setState(() => _customMarkerIcon = bitmap);
  }

  Future<void> _loadCrown() async {
  final crownIcon = await MarkerIcon.fromPngAsset(
    'assets/images/leader_crown.png',
    widthPx: 24,
    heightPx: 24
  );
  if (!mounted) return;
   setState(() => _crownIcon = crownIcon);
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

Future <void> _sendToFirebase(LatLng pos) async {
    // твой существующий трекинг (если нужен)
    await RouteTrackingRepository.instance.sendLocation(
    lat: pos.latitude,
    lng: pos.longitude,
    groupId: widget.groupId, // можно вообще убрать параметр, если sendLocation только users
  );

  // 2) group live (если есть groupId)
  final gid = widget.groupId;
  final uid = _uid;
  if (gid == null || uid == null) return;

  final liveRepo = ref.read(groupsLiveRepositoryProvider);
  await liveRepo.upsertMyLiveLocation(
    groupId: gid,
    userId: uid,
    lat: pos.latitude,
    lng: pos.longitude,
    heading: _bearing,
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

  void _warmUpAvatars(List<LiveUserView> users) {
  for (final u in users) {
    if (_avatarIcons.containsKey(u.userId)) continue;

    AvatarMarkerFactory.I
        .get(userId: u.userId, photoUrl: u.img)
        .then((icon) {
      if (!mounted) return;
      setState(() => _avatarIcons[u.userId] = icon);
    });
  }
}

  @override
  void dispose() {
    // ✅ убрать live запись при выходе (если группа была)
    final gid = widget.groupId;
    final uid = _uid;
    if (gid != null && uid != null) {
      ref.read(groupsLiveRepositoryProvider).stopSharing(
            groupId: gid,
            userId: uid,
          );
    }

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
  data: (users) {
  _warmUpAvatars(users);

  final myUid = _uid;
  final leaderId = ownerAsync.asData?.value;

  final markers = <Marker>{};

  for (final u in users) {
    if (myUid != null && u.userId == myUid) continue;

    final icon = _avatarIcons[u.userId] ?? AvatarMarkerFactory.I.defaultIcon;

    // 1) аватар
    markers.add(
      Marker(
        markerId: MarkerId('live_${u.userId}'),
        position: LatLng(u.lat, u.lng),
        icon: icon,
        infoWindow: InfoWindow(title: u.name),
        flat: false,
        anchor: const Offset(0.5, 0.5),
      ),
    );
    // 2) корона (если лидер)
    final isLeader = (leaderId != null && u.userId == leaderId);
    if (isLeader && _crownIcon != null) {
      markers.add(
        Marker(
          markerId: MarkerId('crown_${u.userId}'),
          position: LatLng(u.lat, u.lng),
          icon: _crownIcon!,
          flat: false,
          rotation: 0,
          // anchor.y > 1 поднимает иконку вверх над аватаром
          anchor: const Offset(0.5, 2.3),
        ),
      );
    }
  }

  return markers;
},
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
              top: 12,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Move to the starting point: ${_distanceToStartM!.round()} m',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_started || widget.mode == TrackingMode.simulated)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Distance remaining: ${(remainingDistance / 1000).toStringAsFixed(2)} km",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      "Time remaining: ${eta.inMinutes} min",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
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
