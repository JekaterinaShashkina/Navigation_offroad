import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/features/groups/data/repositories/groups_repository.dart';

import 'package:offroad_nav/features/groups/domain/entities/group.dart';
import 'package:offroad_nav/features/groups/application/providers/groups_providers.dart';
import 'package:offroad_nav/features/groups/presentation/widgets/route_actions.dart';
import 'package:offroad_nav/features/groups/presentation/widgets/routes_selector.dart';

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
        onOpen: (routeId) => RouteActions.openRouteById(context, routeId, group.id),
        onSelect: setActiveRoute,
      ),
    );
  }
}
