// lib/features/groups/data/models/member.dart

class Member {
  final String id;
  final String name;
  final String? avatarUrl;

  const Member({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id'       : id,
      'name'     : name,
      'avatarUrl': avatarUrl,
    };
  }
}
