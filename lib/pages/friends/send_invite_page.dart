// lib/pages/friends/send_invite_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/widgets/friend_item.dart';

class SendInvitePage extends StatefulWidget {
  const SendInvitePage({super.key});

  @override
  State<SendInvitePage> createState() => _SendInvitePageState();
}

class _SendInvitePageState extends State<SendInvitePage> {
  final _controller = TextEditingController();

  final List<DocumentSnapshot> _results = [];
  bool _loading = false;
  String? _error;

  // связи для статусов кнопок
  final Set<String> _sentIds = {};
  final Set<String> _recvIds = {};
  final Set<String> _friendIds = {};

  // ---------- helpers ----------
  String _capFirst(String s) =>
      s.isEmpty ? s : (s[0].toUpperCase() + s.substring(1));

  String _extractPhoto(Map data) {
    final cands = [
      data['img'],
      data['photoUrl'],
      data['photoURL'],
      data['avatar'],
      data['photo'],
      data['imageUrl'],
    ];
    for (final v in cands) {
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRelations(String uid) async {
    _sentIds.clear();
    _recvIds.clear();
    _friendIds.clear();

    final sent = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('from_user_id', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .get();
    _sentIds.addAll(sent.docs.map((d) => d['to_user_id'] as String));

    final recv = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('to_user_id', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .get();
    _recvIds.addAll(recv.docs.map((d) => d['from_user_id'] as String));

    final friends = await FirebaseFirestore.instance
        .collection('friends')
        .where('user_id', isEqualTo: uid)
        .get();
    _friendIds.addAll(friends.docs.map((d) => d['friend_id'] as String));
  }

  // ---------- поиск name/email без учёта регистра (префикс + клиентский contains) ----------
  Future<void> _search() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _results.clear();
        _error = null;
      });
      return;
    }

    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return;
    final uid = current.uid;

    setState(() {
      _loading = true;
      _error = null;
      _results.clear();
    });

    final q = raw;
    final qLower = raw.toLowerCase();
    final qCap = _capFirst(qLower);

    try {
      await _loadRelations(uid);

      final Map<String, DocumentSnapshot> bucket = {};

      Future<void> _byName(String needle) async {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where('name', isGreaterThanOrEqualTo: needle)
            .where('name', isLessThanOrEqualTo: '$needle\uf8ff')
            .limit(50)
            .get();
        for (final d in snap.docs) {
          bucket[d.id] = d;
        }
      }

      Future<void> _byEmail(String needle) async {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isGreaterThanOrEqualTo: needle)
            .where('email', isLessThanOrEqualTo: '$needle\uf8ff')
            .limit(50)
            .get();
        for (final d in snap.docs) {
          bucket[d.id] = d;
        }
      }

      // префиксные варианты (регистронезависимо)
      await _byName(q);
      if (qLower != q) await _byName(qLower);
      if (qCap != q && qCap != qLower) await _byName(qCap);

      await _byEmail(q);
      if (qLower != q) await _byEmail(qLower);

      // fallback: если мало результатов — доберём пачку и отфильтруем contains() на клиенте
      if (bucket.length < 10) {
        final extraByName = await FirebaseFirestore.instance
            .collection('users')
            .orderBy('name')
            .limit(150)
            .get();
        for (final d in extraByName.docs) {
          final data = (d.data() as Map?) ?? {};
          final name = (data['name'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          if (name.contains(qLower) || email.contains(qLower)) {
            bucket[d.id] = d;
          }
        }

        if (bucket.length < 10) {
          final extraByEmail = await FirebaseFirestore.instance
              .collection('users')
              .orderBy('email')
              .limit(150)
              .get();
          for (final d in extraByEmail.docs) {
            final data = (d.data() as Map?) ?? {};
            final name = (data['name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            if (name.contains(qLower) || email.contains(qLower)) {
              bucket[d.id] = d;
            }
          }
        }
      }

      final filtered = bucket.values.where((doc) => doc.id != uid).toList();

      if (!mounted) return;
      setState(() {
        _results.addAll(filtered);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Search failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _invite(DocumentSnapshot user) async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return;
    final targetId = user.id;

    if (_friendIds.contains(targetId)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The user is already your friend.')),
      );
      return;
    }
    if (_sentIds.contains(targetId) || _recvIds.contains(targetId)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The request has already been sent.')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('friend_requests').add({
      'from_user_id': current.uid,
      'to_user_id': targetId,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    setState(() {
      _sentIds.add(targetId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request sent')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: AppBar(
        backgroundColor: backgroundMainColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textMainColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Send Invite', style: head1TextStyle),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // поле ввода
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: listShadowColor,
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: hintTextStyle,
                  prefixIcon: const Icon(Icons.search, color: textHintColor),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.tune_rounded, color: textHintColor),
                    onPressed: _search,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // результаты
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                      : _results.isEmpty
                          ? const Center(child: Text('Type a name or email to search', style: hintTextStyle))
                          : ListView.separated(
                              itemCount: _results.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                final u = _results[i];
                                final data = (u.data() as Map?) ?? {};
                                final email = (data['email'] ?? '').toString();
                                final name  = (data['name']  ?? '').toString();
                                final photo = _extractPhoto(data);

                                // Заголовок: name, если пуст — local-part email
                                final title = name.isNotEmpty
                                    ? name
                                    : (email.contains('@') ? email.split('@').first : email);

                                // Подпись: полный email (FriendItem сам добавит '@' в начале)
                                final handleText = email;

                                final id = u.id;
                                final isFriend = _friendIds.contains(id);
                                final isSent   = _sentIds.contains(id) || _recvIds.contains(id);

                                final btn = OutlinedButton(
                                  onPressed: (isFriend || isSent) ? null : () => _invite(u),
                                  style: OutlinedButton.styleFrom(
                                    shape: const StadiumBorder(),
                                    backgroundColor: (isFriend || isSent)
                                        ? Colors.white
                                        : buttonSecondBackgroundColor,
                                    side: BorderSide(
                                      color: (isFriend || isSent)
                                          ? const Color(0xFFDDE3EB)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(
                                    isFriend ? 'Friend' : (isSent ? 'Sent' : 'Invite'),
                                    style: TextStyle(
                                      color: (isFriend || isSent) ? textHintColor : Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );

                                return FriendItem(
                                  title: title,
                                  handle: handleText,   // покажет '@email@domain.com'
                                  avatarUrl: photo,
                                  trailing: btn,
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
