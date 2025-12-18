import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/features/routes/presentation/widgets/pill.dart';
import 'package:offroad_nav/features/routes/presentation/controller/routes_controller.dart';
import 'package:offroad_nav/features/routes/presentation/widgets/route_card.dart';
import 'package:offroad_nav/features/routes/presentation/pages/route_detail_page.dart';

enum RoutesTab { all, mine }

class RoutesListPage extends ConsumerStatefulWidget {
  final bool selectionMode;
  const RoutesListPage({super.key, this.selectionMode = false,});

  @override
  ConsumerState<RoutesListPage> createState() => _RoutesListPageState();
}

class _RoutesListPageState extends ConsumerState<RoutesListPage> {
  final _search = TextEditingController();
  RoutesTab _tab = RoutesTab.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routesState = ref.watch(routesControllerProvider);
    // final repo = RoutesRepository();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // 1) фильтр по табу
    final byTab = routesState.routes.where((r) {
      return switch (_tab) {
        RoutesTab.all  => r.isPublic,        // только публичные
        RoutesTab.mine => r.ownerId == uid,  // только мои
      };
    }).toList();

    // 2) фильтр по поиску
    final query = _search.text.trim().toLowerCase();
    final filteredRoutes = byTab.where((r) {
      if (query.isEmpty) return true;
      return r.name.toLowerCase().contains(query);
    }).toList();

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
                contentPadding:
                    const EdgeInsets.symmetric(vertical: padding12),
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

          // список
          Expanded(
            child: Builder(
              builder: (context) {
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

                if (filteredRoutes.isEmpty) {
                  return const Center(child: Text('No routes found'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                  itemCount: filteredRoutes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final route = filteredRoutes[index];
                    final isOwner = route.ownerId == uid;

                    return RouteCard(
                      route: route,
                      isOwner: isOwner,
                      onTap: () {
                        if (widget.selectionMode) {
                          Navigator.pop(context, route); // вернуть выбранный маршрут
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RouteDetailPage(
                                name: route.name,
                                points: route.points
                                    .map((p) => {'lat': p.lat, 'lng': p.lng})
                                    .toList(),
                              ),
                            ),
                          );
                        }
                      },
                      onToggleVisibility: isOwner
                          ? () async {
                              await ref
                                  .read(routesControllerProvider.notifier)
                                  .togglePrivacy(route);
                            }
                          : null,
                      onDelete: isOwner
                          ? () => _confirmDelete(
                            context, 
                            route.id, 
                            ref
                              )
                          : null,
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
        content:
            const Text('Are you sure you want to delete this route?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await    ref
                .read(routesControllerProvider.notifier)
                .deleteRoute(routeId); 

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
}
