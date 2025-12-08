// lib/features/competitions/domain/competition.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Competition {
  final String id;
  final String title;
  final String? description;
  final String rule;
  final DateTime? startTime;
  final bool useLimit;
  final int? limitMinutes; // храним сырые минуты, Duration можно посчитать геттером
  final String vehicle;    // 'ATV' | 'Jeep' | 'Truck'
  final String ownerId;
  final String status;     // 'draft' | 'active' | 'completed' | etc.

  const Competition({
    required this.id,
    required this.title,
    this.description,
    required this.rule,
    this.startTime,
    required this.useLimit,
    this.limitMinutes,
    required this.vehicle,
    required this.ownerId,
    required this.status,
  });

  Duration? get limit =>
      limitMinutes != null ? Duration(minutes: limitMinutes!) : null;

  bool get isCompleted => status == 'completed';

  factory Competition.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return Competition(
      id: doc.id,
      title: (data['title'] as String?)?.trim() ?? '',
      description: (data['description'] as String?)?.trim(),
      rule: (data['rule'] as String?) ?? 'Fastest time',
      startTime: (data['start_time'] as Timestamp?)?.toDate(),
      useLimit: (data['use_limit'] as bool?) ?? false,
      limitMinutes: data['limit_minutes'] as int?,
      vehicle: (data['vehicle'] as String?) ?? 'ATV',
      ownerId: (data['owner_id'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'draft',
    );
  }
}
