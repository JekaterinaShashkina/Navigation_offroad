import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/avatar_marker_factory.dart';
import 'package:offroad_nav/features/groups/application/providers/groups_providers.dart';
import 'package:offroad_nav/features/groups/presentation/models/live_user_view.dart';
import 'package:offroad_nav/features/routes/presentation/map/live_markers_builder.dart';
import 'package:offroad_nav/features/routes/presentation/map/map_icons_loader.dart';
import 'package:offroad_nav/features/routes/presentation/tracking/tracking_presence_service.dart';
import 'package:offroad_nav/features/routes/presentation/widgets/route_action_bar.dart';
import 'package:offroad_nav/features/routes/presentation/widgets/tracking_bottom_controls.dart';
import 'package:offroad_nav/features/routes/presentation/widgets/tracking_bottom_panel.dart';
import 'package:offroad_nav/features/routes/presentation/widgets/tracking_infobar.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../design/widgets/app_bar.dart';
import '../tracking/live_tracking_source.dart';
import '../tracking/sim_tracking_source.dart';
import '../tracking/tracking_sample.dart';
import '../tracking/tracking_source.dart';

// ✅ новые маленькие контроллеры (которые мы договорились вынести)
import '../tracking/leader_follow_controller.dart';
import '../tracking/route_tracking_controller.dart';

// ✅ UI панели

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

  final _iconsLoader = MapIconsLoader();

  BitmapDescriptor? _arrowIcon;
  BitmapDescriptor? _crownIcon;

  /// кэш иконок аватаров для маркеров
  final Map<String, BitmapDescriptor> _avatarIcons = {};

  // tracking sources
  late final ITrackingSource _source;
  StreamSubscription<TrackSample>? _sub;

  // presence for group live mode (RTDB)
  final _presence = TrackingPresenceService();

  // uid
  late final String _uid;

  // ✅ разделённые контроллеры
  final _progress = RouteTrackingController();
  final _leader = LeaderFollowController();
  ProviderSubscription<AsyncValue<String?>>? _ownerSub;
  ProviderSubscription<AsyncValue<List<LiveUserView>>>? _usersSub;

  DateTime? _lastCameraMoveAt;

  @override
  void initState() {
    super.initState();

    _uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

    _source = widget.mode == TrackingMode.simulated
        ? SimTrackingSource(points: widget.points)
        : LiveTrackingSource(
            startPoint: widget.points.isNotEmpty ? widget.points.first : null,
            requireStartWithinM: RouteTrackingController.startRadiusM,
          );

    unawaited(_loadIcons());
    WakelockPlus.enable();

    // ✅ подписки на group provider (ТОЛЬКО один раз, не в build)
    if (widget.groupId != null) {
      final gid = widget.groupId!;

      _ownerSub = ref.listenManual<AsyncValue<String?>>(
        groupOwnerIdProvider(gid),
        (prev, next) {
          final ownerId = next.maybeWhen(data: (v) => v, orElse: () => null);
          _leader.setLeaderId(ownerId);
          // UI не обязательно, но можно:
          if (mounted) setState(() {});
        },
      );

      _usersSub = ref.listenManual<AsyncValue<List<LiveUserView>>>(
        liveUsersWithProfilesProvider(gid),
        (prev, next) {
          final users = next.maybeWhen(data: (v) => v, orElse: () => null);
          if (users != null) {
            _leader.applyUsers(users);
            // если хочешь, чтобы кнопка follow сразу оживала:
            if (mounted) setState(() {});
          }
        },
      );
    }

    // ✅ старт трекинга
    _sub = _source.watch().listen((s) async {
      if (!mounted) return;

      // обновляем прогресс — ТОЛЬКО по своей позиции (s.pos)
      _progress.updatePosition(
        route: widget.points,
        pos: s.pos,
        bearingDeg: s.bearingDeg,
        isLiveMode: widget.mode == TrackingMode.live,
      );

      // камера: если follow включён и есть лидерская позиция — следуем за лидером
      final follow = _leader.state.followLeader;
      final camTarget = follow ? _leader.state.leaderPos : s.pos;
      final camBearing = follow
          ? (_leader.state.leaderHeading ?? s.bearingDeg)
          : s.bearingDeg;

      _updateCameraPosition(target: camTarget, bearing: camBearing);

      // ✅ RTDB live присутствие (только если groupId есть)
      if (widget.groupId != null && widget.mode == TrackingMode.live) {
        unawaited(
          _presence.send(
            ref: ref,
            pos: s.pos,
            groupId: widget.groupId,
            uid: _uid,
            bearing: _progress.state.bearingDeg, // или s.bearingDeg
            accuracyM: s.accuracyM,
          ),
        );
      }

      // перерисовка UI
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadIcons() async {
    final arrow = await _iconsLoader.loadArrow();
    final crown = await _iconsLoader.loadCrown();
    if (!mounted) return;
    setState(() {
      _arrowIcon = arrow;
      _crownIcon = crown;
    });
  }

  @override
  void dispose() {
    if (widget.groupId != null && widget.mode == TrackingMode.live) {
      unawaited(
        _presence.stopSharing(ref: ref, groupId: widget.groupId, uid: _uid),
      );
    }
    _sub?.cancel();
    _source.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

void _toggleFollowLeader() {
  final leaderId = _leader.state.leaderId;

  if (leaderId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Leader is not defined for this group yet'),
        backgroundColor: buttonBackgroundColor,
      ),
    );
    return;
  }

  final enabled = _leader.toggleFollow();
  setState(() {});

  if (enabled) {
    final lp = _leader.state.leaderPos;
    if (lp != null) {
      // ✅ СРАЗУ едем к лидеру, не ждём GPS тик
      _updateCameraPosition(
        target: lp,
        bearing: _leader.state.leaderHeading ?? _progress.state.bearingDeg,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waiting for the leader location...'),
          backgroundColor: buttonBackgroundColor,
        ),
      );
    }
  } else {
    // ✅ СРАЗУ возвращаемся к себе
    final my = _progress.state.currentPos;
    if (my != null) {
      _updateCameraPosition(
        target: my,
        bearing: _progress.state.bearingDeg,
      );
    }
  }
}


  void _updateCameraPosition({LatLng? target, double? bearing}) {
    if (_controller == null) return;

    // лёгкий throttle, чтобы камера не дрожала
    final now = DateTime.now();
    if (_lastCameraMoveAt != null &&
        now.difference(_lastCameraMoveAt!) <
            const Duration(milliseconds: 250)) {
      return;
    }
    _lastCameraMoveAt = now;

    final pos = target;
    if (pos == null) return;

    _controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: pos,
          zoom: 18,
          tilt: 60,
          bearing: _normalize(bearing ?? _progress.state.bearingDeg),
        ),
      ),
    );
  }

  double _normalize(double value) {
    var v = value % 360;
    if (v < 0) v += 360;
    return v;
  }

  /// Для аватаров: прогреваем (генерим) BitmapDescriptor заранее.
  Future<void> _warmUpAvatars(List<LiveUserView> users) async {
    bool changed = false;
    for (final u in users) {
      if (_avatarIcons.containsKey(u.userId)) continue;

      try {
        final icon = await AvatarMarkerFactory.I.get(
          userId: u.userId,
          photoUrlOrAsset: u.img, // ✅ у тебя поле img
          size: 240,
        );
        _avatarIcons[u.userId] = icon;
        changed = true;
      } catch (e) {
        debugPrint('❌ avatar failed for ${u.name}: $e'); // ✅ у тебя поле name
      }
    }
    if (changed && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // --- route polyline (синий) ---
    final routePolyline = Polyline(
      polylineId: const PolylineId('route'),
      points: widget.points,
      color: Colors.blue,
      width: 4,
      zIndex: 0,
    );

    // --- traversed polyline (зелёный) ---
    // ✅ ВАЖНО: traversed теперь “snap-to-route” как sublist,
    // а не GPS-ломаная. Тогда синяя линия не “пропадает кусками”.
    final st = _progress.state;
    final traversedPoints = <LatLng>[];
    if (widget.points.isNotEmpty &&
        (st.started || widget.mode == TrackingMode.simulated)) {
      final idx = st.closestIndex.clamp(0, widget.points.length - 1);
      traversedPoints.addAll(widget.points.sublist(0, idx + 1));
    }
    
    final started = st.started || widget.mode == TrackingMode.simulated;
    final distToStart = st.distanceToStartM;
    final elapsed = st.startTime == null ? Duration.zero : DateTime.now().difference(st.startTime!);
    final isPaused = false; // пока заглушка, потом подключим

    final actions = <ActionButtonConfig>[
  ActionButtonConfig(
    label: 'Finish',
    iconData: Icons.flag,
    onTap: started ? _finishTracking : null,
    filled: true,   // сделаем главной
    enabled: started,
  ),
  ActionButtonConfig(
    label: isPaused ? 'Resume' : 'Pause',
    iconData: isPaused ? Icons.play_arrow : Icons.pause,
    onTap: started ? _togglePause : null,
    filled: false,
    enabled: started,
  ),
  ActionButtonConfig(
    label: 'Settings',
    iconData: Icons.settings,
    onTap: _openTrackingSettings,
    filled: false,
    enabled: true,
  ),
];

    final traversedPolyline = Polyline(
      polylineId: const PolylineId('traversed'),
      points: traversedPoints,
      color: Colors.green,
      width: 5,
      zIndex: 1,
    );

    // --- live users ---
    final gid = widget.groupId;
    final ownerAsync = gid == null
        ? const AsyncValue<String?>.data(null)
        : ref.watch(groupOwnerIdProvider(gid));
    final liveUsersAsync = gid == null
        ? const AsyncValue<List<LiveUserView>>.data(<LiveUserView>[])
        : ref.watch(liveUsersWithProfilesProvider(gid));

    final liveMarkers = liveUsersAsync.when(
      data: (users) {
          final now = DateTime.now().millisecondsSinceEpoch;
          const ttlMs = 60 * 1000; // 30 секунд — норм

          final online = users.where((u) {
            final t = u.updatedAtMs;
            if (t == null) return false;
            return (now - t) <= ttlMs;
          }).toList();

        return buildLiveMarkers(
          users: online,
          warmUpAvatars: _warmUpAvatars,
          avatarIcons: _avatarIcons,
          myUid: _uid,
          leaderId: ownerAsync.asData?.value,
          crownIcon: _crownIcon,
        );
      },
      loading: () => <Marker>{},
      error: (e, st) {
        debugPrint('liveUsersWithProfilesProvider error: $e');
        debugPrintStack(stackTrace: st);
        return <Marker>{};
      },
    );

    // --- my marker ---
    final myPos = st.currentPos;
    final myMarker = (myPos == null || _arrowIcon == null)
        ? <Marker>{}
        : {
            Marker(
              markerId: const MarkerId('me'),
              position: myPos,
              icon: _arrowIcon!,
              anchor: const Offset(0.5, 0.5),
              rotation: _normalize(st.bearingDeg),
              flat: true,
            ),
          };

    // --- start gate banner ---
    //final distToStart = st.distanceToStartM;
    // final showGateBanner =
    //     widget.mode == TrackingMode.live &&
    //     !st.started &&
    //     distToStart != null &&
    //     distToStart > RouteTrackingController.startRadiusM;

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
            myLocationButtonEnabled: false,
            compassEnabled: false,
            initialCameraPosition: CameraPosition(
              target: widget.points.isNotEmpty
                  ? widget.points.first
                  : const LatLng(59.4370, 24.7536),
              zoom: 16,
            ),
            markers: {...liveMarkers, ...myMarker},
            polylines: {routePolyline, traversedPolyline},
            onMapCreated: (c) => _controller = c,
          ),

          // follow leader button (только если мы в группе)
          if (gid != null)
            Positioned(
              right: padding16,
              bottom: 140, // ← подбирается под + / − (можно 130–160)
              child: Tooltip(
              message: _leader.state.followLeader
                  ? 'Stop following leader'
                  : 'Follow leader',                
                child:  GestureDetector(
                onTap: _toggleFollowLeader,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _leader.state.followLeader
                        ? buttonBackgroundColor
                        : Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _leader.state.followLeader
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              ),
            ),
          // start gate hint
          // if (showGateBanner)
            Positioned(
              left: padding16,
              right: padding16,
              top: padding12,
              child: TrackingInfoBar(
                started: started,
                distToStartM: distToStart,
                remainingMeters: st.remainingMeters,
                eta: st.eta,
                elapsed: elapsed,
              ),
            ),
Positioned(
  left: 0,
  right: 0,
  bottom: 24,
  child: RouteActionBar(actions: actions),
),
        ],
      ),
    );
  }

  void _finishTracking() {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Finish pressed')),
  );
}

void _togglePause() {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Pause/Resume pressed')),
  );
}

void _openTrackingSettings() {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Settings pressed')),
  );
}
}
