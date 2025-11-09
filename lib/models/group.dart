class Group {
  final String id;
  final String name;
  final String avatarUrl;
  final List<Member> members;
  final bool isAddNew;
  final String leaderId;
  final String? activeRouteId;

  Group({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.members,
    this.isAddNew = false,
    required this.leaderId,
    this.activeRouteId,
  });

  int get memberCount => members.length;
  
  bool isLeader(String userId) => leaderId == userId;
}

class Member {
  final String id;
  final String name;
  final String? avatarUrl;

  Member({
    required this.id,
    required this.name,
    this.avatarUrl,
  });
}

