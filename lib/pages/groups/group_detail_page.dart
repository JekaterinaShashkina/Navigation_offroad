import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/models/group.dart';
import 'package:offroad_nav/services/groups_repository.dart';
import 'package:offroad_nav/features/friends/data/repositories/friends_repository.dart';
import 'package:offroad_nav/pages/groups/add_member_dialog.dart';
import 'package:offroad_nav/features/routes/presentation/pages/route_detail_page.dart';

class GroupDetailPage extends StatefulWidget {
  final Group group;

  const GroupDetailPage({
    super.key,
    required this.group,
  });

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final GroupsRepository _groupsRepository = GroupsRepository();
  final FriendsRepository _friendsRepository = FriendsRepository();
  late Group _currentGroup;
  String? _currentUserId;
  bool _hasFriends = false;

  @override
  void initState() {
    super.initState();
    _currentGroup = widget.group;
    _getCurrentUser();
    _checkFriends();
    
    // Listen to group changes
    _groupsRepository.groupsStream.listen((groups) {
      if (mounted) {
        final updatedGroup = _groupsRepository.getGroupById(_currentGroup.id);
        if (updatedGroup != null) {
          setState(() {
            _currentGroup = updatedGroup;
          });
        }
      }
    });
  }

  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid;
  }

  Future<void> _checkFriends() async {
    if (_currentUserId != null) {
      final hasFriends = await _friendsRepository.hasFriends(_currentUserId!);
      if (mounted) {
        setState(() {
          _hasFriends = hasFriends;
        });
      }
    }
  }

  bool get _isLeader => _currentUserId != null && _currentGroup.isLeader(_currentUserId!);
  bool get _isMember => _currentUserId != null &&
      _currentGroup.members.any((m) => m.id == _currentUserId);

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Group Header
            _buildGroupHeader(),
            
            // Profile-style sections
            _buildGeneralSettingsSection(),
            _buildMembersSection(),
            _buildRouteSection(),
            _buildChatSection(),
            _buildGroupManagementSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader() {
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
          // Group Avatar
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              _currentGroup.avatarUrl,
              width: 100,
              height: 100,
            ),
          ),
          
          const SizedBox(height: height16),
          
          // Group Name and Leader Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _currentGroup.name,
                style: const TextStyle(
                  fontSize: fontSize22,
                  fontWeight: FontWeight.w600,
                  color: textMainColor,
                ),
              ),
              if (_isLeader) ...[
                const SizedBox(width: width2),
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

  Widget _buildGeneralSettingsSection() {
    return _buildSection(
      title: 'General Settings',
      icon: Icons.settings,
      onTap: _isLeader ? _showGeneralSettingsDialog : null,
    );
  }

  Widget _buildMembersSection() {
    return _buildSection(
      title: 'Members',
      icon: Icons.people,
      onTap: () => _showMembersDialog(),
    );
  }

  Widget _buildRouteSection() {
    return _buildSection(
      title: 'Route',
      icon: Icons.route,
      onTap: () => _openRoutesBottomSheet(),
    );
  }

  Widget _buildChatSection() {
    return _buildSection(
      title: 'Chat',
      icon: Icons.chat,
      onTap: () => _openChat(),
    );
  }

  Widget _buildGroupManagementSection() {
    return _buildSection(
      title: 'Group Management',
      icon: Icons.group_work,
      onTap: () => _showGroupManagementDialog(),
    );
  }

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
        border: Border.all(
          color: listShadowColor,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: onTap != null ? textMainColor : textHintColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: fontSize16,
            fontWeight: FontWeight.w500,
            color: onTap != null ? textMainColor : textHintColor,
          ),
        ),
        trailing: onTap != null
            ? const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: textHintColor,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  void _showGeneralSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('General Settings'),
        content: const Text('Edit group name and avatar functionality will be implemented later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMembersDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radius20),
            topRight: Radius.circular(radius20),
          ),
        ),
        child: Column(
          children: [
            // Header
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
                  if (_isLeader)
                    IconButton(
                      onPressed: _hasFriends ? () => _showAddMemberDialog() : null,
                      icon: Icon(
                        Icons.person_add,
                        color: _hasFriends ? textMainColor : textHintColor,
                      ),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: textMainColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Members List
            Expanded(
              child: _currentGroup.members.isEmpty
                  ? const Center(
                      child: Text(
                        'Only you are in the group so far',
                        style: TextStyle(
                          fontSize: fontSize16,
                          color: textHintColor,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(padding16),
                      itemCount: _currentGroup.members.length,
                      itemBuilder: (context, index) {
                        final member = _currentGroup.members[index];
                        final isCurrentUser = member.id == _currentUserId;
                        final isMemberLeader = member.id == _currentGroup.leaderId;
                        
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
                              // Member Avatar
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                                    ? (member.avatarUrl!.endsWith('.svg')
                                        ? SvgPicture.asset(
                                            member.avatarUrl!,
                                            width: 40,
                                            height: 40,
                                          )
                                        : Image.network(
                                            member.avatarUrl!,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(
                                              Icons.person,
                                              size: 40,
                                              color: textHintColor,
                                            ),
                                          ))
                                    : const Icon(
                                        Icons.person,
                                        size: 40,
                                        color: textHintColor,
                                      ),
                              ),
                              
                              const SizedBox(width: width16),
                              
                              // Member Name and Badges
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
                                          const SizedBox(width: width2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: padding6,
                                              vertical: padding6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: buttonBackgroundColor,
                                              borderRadius: BorderRadius.circular(radius8),
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
                              
                              // Action Buttons
                              if (_isLeader && !isMemberLeader)
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: errorColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: () => _removeMember(member),
                                    icon: const Icon(
                                      Icons.close,
                                      color: surfaceColor,
                                      size: 16,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                )
                              else if (isCurrentUser && !isMemberLeader)
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: errorColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: () => _leaveGroup(),
                                    icon: const Icon(
                                      Icons.exit_to_app,
                                      color: surfaceColor,
                                      size: 16,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => AddMemberDialog(
        group: _currentGroup,
        onMemberAdded: (member) {
          _groupsRepository.addMemberToGroup(_currentGroup.id, member);
          setState(() {
            _currentGroup = _groupsRepository.getGroupById(_currentGroup.id) ?? _currentGroup;
          });
        },
      ),
    );
  }

  void _removeMember(Member member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove ${member.name} from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _groupsRepository.removeMemberFromGroup(_currentGroup.id, member.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${member.name} removed from the group'),
                  backgroundColor: errorColor,
                ),
              );
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: errorColor),
            ),
          ),
        ],
      ),
    );
  }

  void _leaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_currentUserId != null) {
                _groupsRepository.removeMemberFromGroup(_currentGroup.id, _currentUserId!);
                Navigator.pop(context); // Go back to groups list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You left the group'),
                    backgroundColor: buttonBackgroundColor,
                  ),
                );
              }
            },
            child: const Text(
              'Leave',
              style: TextStyle(color: errorColor),
            ),
          ),
        ],
      ),
    );
  }

  void _openActiveRoute() {
    // TODO: open RouteDetailPage for _currentGroup.activeRouteId
    final routeId = _currentGroup.activeRouteId;
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
      final doc = await FirebaseFirestore.instance.collection('routes').doc(routeId).get();
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
          builder: (context) => RouteDetailPage(name: name, points: points),
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

  void _openRoutesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RoutesSelector(
        activeRouteId: _currentGroup.activeRouteId,
        isLeader: _isLeader,
        onOpen: (routeId) {
          Navigator.pop(context);
          _openRouteById(routeId);
        },
        onSelect: (routeId) {
          if (_isLeader) {
            _groupsRepository.setActiveRoute(_currentGroup.id, routeId);
            setState(() {
              _currentGroup = _groupsRepository.getGroupById(_currentGroup.id) ?? _currentGroup;
            });
          }
        },
      ),
    );
  }

  void _openChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Group chat functionality will be implemented'),
        backgroundColor: buttonBackgroundColor,
      ),
    );
  }

  void _showGroupManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Group Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isMember)
              ListTile(
                leading: const Icon(Icons.group_add, color: buttonBackgroundColor),
                title: const Text('Join group'),
                onTap: () async {
                  Navigator.pop(context);
                  await _joinGroup();
                },
              ),
            if (_isLeader)
              ListTile(
                leading: const Icon(Icons.delete, color: errorColor),
                title: const Text(
                  'Delete Group',
                  style: TextStyle(color: errorColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteGroupDialog();
                },
              ),
            if (_isMember)
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: errorColor),
                title: const Text(
                  'Leave Group',
                  style: TextStyle(color: errorColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _leaveGroup();
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

  Future<void> _joinGroup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String name = user.email?.split('@').first ?? 'User';
    String photo = '';
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = snap.data() ?? <String, dynamic>{};
      name = (data['name'] ?? data['displayName'] ?? name).toString();
      photo = _extractPhoto(data);
    } catch (_) {}

    final member = Member(id: user.uid, name: name, avatarUrl: photo);
    _groupsRepository.addMemberToGroup(_currentGroup.id, member);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Joined the group'), backgroundColor: buttonBackgroundColor),
    );
  }

  String _extractPhoto(Map<String, dynamic> user) {
    final candidates = [user['img'], user['photoUrl'], user['photoURL'], user['avatar'], user['photo'], user['imageUrl']];
    for (final v in candidates) {
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  void _showDeleteGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text('Are you sure you want to delete this group? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _groupsRepository.removeGroup(_currentGroup.id);
              Navigator.pop(context); // Go back to groups list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Group deleted'),
                  backgroundColor: errorColor,
                ),
              );
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
          // Header
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

          // Routes list from Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('routes')
                  .where('isPrivate', isEqualTo: false)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final data = d.data();
                    final name = (data['name'] ?? 'Unnamed').toString();
                    final isActive = (activeRouteId == d.id);
                    return GestureDetector(
                      onTap: () => onOpen(d.id),
                      child: Container(
                        padding: const EdgeInsets.all(padding12),
                        decoration: BoxDecoration(
                          color: backgroundMainColor,
                          borderRadius: BorderRadius.circular(radius12),
                          border: Border.all(color: isActive ? buttonBackgroundColor : listShadowColor, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.route, color: textMainColor),
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
                                  backgroundColor: buttonBackgroundColor,
                                  foregroundColor: textMainColor,
                                ),
                                child: const Text('Open'),
                              )
                            else if (isLeader)
                              ElevatedButton(
                                onPressed: () => onSelect(d.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonBackgroundColor,
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