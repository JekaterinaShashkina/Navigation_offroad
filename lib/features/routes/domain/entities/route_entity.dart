class RouteEntity {
  final String id;
  final String ownerId;
  final String name;
  final List<RoutePoint> points; // упорядоченные точки
  final bool isPublic;
  final DateTime createdAt;
  final double? lengthKm; // может не быть в старых доках

  const RouteEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.points,
    required this.isPublic,
    required this.createdAt,
    this.lengthKm,
  });

  RouteEntity copyWith({
    String? id,
    String? ownerId,
    String? name,
    List<RoutePoint>? points,
    bool? isPublic,
    DateTime? createdAt,
    double? lengthKm,
  }) {
    return RouteEntity(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      points: points ?? this.points,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      lengthKm: lengthKm ?? this.lengthKm,
    );
  }
}

class RoutePoint {
  final double lat;
  final double lng;

  const RoutePoint(this.lat, this.lng);
}
