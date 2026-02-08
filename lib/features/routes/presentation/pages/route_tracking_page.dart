import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/avatar_icon_cache.dart';
import 'package:offroad_nav/features/competition/presentation/services/competition_presence_service.dart';
import 'package:offroad_nav/features/groups/application/providers/groups_providers.dart';
import 'package:offroad_nav/features/groups/presentation/models/live_user_view.dart';
import 'package:offroad_nav/features/routes/data/repositories/completed_route_repository.dart';
import 'package:offroad_nav/features/routes/presentation/map/live_markers_builder.dart';
import 'package:offroad_nav/features/routes/presentation/map/map_camera_actions.dart';
import 'package:offroad_nav/features/routes/presentation/map/map_icons_loader.dart';
import 'package:offroad_nav/features/routes/presentation/map/map_quick_controls.dart';
import 'package:offroad_nav/features/routes/presentation/map/restricted_zones_loader.dart';
import 'package:offroad_nav/features/routes/presentation/map/route_markers_builder.dart';
import 'package:offroad_nav/features/routes/presentation/tracking/services/tracking_presence_service.dart';
import 'package:offroad_nav/features/routes/presentation/tracking/settings/tracking_profile.dart';
import 'package:offroad_nav/features/routes/presentation/tracking/settings/tracking_settings_sheet.dart';
import 'package:offroad_nav/features/routes/presentation/widgets/route_action_bar.dart';
import 'package:offroad_nav/features/routes/presentation/widgets/tracking_infobar.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../design/widgets/app_bar.dart';
import '../tracking/sources/live_tracking_source.dart';
import '../tracking/sources/sim_tracking_source.dart';
import '../tracking/sources/tracking_sample.dart';
import '../tracking/sources/tracking_source.dart';

// ✅ новые маленькие контроллеры (которые мы договорились вынести)
import '../tracking/controllers/leader_follow_controller.dart';
import '../tracking/controllers/route_tracking_controller.dart';

// ✅ UI панели

enum TrackingMode { simulated, live, competition }

class TrackingResult {
  final DateTime startedAt;
  final DateTime finishedAt;
  final int startIndex;
  final int endIndex;
  final double distanceMeters;
  final List<LatLng> traversedPolyline;
  final String profileName;

  TrackingResult({
    required this.startedAt,
    required this.finishedAt,
    required this.startIndex,
    required this.endIndex,
    required this.distanceMeters,
    required this.traversedPolyline,
    required this.profileName,
  });

  int get durationSec => finishedAt.difference(startedAt).inSeconds;
}

class RouteTrackingPage extends ConsumerStatefulWidget {
  final List<LatLng> points;
  final TrackingMode mode;

  /// Если null — одиночный режим (без live-участников).
  final String? groupId;
  final String? routeId;
  final String routeName;
  final Future<void> Function(TrackingResult result)? onFinish;
  final Future<void> Function()? onCancel;
  final String? competitionId;

  const RouteTrackingPage({
    super.key,
    required this.points,
    required this.routeName,
    this.routeId,
    this.mode = TrackingMode.simulated,
    this.groupId,
    this.onFinish,
    this.onCancel,
    this.competitionId,
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
  // final Map<String, BitmapDescriptor> _avatarIcons = {};
  final _avatarCache = AvatarIconCache(size: 240);

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
  late final CompletedRouteRepository _completedRepo;
  final _competitionPresence = CompetitionPresenceService();

  bool _showRestricted = false;
  Set<Polygon> _restrictedPolygons = {};
  bool _restrictedLoading = false;

  @override
  void initState() {
    super.initState();
    _completedRepo = CompletedRouteRepository(FirebaseFirestore.instance);
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
    if (widget.groupId != null && widget.mode == TrackingMode.live) {
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

    _loadRestrictedZones();

    // ✅ старт трекинга
    _sub = _source.watch().listen((s) async {
      if (!mounted) return;

      final currentProfile = ref.read(trackingProfileProvider);
      // обновляем прогресс — ТОЛЬКО по своей позиции (s.pos)
      _progress.updatePosition(
        route: widget.points,
        pos: s.pos,
        bearingDeg: s.bearingDeg,
        profile: currentProfile,
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
        debugPrint('✅ MODE=${widget.mode} groupId=${widget.groupId} uid=$_uid');
        unawaited(() async {
          try {
            await _presence.send(
              ref: ref,
              pos: s.pos,
              groupId: widget.groupId,
              uid: _uid,
              bearing: _progress.state.bearingDeg,
              accuracyM: s.accuracyM,
            );
            debugPrint(
              '✅ groups_live send OK groupId=${widget.groupId} uid=$_uid',
            );
          } catch (e, st) {
            debugPrint('❌ groups_live send ERROR: $e');
            debugPrintStack(stackTrace: st);
          }
        }());
      }

      if (widget.mode == TrackingMode.competition &&
          widget.competitionId != null) {
        try {
          await _competitionPresence.send(
            ref: ref,
            competitionId: widget.competitionId!,
            uid: _uid,
            pos: s.pos,
            bearing: _progress.state.bearingDeg,
            accuracyM: s.accuracyM ?? 0,
          );
          debugPrint('✅ RTDB OK');
        } catch (e) {
          debugPrint('❌ RTDB ERROR: $e');
        }
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

Future<void> _loadRestrictedZones() async {
  if (_restrictedLoading || _restrictedPolygons.isNotEmpty) return;
  _restrictedLoading = true;

  try {
    final polys = await RestrictedZonesLoader.loadFromAsset(
      'assets/geo/kr_kaitseala.geojson',
    );
    if (!mounted) return;
    setState(() => _restrictedPolygons = polys);
  } catch (e) {
    debugPrint('Restricted zones load failed: $e');
  } finally {
    _restrictedLoading = false;
  }
}

  @override
  void dispose() {
    _ownerSub?.close();
    _usersSub?.close();
    if (widget.groupId != null && widget.mode == TrackingMode.live) {
      unawaited(
        _presence.stopSharing(ref: ref, groupId: widget.groupId, uid: _uid),
      );
    }
    if (widget.mode == TrackingMode.competition &&
        widget.competitionId != null) {
      unawaited(
        _competitionPresence.stopSharing(
          ref: ref,
          competitionId: widget.competitionId!,
          uid: _uid,
        ),
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
        _updateCameraPosition(target: my, bearing: _progress.state.bearingDeg);
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
    final changed = await _avatarCache.warmUp(users);
    for (final u in users) {
      // debugPrint('❌ LIVE: ${u.userId} name=${u.name} img=${u.img}');
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

    final started = st.started; // ✅ только из контроллера
    final distToStart = st.distanceToStartM;

    final elapsed = (!started || st.startTime == null)
        ? Duration.zero
        : DateTime.now().difference(st.startTime!);

    // traversed polyline (зелёный)
    final traversedPoints = <LatLng>[];
    if (widget.points.isNotEmpty && started) {
      final startIdx = st.startIndex.clamp(0, widget.points.length - 1);
      final idx = st.closestIndex.clamp(startIdx, widget.points.length - 1);

      if (idx > startIdx) {
        traversedPoints.addAll(widget.points.sublist(startIdx, idx + 1));
      } else if (startIdx < widget.points.length - 1) {
        // показать маленький стартовый сегмент (иначе polyline не рисуется)
        traversedPoints.addAll(widget.points.sublist(startIdx, startIdx + 2));
      }
    }

    final isPaused = false; // пока заглушка, потом подключим
    final isCompetition = widget.mode == TrackingMode.competition;

    final actions = <ActionButtonConfig>[
      ActionButtonConfig(
        label: 'Finish',
        iconData: Icons.flag,
        onTap: started ? _finishTracking : null,
        filled: true, // сделаем главной
        enabled: started,
      ),
      if (isCompetition)
        ActionButtonConfig(
          label: 'Cancel',
          iconData: Icons.close,
          onTap: _cancelAttempt, // сделаем
          filled: false,
          enabled: true,
        ),
      if (!isCompetition)
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
    final shouldShowLive = gid != null && widget.mode == TrackingMode.live;
    final ownerAsync = !shouldShowLive
        ? const AsyncValue<String?>.data(null)
        : ref.watch(groupOwnerIdProvider(gid!));

    final liveUsersAsync = !shouldShowLive
        ? const AsyncValue<List<LiveUserView>>.data(<LiveUserView>[])
        : ref.watch(liveUsersWithProfilesProvider(gid!));

    final routeMarkers = buildRouteStartEndMarkers(points: widget.points);
    final liveMarkers = liveUsersAsync.when(
      data: (users) {
        final now = DateTime.now().millisecondsSinceEpoch;
        const ttlMs = 30 * 1000; // 30 секунд — норм

        final online = users.where((u) {
          final t = u.updatedAtMs;
          if (t == null) return false;
          return (now - t) <= ttlMs;
        }).toList();

        return buildLiveMarkers(
          users: online,
          warmUpAvatars: _warmUpAvatars,
          avatarIcons: _avatarCache.map,
          myUid: _uid,
          leaderId: ownerAsync.asData?.value,
          crownIcon: _crownIcon,
        );
      },
      loading: () => <Marker>{},
      error: (e, st) {
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

    return PopScope(
      canPop: widget.mode != TrackingMode.competition,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (widget.mode == TrackingMode.competition) {
          await _cancelAttempt();
        }
      },
      child: Scaffold(
        appBar: NewAppBar(
          title: "Route tracking",
          onPressed: () async {
            if (widget.mode == TrackingMode.competition) {
              await _cancelAttempt(); // ✅ покажет диалог и вызовет widget.onCancel
            } else {
              Navigator.of(context).pop();
            }
          },
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
              markers: {...routeMarkers, ...liveMarkers, ...myMarker},
              polylines: {routePolyline, traversedPolyline},
              onMapCreated: (c) => _controller = c,
              polygons: _showRestricted ? _restrictedPolygons : <Polygon>{},
            ),
            Positioned(
  right: padding16,
  bottom: 200, // чтобы не пересекалось с action bar
  child: MapQuickControls(
    onCenter: () {
      final target = _leader.state.followLeader
          ? _leader.state.leaderPos
          : _progress.state.currentPos;

      MapCameraActions.centerOn(
        controller: _controller,
        target: target ?? (widget.points.isNotEmpty ? widget.points.first : null),
        zoom: 18,
        tilt: 60,
        bearing: _leader.state.followLeader
            ? (_leader.state.leaderHeading ?? _progress.state.bearingDeg)
            : _progress.state.bearingDeg,
      );
    },
    onNorth: () {
      final target = _leader.state.followLeader
          ? _leader.state.leaderPos
          : _progress.state.currentPos;

      MapCameraActions.faceNorth(
        controller: _controller,
        keepTarget: target ?? (widget.points.isNotEmpty ? widget.points.first : null),
        zoom: 18,
        tilt: 60,
      );
    },
      onToggleRestricted: () => setState(() => _showRestricted = !_showRestricted),
  restrictedEnabled: _showRestricted,
  ),
),

            // follow leader button (только если мы в группе)
            if (gid != null && widget.mode == TrackingMode.live)
              Positioned(
                right: padding16,
                bottom: 140, // ← подбирается под + / − (можно 130–160)
                child: Tooltip(
                  message: _leader.state.followLeader
                      ? 'Stop following leader'
                      : 'Follow leader',
                  child: GestureDetector(
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

            Positioned(
              left: padding16,
              right: padding16,
              top: padding12,
              child: TrackingInfoBar(
                started: started,
                distToStartM: distToStart,
                traversedMeters: st.traversedMeters,
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
      ),
    );
  }

  Future<void> _finishTracking() async {
    final st = _progress.state;

    if (!st.started || st.startTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You have not started yet')));
      return;
    }

    final finishedAt = DateTime.now();
    final startedAt = st.startTime!;

    final profile = ref.read(trackingProfileProvider);

    final startIdx = st.startIndex.clamp(0, widget.points.length - 1);
    final endIdx = st.closestIndex.clamp(startIdx, widget.points.length - 1);

    final distanceM = st.traversedMeters;

    final traversed = (endIdx > startIdx)
        ? widget.points.sublist(startIdx, endIdx + 1)
        : <LatLng>[];

    final result = TrackingResult(
      startedAt: startedAt,
      finishedAt: finishedAt,
      startIndex: startIdx,
      endIndex: endIdx,
      distanceMeters: distanceM,
      traversedPolyline: traversed,
      profileName: profile.name,
    );

    try {
      // ✅ 1) Если передали onFinish — значит “особый режим” (например competition)
      if (widget.onFinish != null) {
        await widget.onFinish!(result);

        if (!mounted) return;
        Navigator.pop(context);
        return;
      }

      // ✅ 2) Обычный режим: сохраняем completed как раньше
      await _completedRepo.saveCompletedRoute(
        userId: _uid,
        profileName: profile.name,
        startedAt: startedAt,
        finishedAt: finishedAt,
        distanceMeters: distanceM,
        startIndex: startIdx,
        endIndex: endIdx,
        traversedPolyline: traversed,
        mode: widget.groupId == null ? 'solo' : 'group',
        groupId: widget.groupId,
        routeId: widget.routeId,
        routeName: widget.routeName,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Route saved')));

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

//TODO Доделать паузу!!!
  void _togglePause() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pause/Resume pressed')));
  }

  void _openTrackingSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrackingSettingsSheet(
        onApplyProfile: (p) async {
          // обновляем выбранный профиль в приложении
          ref.read(trackingProfileProvider.notifier).set(p);

          // применяем настройки GPS только если это live
          if (widget.mode != TrackingMode.simulated &&
              _source is LiveTrackingSource) {
            await (_source as LiveTrackingSource).applyProfile(p);
          }
        },
      ),
    );
  }

  Future<void> _cancelAttempt() async {
    if (widget.onCancel == null) {
      Navigator.pop(context);
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel attempt?'),
        content: const Text('Progress will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await widget.onCancel!();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to cancel: $e')));
    }
  }
}
