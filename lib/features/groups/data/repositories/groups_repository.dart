import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/group.dart';
import '../../domain/entities/member.dart';

part 'groups_repository_groups.dart';
part 'groups_repository_members.dart';

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
    this.maxMembers=20,
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
}


