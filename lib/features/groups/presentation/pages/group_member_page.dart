import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/avatars.dart';

import 'package:offroad_nav/features/groups/domain/entities/group.dart';
import 'package:offroad_nav/features/groups/domain/entities/member.dart';
import 'package:offroad_nav/features/groups/application/providers/groups_providers.dart';
import 'package:offroad_nav/features/groups/presentation/pages/add_member_dialog.dart';

class GroupMembersPage extends ConsumerStatefulWidget {
  const GroupMembersPage({
    super.key,
    required this.group,
    required this.currentUserId,
    required this.hasFriends,
  });

  final Group group;
  final String? currentUserId;
  final bool hasFriends;

  @override
  ConsumerState<GroupMembersPage> createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends ConsumerState<GroupMembersPage> {
  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final isLeader = widget.currentUserId == group.ownerId;

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: AppBar(
        backgroundColor: backgroundMainColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textMainColor),
        title: const Text(
          'Members',
          style: TextStyle(
            color: textMainColor,
            fontSize: fontSize18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (isLeader)
            IconButton(
              onPressed:
                  widget.hasFriends ? () => _showAddMemberDialog(group) : null,
              icon: Icon(
                Icons.person_add,
                color: widget.hasFriends ? textMainColor : textHintColor,
              ),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
              final isCurrentUser = member.id == widget.currentUserId;
              final isMemberLeader = member.id == group.ownerId;

              return Container(
                margin: const EdgeInsets.only(bottom: height12),
                padding: const EdgeInsets.all(padding12),
                decoration: BoxDecoration(
                  color: surfaceColor,
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
            name: member.name,
            avatarUrl: member.avatarUrl,
          );
        },
      ),
    );
  }

  Future<void> _removeMemberFromFirestore(Group group, Member member) async {
    final repo = ref.read(groupsRepositoryProvider);
    await repo.removeMemberFromGroup(group.id, member.id);

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
              final currentUserId = widget.currentUserId;
              if (currentUserId == null) return;

              final repo = ref.read(groupsRepositoryProvider);
              await repo.removeMemberFromGroup(group.id, currentUserId);

              if (mounted) {
                Navigator.pop(context); // back to group details
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
}
