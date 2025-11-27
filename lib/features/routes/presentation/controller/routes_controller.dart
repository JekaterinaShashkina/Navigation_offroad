import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RouteEntity {
  final String id;
  final String name;

  const RouteEntity({
    required this.id,
    required this.name,
  });
}

class RoutesState {
  final bool loading;
  final List<RouteEntity> routes;
  final String? error;

  const RoutesState({
    this.loading = false,
    this.routes = const [],
    this.error,
  });

  RoutesState copy({
    bool? loading,
    List<RouteEntity>? routes,
    String? error,
  }) {
    return RoutesState(
      loading: loading ?? this.loading,
      routes: routes ?? this.routes,
      error: error,
    );
  }
}

final routesControllerProvider =
    NotifierProvider<RoutesController, RoutesState>(
  RoutesController.new,
);

class RoutesController extends Notifier<RoutesState> {
  final _db = FirebaseFirestore.instance;

  @override
  RoutesState build() {
    _load();
    return const RoutesState(loading: true);
  }

  Future<void> _load() async {
    state = state.copy(loading: true, error: null);

    try {
      final snap = await _db.collection('routes').get();
      // если вдруг Firestore отдаёт 0 — положим хотя бы заглушку,
      // чтобы отличать "пустую коллекцию" от других проблем
      if (snap.docs.isEmpty) {
        state = const RoutesState(
          loading: false,
          routes: [
            RouteEntity(id: 'empty-test', name: 'No docs in Firestore'),
          ],
        );
        return;
      }

      final items = snap.docs.map((doc) {
        final data = doc.data();
        return RouteEntity(
          id: doc.id,
          name: data['name'] as String? ?? '',
        );
      }).toList();

      state = state.copy(loading: false, routes: items);
    } catch (e) {
      state = state.copy(
        loading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> reload() async => _load();
}
