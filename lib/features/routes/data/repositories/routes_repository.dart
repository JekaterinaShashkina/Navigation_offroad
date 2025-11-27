import 'package:cloud_firestore/cloud_firestore.dart';

class RoutesRepository {
  final _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPublicRoutes() {
    return _db
        .collection('routes')
        .where('isPrivate', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyRoutes(String uid) {
    return _db
        .collection('routes')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> toggleVisibility(String docId, bool currentValue) {
    return _db.collection('routes').doc(docId).update({
      'isPrivate': !currentValue,
    });
  }

  Future<void> deleteRoute(String docId) {
    return _db.collection('routes').doc(docId).delete();
  }
}
