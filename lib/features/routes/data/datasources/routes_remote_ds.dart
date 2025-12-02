// можно будет удалить попозже

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/route_model.dart';
import '../../../../core/failure.dart';

class RoutesRemoteDataSource {
  final FirebaseFirestore _db;
  RoutesRemoteDataSource(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('routes');

  // 👇 ВСЕ маршруты, которые видит пользователь:
  // - все public
  // - все маршруты этого пользователя (и public, и private)
  Future<List<RouteModel>> fetchVisibleForUser(String userId) async {
    try {
      final publicSnap = await _col.where('isPublic', isEqualTo: true).get();
      final mySnap = await _col.where('ownerId', isEqualTo: userId).get();

      // объединяем, убираем дубли по id
      final Map<String, RouteModel> result = {};

      for (final d in publicSnap.docs) {
        result[d.id] = RouteModel.fromMap(d.data(), d.id);
      }
      for (final d in mySnap.docs) {
        result[d.id] = RouteModel.fromMap(d.data(), d.id);
      }

      return result.values.toList();
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Firestore error');
    }
  }

  Future<List<RouteModel>> fetchByOwner(String ownerId) async {
    try {
      final snap = await _col
          .where('userId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => RouteModel.fromMap(d.data(), d.id)).toList();
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Firestore error');
    }
  }

  Stream<List<RouteModel>> watchByOwner(String ownerId) {
    return _col
        .where('userId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(RouteModel.fromDoc).toList());
  }

  Future<String> create(RouteModel m) async {
    try {
      final doc = await _col.add(m.toMap());
      return doc.id;
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Firestore error');
    }
  }

  Future<void> setPrivacy(String id, bool isPublic) async {
    try {
      await _col.doc(id).update({'isPrivate': !isPublic});
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? 'Firestore error');
    }
  }
}
