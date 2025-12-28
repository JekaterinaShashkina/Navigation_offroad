// можно будет удалить попозже

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class RouteTrackingRepository {
  RouteTrackingRepository._();

  static final instance = RouteTrackingRepository._();

  // Можно переиспользовать то же самое, что было в странице
  final DatabaseReference _root = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://react-ff62a-default-rtdb.europe-west1.firebasedatabase.app',
  ).ref();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Отправить текущую позицию пользователя в Realtime Database
Future<void> sendLocation({
  required double lat,
  required double lng,
  String? groupId,
  double? heading,
  double? speed,
}) async {
  final uid = _auth.currentUser?.uid;
  print('✅ sendLocation CALLED uid=$uid lat=$lat lng=$lng groupId=$groupId');
  if (uid == null) return;

  // 1) глобальная позиция пользователя (как было)
  await _root.child('users/$uid/location').set({
    'lat': lat,
    'lng': lng,
    'heading': heading,
    'speed': speed,
    'updatedAt': ServerValue.timestamp,
  });

  // 2) позиция в группе (ТОЛЬКО если есть groupId)
  if (groupId != null && groupId.isNotEmpty) {
    final ref = _root.child('groups_live/$groupId/$uid');

    // один раз ставить onDisconnect — идеально в startSharing,
    // но можно и тут (просто будет чаще дергаться)
    await ref.onDisconnect().remove();

    await ref.set({
      'lat': lat,
      'lng': lng,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
      'updatedAt': ServerValue.timestamp,
    });
  }
}
}
