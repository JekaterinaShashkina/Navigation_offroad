import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Модель профиля пользователя
class UserProfile {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String img;
  final String description;
  final bool locationSharing;
  final List<String> favouriteRoute;
  final DateTime? premiumUntil;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    required this.img,
    required this.description,
    required this.locationSharing,
    required this.favouriteRoute,
    this.premiumUntil,
  });

  factory UserProfile.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    final fav = (data['favourite_route'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    DateTime? premium;
    final pu = data['premium_until'];
    if (pu is Timestamp) {
      premium = pu.toDate();
    }

    return UserProfile(
      uid: doc.id,
      email: (data['email'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      img: (data['img'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      locationSharing: (data['location_sharing'] as bool?) ?? false,
      favouriteRoute: fav,
      premiumUntil: premium,
    );
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'img': img,
      'description': description,
      'location_sharing': locationSharing,
      'favourite_route': favouriteRoute,
      if (premiumUntil != null)
        'premium_until': Timestamp.fromDate(premiumUntil!),
    };
  }

  UserProfile copyWith({
    String? email,
    String? name,
    String? phone,
    String? img,
    String? description,
    bool? locationSharing,
    List<String>? favouriteRoute,
    DateTime? premiumUntil,
  }) {
    return UserProfile(
      uid: uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      img: img ?? this.img,
      description: description ?? this.description,
      locationSharing: locationSharing ?? this.locationSharing,
      favouriteRoute: favouriteRoute ?? this.favouriteRoute,
      premiumUntil: premiumUntil ?? this.premiumUntil,
    );
  }
}

/// Репозиторий/сервис профиля пользователя
class UserProfileService {
  UserProfileService._();
  static final instance = UserProfileService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Создать (если нет) или обновить (если есть) профайл пользователя
  /// по данным FirebaseAuth (как у тебя было раньше).
  Future<void> upsertFromFirebaseUser(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final now = FieldValue.serverTimestamp();

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);

      final displayName = user.displayName ??
          (user.email != null ? user.email!.split('@').first : 'User');

      if (!snap.exists) {
        tx.set(ref, {
          'userID': user.uid,
          'email': user.email ?? '',
          'name': displayName,
          'phone': user.phoneNumber ?? '',
          'img': user.photoURL ?? '',
          'description': '',
          'favourite_route': <String>[],
          'location_sharing': true,
          'last_seen': now,
          'createdAt': now,
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
    return _db.collection('users').doc(uid).set(
          {'last_seen': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
  }

  /// Загрузить профиль по uid (однократно)
  Future<UserProfile?> loadProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromDoc(doc);
  }

  /// Стрим профиля по uid (для Membership и прочего)
  Stream<UserProfile?> watchProfile(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data() == null ? null : UserProfile.fromDoc(doc));
  }

  /// Обновить профиль целиком (EditProfilePage)
  Future<void> updateProfile(UserProfile profile) {
    return _db
        .collection('users')
        .doc(profile.uid)
        .update(profile.toUpdateMap());
  }

  /// Частичное обновление (например, только аватар)
  Future<void> updatePartial(String uid, Map<String, dynamic> data) {
    return _db.collection('users').doc(uid).update(data);
  }

  /// Обновить только аватар
  Future<void> updateAvatar(String uid, String avatarPath) {
    return updatePartial(uid, {'img': avatarPath});
  }
}
