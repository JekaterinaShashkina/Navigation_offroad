class Member {
  final String userId;   // uid пользователя (doc.id в members)
  final String role;     // owner / member
  final String name;     // из users коллекции
  final String? img;     // из users коллекции (assets/...svg или url)

  const Member({
    required this.userId,
    required this.role,
    required this.name,
    this.img,
  });

  Member copyWith({
    String? userId,
    String? role,
    String? name,
    String? img,
  }) {
    return Member(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      name: name ?? this.name,
      img: img ?? this.img,
    );
  }
}