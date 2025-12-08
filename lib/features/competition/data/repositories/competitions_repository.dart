// lib/features/competitions/data/competitions_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition.dart';

class CompetitionCreateParams {
  final String title;
  final String description;
  final String rule;
  final DateTime? startTime;
  final bool useLimit;
  final Duration? limit;
  final String vehicle;

  const CompetitionCreateParams({
    required this.title,
    required this.description,
    required this.rule,
    required this.startTime,
    required this.useLimit,
    required this.limit,
    required this.vehicle,
  });
}

class UnauthenticatedCompetitionException implements Exception {
  @override
  String toString() => 'User is not authenticated';
}

class CompetitionsRepository {
  final FirebaseFirestore _db;

  CompetitionsRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('competitions');

  /// "Мои соревнования" — по owner_id
  Stream<List<Competition>> watchByOwner(String ownerId) {
    return _col
        .where('owner_id', isEqualTo: ownerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Competition.fromFirestore(doc))
              .toList(),
        );
  }

Future<void> createCompetition(CompetitionCreateParams params) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) {
      throw UnauthenticatedCompetitionException();
    }

    await _col.add({
      'title': params.title.trim(),
      'description': params.description.trim(),
      'rule': params.rule,
      'start_time': params.startTime != null
          ? Timestamp.fromDate(params.startTime!)
          : null,
      'use_limit': params.useLimit,
      'limit_minutes':
          params.useLimit && params.limit != null ? params.limit!.inMinutes : null,
      'vehicle': params.vehicle, // 'ATV' | 'Jeep' | 'Truck'
      'owner_id': me.uid,
      'status': 'draft',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}