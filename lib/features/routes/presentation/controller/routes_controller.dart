import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offroad_nav/features/routes/data/repositories/routes_repository.dart';
import '../../domain/entities/route_entity.dart';

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
  final _repo = RoutesRepository();
  
  StreamSubscription<List<RouteEntity>>? _sub;

  @override
  RoutesState build() {
    // при первом build подписываемся на стрим
    _sub ??= _repo.watchAllRoutes().listen(
      (routes) {
        state = state.copy(
          loading: false,
          routes: routes,
          error: null,
        );
      },
      onError: (e, _) {
        state = state.copy(
          loading: false,
          error: e.toString(),
        );
      },
    );

    // отписка, когда провайдер умирает
    ref.onDispose(() {
      _sub?.cancel();
    });

    // пока стрим не дал данные — показываем лоадер
    return const RoutesState(loading: true);
  }

  Future<void> togglePrivacy(RouteEntity route) async {
    final newValue = !route.isPublic;

    // оптимистично обновляем локальный стейт
    state = state.copy(
      routes: [
        for (final r in state.routes)
          if (r.id == route.id)
            r.copyWith(isPublic: newValue) // нужен copyWith у RouteEntity
          else
            r,
      ],
      error: null,
    );

    try {
      await _repo.setPrivacy(route.id, newValue);
      // стрим потом всё равно пришлёт актуальное состояние
    } catch (e) {
      // по желанию можно откатить
      state = state.copy(error: 'Failed to update privacy: $e');
    }
  }

  Future<void> deleteRoute(String id) async {
    // оптимистично убираем маршрут из списка
    final updated = [
      for (final r in state.routes)
        if (r.id != id) r,
    ];

    state = state.copy(
      routes: updated,
      error: null,
    );

    try {
      await _repo.deleteRoute(id);
      // стрим потом всё равно подтянет актуальное состояние
    } catch (e) {
      state = state.copy(error: 'Failed to delete route: $e');
      // по желанию можно откатить список назад
    }
  }

  /// Формальный reload — стрим и так отдаст обновления,
  /// но можем просто пометить, что идёт загрузка
  Future<void> reload() async {
    state = state.copy(loading: true);
    // Ничего больше не делаем — Firestore сам триггерит стрим.
  }
}