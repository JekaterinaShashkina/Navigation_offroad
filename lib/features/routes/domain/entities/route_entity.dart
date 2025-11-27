class RouteEntity {
  final String id;
  final String ownerId;
  final String name;
  final List<RoutePoint> points; // упорядоченные точки
  final bool isPublic;
  final DateTime createdAt;

  const RouteEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.points,
    required this.isPublic,
    required this.createdAt,
  });
}

class RoutePoint {
  final double lat;
  final double lng;
  const RoutePoint(this.lat, this.lng);
}
