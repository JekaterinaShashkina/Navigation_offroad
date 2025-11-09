import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Хранит/обновляет документ users/{uid} в твоём формате.
class UserProfileService {
  UserProfileService._();
  static final instance = UserProfileService._();

  final _db = FirebaseFirestore.instance;

  /// Создать (если нет) или обновить (если есть) профайл пользователя.
  Future<void> upsertFromFirebaseUser(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final now = FieldValue.serverTimestamp();

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);

      final displayName =
          user.displayName ?? (user.email != null ? user.email!.split('@').first : 'User');

      if (!snap.exists) {
        tx.set(ref, {
          'userID'          : user.uid,
          'email'           : user.email ?? '',
          'name'            : displayName,
          'phone'           : user.phoneNumber ?? '',
          'img'             : user.photoURL ?? '',
          'description'     : '',
          'favourite_route' : <String>[],
          'location_sharing': true,          // или false — как тебе нужно
          'last_seen'       : now,
          'createdAt'       : now,
        });
      } else {
        tx.update(ref, {
          if (user.email != null) 'email': user.email,
          if (user.displayName != null) 'name': user.displayName,
          if (user.phoneNumber != null) 'phone': user.phoneNumber,
          if (user.photoURL != null) 'img': user.photoURL,
          'last_seen': now,
        });
      }
    });
  }

  /// Просто обновить last_seen (например, на старте приложения).
  Future<void> touchLastSeen(String uid) {
    return _db.collection('users').doc(uid)
      .set({'last_seen': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }
}
