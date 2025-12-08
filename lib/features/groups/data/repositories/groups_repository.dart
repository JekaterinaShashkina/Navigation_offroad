import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:offroad_nav/features/groups/domain/entities/group.dart';



class GroupCreateParams {
  final String ownerId;    // лидер группы
  final String name;
  final String? avatarUrl;
  final String? activeRouteId;

  const GroupCreateParams({
    required this.ownerId,
    required this.name,
    this.avatarUrl,
    this.activeRouteId,
  });
}

class GroupsRepository {
  GroupsRepository(FirebaseFirestore instance, {FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('groups');

  // ----- чтение -----

  /// Все группы, где текущий пользователь лидер
  Stream<List<Group>> watchMyGroups(String ownerId) {
    return _col
        .where('leader_id', isEqualTo: ownerId)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(Group.fromDoc).toList());
  }

  /// Одна группа
  Stream<Group?> watchGroup(String groupId) {
    return _col.doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Group.fromDoc(doc);
    });
  }

  // ----- мутации -----

  Future<String> createGroup(GroupCreateParams params) async {
    final now = Timestamp.now();
    final docRef = await _col.add({
      'name'          : params.name,
      'avatar_url'    : params.avatarUrl,
      'leader_id'     : params.ownerId,
      'active_route_id': params.activeRouteId,
      'is_add_new'    : false,
      'created_at'    : now,
      'updated_at'    : now,
    });

    // Здесь же можно создать подколлекцию members и добавить лидера
    await docRef.collection('members').doc(params.ownerId).set({
      'user_id'  : params.ownerId,
      'role'     : 'leader',
      'joined_at': now,
    });

    return docRef.id;
  }

  Future<void> updateGroupName(String groupId, String newName) async {
    await _col.doc(groupId).update({
      'name'      : newName,
      'updated_at': Timestamp.now(),
    });
  }

  Future<void> updateGroupAvatar(String groupId, String newAvatarUrl) async {
    await _col.doc(groupId).update({
      'avatar_url': newAvatarUrl,
      'updated_at': Timestamp.now(),
    });
  }

  Future<void> setActiveRoute(String groupId, String? routeId) async {
    await _col.doc(groupId).update({
      'active_route_id': routeId,
      'updated_at'     : Timestamp.now(),
    });
  }

  Future<void> deleteGroup(String groupId) async {
    await _col.doc(groupId).delete();
    // при желании можно ещё удалить подколлекцию members через Cloud Function
  }

  // ----- участники (через подколлекцию) -----

Future<void> addMemberToGroup({
  required String groupId,
  required String userId,
  String? userName,
  String? userAvatar,
}) async {
  final membersCol = _col.doc(groupId).collection('members');

  await membersCol.doc(userId).set({
    'user_id'  : userId,
    'role'     : 'member',
    'joined_at': Timestamp.now(),
    if (userName != null) 'name': userName,
    if (userAvatar != null) 'avatar_url': userAvatar,
  });
}
  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    final membersCol = _col.doc(groupId).collection('members');
    await membersCol.doc(userId).delete();
  }

  Future<Set<String>> getMemberIds(String groupId) async {
    final snap = await _col.doc(groupId).collection('members').get();
    return snap.docs.map((d) => d.id as String).toSet();
  }

    Stream<List<Group>> watchUserGroups(String userId) {
    // Вариант 1: если в документе группы есть массив memberIds
    return _db
        .collectionGroup('members')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .asyncMap((memberSnap) async {
          final groupIds =
              memberSnap.docs.map((d) => d.reference.parent.parent!.id).toSet();
          if (groupIds.isEmpty) return <Group>[];

          final futures = groupIds
              .map((id) => _col.doc(id).get())
              .toList();
          final groupDocs = await Future.wait(futures);

          return groupDocs
              .where((d) => d.exists)
              .map((d) => Group.fromDoc(d))
              .toList();
        });
}
}
