import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/models/group.dart';
import 'package:offroad_nav/services/groups_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final GroupsRepository _groupsRepository = GroupsRepository();
  late Group _currentGroup;

  @override
  void initState() {
    super.initState();
    _currentGroup = widget.group;
    
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
          // Заголовок с названием группы
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
              children: [
                // Аватар группы
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    _currentGroup.avatarUrl,
                    width: 50,
                    height: 50,
                  ),
                ),
                
                const SizedBox(width: width16),
                
                // Название группы
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
                
                // Кнопка закрытия
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
          
          // Action buttons
          Container(
            padding: const EdgeInsets.all(padding20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Chat button
                _ActionButton(
                  icon: Icons.chat,
                  label: 'Chat',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Group chat is not implemented'),
                        backgroundColor: buttonBackgroundColor,
                      ),
                    );
                  },
                ),
                
                // Add member button
                _ActionButton(
                  icon: Icons.person_add,
                  label: 'Add member',
                  onTap: () => _showAddMemberBottomSheet(context),
                ),
              ],
            ),
          ),
          
          // Members list
          Expanded(
            child: _currentGroup.members.isEmpty
                ? const Center(
                    child: Text(
                      'No members in the group yet',
                      style: TextStyle(
                        fontSize: fontSize16,
                        color: textHintColor,
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(padding16),
                    itemCount: _currentGroup.members.length,
                    itemBuilder: (context, index) {
                      final member = _currentGroup.members[index];
                      return _MemberTile(
                        member: member,
                        onDelete: () => _showDeleteMemberDialog(context, member),
                        onChat: () => _showChatDialog(context, member),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

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
                    'Add member',
                    style: TextStyle(
                      fontSize: fontSize20,
                      fontWeight: FontWeight.w600,
                      color: textMainColor,
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
            
            // Friends list
            Expanded(
              child: _FriendsListForGroup(
                onFriendSelected: (friend) {
                  Navigator.pop(context);
                  final newMember = Member(
                    id: friend.uid,
                    name: friend.name,
                    avatarUrl: friend.photo,
                  );
                  _groupsRepository.addMemberToGroup(_currentGroup.id, newMember);
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
          ],
        ),
      ),
    );
  }

  void _showDeleteMemberDialog(BuildContext context, Member member) {
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
            onPressed: () {
              Navigator.pop(context);
              _groupsRepository.removeMemberFromGroup(_currentGroup.id, member.id);
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

  void _showChatDialog(BuildContext context, Member member) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Member chat is not implemented'),
        backgroundColor: buttonBackgroundColor,
      ),
    );
  }
}

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
            Icon(
              icon,
              size: 30,
              color: textMainColor,
            ),
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
        border: Border.all(
          color: listShadowColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Аватар участника
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: member.avatarUrl != null
                ? SvgPicture.asset(
                    member.avatarUrl!,
                    width: 40,
                    height: 40,
                  )
                : const Icon(
                    Icons.person,
                    size: 40,
                    color: textHintColor,
                  ),
          ),
          
          const SizedBox(width: width16),
          
          // Имя участника
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
          
          // Chat button
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: buttonBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: onChat,
              icon: const Icon(
                Icons.chat,
                color: textMainColor,
                size: 16,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Remove button
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: errorColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: onDelete,
              icon: const Icon(
                Icons.close,
                color: surfaceColor,
                size: 16,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsListForGroup extends StatefulWidget {
  final Function(FriendForGroup) onFriendSelected;

  const _FriendsListForGroup({
    required this.onFriendSelected,
  });

  @override
  State<_FriendsListForGroup> createState() => _FriendsListForGroupState();
}

class _FriendsListForGroupState extends State<_FriendsListForGroup> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return const Center(
        child: Text(
          'Please sign in to add friends',
          style: TextStyle(color: textHintColor),
        ),
      );
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(padding16),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search friends...',
              hintStyle: TextStyle(color: textHintColor),
              prefixIcon: Icon(Icons.search, color: textHintColor),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: buttonBackgroundColor),
              ),
            ),
          ),
        ),
        
        // Friends list
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('friends')
                .where('user_id', isEqualTo: currentUser.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Failed to load friends: ${snapshot.error}',
                    style: const TextStyle(color: errorColor),
                  ),
                );
              }

              final friends = snapshot.data?.docs ?? [];
              final friendIds = friends
                  .map((doc) => doc.data()['friend_id'] as String)
                  .where((id) => id.isNotEmpty)
                  .toList();

              if (friendIds.isEmpty) {
                return const Center(
                  child: Text(
                    'No friends to add',
                    style: TextStyle(color: textHintColor),
                  ),
                );
              }

              return FutureBuilder<List<FriendForGroup>>(
                future: _loadFriends(friendIds),
                builder: (context, friendsSnapshot) {
                  if (friendsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var friendsList = friendsSnapshot.data ?? [];
                  
                  // Filter by search query
                  if (_query.isNotEmpty) {
                    friendsList = friendsList.where((friend) {
                      return friend.name.toLowerCase().contains(_query);
                    }).toList();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: padding16),
                    itemCount: friendsList.length,
                    itemBuilder: (context, index) {
                      final friend = friendsList[index];
                      return _FriendTile(
                        friend: friend,
                        onTap: () => widget.onFriendSelected(friend),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<List<FriendForGroup>> _loadFriends(List<String> friendIds) async {
    final futures = friendIds.map((id) => 
        FirebaseFirestore.instance.collection('users').doc(id).get());
    
    final snapshots = await Future.wait(futures);
    
    return snapshots.map((snapshot) {
      final data = snapshot.data() ?? <String, dynamic>{};
      final email = (data['email'] ?? '').toString();
      final name = (data['name'] ?? data['displayName'] ?? 
          (email.isNotEmpty ? email.split('@').first : '')).toString();
      final photo = _extractPhoto(data);
      
      return FriendForGroup(
        uid: snapshot.id,
        name: name,
        email: email,
        photo: photo,
      );
    }).toList();
  }

  String _extractPhoto(Map<String, dynamic> user) {
    final candidates = [
      user['img'], 
      user['photoUrl'], 
      user['photoURL'], 
      user['avatar'], 
      user['photo'], 
      user['imageUrl']
    ];
    for (final v in candidates) {
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }
}

class FriendForGroup {
  final String uid;
  final String name;
  final String email;
  final String photo;

  FriendForGroup({
    required this.uid,
    required this.name,
    required this.email,
    required this.photo,
  });
}

class _FriendTile extends StatelessWidget {
  final FriendForGroup friend;
  final VoidCallback onTap;

  const _FriendTile({
    required this.friend,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius12),
      child: Container(
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
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: _buildAvatar(friend.photo),
            ),
            
            const SizedBox(width: width16),
            
            // Name and email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    style: const TextStyle(
                      fontSize: fontSize16,
                      fontWeight: FontWeight.w500,
                      color: textMainColor,
                    ),
                  ),
                  if (friend.email.isNotEmpty)
                    Text(
                      friend.email,
                      style: const TextStyle(
                        fontSize: fontSize14,
                        color: textHintColor,
                      ),
                    ),
                ],
              ),
            ),
            
            // Add button
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: buttonBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: onTap,
                icon: const Icon(
                  Icons.add,
                  color: textMainColor,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? photoUrl) {
    final url = (photoUrl ?? '').trim();
    
    if (url.isEmpty) {
      return Image.asset(
        'assets/images/avatar_user.png',
        fit: BoxFit.cover,
      );
    }
    
    if (url.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        url,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => Image.asset(
          'assets/images/avatar_user.png',
          fit: BoxFit.cover,
        ),
      );
    }
    
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/avatar_user.png',
          fit: BoxFit.cover,
        ),
      );
    }
    
    return Image.asset(
      'assets/images/avatar_user.png',
      fit: BoxFit.cover,
    );
  }
}
