import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/features/groups/data/repositories/groups_repository.dart';

import 'package:offroad_nav/features/groups/domain/entities/group.dart';
import 'package:offroad_nav/features/groups/application/providers/groups_providers.dart';

import 'package:offroad_nav/features/friends/data/repositories/friends_repository.dart';
import 'package:offroad_nav/features/groups/presentation/pages/group_chat_page.dart';
import 'package:offroad_nav/features/groups/presentation/pages/group_general_settings_page.dart';
import 'package:offroad_nav/features/groups/presentation/pages/group_management_dialog.dart';
import 'package:offroad_nav/features/groups/presentation/pages/group_member_page.dart';
import 'package:offroad_nav/features/groups/presentation/pages/group_routes_page.dart';
import 'package:offroad_nav/features/groups/presentation/widgets/group_header.dart';
import 'package:offroad_nav/features/groups/presentation/widgets/group_menu_section.dart';

class GroupDetailPage extends ConsumerStatefulWidget {
  final Group group;

  const GroupDetailPage({
    super.key,
    required this.group,
  });

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage> {
  final FriendsRepository _friendsRepository = FriendsRepository();

  String? _currentUserId;
  bool _hasFriends = false;

  // leader info
  String? _leaderName;
  bool _loadingLeader = false;
  String? _leaderOwnerIdLoaded; // чтобы отслеживать смену ownerId

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid;
    _checkFriends();
  }

  Future<void> _checkFriends() async {
    if (_currentUserId == null) return;
    final hasFriends = await _friendsRepository.hasFriends(_currentUserId!);
    if (!mounted) return;
    setState(() => _hasFriends = hasFriends);
  }

  bool _isLeader(Group g) => _currentUserId != null && g.ownerId == _currentUserId;

  Future<void> _loadLeaderName(String ownerId) async {
    setState(() {
      _loadingLeader = true;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .get();

      final name = snap.data()?['name'] ?? 'Unknown';

      if (!mounted) return;
      setState(() {
        _leaderName = name;
        _loadingLeader = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _leaderName = 'Unknown';
        _loadingLeader = false;
      });
    }
  }

  void _ensureLeaderLoaded(String ownerId) {
    // если ownerId поменялся — надо перезагрузить лидера
    if (_leaderOwnerIdLoaded != ownerId) {
      _leaderOwnerIdLoaded = ownerId;
      _leaderName = null;

      // дергаем после кадра, чтобы не запускать async прямо в build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadLeaderName(ownerId);
      });
      return;
    }

    // ownerId тот же, но имя ещё не загружено
    if (_leaderName == null && !_loadingLeader) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadLeaderName(ownerId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupProvider(widget.group.id));

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        titleWidget: const Text(
          'Group Details',
          style: TextStyle(
            fontSize: fontSize20,
            fontWeight: FontWeight.w600,
            color: textMainColor,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      body: groupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => const Center(
          child: Text('Failed to load group', style: TextStyle(color: errorColor)),
        ),
        data: (group) {
          if (group == null) {
            return const Center(
              child: Text('Group not found', style: TextStyle(color: textHintColor)),
            );
          }

          // ✅ лидер всегда актуален
          _ensureLeaderLoaded(group.ownerId);

          final isLeader = _isLeader(group);

          return SingleChildScrollView(
            child: Column(
              children: [
                GroupHeader(
                  group: group,
                  isLeader: isLeader,
                  leaderName: _leaderName ?? (_loadingLeader ? 'Loading...' : 'Unknown'),
                ),

                GroupMenuSection(
                  title: 'General Settings',
                  icon: Icons.settings,
                  onTap: isLeader
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GroupGeneralSettingsPage(group: group),
                            ),
                          );
                        }
                      : null,
                ),

                GroupMenuSection(
                  title: 'Members',
                  icon: Icons.people,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupMembersPage(
                          group: group,
                          currentUserId: _currentUserId,
                          hasFriends: _hasFriends,
                        ),
                      ),
                    );
                  },
                ),

                GroupMenuSection(
                  title: 'Route',
                  icon: Icons.route,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupRoutesPage(group: group),
                      ),
                    );
                  },
                ),

                GroupMenuSection(
                  title: 'Chat',
                  icon: Icons.chat_bubble_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupChatPage(group: group),
                      ),
                    );
                  },
                ),

                GroupMenuSection(
                  title: 'Group Management',
                  icon: Icons.admin_panel_settings_outlined,
                  onTap: () => _showGroupManagement(group),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showGroupManagement(Group group) {
    showGroupManagementDialog(
      context: context,
      ref: ref,
      group: group,
      isLeader: _isLeader(group),
      onLeaveGroup: () => _leaveGroup(group),
    );
  }

  Future<void> _leaveGroup(Group group) async {
    if (_currentUserId == null) return;

    final repo = ref.read(groupsRepositoryProvider);

    await repo.removeMemberFromGroup(
      group.id,
      _currentUserId!,
    );

    if (!mounted) return;

    Navigator.pop(context); // back to groups list
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You left the group'),
        backgroundColor: buttonBackgroundColor,
      ),
    );
  }
}
