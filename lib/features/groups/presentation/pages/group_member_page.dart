import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/avatars.dart';
import 'package:offroad_nav/design/widgets/smart_avatar.dart';
import 'package:offroad_nav/features/groups/data/repositories/groups_repository.dart';

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
  if (widget.currentUserId != null)
    StreamBuilder<bool>(
      stream: ref
          .read(groupsRepositoryProvider)
          .watchIsMember(group.id, widget.currentUserId!),
      builder: (context, snap) {
        final isMember = snap.data ?? false;

        // Лидер: плюсик добавления друзей
        if (isLeader) {
          return IconButton(
            onPressed: widget.hasFriends ? () => _showAddMemberDialog(group) : null,
            icon: Icon(
              Icons.person_add,
              color: widget.hasFriends ? textMainColor : textHintColor,
            ),
          );
        }

        // Не лидер и не участник: кнопка Join
        if (!isMember) {
          return IconButton(
            icon: const Icon(Icons.person_add, color: textMainColor), // или Icons.group_add
            onPressed: () async {
              try {
                await ref.read(groupsRepositoryProvider).joinGroup(
                      group.id,
                      // widget.currentUserId!,
                    );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You joined the group')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to join: $e')),
                );
              }
            },
          );
        }

        // Уже участник: ничего не показываем
        return const SizedBox.shrink();
      },
    ),
        ],
      ),
      body: StreamBuilder<List<Member>>(
  stream: ref
      .read(groupsRepositoryProvider)
      .watchMembers(group.id),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (snapshot.hasError) {
      return Center(
        child: Text(
          'Failed to load members',
          style: TextStyle(color: errorColor),
        ),
      );
    }

    final members = snapshot.data ?? const [];

    if (members.isEmpty) {
      return const Center(
        child: Text(
          'No members yet',
          style: TextStyle(color: textHintColor),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(padding16),
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: height12),
      itemBuilder: (context, index) {
        final member = members[index];

        final isOwner = member.userId == group.ownerId;
        final isCurrentUser = member.userId == widget.currentUserId;

        return Container(
          padding: const EdgeInsets.all(padding12),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(radius12),
            border: Border.all(color: listShadowColor),
          ),
          child: Row(
            children: [
              /// 🔹 АВАТАР
              SmartAvatar(
                src: member.img, // assets/...svg или url
                size: 40,
              ),

              const SizedBox(width: width16),

              /// 🔹 ИМЯ + РОЛЬ
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
                        if (isOwner) ...[
                          const SizedBox(width: width8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: padding6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: buttonBackgroundColor,
                              borderRadius: BorderRadius.circular(radius8),
                            ),
                            child: const Text(
                              'Leader',
                              style: TextStyle(
                                fontSize: fontSize12,
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

              /// 🔹 КНОПКИ
              if (isLeader && !isOwner)
                IconButton(
                  icon: const Icon(Icons.close, color: errorColor),
                  onPressed: () {
                    ref
                        .read(groupsRepositoryProvider)
                        .removeMemberFromGroup(group.id, member.userId);
                  },
                )
              else if (isCurrentUser && !isOwner)
                IconButton(
                  icon: const Icon(Icons.exit_to_app, color: errorColor),
                  onPressed: () {
                    final uid = widget.currentUserId;
                    if (uid == null) return;
                    ref
                        .read(groupsRepositoryProvider)
                        .removeMemberFromGroup(group.id, uid);
                  },
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
      onMemberAdded: (userId) async {
        try {
          await ref.read(groupsRepositoryProvider).addMemberToGroup(
            groupId: group.id,
            userId: userId,
          );

          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Участник добавлен')),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      },
    ),
  );
}


  Future<void> _removeMemberFromFirestore(Group group, Member member) async {
    final repo = ref.read(groupsRepositoryProvider);
    await repo.removeMemberFromGroup(group.id, member.userId);

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
