// lib/pages/friends/friends_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// дизайн/токены
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/images.dart';
import 'package:offroad_nav/design/styles.dart';

// экраны
import 'my_friends_page.dart';
import 'send_invite_page.dart';
import 'package:offroad_nav/pages/friends/chat_page.dart';


const kPersonAddSvg = 'assets/images/person_add.svg';
const kDefaultAvatarPng = 'assets/images/avatar_user.png';
const kChatPng = 'assets/images/icon_chat.png';


class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  // поиск по «моим друзьям»
  final _friendsSearch = TextEditingController();
  String _query = '';

  // кэш юзеров для гридки
  final Map<String, Future<DocumentSnapshot<Map<String, dynamic>>>> _userCache = {};

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUser(String uid) {
    return _userCache.putIfAbsent(
      uid,
      () => FirebaseFirestore.instance.collection('users').doc(uid).get(),
    );
  }

  String _extractPhoto(Map<String, dynamic> user) {
    final candidates = [user['img'], user['photoUrl'], user['photoURL'], user['avatar'], user['photo'], user['imageUrl']];
    for (final v in candidates) {
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  // стрим связей «я → friend_id»
  Stream<QuerySnapshot<Map<String, dynamic>>> _friendsStream(String uid) {
    return FirebaseFirestore.instance
        .collection('friends')
        .where('user_id', isEqualTo: uid)
        .snapshots();
  }

  // счётчик входящих «pending» (для бейджа в колокольчике)
  Stream<int> _pendingCountStream(String uid) {
    return FirebaseFirestore.instance
        .collection('friend_requests')
        .where('to_user_id', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.size);
  }

  Future<void> _removeFriend(String friendId) async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return;

    final ref = FirebaseFirestore.instance.collection('friends');
    final mySide = await ref.where('user_id', isEqualTo: me).where('friend_id', isEqualTo: friendId).get();
    final theirSide = await ref.where('user_id', isEqualTo: friendId).where('friend_id', isEqualTo: me).get();

    for (final d in [...mySide.docs, ...theirSide.docs]) {
      await d.reference.delete();
    }
  }

  @override
  void dispose() {
    _friendsSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: AppBar(
        backgroundColor: backgroundMainColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: arrowBackImage, onPressed: () => Navigator.pop(context)),
        title: const Text('Friends', style: head1TextStyle),
        actions: [
          if (current != null)
            StreamBuilder<int>(
              stream: _pendingCountStream(current.uid),
              builder: (context, snap) {
                final count = snap.data ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _BellButton(
                    count: count,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MyFriendsPage()));
                    },
                  ),
                );
              },
            ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(padding16),
        child: Column(
          children: [
            // ПОИСК по моим друзьям (50 px высота, скругление 24)
            SizedBox(
              height: 50,
              child: TextField(
                controller: _friendsSearch,
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search…',
                  hintStyle: hintTextStyle,
                  contentPadding: const EdgeInsets.symmetric(horizontal: padding16),
                  prefixIcon: const Icon(Icons.search, color: textHintColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFE6E6EA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFE6E6EA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFD0D0D6)),
                  ),
                  filled: true,
                  fillColor: surfaceColor,
                ),
              ),
            ),
            const SizedBox(height: height16),

            // ГРИД «Add new» + друзья (с фильтром по _query)
            Expanded(
              child: (current == null)
                  ? const Center(child: Text('Please sign in'))
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _friendsStream(current.uid),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snap.hasError) {
                          return Center(
                            child: Text('Failed to load friends: ${snap.error}', style: const TextStyle(color: Colors.red)),
                          );
                        }

                        final links = snap.data?.docs ?? const [];
                        final uids = <String>[
                          for (final d in links)
                            (d.data()['friend_id'] ?? '').toString(),
                        ]..removeWhere((e) => e.isEmpty);

                        return FutureBuilder<List<_FriendVM>>(
                          future: _loadFriends(uids),
                          builder: (context, uSnap) {
                            if (uSnap.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                            }
                            var friends = uSnap.data ?? const <_FriendVM>[];

                            if (_query.isNotEmpty) {
                              friends = friends.where((f) {
                                final n = f.name.toLowerCase();
                                final e = f.email.toLowerCase();
                                return n.contains(_query) || e.contains(_query);
                              }).toList();
                            }

                            final itemCount = friends.length + 1; // + Add new

                            return LayoutBuilder(
                              builder: (context, constraints) {
                                const cols = 3;
                                final spacing = width16;
                                const tileHeight = 240.0; // компактная плитка
                                final gridWidth = constraints.maxWidth;
                                final tileWidth = (gridWidth - spacing * (cols - 1)) / cols;
                                final aspect = tileWidth / tileHeight;

                                return GridView.builder(
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cols,
                                    mainAxisSpacing: spacing,
                                    crossAxisSpacing: spacing,
                                    childAspectRatio: aspect,
                                  ),
                                  itemCount: itemCount,
                                  itemBuilder: (_, i) {
                                    if (i == 0) {
                                      return _AddNewTile(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const SendInvitePage()),
                                        ),
                                      );
                                    }
                                    final f = friends[i - 1];
                                    return _FriendGridTile(
                                      title: f.name,
                                      avatarUrl: f.photo,
                                      onChat: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatPage(
                                              peerUid: f.uid,
                                              peerName: f.name,
                                              peerAvatar: f.photo,
                                            ),
                                          ),
                                        );
                                      },
                                      onRemove: () => _removeFriend(f.uid),
                                    );
                                  },
                                );
                              },
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

  Future<List<_FriendVM>> _loadFriends(List<String> uids) async {
    final snaps = await Future.wait(uids.map(_getUser));
    return [
      for (final s in snaps)
        (() {
          final data = s.data() ?? <String, dynamic>{};
          final email = (data['email'] ?? '').toString();
          final name = (data['name'] ?? data['displayName'] ?? (email.isNotEmpty ? email.split('@').first : '')).toString();
          final photo = _extractPhoto(data);
          return _FriendVM(uid: s.id, name: name, email: email, photo: photo);
        })(),
    ];
  }
}

// ---------------- View models ----------------
class _FriendVM {
  final String uid;
  final String name;
  final String email;
  final String photo;
  _FriendVM({required this.uid, required this.name, required this.email, required this.photo});
}

// ---------------- UI tiles ----------------

class _FriendGridTile extends StatelessWidget {
  final String title;
  final String? avatarUrl;
  final VoidCallback? onChat;
  final VoidCallback? onRemove;

  const _FriendGridTile({
    required this.title,
    this.avatarUrl,
    this.onChat,
    this.onRemove,
  });

  // Хелпер для аватара (без @override!)
  Widget _avatarWidget(String? url) {
    final u = (url ?? '').trim();

    if (u.isEmpty) {
      // дефолтный плейсхолдер из assets
      return Image.asset(kDefaultAvatarPng, fit: BoxFit.cover);
    }

    if (u.toLowerCase().endsWith('.svg')) {
      // локальный svg из assets (как в БД: "assets/images/avatar_girl_04.svg")
      return SvgPicture.asset(
        u,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => Image.asset(kDefaultAvatarPng, fit: BoxFit.cover),
      );
    }

    if (u.startsWith('http')) {
      // сетевой url
      return Image.network(
        u,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(kDefaultAvatarPng, fit: BoxFit.cover),
      );
    }

    // локальный png/jpg из assets
    return Image.asset(
      u,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(kDefaultAvatarPng, fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(radius16),
        boxShadow: const [
          BoxShadow(color: Color(0x141A1A1A), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: padding12, horizontal: padding12),
      child: Column(
        children: [
          Stack(
            children: [
              // аватар строго 100×100, обрезка по кругу
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F4F4),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(child: _avatarWidget(avatarUrl)),
              ),

              if (onRemove != null)
                Positioned(
                  right: 0,
                  top: 0,
                  child: InkWell(
                    onTap: onRemove,
                    child: const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.black12,
                      child: Icon(Icons.close, size: 16),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: height12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: fontSize16, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          if (onChat != null)
            IconButton(
              onPressed: onChat,
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(), 
              icon: SizedBox(
                width: 18,
                height: 18,
                child: Image.asset(kChatPng),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddNewTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddNewTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(radius16),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: padding12, horizontal: padding12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: radius50,
                backgroundColor: const Color(0xFFF4F4F4),
                child: SvgPicture.asset(
                  kPersonAddSvg,
                  width: 40, height: 38,
                  colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                ),
              ),
              const SizedBox(height: height12),
              const Text('Add new', textAlign: TextAlign.center, style: TextStyle(fontSize: fontSize12, fontWeight: FontWeight.w600)),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _BellButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4))],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.notifications_none_rounded, color: textMainColor),
            ),
            if (count > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: const BoxDecoration(color: Color(0xFFFFA000), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(count > 9 ? '9+' : '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
