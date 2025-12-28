part of 'groups_repository.dart';

extension GroupsRepositoryMembers on GroupsRepository {
  
    //* ------------Добавление пользователей 
    //* Добавить участника (минимальная запись в members)
  Future<void> addMemberToGroup({
    required String groupId,
    required String userId,
    String role = 'member',
  }) async {
    final groupRef = _col.doc(groupId);
    final memberRef = groupRef.collection('members').doc(userId);

    await _db.runTransaction((tx) async {
      // ✅ ВСЕ ЧТЕНИЯ СНАЧАЛА
      final groupSnap = await tx.get(groupRef);
      if (!groupSnap.exists) {
        throw Exception('Group not found');
      }

      final memberSnap = await tx.get(memberRef);
      if (memberSnap.exists) return;
      // ✅ ПОТОМ ЗАПИСИ
      tx.set(memberRef, {
        'user_id': userId,
        'role': role,
        'created_at': FieldValue.serverTimestamp(),
      });

      tx.update(groupRef, {
        'member_ids': FieldValue.arrayUnion([userId]),
        'updated_at': FieldValue.serverTimestamp(),
      });

    });
  }

//* присоединиться к группе
  Future<void> joinGroup(String groupId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');

    // вступаем сами в себя
    await addMemberToGroup(
      groupId: groupId,
      userId: uid,
      role: 'member',
    );
  }
  
  //* Удалить участника
  Future<void> removeMemberFromGroup(String groupId, String userId) async {
      final groupRef = _col.doc(groupId);
      final memberRef = groupRef.collection('members').doc(userId);

      await _db.runTransaction((tx) async {
        final memberSnap = await tx.get(memberRef);
        if (!memberSnap.exists) return;

        tx.delete(memberRef);
        tx.update(groupRef, {
          'member_ids': FieldValue.arrayRemove([userId]),
          'updated_at': FieldValue.serverTimestamp(),
        });
      });
    }

 //* Стрим: список участников группы с именами/аватарками из коллекции users
  Stream<List<Member>> watchMembers(String groupId) {
      final membersRef = _col.doc(groupId).collection('members');
      final usersRef = _db.collection('users');

      return membersRef.snapshots().asyncMap((membersSnap) async {
        if (membersSnap.docs.isEmpty) return <Member>[];

        // Собираем роли из members (userId = doc.id)
        final rolesByUserId = <String, String>{
          for (final d in membersSnap.docs)
            d.id: (d.data()['role'] as String?) ?? 'member',
        };

        final userIds = rolesByUserId.keys.toList();

        // Firestore whereIn обычно ограничен 10 значениями -> чанки
        const chunkSize = 10;
        final profilesById = <String, Map<String, dynamic>>{};

        for (var i = 0; i < userIds.length; i += chunkSize) {
          final chunk = userIds.sublist(
            i,
            (i + chunkSize > userIds.length) ? userIds.length : i + chunkSize,
          );

          final snap = await usersRef
              .where(FieldPath.documentId, whereIn: chunk)
              .get();

          for (final u in snap.docs) {
            profilesById[u.id] = u.data() as Map<String, dynamic>;
          }
        }

        // Собираем итоговый список
        return userIds.map((uid) {
          final profile = profilesById[uid];

          return Member(
            userId: uid,
            role: rolesByUserId[uid] ?? 'member',
            name: (profile?['name'] as String?) ?? 'User',
            img: profile?['img'] as String?, // assets/images/...svg
          );
        }).toList();
      });
    }


  Stream<bool> watchIsMember(String groupId, String userId) {
  return _col
      .doc(groupId)
      .collection('members')
      .doc(userId)
      .snapshots()
      .map((d) => d.exists);
}

//* количество мемберов в группе
Future<int> getMembersCount(String groupId) async {
  final snap = await _col.doc(groupId).collection('members').get();
  return snap.size;
}


  Future<Set<String>> getMemberIds(String groupId) async {
      final snap = await _col.doc(groupId).collection('members').get();
      return snap.docs.map((d) => d.id as String).toSet();
    }

}