import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String status;
  final String email; // email другого пользователя (для отображения в UI)

  FriendRequestModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.email,
  });
}

class FriendRequestsRepository {
  static final FriendRequestsRepository _instance =
      FriendRequestsRepository._internal();
  factory FriendRequestsRepository() => _instance;
  FriendRequestsRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------- helpers ----------

  Future<String> _getUserEmail(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    return (userDoc.data()?['email'] ?? 'unknown').toString();
  }

  // ---------- запросы ----------

  /// Входящие pending-заявки (когда ТЕБЕ отправили запрос)
  Future<List<FriendRequestModel>> getIncomingRequests(String uid) async {
    final snap = await _firestore
        .collection('friend_requests')
        .where('to_user_id', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .get();

    final List<FriendRequestModel> list = [];

    for (final doc in snap.docs) {
      final data = doc.data();
      final fromUid = (data['from_user_id'] ?? '').toString();
      final toUid   = (data['to_user_id']   ?? '').toString();
      final status  = (data['status']       ?? '').toString();

      // email отправителя (того, кто просится в друзья)
      final email = await _getUserEmail(fromUid);

      list.add(FriendRequestModel(
        id: doc.id,
        fromUserId: fromUid,
        toUserId: toUid,
        status: status,
        email: email,
      ));
    }

    return list;
  }

  /// Исходящие pending-заявки (когда ТЫ отправил запрос)
  Future<List<FriendRequestModel>> getOutgoingRequests(String uid) async {
    final snap = await _firestore
        .collection('friend_requests')
        .where('from_user_id', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .get();

    final List<FriendRequestModel> list = [];

    for (final doc in snap.docs) {
      final data = doc.data();
      final fromUid = (data['from_user_id'] ?? '').toString();
      final toUid   = (data['to_user_id']   ?? '').toString();
      final status  = (data['status']       ?? '').toString();

      // email того, КОМУ ты отправил запрос
      final email = await _getUserEmail(toUid);

      list.add(FriendRequestModel(
        id: doc.id,
        fromUserId: fromUid,
        toUserId: toUid,
        status: status,
        email: email,
      ));
    }

    return list;
  }

  // ---------- действия с заявками ----------

  Future<void> acceptRequest({
    required String currentUid,
    required FriendRequestModel request,
  }) async {
    final fromUserId = request.fromUserId;
    final reqRef = _firestore.collection('friend_requests').doc(request.id);
    final friendsRef = _firestore.collection('friends');
    final now = FieldValue.serverTimestamp();

    final batch = _firestore.batch();

    // Добавляем каждому по другу
    batch.set(friendsRef.doc(), {
      'user_id': currentUid,
      'friend_id': fromUserId,
      'created_at': now,
    });
    batch.set(friendsRef.doc(), {
      'user_id': fromUserId,
      'friend_id': currentUid,
      'created_at': now,
    });

    // Удаляем запрос
    batch.delete(reqRef);

    await batch.commit();
  }

  Future<void> rejectRequest(FriendRequestModel request) async {
    await _firestore
        .collection('friend_requests')
        .doc(request.id)
        .delete();
  }

  Future<void> cancelSentRequest(FriendRequestModel request) async {
    await _firestore
        .collection('friend_requests')
        .doc(request.id)
        .delete();
  }

  Future<void> sendRequest({
    required String fromUid,
    required String toUid,
  }) async {
    await _firestore.collection('friend_requests').add({
      'from_user_id': fromUid,
      'to_user_id': toUid,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
