import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/avatars.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';

import 'package:offroad_nav/features/groups/domain/entities/group.dart';
import 'package:offroad_nav/features/groups/domain/entities/member.dart';
import 'package:offroad_nav/features/groups/application/providers/groups_providers.dart';

import 'package:offroad_nav/features/friends/data/repositories/friends_repository.dart';
import 'package:offroad_nav/features/groups/presentation/pages/add_member_dialog.dart';
import 'package:offroad_nav/features/routes/presentation/pages/route_detail_page.dart';

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
                _buildGroupHeader(group),
                _buildSection(
                  title: 'General Settings',
                  icon: Icons.settings,
                  onTap: _isLeader(group)
                      ? () => _showGeneralSettingsDialog()
                      : null,
                ),
                _buildMembersSection(group),
                _buildRouteSection(group),
                _buildChatSection(),
                _buildGroupManagementSection(group),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------- header ----------

  Widget _buildGroupHeader(Group group) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(padding20),
      decoration: const BoxDecoration(
        color: surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: listShadowColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // avatar
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: (group.avatarUrl != null &&
                    group.avatarUrl!.trim().isNotEmpty)
                ? ClipOval(child: avatarSvg(group.avatarUrl!, size: 100))
                : const CircleAvatar(
                    radius: 50,
                    backgroundColor: backgroundMainColor,
                    child: Icon(Icons.group, size: 40, color: textHintColor),
                  ),
          ),
          const SizedBox(height: height16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                group.name,
                style: const TextStyle(
                  fontSize: fontSize22,
                  fontWeight: FontWeight.w600,
                  color: textMainColor,
                ),
              ),
              if (_isLeader(group)) ...[
                const SizedBox(width: width8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: padding8,
                    vertical: padding6,
                  ),
                  decoration: BoxDecoration(
                    color: buttonBackgroundColor,
                    borderRadius: BorderRadius.circular(radius12),
                  ),
                  child: const Text(
                    'Leader',
                    style: TextStyle(
                      fontSize: fontSize12,
                      fontWeight: FontWeight.w500,
                      color: textMainColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
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

  Widget _buildMembersSection(Group group) {
    return _buildSection(
      title: 'Members',
      icon: Icons.people,
      onTap: () => _showMembersBottomSheet(group),
    );
  }

  Widget _buildRouteSection(Group group) {
    return _buildSection(
      title: 'Route',
      icon: Icons.route,
      onTap: () => _openRoutesBottomSheet(group),
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

  /// ЧТО МЕНЯЕМ СИЛЬНЕЕ ВСЕГО: список участников теперь из подколлекции Firestore
  void _showMembersBottomSheet(Group group) {
    final isLeader = _isLeader(group);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: const BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radius20),
            topRight: Radius.circular(radius20),
          ),
        ),
        child: Column(
          children: [
            // header
            Container(
              padding: const EdgeInsets.all(padding20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: listShadowColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Members',
                    style: TextStyle(
                      fontSize: fontSize20,
                      fontWeight: FontWeight.w600,
                      color: textMainColor,
                    ),
                  ),
                  if (isLeader)
                    IconButton(
                      onPressed:
                          _hasFriends ? () => _showAddMemberDialog(group) : null,
                      icon: Icon(
                        Icons.person_add,
                        color: _hasFriends ? textMainColor : textHintColor,
                      ),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: textMainColor),
                  ),
                ],
              ),
            ),

            // members list from Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(group.id)
                    .collection('members')
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load members: ${snap.error}',
                        style: const TextStyle(color: errorColor),
                      ),
                    );
                  }

                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Only you are in the group so far',
                        style: TextStyle(
                          fontSize: fontSize16,
                          color: textHintColor,
                        ),
                      ),
                    );
                  }

                  final members = docs.map((d) {
                    final data = d.data();
                    return Member(
                      id: data['user_id'] as String? ?? d.id,
                      name: (data['name'] ?? 'User').toString(),
                      avatarUrl: data['avatar_url'] as String?,
                    );
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.all(padding16),
                    itemCount: members.length,
                    itemBuilder: (_, index) {
                      final member = members[index];
                      final isCurrentUser = member.id == _currentUserId;
                      final isMemberLeader = member.id == group.ownerId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: height12),
                        padding: const EdgeInsets.all(padding12),
                        decoration: BoxDecoration(
                          color: backgroundMainColor,
                          borderRadius: BorderRadius.circular(radius12),
                          border: Border.all(
                            color: listShadowColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // avatar
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: backgroundMainColor,
                              child: (member.avatarUrl != null &&
                                      member.avatarUrl!.isNotEmpty &&
                                      member.avatarUrl!.endsWith('.svg'))
                                  ? avatarSvg(member.avatarUrl!, size: 40)
                                  : const Icon(
                                      Icons.person,
                                      size: 24,
                                      color: textHintColor,
                                    ),
                            ),
                            const SizedBox(width: width16),

                            // name + badges
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        member.name,
                                        style: const TextStyle(
                                          fontSize: fontSize16,
                                          fontWeight: FontWeight.w500,
                                          color: textMainColor,
                                        ),
                                      ),
                                      if (isMemberLeader) ...[
                                        const SizedBox(width: width4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: padding6,
                                            vertical: padding6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: buttonBackgroundColor,
                                            borderRadius:
                                                BorderRadius.circular(radius8),
                                          ),
                                          child: const Text(
                                            'Leader',
                                            style: TextStyle(
                                              fontSize: fontSize12,
                                              fontWeight: FontWeight.w500,
                                              color: textMainColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (isCurrentUser)
                                    const Text(
                                      'You',
                                      style: TextStyle(
                                        fontSize: fontSize12,
                                        color: textHintColor,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // actions
                            if (isLeader && !isMemberLeader)
                              _circleIconButton(
                                color: errorColor,
                                icon: Icons.close,
                                onPressed: () =>
                                    _removeMemberFromFirestore(group, member),
                              )
                            else if (isCurrentUser && !isMemberLeader)
                              _circleIconButton(
                                color: errorColor,
                                icon: Icons.exit_to_app,
                                onPressed: () => _leaveGroup(group),
                              ),
                          ],
                        ),
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

  Widget _circleIconButton({
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, color: surfaceColor, size: 16),
      ),
    );
  }

  void _showAddMemberDialog(Group group) {
    showDialog(
      context: context,
      builder: (_) => AddMemberDialog(
        group: group,
        onMemberAdded: (member) async {
          final repo = ref.read(groupsRepositoryProvider);
          await repo.addMemberToGroup(
            groupId: group.id,
            userId: member.id,
            userName: member.name,
            userAvatar: member.avatarUrl,
          );
        },
      ),
    );
  }

  Future<void> _removeMemberFromFirestore(Group group, Member member) async {
    final repo = ref.read(groupsRepositoryProvider);
    await repo.removeMemberFromGroup(
      group.id,
      member.id,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${member.name} removed from the group'),
        backgroundColor: errorColor,
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

  // ---------- routes ----------

  void _openActiveRoute(Group group) {
    final routeId = group.routeId;
    if (routeId == null || routeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active route selected'),
          backgroundColor: buttonBackgroundColor,
        ),
      );
      return;
    }
    _openRouteById(routeId);
  }

  Future<void> _openRouteById(String routeId) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('routes').doc(routeId).get();
      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route not found'),
            backgroundColor: errorColor,
          ),
        );
        return;
      }
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? 'Route').toString();
      final points = (data['points'] ?? []) as List<dynamic>;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RouteDetailPage(name: name, points: points),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening route: $e'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  void _openRoutesBottomSheet(Group group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoutesSelector(
        activeRouteId: group.routeId,
        isLeader: _isLeader(group),
        onOpen: (routeId) {
          Navigator.pop(context);
          _openRouteById(routeId);
        },
        onSelect: (routeId) async {
          if (!_isLeader(group)) return;
          final repo = ref.read(groupsRepositoryProvider);
          await repo.setActiveRoute(
            group.id,
            routeId,
          );
        },
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

// ---------- Routes selector ----------

class _RoutesSelector extends StatelessWidget {
  final String? activeRouteId;
  final bool isLeader;
  final void Function(String routeId) onOpen;
  final void Function(String routeId) onSelect;

  const _RoutesSelector({
    required this.activeRouteId,
    required this.isLeader,
    required this.onOpen,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radius20),
          topRight: Radius.circular(radius20),
        ),
      ),
      child: Column(
        children: [
          // header
          Container(
            padding: const EdgeInsets.all(padding20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: listShadowColor, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Routes',
                  style: TextStyle(
                    fontSize: fontSize20,
                    fontWeight: FontWeight.w600,
                    color: textMainColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: textMainColor),
                ),
              ],
            ),
          ),

          if (activeRouteId != null)
            Container(
              margin: const EdgeInsets.all(padding16),
              padding: const EdgeInsets.all(padding12),
              decoration: BoxDecoration(
                color: backgroundMainColor,
                borderRadius: BorderRadius.circular(radius12),
                border: Border.all(color: listShadowColor, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: buttonBackgroundColor),
                  const SizedBox(width: width16),
                  const Expanded(
                    child: Text(
                      'Active route',
                      style: TextStyle(
                        fontSize: fontSize16,
                        fontWeight: FontWeight.w500,
                        color: textMainColor,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => onOpen(activeRouteId!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonBackgroundColor,
                      foregroundColor: textMainColor,
                    ),
                    child: const Text('Open'),
                  ),
                ],
              ),
            ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('routes')
                  .where('isPrivate', isEqualTo: false)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No routes found'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(padding16),
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final data = d.data();
                    final name =
                        (data['name'] ?? 'Unnamed').toString();
                    final isActive = activeRouteId == d.id;

                    return GestureDetector(
                      onTap: () => onOpen(d.id),
                      child: Container(
                        padding: const EdgeInsets.all(padding12),
                        decoration: BoxDecoration(
                          color: backgroundMainColor,
                          borderRadius:
                              BorderRadius.circular(radius12),
                          border: Border.all(
                            color: isActive
                                ? buttonBackgroundColor
                                : listShadowColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.route,
                                color: textMainColor),
                            const SizedBox(width: width16),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: fontSize16,
                                  color: textMainColor,
                                ),
                              ),
                            ),
                            if (isActive)
                              ElevatedButton(
                                onPressed: () => onOpen(d.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      buttonBackgroundColor,
                                  foregroundColor: textMainColor,
                                ),
                                child: const Text('Open'),
                              )
                            else if (isLeader)
                              ElevatedButton(
                                onPressed: () => onSelect(d.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      buttonBackgroundColor,
                                  foregroundColor: textMainColor,
                                ),
                                child: const Text('Set active'),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
