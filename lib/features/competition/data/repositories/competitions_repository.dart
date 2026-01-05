// lib/features/competitions/data/competitions_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition_attempt.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition_participant.dart';

class CompetitionInput {
  final String name;
  final String description;
  final String rulesText;
  final String routeId;
  final DateTime startAt;
  final DateTime endAt;
  // final String vehicle;

  const CompetitionInput({
    required this.name,
    required this.description,
    required this.rulesText,
    required this.routeId,
    required this.startAt,
    required this.endAt,
    //required this.vehicle,
  });
}

class CompetitionActionException implements Exception {
  final String message;
  CompetitionActionException(this.message);

  @override
  String toString() => message;
}

class CompetitionsRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CompetitionsRepository(this._db, this._auth);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('competitions');

  DocumentReference<Map<String, dynamic>> _competitionRef(String id) =>
      _col.doc(id);

  CollectionReference<Map<String, dynamic>> _participants(String id) =>
      _competitionRef(id).collection('participants');

  CollectionReference<Map<String, dynamic>> _attempts(String id) =>
      _competitionRef(id).collection('attempts');

  String _requireUser() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw CompetitionActionException('User not authenticated');
    return uid;
  }

  Future<Competition> _fetchCompetitionOrThrow(String id) async {
    final doc = await _competitionRef(id).get();
    if (!doc.exists) {
      throw CompetitionActionException('Competition not found');
    }
    return Competition.fromDoc(doc);
  }

  Future<String> createCompetition(CompetitionInput input) async {
    final uid = _requireUser();
    final now = FieldValue.serverTimestamp();

    final doc = await _col.add({
      'name': input.name.trim(),
      'description': input.description.trim(),
      'rulesText': input.rulesText.trim(),
      'routeId': input.routeId,
      'startAt': Timestamp.fromDate(input.startAt),
      'endAt': Timestamp.fromDate(input.endAt),
      'createdBy': uid,
      'createdAt': now,
      'updatedAt': now,
    });

    return doc.id;
  }

  Stream<List<Competition>> watchCompetitions() {
    return _col.orderBy('startAt', descending: false).snapshots().map(
          (snap) => snap.docs.map(Competition.fromDoc).toList(),
          );

  }

  Stream<Competition?> watchCompetition(String id) {
      return _competitionRef(id).snapshots().map((doc) {
        if (!doc.exists) return null;
        return Competition.fromDoc(doc);
      });
    } 

    Stream<List<CompetitionParticipant>> watchParticipants(String competitionId) {
    return _participants(competitionId)
        .orderBy('joinedAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(CompetitionParticipant.fromDoc).toList());
  }

    Stream<List<CompetitionAttempt>> watchAttempts(String competitionId) {
    return _attempts(competitionId)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CompetitionAttempt.fromDoc).toList()
        );
    }

    Future<void> joinCompetition(String competitionId) async {
    final user = _auth.currentUser;
    final uid = _requireUser();

    await _participants(competitionId).doc(uid).set({
      'displayName': user?.displayName,
      'photoUrl': user?.photoURL,
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

    Future<void> leaveCompetition(String competitionId) async {
    final uid = _requireUser();
    await _participants(competitionId).doc(uid).delete();
  }

    Future<void> startAttempt(String competitionId) async {
    final uid = _requireUser();
    final competition = await _fetchCompetitionOrThrow(competitionId);
    if (competition.status != CompetitionStatus.active) {
      throw CompetitionActionException('Competition is not active');
    }

    final activeAttempt = await _attempts(competitionId)
        .where('uid', isEqualTo: uid)
        .where('finishedAt', isNull: true)
        .limit(1)
        .get();

    if (activeAttempt.docs.isNotEmpty) {
      throw CompetitionActionException('You already have an active attempt');
    }

    await _attempts(competitionId).add({
      'uid': uid,
      'startedAt': Timestamp.fromDate(DateTime.now()),
      'finishedAt': null,
      'durationSeconds': null,
    });
  }

    Future<void> finishAttempt(String competitionId) async {
    final uid = _requireUser();
    final competition = await _fetchCompetitionOrThrow(competitionId);
    if (competition.status != CompetitionStatus.active) {
      throw CompetitionActionException('Competition is not active');
    }

    final query = await _attempts(competitionId)
        .where('uid', isEqualTo: uid)
        .where('finishedAt', isNull: true)
        .orderBy('startedAt', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw CompetitionActionException('No active attempt to finish');
    }
    final doc = query.docs.first;
    final startedAt = (doc['startedAt'] as Timestamp?)?.toDate();
    if (startedAt == null) {
      throw CompetitionActionException('Attempt start time missing');
    }

    final finishTime = DateTime.now();
    final duration = finishTime.difference(startedAt).inSeconds;

    await doc.reference.update({
      'finishedAt': Timestamp.fromDate(finishTime),
      'durationSeconds': duration < 0 ? 0 : duration,
  });
  }
}