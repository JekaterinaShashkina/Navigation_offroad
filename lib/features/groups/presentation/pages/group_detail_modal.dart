import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';

import 'package:offroad_nav/features/groups/domain/entities/group.dart';
import 'package:offroad_nav/features/groups/domain/entities/member.dart';
import 'package:offroad_nav/features/groups/presentation/widgets/friends_list_for_group.dart';

class GroupDetailModal extends StatefulWidget {
  final Group group;
  final VoidCallback? onGroupUpdated;

  const GroupDetailModal({
    super.key,
    required this.group,
    this.onGroupUpdated,
  });

  @override
  State<GroupDetailModal> createState() => _GroupDetailModalState();
}

class _GroupDetailModalState extends State<GroupDetailModal> {
  late Group _currentGroup;

  @override
  void initState() {
    super.initState();
    _currentGroup = widget.group;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          _buildHeader(context),
          _buildActionsRow(context),
          const SizedBox(height: height8),
          Expanded(child: _buildMembersList()),
        ],
      ),
    );
  }

  // ---------- UI parts ----------

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(padding20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: listShadowColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: _buildGroupAvatar(_currentGroup.avatarUrl),
          ),
          const SizedBox(width: width16),
          Expanded(
            child: Text(
              _currentGroup.name,
              style: const TextStyle(
                fontSize: fontSize20,
                fontWeight: FontWeight.w600,
                color: textMainColor,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: textMainColor),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(padding20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.chat,
            label: 'Chat',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Group chat is not implemented yet'),
                  backgroundColor: buttonBackgroundColor,
                ),
              );
            },
          ),
          _ActionButton(
            icon: Icons.person_add,
            label: 'Add member',
            onTap: () => _showAddMemberBottomSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(_currentGroup.id)
          .collection('members')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
              'No members in the group yet',
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
          itemBuilder: (context, index) {
            final member = members[index];
            return _MemberTile(
              member: member,
              onDelete: () => _showDeleteMemberDialog(member),
              onChat: () => _showChatDialog(member),
            );
          },
        );
      },
    );
  }

  // ---------- helpers ----------

  Widget _buildGroupAvatar(String? url) {
    final path = (url ?? '').trim();
    if (path.isEmpty) {
      return Image.asset(
        'assets/images/group.png',
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      );
    }
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      );
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/group.png',
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      'assets/images/group.png',
      width: 50,
      height: 50,
      fit: BoxFit.cover,
    );
  }

  // ---------- add / delete member ----------

  void _showAddMemberBottomSheet(BuildContext context) {
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
        child: FriendsListForGroup(
          onFriendSelected: (friend) async {
            Navigator.pop(context);

            await FirebaseFirestore.instance
                .collection('groups')
                .doc(_currentGroup.id)
                .collection('members')
                .doc(friend.uid)
                .set({
              'user_id': friend.uid,
              'name': friend.name,
              'avatar_url': friend.photo,
              'created_at': FieldValue.serverTimestamp(),
            });

            widget.onGroupUpdated?.call();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${friend.name} added to the group'),
                backgroundColor: buttonBackgroundColor,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDeleteMemberDialog(Member member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove member'),
        content: Text('Remove ${member.name} from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('groups')
                  .doc(_currentGroup.id)
                  .collection('members')
                  .doc(member.id)
                  .delete();

              widget.onGroupUpdated?.call();

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

  void _showChatDialog(Member member) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Member chat is not implemented yet'),
        backgroundColor: buttonBackgroundColor,
      ),
    );
  }
}

// ---------- small helper widgets ----------

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: buttonBackgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: listShadowColor,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: textMainColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: fontSize12,
                fontWeight: FontWeight.w500,
                color: textMainColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Member member;
  final VoidCallback onDelete;
  final VoidCallback onChat;

  const _MemberTile({
    required this.member,
    required this.onDelete,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: height12),
      padding: const EdgeInsets.all(padding12),
      decoration: BoxDecoration(
        color: backgroundMainColor,
        borderRadius: BorderRadius.circular(radius12),
        border: Border.all(color: listShadowColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: _buildAvatar(member.avatarUrl),
          ),
          const SizedBox(width: width16),
          Expanded(
            child: Text(
              member.name,
              style: const TextStyle(
                fontSize: fontSize16,
                fontWeight: FontWeight.w500,
                color: textMainColor,
              ),
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: buttonBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: onChat,
              icon: const Icon(Icons.chat, color: textMainColor, size: 16),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: errorColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.close, color: surfaceColor, size: 16),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url) {
    final v = (url ?? '').trim();
    if (v.isEmpty) {
      return const Icon(Icons.person, size: 40, color: textHintColor);
    }
    if (v.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(v, width: 40, height: 40);
    }
    if (v.startsWith('http')) {
      return Image.network(
        v,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.person, size: 40, color: textHintColor),
      );
    }
    return const Icon(Icons.person, size: 40, color: textHintColor);
  }
}
