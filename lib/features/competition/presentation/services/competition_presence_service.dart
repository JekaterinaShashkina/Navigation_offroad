import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CompetitionPresenceService {
  DatabaseReference get _db => FirebaseDatabase.instance.ref();

  Future<void> send({
    required WidgetRef ref,
    required String competitionId,
    required String uid,
    required LatLng pos,
    required double bearing,
    required double accuracyM,
  }) async {
    await _db.child('competition_live/$competitionId/$uid').set({
      'lat': pos.latitude,
      'lng': pos.longitude,
      'bearing': bearing,
      'accuracyM': accuracyM,
      'updatedAtMs': ServerValue.timestamp,
    });
  }

  Future<void> stopSharing({
    required WidgetRef ref,
    required String competitionId,
    required String uid,
  }) async {
    await _db.child('competition_live/$competitionId/$uid').remove();
  }
}
