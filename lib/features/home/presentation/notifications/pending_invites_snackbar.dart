import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:offroad_nav/features/friends/data/repositories/friends_repository.dart';
import 'package:offroad_nav/features/home/presentation/pages/notifications_page.dart';

class PendingInvitesSnackbarController {
  PendingInvitesSnackbarController({FriendsRepository? repo})
      : _repo = repo ?? FriendsRepository();

  final FriendsRepository _repo;

  StreamSubscription<int>? _sub;
  int _lastPending = 0;

  void start(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _sub = _repo.incomingPendingCount(uid).listen((count) {
      if (count > _lastPending) {
        final diff = count - _lastPending;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final messenger = ScaffoldMessenger.maybeOf(context);
          if (messenger == null) return;

          messenger.showSnackBar(
            SnackBar(
              content: Text(
                diff == 1 ? 'New friend request' : '$diff new friend requests',
              ),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsPage()),
                  );
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        });
      }

      _lastPending = count;
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
