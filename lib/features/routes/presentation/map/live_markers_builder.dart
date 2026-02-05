import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:offroad_nav/features/groups/presentation/models/live_user_view.dart';

typedef WarmUpAvatars = Future<void> Function(List<LiveUserView> users);

const _crownAnchor = Offset(0.5, 2.3);

final _headingCache = <String, double>{};

Set<Marker> buildLiveMarkers({
  required List<LiveUserView> users,
  required WarmUpAvatars warmUpAvatars,
  required Map<String, BitmapDescriptor> avatarIcons,
  required String? myUid,
  required String? leaderId,
  required BitmapDescriptor? crownIcon,
  bool includeMe = false,
}) {
  warmUpAvatars(users);
    final ids = users.map((u) => u.userId).toSet();
  _headingCache.removeWhere((key, _) => !ids.contains(key));
  final markers = <Marker>{};
  for (final u in users) {
    if (!includeMe && myUid != null && u.userId == myUid) continue;
    final icon = avatarIcons[u.userId] ?? BitmapDescriptor.defaultMarker;
    // final rotation = _smoothedHeading(u.userId, u.heading);
    markers.add(
      Marker(
        markerId: MarkerId('live_${u.userId}'),
        position: LatLng(u.lat, u.lng),
        icon: icon,
        infoWindow: InfoWindow(title: u.name),
        rotation: 0,
        flat: false,
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 10,
      ),
    );

    final isLeader = (leaderId != null && u.userId == leaderId);
    if (isLeader && crownIcon != null) {
      markers.add(
        Marker(
          markerId: MarkerId('crown_${u.userId}'),
          position: LatLng(u.lat, u.lng),
          icon: crownIcon,
          flat: false,
          rotation: 0,
          anchor: _crownAnchor,
          zIndexInt: 20,
        ),
      );
    }
  }

  return markers;
}