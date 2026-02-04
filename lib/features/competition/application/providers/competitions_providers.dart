// lib/features/competitions/application/competitions_providers.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offroad_nav/features/competition/data/repositories/competitions_repository.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition_attempt.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition_participant.dart';
import 'package:offroad_nav/features/routes/domain/entities/route_entity.dart';
import 'package:offroad_nav/features/routes/presentation/controller/routes_controller.dart';


final competitionsRepositoryProvider = Provider<CompetitionsRepository>((ref) {
  return CompetitionsRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

final competitionsListProvider = StreamProvider.autoDispose<List<Competition>>((ref) {
  return ref.watch(competitionsRepositoryProvider).watchCompetitions();
});

final competitionProvider = StreamProvider.autoDispose.family<Competition?, String>((ref, id) {
  return ref.watch(competitionsRepositoryProvider).watchCompetition(id);
});

final competitionParticipantsProvider =
    StreamProvider.autoDispose.family<List<CompetitionParticipant>, String>((ref, id) {
  return ref.watch(competitionsRepositoryProvider).watchParticipants(id);
});

final competitionAttemptsProvider =
    StreamProvider.autoDispose.family<List<CompetitionAttempt>, String>((ref, id) {
  return ref.watch(competitionsRepositoryProvider).watchAttempts(id);
});

final activeAttemptProvider =
    Provider.autoDispose.family<CompetitionAttempt?, String>((ref, id) {
  final attempts = ref.watch(competitionAttemptsProvider(id)).maybeWhen(
        data: (items) => items,
        orElse: () => const <CompetitionAttempt>[],
      ) ??
      const <CompetitionAttempt>[];
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;

  for (final attempt in attempts) {
    if (attempt.uid == uid && attempt.finishedAt == null) {
      return attempt;
    }
  }
    return null;
});

class LeaderboardEntry {
  final CompetitionParticipant? participant;
  final CompetitionAttempt attempt;

  const LeaderboardEntry({
    required this.participant,
    required this.attempt,
  });
}

bool _isValidAttempt({
  required CompetitionAttempt a,
  required RouteEntity route,
}) {
  if (a.finishedAt == null) return false;
  final dur = a.durationSeconds ?? 0;
  if (dur <= 0) return false;

  final totalPoints = route.points.length;
  if (totalPoints < 2) return false;

  // 1️⃣ Проверка по индексу
  final byIndex =
      a.endIndex != null && a.endIndex! >= totalPoints - 2;

  // 2️⃣ Проверка по дистанции (если есть lengthKm)
  final byDistance =
      route.lengthKm != null && a.distanceMeters != null
          ? a.distanceMeters! >= route.lengthKm! * 1000 * 0.9
          : false;

  // Достаточно одного условия
  return byIndex || byDistance;
}

final leaderboardProvider = FutureProvider.autoDispose.family<List<LeaderboardEntry>, String>((ref, competitionId) async {
  final participants = await ref.watch(competitionParticipantsProvider(competitionId).future);
  final attempts = await ref.watch(competitionAttemptsProvider(competitionId).future);

  final competition = await ref.watch(competitionProvider(competitionId).future);
  if (competition == null) return const [];

  final route = await ref.watch(routeByIdProvider(competition.routeId).future);

  final bestByUser = <String, CompetitionAttempt>{};

  for (final attempt in attempts) {
    // берем только законченные попытки
    if (attempt.durationSeconds == null) continue;

    // ✅ фильтр "прошёл маршрут"
    if (!_isValidAttempt(a: attempt, route: route)) continue;

    final current = bestByUser[attempt.uid];
    if (current == null || (attempt.durationSeconds ?? 0) < (current.durationSeconds ?? 0)) {
      bestByUser[attempt.uid] = attempt;
    }
  }

  final items = bestByUser.entries.map((entry) {
    final participant = participants.firstWhere(
      (p) => p.uid == entry.key,
      orElse: () => CompetitionParticipant(
        uid: entry.key,
        joinedAt: entry.value.startedAt ?? DateTime.now(),
      ),
    );
    return LeaderboardEntry(participant: participant, attempt: entry.value);
  }).toList();

  items.sort((a, b) {
    final aDur = a.attempt.durationSeconds ?? 1 << 31;
    final bDur = b.attempt.durationSeconds ?? 1 << 31;
    return aDur.compareTo(bDur);
  });

  return items;
});

