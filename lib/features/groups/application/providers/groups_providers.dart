import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/features/groups/data/repositories/groups_repository.dart';
import 'package:offroad_nav/features/groups/domain/entities/group.dart';

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
