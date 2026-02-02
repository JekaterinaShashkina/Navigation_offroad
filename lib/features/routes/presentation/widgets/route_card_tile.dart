import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:offroad_nav/features/routes/domain/entities/route_entity.dart';
import 'package:offroad_nav/features/routes/presentation/controller/routes_controller.dart';
import 'package:offroad_nav/features/routes/presentation/pages/route_detail_page.dart';
import 'package:offroad_nav/features/routes/presentation/widgets/route_card.dart';

class RouteCardTile extends ConsumerWidget {
  const RouteCardTile({
    super.key,
    required this.route,
    required this.uid,
    required this.selectionMode,
    this.widthFactor,
  });

  final RouteEntity route;
  final String uid;
  final bool selectionMode;
  final double? widthFactor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = route.ownerId == uid;

    return RouteCard(
      route: route,
      isOwner: isOwner,
      widthFactor: widthFactor ?? 0.94,
      onTap: () {
        if (selectionMode) {
          Navigator.pop(context, route);
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RouteDetailPage(
              name: route.name,
              points: route.points,
            ),
          ),
        );
      },
      onToggleVisibility: isOwner
          ? () async {
              await ref.read(routesControllerProvider.notifier).togglePrivacy(route);
            }
          : null,
      onDelete: isOwner
          ? () => _confirmDelete(context, ref, route.id)
          : null,
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String routeId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete route?'),
        content: const Text('Are you sure you want to delete this route?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(routesControllerProvider.notifier).deleteRoute(routeId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

