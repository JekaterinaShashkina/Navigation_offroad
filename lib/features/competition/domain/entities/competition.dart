// lib/features/competitions/domain/competition.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum CompetitionStatus { upcoming, active, ended }

class Competition {
  final String id;
  final String name;
  final String description;
  final String rulesText;
  final String routeId;
  final String? routeName;
  final DateTime startAt;
    final DateTime endAt;
  final String createdBy;
  // final bool useLimit;
  // final int? limitMinutes; // храним сырые минуты, Duration можно посчитать геттером
  // final String vehicle;    // 'ATV' | 'Jeep' | 'Truck'
  // final String ownerId;
  // final String status;     // 'draft' | 'active' | 'completed' | etc.

  const Competition(  {
    required this.id,
    required this.name,
    required this.description,
    required this.rulesText,
    required this.routeId,
    this.routeName,
    required this.startAt,
    required this.endAt,
    required this.createdBy,
    // required this.useLimit,
    // this.limitMinutes,
    // required this.vehicle,
    // required this.ownerId,
    // required this.status,
  });

  CompetitionStatus get status {
    final now = DateTime.now();
    if (now.isBefore(startAt)) return CompetitionStatus.upcoming;
    if (now.isAfter(endAt)) return CompetitionStatus.ended;
    return CompetitionStatus.active;
  }

  factory Competition.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Competition(
      id: doc.id,
      name: (data['name'] as String? ?? data['title'] as String? ?? '').trim(),
      description: (data['description'] as String? ?? '').trim(),
      rulesText: (data['rulesText'] as String? ?? data['rule'] as String? ?? '').trim(),
      routeId: (data['routeId'] as String? ?? data['route_id'] as String? ?? '').trim(),
      routeName: (data['routeName'] as String?)?.trim(),
      startAt: (data['startAt'] as Timestamp?)?.toDate() ??
          (data['start_time'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      endAt: (data['endAt'] as Timestamp?)?.toDate() ??
          (data['end_time'] as Timestamp?)?.toDate() ??
          (data['start_time'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      createdBy: data['createdBy'] as String? ?? data['owner_id'] as String? ?? '',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'rulesText': rulesText,
      'routeId': routeId,
      'routeName': routeName,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'createdBy': createdBy,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
