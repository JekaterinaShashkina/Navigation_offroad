import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';

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
  String? _leaderName;
  bool _loadingLeader = true;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid;
    _checkFriends();
    _loadLeaderName();
  }

  Future<void> _loadLeaderName() async {
  try {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.group.ownerId) // или group.ownerId, как у тебя называется
        .get();

    final name = snap.data()?['name'] ?? 'Unknown';

    if (mounted) {
      setState(() {
        _leaderName = name;
        _loadingLeader = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _leaderName = 'Unknown';
        _loadingLeader = false;
      });
    }
  }
}

  Future<void> _checkFriends() async {
    if (_currentUserId == null) return;
    final hasFriends = await _friendsRepository.hasFriends(_currentUserId!);
    if (!mounted) return;
    setState(() => _hasFriends = hasFriends);
  }

  bool _isLeader(Group g) =>
      _currentUserId != null && g.ownerId == _currentUserId;

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(myGroupsProvider);

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
      body: groupsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => const Center(
          child: Text(
            'Failed to load group',
            style: TextStyle(color: errorColor),
          ),
        ),
        data: (groups) {
          final group = groups.firstWhere(
            (g) => g.id == widget.group.id,
            orElse: () => widget.group,
          );

          return SingleChildScrollView(
            child: Column(
              children: [
                GroupHeader(group: group, isLeader: _isLeader(group), leaderName: _leaderName??'Loading',),
                GroupMenuSection(
                  title: 'General Settings',
                  icon: Icons.settings,
                  onTap: _isLeader(group)
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupGeneralSettingsPage(
                          group: group,
                        ),
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
                  icon: Icons.route,
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
                  icon: Icons.route,
                  onTap: () => _showGroupManagement(group)
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