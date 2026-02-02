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
  final String routeName;
  final DateTime startAt;
  final DateTime endAt;
  final String? vehicleType;

  const CompetitionInput({
    required this.name,
    required this.description,
    required this.rulesText,
    required this.routeId,
    required this.routeName,
    required this.startAt,
    required this.endAt,
    this.vehicleType,
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
      'routeName': input.routeName.trim(),
      'vehicleType': input.vehicleType,
      'startAt': Timestamp.fromDate(input.startAt),
      'endAt': Timestamp.fromDate(input.endAt),
      'createdBy': uid,
      'createdAt': now,
      'updatedAt': now,
    });

    return doc.id;
  }

  Future<void> updateCompetition(
    String competitionId,
    CompetitionInput input,
  ) async {
    final uid = _requireUser();
    final now = FieldValue.serverTimestamp();

    // (опционально, но полезно) — защита: редактировать может только создатель
    final docRef = _col.doc(competitionId);
    final snap = await docRef.get();
    if (!snap.exists) {
      throw Exception('Competition not found');
    }

    final data = snap.data() as Map<String, dynamic>;
    final createdBy = data['createdBy'] as String?;
    if (createdBy != null && createdBy != uid) {
      throw Exception('Only competition owner can edit this competition');
    }

    // (опционально) — защита по времени: если уже началось, не даём менять
    final startAtTs = data['startAt'];
    if (startAtTs is Timestamp) {
      final startAt = startAtTs.toDate();
      if (DateTime.now().isAfter(startAt)) {
        throw Exception('Competition already started. Editing is not allowed.');
      }
    }

    await docRef.update({
      'name': input.name.trim(),
      'description': input.description.trim(),
      'rulesText': input.rulesText.trim(),
      'routeId': input.routeId,
      'routeName': input.routeName.trim(),
      'vehicleType': input.vehicleType,
      'startAt': Timestamp.fromDate(input.startAt),
      'endAt': Timestamp.fromDate(input.endAt),
      'updatedAt': now,
      // можно хранить кто обновил:
      'updatedBy': uid,
    });
  }

  Stream<List<Competition>> watchCompetitions() {
    return _col
        .orderBy('startAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(Competition.fromDoc).toList());
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
        .map((snap) => snap.docs.map(CompetitionAttempt.fromDoc).toList());
  }

  Future<void> joinCompetition(String competitionId) async {
    // final user = _auth.currentUser;
    final uid = _requireUser();
    // 1) читаем профиль из твоей коллекции users
    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final userData = userSnap.data() ?? const <String, dynamic>{};

    final name = (userData['name'] as String?)?.trim();
    final img = (userData['img'] as String?)?.trim();

    // fallback если вдруг пусто
    final fallbackName = _auth.currentUser?.email?.split('@').first ?? 'User';

    // 2) пишем участника в competition participants
    await _participants(competitionId).doc(uid).set({
      'uid': uid,
      'displayName': (name != null && name.isNotEmpty) ? name : fallbackName,
      'photoUrl': (img != null && img.isNotEmpty) ? img : null,
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> leaveCompetition(String competitionId) async {
    final uid = _requireUser();
    await _participants(competitionId).doc(uid).delete();
  }

  Future<String> startAttempt(String competitionId) async {
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

    final doc = await _attempts(competitionId).add({
      'uid': uid,
      'startedAt': Timestamp.fromDate(DateTime.now()),
      'finishedAt': null,
      'durationSeconds': null,
      // сюда позже можно добавить route snapshot/vehicleType если надо
    });

    return doc.id;
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

  Future<void> finishAttemptWithResult({
  required String competitionId,
  required String attemptId,
  required int durationSeconds,
  required double distanceMeters,
  required int startIndex,
  required int endIndex,
  List<Map<String, double>>? traversed, // optional
}) async {
  final uid = _requireUser();

  final competition = await _fetchCompetitionOrThrow(competitionId);
  if (competition.status != CompetitionStatus.active) {
    throw CompetitionActionException('Competition is not active');
  }

  final ref = _attempts(competitionId).doc(attemptId);
  final snap = await ref.get();
  if (!snap.exists) {
    throw CompetitionActionException('Attempt not found');
  }

  final data = snap.data()!;
  if (data['uid'] != uid) {
    throw CompetitionActionException('Not your attempt');
  }

  if (data['finishedAt'] != null) {
    throw CompetitionActionException('Attempt already finished');
  }

  final finishTime = DateTime.now();

  await ref.update({
    'finishedAt': Timestamp.fromDate(finishTime),
    'durationSeconds': durationSeconds < 0 ? 0 : durationSeconds,
    'distanceMeters': distanceMeters,
    'startIndex': startIndex,
    'endIndex': endIndex,
    if (traversed != null) 'traversed': traversed,
  });
}


  Future<void> cancelAttempt(String competitionId, String attemptId) async {
  await _attempts(competitionId).doc(attemptId).delete();
}
}
