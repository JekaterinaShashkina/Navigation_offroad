import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';

import 'package:offroad_nav/features/groups/domain/entities/group.dart';
import 'package:offroad_nav/features/groups/application/providers/groups_providers.dart';
import 'package:offroad_nav/features/routes/presentation/pages/route_detail_page.dart';
import 'package:offroad_nav/features/groups/presentation/widgets/routes_selector.dart';
// ^^^ путь к RoutesSelector подставь свой, как ты его сохранила

class GroupRoutesPage extends ConsumerWidget {
  const GroupRoutesPage({
    super.key,
    required this.group,
  });

  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isLeader = currentUserId == group.ownerId;

    Future<void> openRouteById(String routeId) async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('routes')
            .doc(routeId)
            .get();

        if (!doc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Route not found'),
              backgroundColor: errorColor,
            ),
          );
          return;
        }

        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? 'Route').toString();
        final points = (data['points'] ?? []) as List<dynamic>;

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RouteDetailPage(
              name: name,
              points: points,
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening route: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }

    Future<void> setActiveRoute(String routeId) async {
      final repo = ref.read(groupsRepositoryProvider);
      await repo.setActiveRoute(group.id, routeId);
      // RoutesSelector сам обновит локальный _activeRouteId через setState
    }

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        titleWidget: const Text(
          'Routes',
          style: TextStyle(
            fontSize: fontSize18,
            fontWeight: FontWeight.w600,
            color: textMainColor,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      body: RoutesSelector(
        initialActiveRouteId: group.routeId,
        isLeader: isLeader,
        onOpen: openRouteById,
        onSelect: setActiveRoute,
      ),
    );
  }
}
