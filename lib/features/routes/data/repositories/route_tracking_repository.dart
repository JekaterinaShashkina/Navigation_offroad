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
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _root.child('users/$uid/location').set({
      'lat': lat,
      'lng': lng,
      'timestamp': ServerValue.timestamp,
    });
  }
}
