import 'package:cloud_firestore/cloud_firestore.dart';

class CompletedRouteEntity {
  final String id;

  final String userId;
  final String mode;
  final String? groupId;
  final String? competitionId;

  final String? routeId;
  final String routeName;

  final String profile;

  final DateTime startedAt;
  final DateTime finishedAt;

  final int durationSec;
  final double distanceMeters;
  final double? avgSpeedMps;

  final int startIndex;
  final int endIndex;

  final List<Map<String, double>> traversedPolyline; // [{lat, lng}]
  final String source;
  final DateTime? createdAt;

  CompletedRouteEntity({
    required this.id,
    required this.userId,
    required this.mode,
    this.groupId,
    this.competitionId,
    this.routeId,
    required this.routeName,
    required this.profile,
    required this.startedAt,
    required this.finishedAt,
    required this.durationSec,
    required this.distanceMeters,
    this.avgSpeedMps,
    required this.startIndex,
    required this.endIndex,
    required this.traversedPolyline,
    required this.source,
    this.createdAt,
  });

  factory CompletedRouteEntity.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};

    final poly = <Map<String, double>>[];
    final raw = d['traversedPolyline'];

    if (raw is List) {
      poly.addAll(
        raw.whereType<Map>().map((m) => {
          'lat': (m['lat'] as num).toDouble(),
          'lng': (m['lng'] as num).toDouble(),
        }),
      );
    }

    return CompletedRouteEntity(
      id: doc.id,
      userId: (d['userId'] ?? '') as String,
      mode: (d['mode'] ?? 'solo') as String,
      groupId: d['groupId'] as String?,
      competitionId: d['competitionId'] as String?,
      routeId: d['routeId'] as String?,
      routeName: (d['routeName'] ?? 'Unnamed route') as String,
      profile: (d['profile'] ?? '') as String,
      startedAt: (d['startedAt'] as Timestamp).toDate(),
      finishedAt: (d['finishedAt'] as Timestamp).toDate(),
      durationSec: (d['durationSec'] ?? 0) as int,
      distanceMeters: (d['distanceMeters'] ?? 0).toDouble(),
      avgSpeedMps: (d['avgSpeedMps'] is num) ? (d['avgSpeedMps'] as num).toDouble() : null,
      startIndex: (d['startIndex'] ?? 0) as int,
      endIndex: (d['endIndex'] ?? 0) as int,
      traversedPolyline: poly,
      source: (d['source'] ?? 'tracking') as String,
      createdAt: (d['createdAt'] is Timestamp)
          ? (d['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}
