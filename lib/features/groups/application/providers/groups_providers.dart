import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:offroad_nav/features/groups/data/repositories/groups_repository.dart';
import 'package:offroad_nav/features/groups/data/repositories/groups_live_repository.dart';
import 'package:offroad_nav/features/groups/domain/entities/group.dart';
import 'package:offroad_nav/features/groups/presentation/models/live_user_view.dart';
import 'package:offroad_nav/features/routes/presentation/utils/route_math.dart';
import 'package:rxdart/rxdart.dart';

// репозиторий — один на всё приложение.
final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  final db = FirebaseFirestore.instance;
  return GroupsRepository(db);
});

// мои группы
final myGroupsProvider = StreamProvider.autoDispose<List<Group>>((ref) {
  final auth = FirebaseAuth.instance;
  final uid = auth.currentUser?.uid;
  if (uid == null) {
    // Если не залогинен — пустой стрим, чтобы UI не падал.
    return Stream.value(const []);
  }
  final repo = ref.watch(groupsRepositoryProvider);
  return repo.watchMyGroups(uid);
});

// конкретная группа
final groupProvider = StreamProvider.autoDispose.family<Group?, String>((
  ref,
  groupId,
) {
  final repo = ref.watch(groupsRepositoryProvider);
  return repo.watchGroup(groupId);
});

// открытые группы (видны всем)
final openGroupsProvider = StreamProvider.autoDispose<List<Group>>((ref) {
  final repo = ref.watch(groupsRepositoryProvider);
  return repo.watchOpenGroups();
});

final isMemberProvider = StreamProvider.autoDispose.family<bool, String>((ref, groupId) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(false);

  final repo = ref.watch(groupsRepositoryProvider);
  return repo
      .watchIsMember(groupId, uid)
      .map((exists) => exists);
});

final visibleGroupsProvider = StreamProvider.autoDispose<List<Group>>((ref) {
  final repo = ref.watch(groupsRepositoryProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid;

  final open$ = repo.watchOpenGroups();

  if (uid == null) return open$;

  final ownedPrivate$ = repo.watchMyGroups(uid);
  final memberPrivate$ = repo.watchPrivateGroupsWhereIamMember(uid);

  return CombineLatestStream.combine3<List<Group>, List<Group>, List<Group>, List<Group>>(
    open$,
    ownedPrivate$,
    memberPrivate$,
    (open, owned, member) {
      final map = <String, Group>{};

      for (final g in open) map[g.id] = g;
      for (final g in owned) map[g.id] = g;
      for (final g in member) map[g.id] = g;

      final list = map.values.toList();

      list.sort((a, b) {
        final at = a.createdAt;
        final bt = b.createdAt;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });

      return list;
    },
  );
});


final groupsLiveRepositoryProvider = Provider<GroupsLiveRepository>((ref) {
  return GroupsLiveRepository(FirebaseDatabase.instance);
});

final liveUsersProvider = StreamProvider.autoDispose.family<List<LiveUserRtdb>, String>((ref, groupId) {
  final repo = ref.watch(groupsLiveRepositoryProvider);
  return repo.watchLiveUsers(groupId);
});

final liveUsersWithProfilesProvider =
    StreamProvider.autoDispose.family<List<LiveUserView>, String>((ref, groupId) async* {
  final liveRepo = ref.watch(groupsLiveRepositoryProvider);
  debugPrint('🟢 SUBSCRIBE groups_live for groupId=$groupId');
  final db = FirebaseFirestore.instance;

  // ✅ кеш профилей: userId -> data
    const minAnimMs = 220;
  const maxAnimMs = 1200;
  const frameIntervalMs = 16;
  const maxJumpM = 40.0;
  const maxAccuracyM = 45.0;
  final profiles = <String, Map<String, dynamic>>{};
    final motions = <String, _LiveUserMotionState>{};
  final controller = StreamController<List<LiveUserView>>();
  var disposed = false;

  // ✅ чтобы не гонять одни и те же запросы параллельно
  Future<void> fetchMissingProfiles(Set<String> ids) async {
    final missing = ids.where((id) => !profiles.containsKey(id)).toList();
    if (missing.isEmpty) return;

    const chunkSize = 10;
    for (var i = 0; i < missing.length; i += chunkSize) {
      final chunk = missing.sublist(i, (i + chunkSize > missing.length) ? missing.length : i + chunkSize);

      final snap = await db.collection('users').where(FieldPath.documentId, whereIn: chunk).get();  

      for (final doc in snap.docs) {
        profiles[doc.id] = doc.data();
      }

      // ✅ если кого-то нет в Firestore, тоже отметим чтобы не пытаться снова
      for (final id in chunk) {
        profiles.putIfAbsent(id, () => <String, dynamic>{});
      }
    }
  }

  // await for (final live in liveRepo.watchLiveUsers(groupId)) {
  //   if (live.isEmpty) {
  //     yield <LiveUserView>[];
  //     continue;
  //   }

  //   final ids = live.map((u) => u.userId).toSet();

    List<LiveUserView> buildFrame(int nowMs) {
    final views = motions.entries.map((entry) {
      final state = entry.value;
      final pos = state.positionAt(nowMs);
      final p = profiles[entry.key];

    // ✅ подгружаем только тех, кого ещё нет в кеше
    // await fetchMissingProfiles(ids);

    // final liveSorted = [...live]..sort((a, b) => a.userId.compareTo(b.userId));

    // // ✅ собираем view без сетевых запросов
    // yield liveSorted.map((u) {
    //   final p = profiles[u.userId];
      return LiveUserView(
        userId: entry.key,
        lat: pos.latitude,
        lng: pos.longitude,
        heading: state.heading,
        accuracyM: state.accuracyM,
        updatedAtMs: state.lastServerTs,
        name: (p?['name'] as String?) ?? 'User',
        img: (p?['img'] as String?) ?? (p?['photoUrl'] as String?),
      );
    }).toList()
          ..sort((a, b) => a.userId.compareTo(b.userId));

    return views;
  }
  void emitFrame() {
    if (disposed) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    controller.add(buildFrame(nowMs));
  }

  final ticker = Timer.periodic(const Duration(milliseconds: frameIntervalMs), (_) => emitFrame());

  Future<void> handleLive() async {
    await for (final live in liveRepo.watchLiveUsers(groupId)) {
      if (disposed) break;

      if (live.isEmpty) {
        motions.clear();
        emitFrame();
        continue;
      }

      final ids = live.map((u) => u.userId).toSet();
      await fetchMissingProfiles(ids);

      final nowMs = DateTime.now().millisecondsSinceEpoch;

      motions.removeWhere((uid, _) => !ids.contains(uid));

      for (final u in live) {
        final candidatePos = LatLng(u.lat, u.lng);
        if (u.accuracyM != null && u.accuracyM! > maxAccuracyM) {
          continue;
        }

        final state = motions[u.userId];
        if (state != null) {
          final jump = distanceM(state.to, candidatePos);
          if (jump > maxJumpM) continue;
          state.updateTarget(
            target: candidatePos,
            serverTs: u.updatedAtMs ?? nowMs,
            nowMs: nowMs,
            minAnimMs: minAnimMs,
            maxAnimMs: maxAnimMs,
            headingRaw: u.heading,
            accuracyRaw: u.accuracyM,
          );
        } else {
          motions[u.userId] = _LiveUserMotionState.initial(
            raw: u,
            nowMs: nowMs,
          );
        }
      }

      emitFrame();
    }
  }

  unawaited(handleLive());

  ref.onDispose(() {
    disposed = true;
    ticker.cancel();
    controller.close();
    motions.clear();
  });

  yield* controller.stream; 
});


final groupOwnerIdProvider =
    StreamProvider.autoDispose.family<String?, String>((ref, groupId) {
  return FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .snapshots()
      .map((doc) {
        final data = doc.data();
        return data?['owner_id'] as String?;
      });
});

class _LiveUserMotionState {
  _LiveUserMotionState({
    required this.from,
    required this.to,
    required this.animStartMs,
    required this.animEndMs,
    required this.lastServerTs,
    required this.heading,
    required this.accuracyM,
  });

  LatLng from;
  LatLng to;
  int animStartMs;
  int animEndMs;
  int lastServerTs;
  double? heading;
  double? accuracyM;

  factory _LiveUserMotionState.initial({
    required LiveUserRtdb raw,
    required int nowMs,
  }) {
    final ts = raw.updatedAtMs ?? nowMs;
    return _LiveUserMotionState(
      from: LatLng(raw.lat, raw.lng),
      to: LatLng(raw.lat, raw.lng),
      animStartMs: nowMs,
      animEndMs: nowMs,
      lastServerTs: ts,
      heading: raw.heading,
      accuracyM: raw.accuracyM,
    );
  }

  void updateTarget({
    required LatLng target,
    required int serverTs,
    required int nowMs,
    required int minAnimMs,
    required int maxAnimMs,
    double? headingRaw,
    double? accuracyRaw,
  }) {
    final current = positionAt(nowMs);
    from = current;
    to = target;
    animStartMs = nowMs;

    final diff = (serverTs - lastServerTs).abs();
    final animDuration = diff.clamp(minAnimMs, maxAnimMs).toInt();
    animEndMs = nowMs + animDuration;
    lastServerTs = serverTs;

    if (headingRaw != null) {
      heading = headingRaw;
    }
    accuracyM = accuracyRaw ?? accuracyM;
  }

  LatLng positionAt(int nowMs) {
    if (animEndMs <= animStartMs) return to;
    final total = animEndMs - animStartMs;
    final t = ((nowMs - animStartMs) / total).clamp(0.0, 1.0);
    final lat = from.latitude + (to.latitude - from.latitude) * t;
    final lng = from.longitude + (to.longitude - from.longitude) * t;
    return LatLng(lat, lng);
  }
}