import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/route_model.dart';
import '../../domain/entities/route_entity.dart';

class RoutesRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('routes');

  /// 🔁 Стрим всех маршрутов (и публичных, и приватных),
  /// дальше UI сам фильтрует по вкладкам.
  Stream<List<RouteEntity>> watchAllRoutes() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((doc) => RouteModel.fromDoc(doc).toEntity(doc.id))
          .toList();
    });
  }

  Future<RouteEntity> getRouteById(String routeId) async {
  final doc = await _col.doc(routeId).get();

  if (!doc.exists) {
    throw Exception('Route not found');
  }

  return RouteModel.fromDoc(doc).toEntity(doc.id);
}

  /// 💾 Сохранить маршрут.
  /// Если id пустой — создаём новый документ и возвращаем его id.
  /// Если id не пустой — обновляем существующий.
  Future<String> saveRoute(RouteEntity route) async {
    final model = RouteModel.fromEntity(route);

    if (route.id.isEmpty) {
      final doc = await _col.add(model.toMap());
      return doc.id;
    } else {
      await _col.doc(route.id).set(
            model.toMap(),
            SetOptions(merge: true),
          );
      return route.id;
    }
  }

  /// 👁‍🗨 Изменить публичность маршрута.
  /// Пишем и isPublic, и isPrivate — для совместимости со старыми доками.
  Future<void> setPrivacy(String routeId, bool isPublic) async {
    await _col.doc(routeId).update({
      'isPublic': isPublic,
      'isPrivate': !isPublic,
    });
  }

  Future<void> deleteRoute(String routeId) async {
    await _col.doc(routeId).delete();
  }
}
