import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepository {
  static final _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  static Future<void> upsertOnLogin(
    User user, {
    Map<String, dynamic>? extra,
  }) async {
    final ref = _users.doc(user.uid);

    // Текущее содержимое документа (если есть)
    final snap = await ref.get();
    final current = snap.data() ?? const <String, dynamic>{};

    // Почистим extra от null
    final ex = {...?extra}..removeWhere((k, v) => v == null);

    // Удобный хелпер: берём первое непустое значение
    String _pick(List<String?> xs) =>
        xs.firstWhere(
          (v) => v != null && v.trim().isNotEmpty,
          orElse: () => '',
        )!;

    final email = _pick([ex['email'] as String?, current['email'] as String?, user.email]);
    final phone = _pick([ex['phone'] as String?, current['phone'] as String?, user.phoneNumber]);
    final name  = _pick([ex['name']  as String?, current['name']  as String?, user.displayName]);
    final img   = _pick([ex['img']   as String?, current['img']   as String?, user.photoURL]);

    final payload = <String, dynamic>{
      'userID': user.uid,
      if (email.isNotEmpty) 'email': email,
      if (phone.isNotEmpty) 'phone': phone,
      if (name.isNotEmpty)  'name':  name,
      if (img.isNotEmpty)   'img':   img,
      'providers': user.providerData.map((p) => p.providerId).toSet().toList(),
      'last_seen': FieldValue.serverTimestamp(),
      if (!snap.exists) 'createdAt': FieldValue.serverTimestamp(),
      // кладём прочие поля из extra (кроме уже обработанных)
      ...{
        ...ex
          ..remove('email')
          ..remove('phone')
          ..remove('name')
          ..remove('img'),
      },
    };

    await ref.set(payload, SetOptions(merge: true));
  }
}
