  import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
  import 'package:flutter_svg/flutter_svg.dart';

  import 'package:offroad_nav/design/colors.dart';
  import 'package:offroad_nav/design/dimension.dart';
  import 'package:offroad_nav/features/groups/data/repositories/groups_repository.dart';

  import 'package:offroad_nav/features/groups/domain/entities/group.dart';
  import 'package:offroad_nav/features/groups/domain/entities/member.dart';
  import 'package:offroad_nav/features/friends/data/repositories/friends_repository.dart';

  class AddMemberDialog extends StatefulWidget {
    final Group group;
    final ValueChanged<String> onMemberAdded;

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
    final GroupsRepository _groupsRepository = GroupsRepository(FirebaseFirestore.instance);

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
        // лидер группы = ownerId
        final currentUserId = widget.group.ownerId;

        // все друзья лидера
        final friends = await _friendsRepository.getFriends(currentUserId);

        // id уже состоящих в группе участников
        final existingMemberIds =
            await _groupsRepository.getMemberIds(widget.group.id);
            
        // оставляем только тех друзей, кого ещё нет в группе
        final availableFriends = friends
            .where((friend) => !existingMemberIds.contains(friend.uid))
            .toList();

        setState(() {
          _friends = availableFriends;
          _filteredFriends = availableFriends;
          _isLoading = false;
        });
      } catch (_) {
        setState(() => _isLoading = false);
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
      widget.onMemberAdded(friend.uid);
      Navigator.pop(context);
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
              // header
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

              // search
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск друзей...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: backgroundMainColor,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: padding12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: height16),

              // list
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
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: height8),
                            itemBuilder: (_, index) {
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
              // avatar
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: friend.avatarUrl != null &&
                        friend.avatarUrl!.isNotEmpty
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
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person,
                                    size: 40, color: textHintColor),
                          ))
                    : const Icon(Icons.person,
                        size: 40, color: textHintColor),
              ),
              const SizedBox(width: width16),

              // name + email
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

              // add button
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: buttonBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: onTap,
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.add,
                    color: textMainColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
