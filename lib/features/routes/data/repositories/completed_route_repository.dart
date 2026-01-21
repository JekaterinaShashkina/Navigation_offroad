import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:offroad_nav/features/routes/domain/entities/completed_route_entity.dart';

class CompletedRouteRepository {
  CompletedRouteRepository(this._db);
  final FirebaseFirestore _db;

  Future<DocumentReference<Map<String, dynamic>>> saveCompletedRoute({
    required String userId,
    required DateTime startedAt,
    required DateTime finishedAt,
    required double distanceMeters,
    required int startIndex,
    required int endIndex,
    required String profileName,

    // ✅ optional
    List<LatLng>? traversedPolyline,

    String mode = 'solo',
    String? groupId,
    String? routeId,
    String? routeName,
    String source = 'tracking',
    String? competitionId,
  }) async {
    final durationSec = finishedAt.difference(startedAt).inSeconds;
    final avgSpeedMps = durationSec > 0 ? distanceMeters / durationSec : null;

    return _db.collection('completed_routes').add({
      'userId': userId,

      'mode': mode,
      if (groupId != null) 'groupId': groupId,

      if (routeId != null) 'routeId': routeId,
      if (routeName != null) 'routeName': routeName,

      if (competitionId != null) 'competitionId': competitionId,

      'profile': profileName,

      'startedAt': Timestamp.fromDate(startedAt),
      'finishedAt': Timestamp.fromDate(finishedAt),
      'durationSec': durationSec,

      'distanceMeters': distanceMeters,
      'avgSpeedMps': avgSpeedMps,

      'startIndex': startIndex,
      'endIndex': endIndex,

      if (traversedPolyline != null && traversedPolyline.isNotEmpty)
        'traversedPolyline': traversedPolyline
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),

      'source': source,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<CompletedRouteEntity>> watchMyCompletedRoutes(String uid) {
    return _db
        .collection('completed_routes')
        .where('userId', isEqualTo: uid)
        .orderBy('finishedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(CompletedRouteEntity.fromDoc).toList());
  }
}
