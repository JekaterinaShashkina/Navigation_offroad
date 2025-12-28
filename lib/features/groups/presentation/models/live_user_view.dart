class LiveUserView {
  final String userId;
  final double lat;
  final double lng;
  final double? heading;

  final String name;
  final String? img; // из users.img (assets/...svg или png или url)

  LiveUserView({
    required this.userId,
    required this.lat,
    required this.lng,
    required this.name,
    this.heading,
    this.img,
  });
}