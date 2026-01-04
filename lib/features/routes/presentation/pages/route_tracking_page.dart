import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:wakelock_plus/wakelock_plus.dart';

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
  ProviderSubscription<AsyncValue<List<LiveUserView>>>? _liveSubscription;
  ProviderSubscription<AsyncValue<String?>>? _ownerSubscription;

  String? _leaderId;
  LatLng? _leaderPosition;
  double? _leaderHeading;
  bool _followLeader = false;

  LatLng? get _activePosition =>
      (_followLeader && _leaderPosition != null) ? _leaderPosition : _currentPosition;

  double get _activeBearing => _followLeader ? (_leaderHeading ?? _bearing) : _bearing;

  // LatLng? _lastCameraTarget;
  // double? _lastCameraBearing;
  // DateTime? _lastCameraMoveAt;

  bool get _showStartBanner =>
      widget.mode == TrackingMode.live &&
      !_started &&
      _distanceToStartM != null &&
      _distanceToStartM! > _startRadiusM;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

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
        accuracyM: s.accuracyM,
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
      final progressPoint = _activePosition ?? s.pos;
      _updateRouteProgress(progressPoint);
    });
    debugPrint('RouteTrackingPage mode=${widget.mode} groupId=${widget.groupId} uid=$_uid');

    _listenLeaderLive();
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

  void _listenLeaderLive() {
    final gid = widget.groupId;
    if (gid == null) return;

    // начальное значение владельца
    final ownerInitial = ref.read(groupOwnerIdProvider(gid)).value;
    if (ownerInitial != null) {
      _leaderId = ownerInitial;
    }

    ref.listen<AsyncValue<String?>>(
      groupOwnerIdProvider(gid),
      (previous, next) {
        next.whenData((ownerId) {
          if (!mounted) return;
          setState(() => _leaderId = ownerId);
        });
      },
    );

    // подхватим уже имеющиеся live данные, если они прогружены
    _applyLeaderFromUsers(ref.read(liveUsersWithProfilesProvider(gid)).value);

    ref.listen<AsyncValue<List<LiveUserView>>>(
      liveUsersWithProfilesProvider(gid),
      (previous, next) {
        next.whenData((users) {
          _applyLeaderFromUsers(users);

          if (_followLeader && _leaderPosition != null) {
            _updateCameraPosition(
              target: _leaderPosition,
              bearing: _leaderHeading,
            );
            _updateRouteProgress(_leaderPosition!);
          }
        });
      },
    );
  }
 void _applyLeaderFromUsers(List<LiveUserView>? users) {
    if (users == null) return;

    final leaderId = _leaderId;
    if (leaderId == null) return;

    LiveUserView? leader;
    for (final u in users) {
      if (u.userId == leaderId) {
        leader = u;
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      if (leader != null) {
        _leaderPosition = LatLng(leader.lat, leader.lng);
        _leaderHeading = leader.heading;
      } else {
        _leaderPosition = null;
        _leaderHeading = null;
      }
    });
  }

  void _updateCameraPosition({LatLng? target, double? bearing}) {
    final pos = target ?? _activePosition;
    if (pos == null || _controller == null) return;

    _controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: pos,
          zoom: 18,
          tilt: 60,
          bearing: _normalize(bearing ?? _activeBearing),
        ),
      ),
    );
    //     final now = DateTime.now();
    // if (_lastCameraMoveAt != null &&
    //     now.difference(_lastCameraMoveAt!) < const Duration(milliseconds: 1200)) {
    //   return;
    // }

    // final distance =
    //     _lastCameraTarget != null ? distanceM(_lastCameraTarget!, _currentPosition!) : null;
    // final bearingDelta =
    //     _lastCameraBearing != null ? _bearingDelta(_bearing, _lastCameraBearing!) : null;

    // const distanceThresholdM = 5.0;
    // const bearingThresholdDeg = 6.0;

    // if (distance != null &&
    //     bearingDelta != null &&
    //     distance <= distanceThresholdM &&
    //     bearingDelta <= bearingThresholdDeg) {
    //   return;
    // }

    // final cameraPosition = CameraPosition(
    //   target: _currentPosition!,
    //   zoom: 18,
    //   tilt: 60,
    //   bearing: _bearing,
    // );
    //     final isSmallShift = distance != null && distance < 15;
    // final isSmallBearingChange = bearingDelta == null || bearingDelta < 10;

    // if (isSmallShift && isSmallBearingChange) {
    //   _controller!.moveCamera(CameraUpdate.newLatLng(_currentPosition!));
    // } else {
    //   _controller!.animateCamera(
    //     CameraUpdate.newCameraPosition(cameraPosition),
    //   );
    // }

    // _lastCameraTarget = _currentPosition;
    // _lastCameraBearing = _normalize(_bearing);
    // _lastCameraMoveAt = now;
  }

  void _updateRouteProgress(LatLng current) {
    //if (widget.mode == TrackingMode.simulated || _started) {
    final hasStarted = widget.mode == TrackingMode.simulated ||
    _started ||
    (_followLeader && _leaderPosition != null);

    if (hasStarted) {
      traversedPoints.add(current);
    }

    //final hasStarted = widget.mode == TrackingMode.simulated || _started;
    final remainingPoints =
        hasStarted && widget.points.isNotEmpty
            ? widget.points.sublist(_closestPointIndex(current))
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
    _liveSubscription?.close();
    _ownerSubscription?.close();
    _source.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _toggleFollowLeader() {
    if (_leaderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leader is not defined for this group yet'),
          backgroundColor: buttonBackgroundColor,
        ),
      );
      return;
    }

    setState(() => _followLeader = !_followLeader);

    if (_followLeader && _leaderPosition != null) {
      _updateCameraPosition(
        target: _leaderPosition,
        bearing: _leaderHeading,
      );
      _updateRouteProgress(_leaderPosition!);
    }

    if (_followLeader && _leaderPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waiting for the leader location...'),
          backgroundColor: buttonBackgroundColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final traversed = (_started || widget.mode == TrackingMode.simulated)
        ? traversedPoints.toList()
        : <LatLng>[];
    final currentIndex = (_activePosition != null)
        ? _closestPointIndex(_activePosition!)
        : 0;

    final remaining =
        widget.points.isNotEmpty ? widget.points.sublist(currentIndex) : <LatLng>[];

    final routePolyline = widget.points;

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
                polylineId: const PolylineId('route'),
                color: Colors.blue,
                width: 4,
                points: routePolyline,
                zIndex: 0,
              ),
              Polyline(
                polylineId: const PolylineId('traversed'),
                color: Colors.green,
                width: 5,
                points: traversed,
                zIndex: 1,
              //),
              // Polyline(
              //   polylineId: const PolylineId('remaining'),
              //   color: Colors.blue,
              //   width: 4,
              //   points: remaining,

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
                      if (widget.groupId != null)
            Positioned(
              bottom: padding16,
              right: padding16,
              child: FloatingActionButton.extended(
                heroTag: 'follow_leader_btn',
                backgroundColor:
                    _followLeader ? buttonBackgroundColor : surfaceColor,
                foregroundColor: Colors.black,
                onPressed: _toggleFollowLeader,
                label: Text(_followLeader ? 'Following leader' : 'Follow leader'),
                icon: Icon(_followLeader ? Icons.visibility : Icons.person_pin_circle),
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
    double _bearingDelta(double a, double b) {
    final diff = (_normalize(a) - _normalize(b)).abs();
    return diff > 180 ? 360 - diff : diff;
  }
}
