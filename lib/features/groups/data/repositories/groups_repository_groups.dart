part of 'groups_repository.dart';

extension GroupsRepositoryGroups on GroupsRepository{
    
    //* ----- чтение -----
    //* Одна группа
  Stream<Group?> watchGroup(String groupId) {
      return _col.doc(groupId).snapshots().map((doc) {
        if (!doc.exists) return null;
        return Group.fromDoc(doc);
      });
    }

      //* все open группы
  Stream<List<Group>> watchOpenGroups() {
    return _col
        .where('is_open', isEqualTo: true)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Group.fromDoc).toList());
  }
  
    //* Закрытые группы, где текущий пользователь лидер
  Stream<List<Group>> watchMyGroups(String userId) {
    return _col
        .where('is_open', isEqualTo: false)
        .where('owner_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Group.fromDoc).toList());

    }
  
  //* Закрытые группы где я пользователь
  Stream<List<Group>> watchPrivateGroupsWhereIamMember(String uid) {
  return _col
      .where('is_open', isEqualTo: false)
      .where('member_ids', arrayContains: uid)
      .snapshots()
      .map((s) => s.docs.map(Group.fromDoc).toList());
  }
  
  
  //* ---------Создание группы -------------
    //* Создание группы, возвращает id документа.
  Future<String> createGroup(GroupCreateParams p) async {
      final now = FieldValue.serverTimestamp();

      final docRef = await _col.add({
        'name': p.name,
        'owner_id': p.ownerId,
        'description': p.description,
        'avatar_url': p.avatarUrl,
        'competition_id': p.competitionId,
        'route_id': p.activeRouteId,
        'max_members': p.maxMembers,
        'is_open': p.isOpen,
        'status': 'active',
        'created_at': now,
        'updated_at': now,
      });
      //* Здесь же можно создать подколлекцию members и добавить лидера
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


  //* обновить данные группы 
  Future<void> updateGroup(
    String groupId, {
    String? name,
    String? description,
    String? avatarUrl,
    int? maxMembers,
    bool? isOpen,
  }) async {
    final data = <String, dynamic>{};

    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (maxMembers != null) data['max_members'] = maxMembers;
    if (isOpen != null) data['is_open'] = isOpen;

    data['updated_at'] = FieldValue.serverTimestamp();

    await _col.doc(groupId).update(data);
  }

  //* Установить активный маршрут для группы.
  Future<void> setActiveRoute(String groupId, String? routeId) async {
      await _col.doc(groupId).update({
        'route_id': routeId,
        'updated_at': FieldValue.serverTimestamp()
      });
    }

  //* Удалить группу (документ + по-хорошему members — потом).
  Future<void> deleteGroup(String groupId) async {
    final groupRef = _col.doc(groupId);

    // 1) удалить всех members батчами
    while (true) {
      final membersSnap = await groupRef
          .collection('members')
          .limit(200) // можно 200-400, чтобы не упереться в лимит
          .get();

      if (membersSnap.docs.isEmpty) break;

      final batch = _db.batch();
      for (final d in membersSnap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
    // 2) удалить документ группы
    await groupRef.delete();
    }

}