import "../../domain/entities/route_entity.dart";



class RouteModel {
final String? id;
final String ownerId;
final String name;
final List<Map<String, double>> points;
final bool isPublic;
final DateTime createdAt;


const RouteModel({
this.id,
required this.ownerId,
required this.name,
required this.points,
required this.isPublic,
required this.createdAt,
});


factory RouteModel.fromEntity(RouteEntity e) => RouteModel(
id: e.id,
ownerId: e.ownerId,
name: e.name,
points: e.points.map((p) => {"lat": p.lat, "lng": p.lng}).toList(),
isPublic: e.isPublic,
createdAt: e.createdAt,
);


RouteEntity toEntity(String id) => RouteEntity(
id: id,
ownerId: ownerId,
name: name,
points: points.map((m) => RoutePoint(m['lat']!, m['lng']!)).toList(),
isPublic: isPublic,
createdAt: createdAt,
);


Map<String, dynamic> toMap() => {
'ownerId': ownerId,
'name': name,
'points': points,
'isPublic': isPublic,
'createdAt': createdAt.toUtc(),
};


factory RouteModel.fromMap(Map<String, dynamic> map, String id) => RouteModel(
id: id,
ownerId: map['ownerId'] as String,
name: map['name'] as String,
points: (map['points'] as List)
.cast<Map>()
.map((m) => {"lat": (m['lat'] as num).toDouble(), "lng": (m['lng'] as num).toDouble()})
.toList(),
isPublic: map['isPublic'] as bool,
createdAt: DateTime.parse(map['createdAt'].toDate().toString()),
);
}