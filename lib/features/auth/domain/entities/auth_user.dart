class AuthUser {
  final String id;
  final String? email;
  final String? phone;
  final String? name;
  final String? photoUrl;

  const AuthUser({
    required this.id,
    this.email,
    this.phone,
    this.name,
    this.photoUrl,
  });
}
