import 'package:flutter/material.dart';
import 'package:offroad_nav/features/routes/domain/entities/completed_route_entity.dart';
import 'package:offroad_nav/features/routes/domain/entities/route_entity.dart';
import 'package:offroad_nav/design/widgets/accordion_card.dart';

typedef RouteCardBuilder = Widget Function(RouteEntity route);
typedef CompletedCardBuilder = Widget Function(CompletedRouteEntity item);

class MyRoutesAccordion extends StatelessWidget {
  const MyRoutesAccordion({
    super.key,
    required this.myRoutes,
    required this.completedRoutes,
    required this.favoritesCount,
    required this.buildRoutePreviewItem,
    required this.buildCompletedPreviewItem,
    required this.onShowAllMyRoutes,
    this.onShowAllCompletedRoutes,
  });

  final List<RouteEntity> myRoutes;
  final List<CompletedRouteEntity> completedRoutes;
  final int favoritesCount;

  final RouteCardBuilder buildRoutePreviewItem;
  final CompletedCardBuilder buildCompletedPreviewItem;

  final VoidCallback onShowAllMyRoutes;
  final VoidCallback? onShowAllCompletedRoutes;

  @override
  Widget build(BuildContext context) {
    // my routes preview
    final mySorted = [...myRoutes]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final myPreview = mySorted.take(5).toList();
    final myHasMore = mySorted.length > 5;

    // completed preview
    final compSorted = [...completedRoutes]..sort((a, b) {
      final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    final compPreview = compSorted.take(5).toList();
    final compHasMore = compSorted.length > 5;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      children: [
        AccordionCard(
          title: 'My routes',
          count: myRoutes.length,
          initiallyExpanded: true,
          child: myPreview.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No routes yet'),
                )
              : Column(
                  children: [
                    for (final r in myPreview) ...[
                      buildRoutePreviewItem(r),
                      const SizedBox(height: 10),
                    ],
                    if (myHasMore)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: onShowAllMyRoutes,
                          child: const Text('Show all'),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 10),

        AccordionCard(
          title: 'Completed routes',
          count: completedRoutes.length,
          initiallyExpanded: true,
          child: compPreview.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No completed routes yet'),
                )
              : Column(
                  children: [
                    for (final c in compPreview) ...[
                      buildCompletedPreviewItem(c),
                      const SizedBox(height: 10),
                    ],
                    if (compHasMore && onShowAllCompletedRoutes != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: onShowAllCompletedRoutes,
                          child: const Text('Show all'),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 10),

        AccordionCard(
          title: 'Favorites',
          count: favoritesCount,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Coming soon'),
          ),
        ),
      ],
    );
  }
}
