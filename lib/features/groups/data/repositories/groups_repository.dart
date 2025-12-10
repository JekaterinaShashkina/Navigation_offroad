import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:offroad_nav/features/groups/domain/entities/group.dart';



class GroupCreateParams {
  final String ownerId;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String? competitionId;
  final String? activeRouteId;
  final int? maxMembers;
  final bool isOpen;

  const GroupCreateParams( {
    this.description, 
    this.competitionId, 
    this.maxMembers, 
    this.isOpen = true,
    required this.ownerId,
    required this.name,
    this.avatarUrl,
    this.activeRouteId,
  });
}

class GroupsRepository {
    final FirebaseFirestore _db;
    final CollectionReference<Map<String, dynamic>> _col;

  GroupsRepository(FirebaseFirestore db)
      : _db = db,
        _col = db.collection('groups');

  // ----- чтение -----

  /// Все группы, где текущий пользователь лидер
  Stream<List<Group>> watchMyGroups(String userId) {
    return _col
        .where('owner_id', isEqualTo: userId)
       .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(Group.fromDoc).toList();

                // Если в Group есть поле createdAt (DateTime?):
        list.sort((a, b) {
          final aTime = a.createdAt;
          final bTime = b.createdAt;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;  // null в конец
          if (bTime == null) return -1;
          return bTime.compareTo(aTime); // по убыванию (новые сверху)
        });

        return list;
      });

  }

  /// Одна группа
  Stream<Group?> watchGroup(String groupId) {
    return _col.doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Group.fromDoc(doc);
    });
  }

  /// Создание группы, возвращает id документа.
  Future<String> createGroup(GroupCreateParams p) async {
    final now = FieldValue.serverTimestamp();

    final docRef = await _col.add({
      'name': p.name,
      'owner_id': p.ownerId,
      'description': p.description,
      'avatar_url': p.avatarUrl,
      'competition_id': p.competitionId,
      'route_id': p.activeRouteId,
      'members_count': 1, // владелец как первый участник
      'max_members': p.maxMembers,
      'is_open': p.isOpen,
      'status': 'active',
      'created_at': now,
      'updated_at': now,
    });

    // Здесь же можно создать подколлекцию members и добавить лидера
   await _col
        .doc(docRef.id)
        .collection('members')
        .doc(p.ownerId)
        .set({
      'user_id': p.ownerId,
      'role': 'owner',
      'created_at': now,
    });

    return docRef.id;
  }



  /// Добавить участника в группу (подколлекция members + счётчик).
Future<void> addMemberToGroup({
  required String groupId,
  required String userId,
  String? name,
  String? avatarUrl,
}) async {
  final groupRef = _col.doc(groupId);
  final memberRef = groupRef.collection('members').doc(userId);

    await _db.runTransaction((tx) async {
      final memberSnap = await tx.get(memberRef);
      if (!memberSnap.exists) {
        tx.set(memberRef, {
          'user_id': userId,
          'name': name,
          'avatar_url': avatarUrl,
          'created_at': FieldValue.serverTimestamp(),
        });

        final groupSnap = await tx.get(groupRef);
        final data = groupSnap.data() ?? {};
        final currentCount = (data['members_count'] as num?)?.toInt() ?? 0;
        tx.update(groupRef, {
          'members_count': currentCount + 1,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
  });
}

/// Удалить участника (и уменьшить счётчик).
  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    final groupRef = _col.doc(groupId);
    final memberRef = groupRef.collection('members').doc(userId);
    
    await _db.runTransaction((tx) async {
      final memberSnap = await tx.get(memberRef);
      if (!memberSnap.exists) return;

      tx.delete(memberRef);

      final groupSnap = await tx.get(groupRef);
      final data = groupSnap.data() ?? {};
      final currentCount = (data['members_count'] as num?)?.toInt() ?? 0;
      tx.update(groupRef, {
        'members_count': currentCount > 0 ? currentCount - 1 : 0,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

 /// Установить активный маршрут для группы.
    Future<void> setActiveRoute(String groupId, String? routeId) async {
    await _col.doc(groupId).update({
      'route_id': routeId,
      'updated_at': FieldValue.serverTimestamp()
    });
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


/// Удалить группу (документ + по-хорошему members — потом).
  Future<void> deleteGroup(String groupId) async {
    await _col.doc(groupId).delete();
        // TODO: по уму — пройтись по подколлекции members и тоже подчистить
    // (через батчи или Cloud Function).
  }
}
