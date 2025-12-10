import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';

import 'package:offroad_nav/features/groups/application/providers/groups_providers.dart';
import 'package:offroad_nav/features/groups/presentation/pages/group_detail_page.dart';

import 'package:offroad_nav/features/groups/domain/entities/group.dart';
import 'package:offroad_nav/features/groups/presentation/widgets/add_group_card.dart';
import 'package:offroad_nav/features/groups/presentation/widgets/create_group_dialog.dart';
import 'package:offroad_nav/features/groups/presentation/widgets/group_card.dart';

class GroupsPage extends ConsumerStatefulWidget {
  const GroupsPage({super.key});

  @override
  ConsumerState<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends ConsumerState<GroupsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(myGroupsProvider);

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        titleWidget: const Text(
          'Groups',
          style: TextStyle(
            fontSize: fontSize20,
            fontWeight: FontWeight.w600,
            color: textMainColor,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(padding16),
        child: Column(
          children: [
            // Search
            Container(
              margin: const EdgeInsets.only(bottom: padding16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(radius12),
                boxShadow: [
                  BoxShadow(
                    color: listShadowColor,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(
                    color: textHintColor,
                    fontSize: fontSize16,
                  ),
                  prefixIcon: Icon(Icons.search, color: textHintColor),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: padding16,
                    vertical: padding12,
                  ),
                ),
              ),
            ),

            // Groups grid
            Expanded(
              child: groupsAsync.when(
                data: (groups) {
                  final query = _searchController.text.trim().toLowerCase();

                  final filtered = query.isEmpty
                      ? groups
                      : groups
                            .where((g) => g.name.toLowerCase().contains(query))
                            .toList();

                  // если вообще нет групп
                  if (filtered.isEmpty) {
                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: padding16,
                            mainAxisSpacing: padding16,
                            childAspectRatio: 0.8,
                          ),
                      itemCount: 1, // только кнопка "Create group"
                      itemBuilder: (context, index) {
                        return AddGroupCard(
                          onTap: () => CreateGroupDialog.show(context),
                        );
                      },
                    );
                  }

                  return GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: padding16,
                          mainAxisSpacing: padding16,
                          childAspectRatio: 0.8,
                        ),
                    // +1 – отдельная карточка "Create group"
                    itemCount: filtered.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // первая плитка — создать группу
                        return AddGroupCard(
                          onTap: () => CreateGroupDialog.show(context),
                        );
                      }

                      final group = filtered[index - 1];
                      return GroupCard(
                        group: group,
                        onTap: () => _showGroupDetail(context, group),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => const Center(
                  child: Text(
                    'Failed to load groups',
                    style: TextStyle(color: textHintColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupDetail(BuildContext context, Group group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GroupDetailPage(group: group)),
    );
  }
}
