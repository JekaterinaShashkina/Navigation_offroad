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
                      ? () => _showGeneralSettingsDialog()
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
                _buildChatSection(),
                _buildGroupManagementSection(group),
              ],
            ),
          );
        },
      ),
    );
  }


  // ---------- sections ----------

  Widget _buildSection({
    required String title,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: padding16,
        vertical: padding8,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(radius12),
        border: Border.all(color: listShadowColor, width: 1),
      ),
      child: ListTile(
        leading:
            Icon(icon, color: onTap != null ? textMainColor : textHintColor),
        title: Text(
          title,
          style: TextStyle(
            fontSize: fontSize16,
            fontWeight: FontWeight.w500,
            color: onTap != null ? textMainColor : textHintColor,
          ),
        ),
        trailing: onTap != null
            ? const Icon(Icons.arrow_forward_ios,
                size: 16, color: textHintColor)
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildChatSection() {
    return _buildSection(
      title: 'Chat',
      icon: Icons.chat,
      onTap: _openChat,
    );
  }

  Widget _buildGroupManagementSection(Group group) {
    return _buildSection(
      title: 'Group Management',
      icon: Icons.group_work,
      onTap: () => _showGroupManagementDialog(group),
    );
  }

  // ---------- dialogs / actions ----------

  void _showGeneralSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('General Settings'),
        content: Text(
          'Edit group name and avatar functionality will be implemented later.',
        ),
      ),
    );
  }

  void _leaveGroup(Group group) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_currentUserId == null) return;
              final repo = ref.read(groupsRepositoryProvider);
              await repo.removeMemberFromGroup(
                group.id,
                _currentUserId!,
              );
              if (mounted) {
                Navigator.pop(context); // back to groups list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You left the group'),
                    backgroundColor: buttonBackgroundColor,
                  ),
                );
              }
            },
            child: const Text('Leave', style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
  }

  // ---------- chat / management ----------

  void _openChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Group chat functionality will be implemented'),
        backgroundColor: buttonBackgroundColor,
      ),
    );
  }

  void _showGroupManagementDialog(Group group) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Group Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLeader(group))
              ListTile(
                leading: const Icon(Icons.delete, color: errorColor),
                title: const Text(
                  'Delete Group',
                  style: TextStyle(color: errorColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteGroupDialog(group);
                },
              ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: errorColor),
              title: const Text(
                'Leave Group',
                style: TextStyle(color: errorColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _leaveGroup(group);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDeleteGroupDialog(Group group) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final repo = ref.read(groupsRepositoryProvider);
              await repo.deleteGroup(group.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Group deleted'),
                    backgroundColor: errorColor,
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: errorColor),
            ),
          ),
        ],
      ),
    );
  }
}