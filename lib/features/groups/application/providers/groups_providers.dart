  // import 'package:cloud_firestore/cloud_firestore.dart';
  // import 'package:flutter_riverpod/flutter_riverpod.dart';

  // import 'package:offroad_nav/features/groups/data/repositories/groups_repository.dart';
  // import 'package:offroad_nav/features/groups/domain/entities/group.dart';

  // // репозиторий
  // final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  //   final db = FirebaseFirestore.instance;
  //   return GroupsRepository(db: db);
  // });

  // // сюда нужно подставить твой реальный провайдер uid'а
  // final currentUserIdProvider = Provider<String?>((ref) {
  //   // TODO: вернуть uid из auth
  //   return null;
  // });

  // // мои группы
  // final myGroupsProvider =
  //     StreamProvider.autoDispose<List<Group>>((ref) {
  //   final uid = ref.watch(currentUserIdProvider);
  //   if (uid == null) {
  //     return const Stream<List<Group>>.empty();
  //   }
  //   final repo = ref.watch(groupsRepositoryProvider);
  //   return repo.watchMyGroups(uid);
  // });

  // // конкретная группа
  // final groupProvider =
  //     StreamProvider.autoDispose.family<Group?, String>((ref, groupId) {
  //   final repo = ref.watch(groupsRepositoryProvider);
  //   return repo.watchGroup(groupId);
  // });


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offroad_nav/features/groups/data/repositories/groups_repository.dart';
import 'package:offroad_nav/features/groups/domain/entities/group.dart';

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return GroupsRepository(FirebaseFirestore.instance);
});

final myGroupsProvider = StreamProvider<List<Group>>((ref) {
  final user = FirebaseAuth.instance.currentUser;

  // если не залогинен – пустой список, но НЕ вечный loading
  if (user == null) {
    return Stream<List<Group>>.value(<Group>[]);
  }

  final repo = ref.watch(groupsRepositoryProvider);
  return repo.watchUserGroups(user.uid);
});
