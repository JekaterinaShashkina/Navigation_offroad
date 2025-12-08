// lib/features/competitions/application/competitions_providers.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offroad_nav/features/competition/data/repositories/competitions_repository.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition.dart';


final competitionsRepositoryProvider =
    Provider<CompetitionsRepository>((ref) {
  return CompetitionsRepository(FirebaseFirestore.instance);
});

/// Стрим "My competitions"
final myCompetitionsProvider =
    StreamProvider<List<Competition>>((ref) {
  final repo = ref.watch(competitionsRepositoryProvider);
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    // если юзер не залогинен — пустой стрим
    return const Stream<List<Competition>>.empty();
  }

  return repo.watchByOwner(user.uid);
});
