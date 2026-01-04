import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:offroad_nav/features/routes/presentation/utils/route_math.dart';

class LiveUserRtdb {
  final String userId;
  final double lat;
  final double lng;
  final double? heading;
  final double? speed;
  final double? accuracyM;
  final int? updatedAtMs;

  LiveUserRtdb({
    required this.userId,
    required this.lat,
    required this.lng,
    this.heading,
    this.speed,
    this.accuracyM,
    this.updatedAtMs,
  });

  factory LiveUserRtdb.fromMap(String userId, Map<dynamic, dynamic> m) {
    double toD(v) => (v is int) ? v.toDouble() : (v as num).toDouble();

    return LiveUserRtdb(
      userId: userId,
      lat: toD(m['lat']),
      lng: toD(m['lng']),
      heading: m['heading'] == null ? null : toD(m['heading']),
      speed: m['speed'] == null ? null : toD(m['speed']),
      accuracyM: m['accuracy'] == null ? null : toD(m['accuracy']),
      updatedAtMs: (m['updatedAt'] as int?) ?? (m['updated_at'] as int?),
    );
  }
}

class _SmoothState {
  double lat;
  double lng;
  int lastEmitMs;
  _SmoothState(this.lat, this.lng, this.lastEmitMs);
}

class GroupsLiveRepository {
  final FirebaseDatabase _rtdb;
  final Map<String, _SmoothState> _smooth = {};
  static const int _minEmitMs = 300;
  static const double _minMoveM = 4.0;
  static const double _alpha = 0.2;

  GroupsLiveRepository(this._rtdb);

  DatabaseReference _liveRef(String groupId) =>
      _rtdb.ref('groups_live/$groupId');

  DatabaseReference _meRef(String groupId, String uid) =>
      _rtdb.ref('groups_live/$groupId/$uid');

  /// слушаем всех живых юзеров группы
  Stream<List<LiveUserRtdb>> watchLiveUsers(String groupId) {
    final ref = _liveRef(groupId);

  return ref.onValue.map((event) {
      final val = event.snapshot.value;
      if (val == null) return <LiveUserRtdb>[];

      final map = val as Map<dynamic, dynamic>;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final res = <LiveUserRtdb>[];

      map.forEach((k, v) {
        if (v is! Map<dynamic, dynamic>) return;

        final uid = k.toString();
        LiveUserRtdb raw;
        try {
          raw = LiveUserRtdb.fromMap(uid, v);
        } catch (_) {
          return;
        }

        final st = _smooth[uid];

        // первый раз — без сглаживания
        if (st == null) {
          _smooth[uid] = _SmoothState(raw.lat, raw.lng, nowMs);
          res.add(raw);
          return;
        }

        // 1) throttle: не чаще чем раз в 300ms на юзера
        if (nowMs - st.lastEmitMs < _minEmitMs) {
          // возвращаем последнее сглаженное значение
          res.add(
            LiveUserRtdb(
              userId: raw.userId,
              lat: st.lat,
              lng: st.lng,
              heading: raw.heading,
              speed: raw.speed,
              accuracyM: raw.accuracyM,
              updatedAtMs: raw.updatedAtMs,
            ),
          );
          return;
        }

        // 2) min move filter (метры)
        final movedM = distanceM(
          LatLng(st.lat, st.lng),
          LatLng(raw.lat, raw.lng),
        );
                if (movedM < _minMoveM) {
          st.lastEmitMs = nowMs;
          res.add(
            LiveUserRtdb(
              userId: raw.userId,
              lat: st.lat,
              lng: st.lng,
              heading: raw.heading,
              speed: raw.speed,
              accuracyM: raw.accuracyM,
              updatedAtMs: raw.updatedAtMs,
            ),
          );
          return;
        }

        // 3) EMA smoothing
        st.lat = st.lat + _alpha * (raw.lat - st.lat);
        st.lng = st.lng + _alpha * (raw.lng - st.lng);

        st.lastEmitMs = nowMs;

        res.add(
          LiveUserRtdb(
            userId: raw.userId,
            lat: st.lat,
            lng: st.lng,
            heading: raw.heading,
            speed: raw.speed,
            accuracyM: raw.accuracyM,
            updatedAtMs: raw.updatedAtMs,
          ),
        );

    });

    // если кто-то исчез из RTDB — чистим его из кэша
      final currentIds = map.keys.map((e) => e.toString()).toSet();
      _smooth.removeWhere((uid, _) => !currentIds.contains(uid));

      return res;
    });
  }
  

  /// апдейт своей позиции
  Future<void> upsertMyLiveLocation({
    required String groupId,
    required String userId,
    required double lat,
    required double lng,
    double? heading,
    double? speed,
    double? accuracyM,
  }) async {
    final ref = _meRef(groupId, userId);

    await ref.set({
      'lat': lat,
      'lng': lng,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
      if (accuracyM != null) 'accuracy': accuracyM,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<void> startSharing({
    required String groupId,
    required String userId,
  }) async {
    await _meRef(groupId, userId).onDisconnect().remove();
  }

  /// остановить шаринг
  Future<void> stopSharing({
    required String groupId,
    required String userId,
  }) async {
    await _meRef(groupId, userId).remove();
  }
}
