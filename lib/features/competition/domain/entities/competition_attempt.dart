import 'package:cloud_firestore/cloud_firestore.dart';

class CompetitionAttempt {
  final String id;
  final String uid;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int? durationSeconds;
  final double? distanceMeters;
  final int? startIndex;
  final int? endIndex;

  const CompetitionAttempt({
    required this.id,
    required this.uid,
    this.startedAt,
    this.finishedAt,
    this.durationSeconds,
    this.distanceMeters,
    this.startIndex,
    this.endIndex,
  });

  factory CompetitionAttempt.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return CompetitionAttempt(
      id: doc.id,
      uid: (data['uid'] as String?) ?? '',

      startedAt: (data['startedAt'] as Timestamp?)?.toDate()
          ?? (data['started_at'] as Timestamp?)?.toDate(),

      finishedAt: (data['finishedAt'] as Timestamp?)?.toDate()
          ?? (data['finished_at'] as Timestamp?)?.toDate(),

      durationSeconds: (data['durationSeconds'] as num?)?.toInt()
          ?? (data['duration_seconds'] as num?)?.toInt(),

      startIndex: (data['startIndex'] as num?)?.toInt(),
      endIndex: (data['endIndex'] as num?)?.toInt(),

      // ✅ читаем только одно поле, которое реально пишем
      distanceMeters: (data['distanceMeters'] as num?)?.toDouble()
          // на всякий случай поддержим старое название, если где-то встречается
          ?? (data['routeDistanceMeters'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      if (startedAt != null) 'startedAt': Timestamp.fromDate(startedAt!),
      if (finishedAt != null) 'finishedAt': Timestamp.fromDate(finishedAt!),
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      if (distanceMeters != null) 'distanceMeters': distanceMeters,
      if (startIndex != null) 'startIndex': startIndex,
      if (endIndex != null) 'endIndex': endIndex,
    };
  }
}
