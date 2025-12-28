import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

class LiveUserRtdb {
  final String userId;
  final double lat;
  final double lng;
  final double? heading;
  final double? speed;
  final int? updatedAtMs;

  LiveUserRtdb({
    required this.userId,
    required this.lat,
    required this.lng,
    this.heading,
    this.speed,
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
      updatedAtMs: (m['updatedAt'] as int?) ?? (m['updated_at'] as int?),
    );
  }
}

class GroupsLiveRepository {
  final FirebaseDatabase _rtdb;
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
      final res = <LiveUserRtdb>[];

      map.forEach((k, v) {
        if (v is Map<dynamic, dynamic>) {
          try {
            res.add(LiveUserRtdb.fromMap(k.toString(), v));
          } catch (_) {}
        }
      });

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
  }) async {
    final ref = _meRef(groupId, userId);

    // полезно: если приложение умерло/сеть пропала — удалим запись
    // (работает когда есть соединение; иначе удалится при переподключении)
    await ref.onDisconnect().remove();

    await ref.set({
      'lat': lat,
      'lng': lng,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
      'updatedAt': ServerValue.timestamp,
    });
  }

  /// остановить шаринг
  Future<void> stopSharing({
    required String groupId,
    required String userId,
  }) async {
    await _meRef(groupId, userId).remove();
  }
}
