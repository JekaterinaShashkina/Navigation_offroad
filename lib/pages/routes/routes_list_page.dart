import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/design/widgets/pill.dart';
import 'package:offroad_nav/features/routes/presentation/controller/routes_controller.dart';

// ^^^ поправь путь, если у тебя другой

enum RoutesTab { all, mine }

class RoutesListPage extends ConsumerStatefulWidget {
  const RoutesListPage({super.key});

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

    final filteredRoutes = routesState.routes.where((route) {
      final query = _search.text.trim().toLowerCase();
      if (query.isEmpty) return true;
      return route.name.toLowerCase().contains(query);
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
          // табы (пока они только визуальные)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Pill(
                    text: 'All routes',
                    selected: _tab == RoutesTab.all,
                    onTap: () {
                      setState(() => _tab = RoutesTab.all);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Pill(
                    text: 'My routes',
                    selected: _tab == RoutesTab.mine,
                    onTap: () {
                      setState(() => _tab = RoutesTab.mine);
                    },
                  ),
                ),
              ],
            ),
          ),
          // список
          Expanded(
            child: Builder(
              builder: (context) {
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

                return ListView.builder(
                  itemCount: filteredRoutes.length,
                  itemBuilder: (context, index) {
                    final route = filteredRoutes[index];
                    return ListTile(
                      title: Text(route.name),
                      subtitle: Text('dummy subtitle'),
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
}
