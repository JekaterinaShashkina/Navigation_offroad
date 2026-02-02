import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteEntity {
  final String id;
  final String ownerId;
  final String name;
  final List<RoutePoint> points;
  final bool isPublic;
  final DateTime createdAt;
  final double? lengthKm;

  const RouteEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.points,
    required this.isPublic,
    required this.createdAt,
    this.lengthKm,
  });

  /// ✅ UI-friendly points
  List<LatLng> get latLngPoints =>
      points.map((p) => LatLng(p.lat, p.lng)).toList();

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
    factory RoutePoint.fromAny(dynamic p) {
    // вариант 1: {'lat': ..., 'lng': ...}
    if (p is Map) {
      final lat = (p['lat'] as num).toDouble();
      final lng = (p['lng'] as num).toDouble();
      return RoutePoint(lat, lng);
    }

    // вариант 2: GeoPoint (если вдруг так сохранялось)
    if (p is GeoPoint) {
      return RoutePoint(p.latitude, p.longitude);
    }

    throw Exception('Unsupported point type: ${p.runtimeType}');
  }

  Map<String, dynamic> toMap() => {'lat': lat, 'lng': lng};
}
