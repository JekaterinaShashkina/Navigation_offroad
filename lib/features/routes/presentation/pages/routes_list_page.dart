import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';

import 'package:offroad_nav/features/routes/data/repositories/completed_route_repository.dart';
import 'package:offroad_nav/features/routes/domain/entities/completed_route_entity.dart';
import 'package:offroad_nav/features/routes/domain/entities/route_entity.dart';
import 'package:offroad_nav/features/routes/presentation/controller/routes_controller.dart';
import 'package:offroad_nav/features/routes/presentation/pages/completed_route_detail_page.dart';
import 'package:offroad_nav/features/routes/presentation/pages/route_detail_page.dart';
import 'package:offroad_nav/features/routes/presentation/widgets/completed_route_card.dart';
import 'package:offroad_nav/features/routes/presentation/widgets/my_routes_accordion.dart';
import 'package:offroad_nav/design/widgets/pill.dart';
import 'package:offroad_nav/features/routes/presentation/widgets/route_card.dart';
import 'package:offroad_nav/features/routes/presentation/widgets/route_card_tile.dart';

enum RoutesTab { all, mine }

class RoutesListPage extends ConsumerStatefulWidget {
  final bool selectionMode;
  final RoutesTab initialTab;

  /// если true — показываем полный список "My routes" (без аккордеона)
  final bool showAllMine;

  const RoutesListPage({
    super.key,
    this.selectionMode = false,
    this.initialTab = RoutesTab.all,
    this.showAllMine = false,
  });

  @override
  ConsumerState<RoutesListPage> createState() => _RoutesListPageState();
}

class _RoutesListPageState extends ConsumerState<RoutesListPage> {
  final _search = TextEditingController();
  late RoutesTab _tab;

  late final CompletedRouteRepository _completedRepo;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _completedRepo = CompletedRouteRepository(FirebaseFirestore.instance);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routesState = ref.watch(routesControllerProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // базовые списки
    final allPublic = routesState.routes.where((r) => r.isPublic).toList();
    final myRoutes = routesState.routes.where((r) => r.ownerId == uid).toList();

    // поиск
    final query = _search.text.trim().toLowerCase();

    List<RouteEntity> applySearch(List<RouteEntity> list) {
      if (query.isEmpty) return list;
      return list.where((r) => r.name.toLowerCase().contains(query)).toList();
    }

    final allPublicFiltered = applySearch(allPublic);
    final myRoutesFiltered = applySearch(myRoutes);

    // текущий список для обычного списка (all / mine)
    final listForTab = _tab == RoutesTab.all ? allPublicFiltered : myRoutesFiltered;

    return Scaffold(
      appBar: NewAppBar(
        title: 'Routes',
        onPressed: () => Navigator.pop(context),
      ),
      backgroundColor: backgroundMainColor,
      body: Column(
        children: [
          // поиск
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: surfaceColor,
                contentPadding: const EdgeInsets.symmetric(vertical: padding12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(radius16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // табы
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Pill(
                    text: 'All routes',
                    selected: _tab == RoutesTab.all,
                    onTap: () => setState(() => _tab = RoutesTab.all),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Pill(
                    text: 'My routes',
                    selected: _tab == RoutesTab.mine,
                    onTap: () => setState(() => _tab = RoutesTab.mine),
                  ),
                ),
              ],
            ),
          ),

          // контент
          Expanded(
            child: Builder(
              builder: (_) {
                if (routesState.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (routesState.error != null) {
                  return Center(
                    child: Text(
                      routesState.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                // ---------- вкладка ALL ----------
                if (_tab == RoutesTab.all) {
                  if (listForTab.isEmpty) {
                    return const Center(child: Text('No routes found'));
                  }
                  return _routesListSeparated(
                    context: context,
                    routes: listForTab,
                    uid: uid,
                    ref: ref,
                  );
                }

                // ---------- вкладка MY ----------
                // если пришли в режим "Show all mine" — показываем обычный список
                if (widget.showAllMine) {
                  if (myRoutesFiltered.isEmpty) {
                    return const Center(child: Text('No routes found'));
                  }
                  return _routesListSeparated(
                    context: context,
                    routes: myRoutesFiltered,
                    uid: uid,
                    ref: ref,
                  );
                }

                // иначе — аккордеон (превью 5) + completed/favorites
                return StreamBuilder<List<CompletedRouteEntity>>(
                  stream: _completedRepo.watchMyCompletedRoutes(uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Failed to load completed routes'),
                      );
                    }

                    final completed =
                        snapshot.data ?? const <CompletedRouteEntity>[];

                    return MyRoutesAccordion(
                      myRoutes: myRoutesFiltered,
                        completedRoutes: completed,
                        favoritesCount: 0,

                        buildRoutePreviewItem: (route) => RouteCardTile(
                          route: route,
                          uid: uid,
                          selectionMode: widget.selectionMode,
                        ),

                        buildCompletedPreviewItem: (item) => CompletedRouteCard(
                          item: item,
                          onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CompletedRouteDetailPage(
                                name: item.routeName,
                                completedPoints: item.traversedPolyline,
                                //plannedPoints: item.plannedPoints, // если есть
                                completedAt: item.finishedAt,
                                duration: Duration(seconds: item.durationSec),
                              ),
                            ),
                          );
                          },
                        ),
                      onShowAllMyRoutes: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RoutesListPage(
                              initialTab: RoutesTab.mine,
                              showAllMine: true,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: AppButton(
          text: 'Make a route',
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/makeroutepage'),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    String routeId,
    WidgetRef ref,
  ) {
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
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- UI: обычный список (для All routes и Show all mine) ----------
  Widget _routesListSeparated({
    required BuildContext context,
    required List<RouteEntity> routes,
    required String uid,
    required WidgetRef ref,
  }) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      itemCount: routes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final route = routes[index];
        final isOwner = route.ownerId == uid;

        return RouteCard(
          route: route,
          isOwner: isOwner,
          onTap: () {
            if (widget.selectionMode) {
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
          onDelete: isOwner ? () => _confirmDelete(context, route.id, ref) : null,
        );
      },
    );
  }
}
