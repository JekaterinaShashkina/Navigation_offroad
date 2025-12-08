import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/avatars.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';

// import 'package:offroad_nav/features/groups/data/models/group.dart';
import 'package:offroad_nav/features/groups/application/providers/groups_providers.dart';
import 'package:offroad_nav/features/groups/data/repositories/groups_repository.dart';
import 'package:offroad_nav/features/groups/domain/entities/member.dart';
import 'package:offroad_nav/features/groups/presentation/pages/group_detail_page.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:offroad_nav/features/groups/domain/entities/group.dart';
import 'package:offroad_nav/features/groups/presentation/widgets/add_group_card.dart';
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

  String _extractPhoto(Map<String, dynamic> user) {
    final candidates = [
      user['img'],
      user['photoUrl'],
      user['photoURL'],
      user['avatar'],
      user['photo'],
      user['imageUrl'],
    ];
    for (final v in candidates) {
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
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
            // Expanded(
            //   child: groupsAsync.when(
            //     data: (groups) {
            //       final query = _searchController.text.trim().toLowerCase();

            //       final filtered = query.isEmpty
            //           ? groups
            //           : groups
            //                 .where((g) => g.name.toLowerCase().contains(query))
            //                 .toList();

            //       // только реальные группы
            //       final items = filtered;

            //       return GridView.builder(
            //         physics: const BouncingScrollPhysics(),
            //         gridDelegate:
            //             const SliverGridDelegateWithFixedCrossAxisCount(
            //               crossAxisCount: 2,
            //               crossAxisSpacing: padding16,
            //               mainAxisSpacing: padding16,
            //               childAspectRatio: 0.8,
            //             ),
            //         // +1 – отдельная карточка "Create group"
            //         itemCount: items.length + 1,
            //         itemBuilder: (context, index) {
            //           if (index == 0) {
            //             // первая плитка — создать группу
            //             return AddGroupCard(
            //               onTap: () => _showAddGroupDialog(context),
            //             );
            //           }

            //           final group = filtered[index - 1];
            //           return GroupCard(
            //             group: group,
            //             onTap: () => _showGroupDetail(context, group),
            //           );
            //         },
            //       );
            //     },
            //     loading: () => const Center(child: CircularProgressIndicator()),
            //     error: (e, st) => const Center(
            //       child: Text(
            //         'Failed to load groups',
            //         style: TextStyle(color: textHintColor),
            //       ),
            //     ),
            //   ),
            // ),

            Expanded(
  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('groups')
        .snapshots(),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snap.hasError) {
        return Center(
          child: Text(
            'Firestore error: ${snap.error}',
            style: const TextStyle(color: errorColor),
          ),
        );
      }

      final docs = snap.data?.docs ?? [];
      if (docs.isEmpty) {
        return const Center(
          child: Text(
            'Нет групп',
            style: TextStyle(color: textHintColor),
          ),
        );
      }

      // Показать просто id и name, чтобы убедиться, что данные есть
      return ListView.builder(
        itemCount: docs.length,
        itemBuilder: (_, i) {
          final data = docs[i].data();
          return ListTile(
            title: Text((data['name'] ?? 'Без имени').toString()),
            subtitle: Text('id: ${docs[i].id}'),
          );
        },
      );
    },
  ),
),

          ],
        ),
      ),
    );
  }

  // ---------- dialog "Create group" ----------

  void _showAddGroupDialog(BuildContext context) {
    final nameController = TextEditingController();
    String? selectedAvatar;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text(
            'Create group',
            style: TextStyle(
              fontSize: fontSize20,
              fontWeight: FontWeight.w600,
              color: textMainColor,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group name',
                    labelStyle: TextStyle(color: textHintColor),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: buttonBackgroundColor),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: height20),

                const Text(
                  'Choose avatar',
                  style: TextStyle(
                    fontSize: fontSize16,
                    fontWeight: FontWeight.w500,
                    color: textMainColor,
                  ),
                ),
                const SizedBox(height: height12),

                GestureDetector(
                  onTap: () async {
                    final chosen = await showAvatarPicker(context);
                    if (chosen != null) {
                      setState(() => selectedAvatar = chosen);
                    }
                  },
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: selectedAvatar == null
                        ? const Icon(Icons.add_a_photo, color: textHintColor)
                        : avatarSvg(selectedAvatar!, size: 48),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: textHintColor),
              ),
            ),
            ElevatedButton(
              onPressed:
                  (nameController.text.isNotEmpty && selectedAvatar != null)
                  ? () async {
                      final currentUser = FirebaseAuth.instance.currentUser;

                      if (currentUser == null) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please sign in to create a group'),
                            backgroundColor: errorColor,
                          ),
                        );
                        return;
                      }

                      try {
                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser.uid)
                            .get();

                        final userData = userDoc.data() ?? {};
                        final userName =
                            (userData['name'] ??
                                    userData['displayName'] ??
                                    currentUser.email?.split('@').first ??
                                    'User')
                                .toString();
                        final userAvatar = _extractPhoto(userData);

                        final repo = ref.read(groupsRepositoryProvider);

                        final groupId = await repo.createGroup(
                          GroupCreateParams(
                            ownerId: currentUser.uid,
                            name: nameController.text.trim(),
                            avatarUrl: selectedAvatar!,
                          ),
                        );

                        await repo.addMemberToGroup(
                          groupId: groupId,
                          userId: currentUser.uid,
                          // можно расширить: userName, userAvatar
                        );

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Group created successfully'),
                            backgroundColor: buttonBackgroundColor,
                          ),
                        );
                      } catch (e) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to create group: $e'),
                            backgroundColor: errorColor,
                          ),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonBackgroundColor,
                foregroundColor: textMainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius8),
                ),
              ),
              child: const Text('Create'),
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
