import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/models/group.dart';
import 'package:offroad_nav/services/friends_repository.dart';

class AddMemberDialog extends StatefulWidget {
  final Group group;
  final Function(Member) onMemberAdded;

  const AddMemberDialog({
    super.key,
    required this.group,
    required this.onMemberAdded,
  });

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final FriendsRepository _friendsRepository = FriendsRepository();
  List<Friend> _friends = [];
  List<Friend> _filteredFriends = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _searchController.addListener(_filterFriends);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    try {
      final currentUserId = widget.group.leaderId; // Предполагаем, что лидер - текущий пользователь
      final friends = await _friendsRepository.getFriends(currentUserId);
      
      // Фильтруем друзей, которые еще не в группе
      final existingMemberIds = widget.group.members.map((m) => m.id).toSet();
      final availableFriends = friends.where((friend) => !existingMemberIds.contains(friend.uid)).toList();
      
      setState(() {
        _friends = availableFriends;
        _filteredFriends = availableFriends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterFriends() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFriends = _friends.where((friend) {
        return friend.name.toLowerCase().contains(query) ||
               friend.email.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _addMember(Friend friend) {
    final member = Member(
      id: friend.uid,
      name: friend.name,
      avatarUrl: friend.avatarUrl,
    );
    
    widget.onMemberAdded(member);
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${friend.name} добавлен в группу'),
        backgroundColor: buttonBackgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(padding20),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Добавить участника',
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
            
            const SizedBox(height: height16),
            
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск друзей...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: backgroundMainColor,
                contentPadding: const EdgeInsets.symmetric(vertical: padding12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(radius16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: height16),
            
            // Friends list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredFriends.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.people_outline,
                                size: 64,
                                color: textHintColor,
                              ),
                              const SizedBox(height: height16),
                              Text(
                                _friends.isEmpty
                                    ? 'У вас нет друзей для добавления'
                                    : 'Друзья не найдены',
                                style: const TextStyle(
                                  fontSize: fontSize16,
                                  color: textHintColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _filteredFriends.length,
                          separatorBuilder: (_, __) => const SizedBox(height: height8),
                          itemBuilder: (context, index) {
                            final friend = _filteredFriends[index];
                            return _FriendTile(
                              friend: friend,
                              onTap: () => _addMember(friend),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback onTap;

  const _FriendTile({
    required this.friend,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(padding12),
        decoration: BoxDecoration(
          color: backgroundMainColor,
          borderRadius: BorderRadius.circular(radius12),
          border: Border.all(color: listShadowColor, width: 1),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: friend.avatarUrl != null && friend.avatarUrl!.isNotEmpty
                  ? (friend.avatarUrl!.endsWith('.svg')
                      ? SvgPicture.asset(
                          friend.avatarUrl!,
                          width: 40,
                          height: 40,
                        )
                      : Image.network(
                          friend.avatarUrl!,
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
                        fontSize: fontSize12,
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
              decoration: const BoxDecoration(
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
}

