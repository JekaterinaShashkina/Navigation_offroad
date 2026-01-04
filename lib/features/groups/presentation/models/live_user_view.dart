class LiveUserView {
  final String userId;
  final double lat;
  final double lng;
  final double? heading;
  final double? accuracyM;
  final int? updatedAtMs;

  final String name;
  final String? img; // из users.img (assets/...svg или png или url)

  LiveUserView({
    required this.userId,
    required this.lat,
    required this.lng,
    required this.name,
    this.heading,
    this.img,
    this.accuracyM,
    this.updatedAtMs,
  });
}