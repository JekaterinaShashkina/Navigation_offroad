import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/widgets/avatar_icon_cache.dart';

import 'package:offroad_nav/features/groups/presentation/models/live_user_view.dart';
import 'package:offroad_nav/features/routes/presentation/map/live_markers_builder.dart';
import 'package:offroad_nav/features/routes/presentation/map/map_icons_loader.dart';

class CompetitionLiveMapPage extends StatefulWidget {
  const CompetitionLiveMapPage({
    super.key,
    required this.competitionId,
    required this.routePoints,
    required this.routeName,
    required this.leaderId, // ✅ adminId
  });

  final String competitionId;
  final List<LatLng> routePoints;
  final String routeName;
  final String? leaderId;

  @override
  State<CompetitionLiveMapPage> createState() => _CompetitionLiveMapPageState();
}

class _CompetitionLiveMapPageState extends State<CompetitionLiveMapPage> {
  StreamSubscription<DatabaseEvent>? _sub;

  final _avatarCache = AvatarIconCache(size: 240);

  final _iconsLoader = MapIconsLoader();
  BitmapDescriptor? _crownIcon;

  Set<Marker> _liveMarkers = {};

  @override
  void initState() {
    super.initState();
    _loadIcons();
    _listenLive();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadIcons() async {
    final crown = await _iconsLoader.loadCrown();
    if (!mounted) return;
    setState(() => _crownIcon = crown);
  }

  void _listenLive() {
    final ref = FirebaseDatabase.instance.ref('competition_live/${widget.competitionId}');
    _sub = ref.onValue.listen((event) async {
      final raw = event.snapshot.value;

      final now = DateTime.now().millisecondsSinceEpoch;
      const ttlMs = 30 * 1000;

      final users = <LiveUserView>[];

      if (raw is Map) {
        raw.forEach((uid, v) {
          if (uid is! String || v is! Map) return;

          final lat = (v['lat'] as num?)?.toDouble();
          final lng = (v['lng'] as num?)?.toDouble();
          final heading = (v['bearing'] as num?)?.toDouble();
          final accuracyM = (v['accuracyM'] as num?)?.toDouble();
          final updatedAtMs = (v['updatedAtMs'] as num?)?.toInt();

          final name = (v['name'] ?? '').toString();
          final img = (v['img'] ?? '').toString();

          if (lat == null || lng == null || updatedAtMs == null) return;
          if (now - updatedAtMs > ttlMs) return;

          users.add(
            LiveUserView(
              userId: uid,
              lat: lat,
              lng: lng,
              heading: heading,
              accuracyM: accuracyM,
              updatedAtMs: updatedAtMs,
              name: name.isNotEmpty ? name : 'User',
              img: img.isNotEmpty ? img : null,
            ),
          );
        });
      }

      // ✅ прогреваем аватарки
      final changed = await _avatarCache.warmUp(users);

      // ✅ собираем маркеры (аватары + корона)
      final markers = buildLiveMarkers(
        users: users,
        warmUpAvatars: (_) async {}, // уже прогрели выше
        avatarIcons: _avatarCache.map,
        myUid: null,
        leaderId: widget.leaderId,
        crownIcon: _crownIcon,
        includeMe: true,
      );

      if (!mounted) return;

      // если прогрелись новые иконки — просто перерисуем
      setState(() {
        _liveMarkers = markers;
      });
    });
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
        markers: _liveMarkers, // ✅ ВОТ ЭТО ВАЖНО
      ),
    );
  }
}
