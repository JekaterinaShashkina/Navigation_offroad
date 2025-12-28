import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class LiveUser {
  final String userId;
  final double lat;
  final double lng;
  final double? heading;
  final double? speed;
  final DateTime? updatedAt;

  const LiveUser({
    required this.userId,
    required this.lat,
    required this.lng,
    this.heading,
    this.speed,
    this.updatedAt,
  });

    factory LiveUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return LiveUser(
      userId: (data['user_id'] as String?) ?? doc.id,
      lat: (data['lat'] as num?)?.toDouble() ?? 0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0,
      heading: (data['heading'] as num?)?.toDouble(),
      speed: (data['speed'] as num?)?.toDouble(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }
  
    LatLng get position => LatLng(lat, lng);

}
