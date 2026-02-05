import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:offroad_nav/design/widgets/avatar_marker_factory.dart';
import 'package:offroad_nav/features/groups/presentation/models/live_user_view.dart';

class AvatarIconCache {
  AvatarIconCache({this.size = 240});

  final int size;

  final Map<String, BitmapDescriptor> _cache = {};
  Map<String, BitmapDescriptor> get map => _cache;

  /// Никогда не зависим от defaultIcon фабрики — всегда есть системный fallback
BitmapDescriptor iconFor(String userId) =>
    _cache[userId] ?? BitmapDescriptor.defaultMarker;

  bool contains(String userId) => _cache.containsKey(userId);

  void prune(Set<String> aliveIds) {
    _cache.removeWhere((id, _) => !aliveIds.contains(id));
  }

  Future<bool> warmUp(List<LiveUserView> users) async {
  bool changed = false;

  for (final u in users) {
    if (_cache.containsKey(u.userId)) continue;

    final src = (u.img ?? '').trim();

    // ✅ нет фотки — кладём дефолт, чтобы было стабильно
    if (src.isEmpty) {
      _cache[u.userId] = BitmapDescriptor.defaultMarker;
      changed = true;
      continue;
    }

    try {
      final icon = await AvatarMarkerFactory.I.get(
        userId: u.userId,
        photoUrlOrAsset: src,
        size: size,
      );
      _cache[u.userId] = icon;
      changed = true;
    } catch (e) {
      // ✅ упало — всё равно кладём дефолт
      _cache[u.userId] = BitmapDescriptor.defaultMarker;
      changed = true;
      debugPrint('❌ avatar failed uid=${u.userId}, src=$src, err=$e');
    }
  }

  return changed;
}
}
