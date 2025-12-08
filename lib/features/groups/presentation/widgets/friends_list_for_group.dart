import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';

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

/// Список друзей, которых можно добавить в группу.
class FriendsListForGroup extends StatefulWidget {
  final Function(FriendForGroup) onFriendSelected;

  const FriendsListForGroup({
    super.key,
    required this.onFriendSelected,
  });

  @override
  State<FriendsListForGroup> createState() => _FriendsListForGroupState();
}

class _FriendsListForGroupState extends State<FriendsListForGroup> {
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
                  if (friendsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var friendsList = friendsSnapshot.data ?? [];

                  if (_query.isNotEmpty) {
                    friendsList = friendsList
                        .where((f) =>
                            f.name.toLowerCase().contains(_query) ||
                            f.email.toLowerCase().contains(_query))
                        .toList();
                  }

                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: padding16),
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
    final futures = friendIds
        .map((id) => FirebaseFirestore.instance.collection('users').doc(id).get());

    final snapshots = await Future.wait(futures);

    return snapshots.map((snapshot) {
      final data = snapshot.data() ?? <String, dynamic>{};
      final email = (data['email'] ?? '').toString();
      final name = (data['name'] ??
              data['displayName'] ??
              (email.isNotEmpty ? email.split('@').first : ''))
          .toString();
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
      user['imageUrl'],
    ];
    for (final v in candidates) {
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }
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
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: _buildAvatar(friend.photo),
            ),
            const SizedBox(width: width16),
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

  Widget _buildAvatar(String photoUrl) {
    final url = photoUrl.trim();

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
