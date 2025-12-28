import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/features/groups/data/repositories/groups_repository.dart';
import 'package:offroad_nav/features/groups/data/repositories/groups_live_repository.dart';
import 'package:offroad_nav/features/groups/domain/entities/group.dart';
import 'package:offroad_nav/features/groups/domain/entities/live_user.dart';
import 'package:offroad_nav/features/groups/presentation/models/live_user_view.dart';
// import 'package:offroad_nav/features/groups/presentation/models/live_user_view.dart';
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
  final db = FirebaseFirestore.instance;

  await for (final live in liveRepo.watchLiveUsers(groupId)) {
    if (live.isEmpty) {
      yield <LiveUserView>[];
      continue;
    }

    final ids = live.map((u) => u.userId).toSet().toList();

    // whereIn лимит 10 -> chunks
    const chunkSize = 10;
    final profiles = <String, Map<String, dynamic>>{};

    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(i, (i + chunkSize > ids.length) ? ids.length : i + chunkSize);

      final snap = await db
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snap.docs) {
        profiles[doc.id] = doc.data();
      }
    }

    yield live.map((u) {
      final p = profiles[u.userId];
      return LiveUserView(
        userId: u.userId,
        lat: u.lat,
        lng: u.lng,
        heading: u.heading,
        name: (p?['name'] as String?) ?? 'User',
        img: (p?['img'] as String?) ?? (p?['photoUrl'] as String?),
      );
    }).toList();
  }
});

final groupOwnerIdProvider =
    StreamProvider.autoDispose.family<String?, String>((ref, groupId) {
  return FirebaseFirestore.instance
      .collection('groups') // ⚠️ если коллекция у тебя называется иначе — поменяй
      .doc(groupId)
      .snapshots()
      .map((doc) {
        final data = doc.data();
        return data?['owner_id'] as String?;
      });
});