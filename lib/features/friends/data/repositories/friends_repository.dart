import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Friend {
  final String uid;
  final String name;
  final String email;
  final String? avatarUrl;

  Friend({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarUrl,
  });
}

class FriendsRepository {
  static final FriendsRepository _instance = FriendsRepository._internal();
  factory FriendsRepository() => _instance;
  FriendsRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить список друзей текущего пользователя
  Future<List<Friend>> getFriends(String userId) async {
    try {
      // Получаем список друзей из коллекции 'friends'
      final friendsSnapshot = await _firestore
          .collection('friends')
          .where('user_id', isEqualTo: userId)
          .get();

      if (friendsSnapshot.docs.isEmpty) {
        return [];
      }

      // Получаем ID друзей
      final friendIds = friendsSnapshot.docs
          .map((doc) => doc.data()['friend_id'] as String)
          .toList();

      // Получаем данные пользователей
      final friends = <Friend>[];
      for (final friendId in friendIds) {
        try {
          final userDoc = await _firestore.collection('users').doc(friendId).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final name = _extractName(userData);
            final email = _extractEmail(userData);
            final avatarUrl = _extractAvatar(userData);
            
            friends.add(Friend(
              uid: friendId,
              name: name,
              email: email,
              avatarUrl: avatarUrl,
            ));
          }
        } catch (e) {
          // Пропускаем пользователей с ошибками
          continue;
        }
      }

      return friends;
    } catch (e) {
      return [];
    }
  }

  /// Получить стрим друзей для текущего пользователя
  Stream<List<Friend>> getFriendsStream(String userId) {
    return _firestore
        .collection('friends')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        return <Friend>[];
      }

      final friendIds = snapshot.docs
          .map((doc) => doc.data()['friend_id'] as String)
          .toList();

      final friends = <Friend>[];
      for (final friendId in friendIds) {
        try {
          final userDoc = await _firestore.collection('users').doc(friendId).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final name = _extractName(userData);
            final email = _extractEmail(userData);
            final avatarUrl = _extractAvatar(userData);
            
            friends.add(Friend(
              uid: friendId,
              name: name,
              email: email,
              avatarUrl: avatarUrl,
            ));
          }
        } catch (e) {
          continue;
        }
      }

      return friends;
    });
  }

  Stream<int> incomingPendingCount(String uid) {
    return _firestore
        .collection('friend_requests')
        .where('to_user_id', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.size);
  }

  Future<void> removeFriend(String currentUid, String friendId) async {
    final ref = _firestore.collection('friends');

    final mySide = await ref
        .where('user_id', isEqualTo: currentUid)
        .where('friend_id', isEqualTo: friendId)
        .get();

    final theirSide = await ref
        .where('user_id', isEqualTo: friendId)
        .where('friend_id', isEqualTo: currentUid)
        .get();

    for (final d in [...mySide.docs, ...theirSide.docs]) {
      await d.reference.delete();
    }
  }

  /// Проверить, есть ли у пользователя друзья
  Future<bool> hasFriends(String userId) async {
    final friends = await getFriends(userId);
    return friends.isNotEmpty;
  }

  String _extractName(Map<String, dynamic> userData) {
    final candidates = [
      userData['name'],
      userData['displayName'],
      userData['email']?.toString().split('@').first,
    ];
    
    for (final candidate in candidates) {
      if (candidate != null && candidate.toString().trim().isNotEmpty) {
        return candidate.toString().trim();
      }
    }
    
    return 'Unknown User';
  }

  String _extractEmail(Map<String, dynamic> userData) {
    return userData['email']?.toString() ?? '';
  }

  String? _extractAvatar(Map<String, dynamic> userData) {
    final candidates = [
      userData['img'],
      userData['photoUrl'],
      userData['photoURL'],
      userData['avatar'],
      userData['photo'],
      userData['imageUrl'],
    ];
    
    for (final candidate in candidates) {
      if (candidate != null && candidate.toString().trim().isNotEmpty) {
        return candidate.toString().trim();
      }
    }
    
    return null;
  }
}

