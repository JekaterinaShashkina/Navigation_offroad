import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:offroad_nav/design/widgets/avatar_marker_factory.dart';
import 'package:offroad_nav/features/groups/presentation/models/live_user_view.dart';
import 'package:offroad_nav/features/routes/presentation/utils/route_math.dart';

typedef WarmUpAvatars = void Function(List<LiveUserView> users);

const _crownAnchor = Offset(0.5, 2.3);
const _headingAlpha = 0.15;
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

    final icon = avatarIcons[u.userId] ?? AvatarMarkerFactory.I.defaultIcon;
    final rotation = _smoothedHeading(u.userId, u.heading);

    markers.add(
      Marker(
        markerId: MarkerId('live_${u.userId}'),
        position: LatLng(u.lat, u.lng),
        icon: icon,
        infoWindow: InfoWindow(title: u.name),
        rotation: rotation,
        flat: true,
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

double _smoothedHeading(String userId, double? heading) {
  if (heading == null) {
    return _headingCache[userId] ?? 0;
  }

  final prev = _headingCache[userId];
  final next = prev == null ? heading : lerpAngle(prev, heading, _headingAlpha);
  _headingCache[userId] = next;
  return next;
}