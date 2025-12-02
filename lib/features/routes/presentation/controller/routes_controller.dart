import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:offroad_nav/features/routes/data/repositories/routes_repository.dart';

import '../../data/models/route_model.dart';
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

  /// Формальный reload — стрим и так отдаст обновления,
  /// но можем просто пометить, что идёт загрузка
  Future<void> reload() async {
    state = state.copy(loading: true);
    // Ничего больше не делаем — Firestore сам триггерит стрим.
  }
}