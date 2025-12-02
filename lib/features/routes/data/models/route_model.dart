import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/route_entity.dart';

class RouteModel {
  final String? id;
  final String ownerId;
  final String name;
  final List<RoutePoint> points;
  final bool isPublic;
  final DateTime createdAt;
  final double? lengthKm;

  const RouteModel({
    this.id,
    required this.ownerId,
    required this.name,
    required this.points,
    required this.isPublic,
    required this.createdAt,
    this.lengthKm,
  });

  /// ----- FROM ENTITY -----
  factory RouteModel.fromEntity(RouteEntity e) => RouteModel(
        id: e.id.isEmpty ? null : e.id,
        ownerId: e.ownerId,
        name: e.name,
        points: e.points,
        isPublic: e.isPublic,
        createdAt: e.createdAt,
        lengthKm: e.lengthKm,
      );

  /// ----- TO ENTITY -----
  RouteEntity toEntity(String id) => RouteEntity(
        id: id,
        ownerId: ownerId,
        name: name,
        points: points,
        isPublic: isPublic,
        createdAt: createdAt,
        lengthKm: lengthKm,
      );

  /// ----- TO MAP (в Firestore) -----
  Map<String, dynamic> toMap() => {
        'userId': ownerId,
        'name': name,
        'points': points
            .map((p) => {
                  'lat': p.lat,
                  'lng': p.lng,
                })
            .toList(),
        // основной флаг
        'isPublic': isPublic,
        // можно дублировать для совместимости со старыми доками
        'isPrivate': !isPublic,
        'createdAt': Timestamp.fromDate(createdAt.toUtc()),
        if (lengthKm != null) 'lengthKm': lengthKm,
      };

  /// ----- FROM MAP + id -----
  factory RouteModel.fromMap(Map<String, dynamic> map, String id) {
    final ts = map['createdAt'];
    final createdAt = ts is Timestamp
        ? ts.toDate()
        : DateTime.tryParse(ts?.toString() ?? '') ?? DateTime.now();

    final ptsRaw = (map['points'] as List?) ?? const [];
    final pts = ptsRaw.map<RoutePoint>((m) {
      final mm = m as Map;
      return RoutePoint(
        (mm['lat'] as num).toDouble(),
        (mm['lng'] as num).toDouble(),
      );
    }).toList();

    // читаем isPublic, если его нет — инвертируем isPrivate
    final isPublic = (map['isPublic'] as bool?) ??
        (map['isPrivate'] is bool ? !(map['isPrivate'] as bool) : false);

    return RouteModel(
      id: id,
      ownerId: (map['userId'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      points: pts,
      isPublic: isPublic,
      createdAt: createdAt,
      lengthKm: (map['lengthKm'] is num)
          ? (map['lengthKm'] as num).toDouble()
          : null,
    );
  }

  /// ----- FROM FIRESTORE DOC -----
  factory RouteModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return RouteModel.fromMap(m, doc.id);
  }
}
