import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:offroad_nav/design/widgets/bell_button.dart';
import 'package:offroad_nav/features/friends/data/repositories/friends_repository.dart';
import 'package:offroad_nav/features/home/presentation/pages/notifications_page.dart';

class PendingInvitesBell extends StatelessWidget {
  PendingInvitesBell({super.key});

  final FriendsRepository _friendsRepo = FriendsRepository();

  Stream<int> _pendingCountStream(String uid) =>
      _friendsRepo.incomingPendingCount(uid);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox(width: 36, height: 36);
    }

    return StreamBuilder<int>(
      stream: _pendingCountStream(user.uid),
      builder: (context, snap) {
        final count = snap.data ?? 0;
        return BellButton(
          count: count,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            );
          },
        );
      },
    );
  }
}
