import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:offroad_nav/features/routes/presentation/utils/route_math.dart';

class RouteTrackingRepository {
  RouteTrackingRepository._();

  static final instance = RouteTrackingRepository._();

  final DatabaseReference _root = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://react-ff62a-default-rtdb.europe-west1.firebasedatabase.app',
  ).ref();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime _lastSentAt = DateTime.fromMillisecondsSinceEpoch(0);
  LatLng? _lastPos;

  static const int _minIntervalMs = 900;
  static const double _minMoveM = 5.0;

  /// Отправить текущую позицию пользователя в Realtime Database
  Future<void> sendLocation({
    required double lat,
    required double lng,
    String? groupId,
    double? heading,
    double? speed,
    double? accuracyM,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final dt = now.difference(_lastSentAt).inMilliseconds;

    final cur = LatLng(lat, lng);

    // фильтр по расстоянию (шум GPS)
    final movedM = (_lastPos == null) ? 999999.0 : distanceM(_lastPos!, cur);

    // throttle по времени + по движению
    final shouldSend = (dt >= _minIntervalMs) || (movedM >= _minMoveM);
    if (!shouldSend) return;

    _lastSentAt = now;
    _lastPos = cur;

    final payload = {
      'lat': lat,
      'lng': lng,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
      if (accuracyM != null) 'accuracy': accuracyM,
      'updatedAt': ServerValue.timestamp,
    };

    // 1) глобальная позиция пользователя
    await _root.child('users/$uid/location').set(payload);

    // 2) позиция в группе (только если есть groupId)
    if (groupId != null && groupId.isNotEmpty) {
      await _root.child('groups_live/$groupId/$uid').set(payload);
    }
  }

  /// Вызвать один раз при старте шаринга локации в группе
  Future<void> startSharing({required String groupId}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _root.child('groups_live/$groupId/$uid').onDisconnect().remove();
  }

  /// Вызвать при выходе из трекинга/группы
  Future<void> stopSharing({required String groupId}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _root.child('groups_live/$groupId/$uid').remove();
  }
}
