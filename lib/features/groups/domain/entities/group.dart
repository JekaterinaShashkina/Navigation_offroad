import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final String? avatarUrl;
  final String? competitionId;
  final String? routeId;
   /// Сколько людей в группе (для превью на карточке)
  final int membersCount;
  final int? maxMembers;
  final bool isOpen;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Group(  {
    required this.id,
    required this.name,
    required this.ownerId,
    this.avatarUrl,
    this.description,
    this.competitionId,
    this.routeId,
    this.membersCount=0,
    this.maxMembers,
    required this.isOpen,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Group.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Group(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      ownerId: data['owner_id'] as String,
      avatarUrl: (data['avatar_url'] ?? '') as String,
      competitionId: data['competition_id'] as String?,
      routeId: data['route_id'] as String?,
      membersCount: (data['members_count'] as num?)?.toInt() ?? 0,
      maxMembers: (data['max_members'] as num?)?.toInt(),
      isOpen: data['is_open'] as bool? ?? true,
      status: data['status'] as String? ?? 'active',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'owner_id': ownerId,
      'avatar_url': avatarUrl,
      'competition_id': competitionId,
      'route_id': routeId,
      'members_count': membersCount,
      'max_members': maxMembers,
      'is_open': isOpen,
      'status': status,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    String? avatarUrl,
    String? competitionId,
    String? routeId,
    int? membersCount,
    int? maxMembers,
    bool? isOpen,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      competitionId: competitionId ?? this.competitionId,
      routeId: routeId ?? this.routeId,
      membersCount: membersCount ?? this.membersCount,
      maxMembers: maxMembers ?? this.maxMembers,
      isOpen: isOpen ?? this.isOpen,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
