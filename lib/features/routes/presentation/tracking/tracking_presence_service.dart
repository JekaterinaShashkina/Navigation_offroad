import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:offroad_nav/features/groups/application/providers/groups_providers.dart';
import 'package:offroad_nav/features/routes/data/repositories/route_tracking_repository.dart';

class TrackingPresenceService {
  const TrackingPresenceService();

  Future<void> send({
    required WidgetRef ref,
    required LatLng pos,
    required String? groupId,
    required String? uid,
    required double bearing,
    double? accuracyM,
    
  }) async {
    // 1) users/location (твоя текущая логика)
    await RouteTrackingRepository.instance.sendLocation(
      lat: pos.latitude,
      lng: pos.longitude,
      groupId: groupId,
      accuracyM: accuracyM,
    );

    // 2) groups_live (только если группа)
    if (groupId == null || uid == null) return;

    final liveRepo = ref.read(groupsLiveRepositoryProvider);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    
    await liveRepo.upsertMyLiveLocation(
      groupId: groupId,
      userId: uid,
      lat: pos.latitude,
      lng: pos.longitude,
      heading: bearing,
      accuracyM: accuracyM,
      updatedAtMs: nowMs,
    );
  }

  Future<void> stopSharing({
    required WidgetRef ref,
    required String? groupId,
    required String? uid,
  }) async {
    if (groupId == null || uid == null) return;

    await ref.read(groupsLiveRepositoryProvider).stopSharing(
          groupId: groupId,
          userId: uid,
        );
  }
}
