import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offroad_nav/features/routes/data/repositories/routes_repository.dart';
import '../../domain/entities/route_entity.dart';

// --- providers ---
final routesRepositoryProvider = Provider<RoutesRepository>((ref) {
  return RoutesRepository();
});

final routeByIdProvider =
    FutureProvider.family<RouteEntity, String>((ref, routeId) async {
  return ref.read(routesRepositoryProvider).getRouteById(routeId);
});

final routesControllerProvider =
    NotifierProvider<RoutesController, RoutesState>(RoutesController.new);

// --- state ---
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

// --- controller ---
class RoutesController extends Notifier<RoutesState> {
  late final RoutesRepository _repo;
  StreamSubscription<List<RouteEntity>>? _sub;

  @override
  RoutesState build() {
    _repo = ref.read(routesRepositoryProvider);

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

    ref.onDispose(() => _sub?.cancel());

    return const RoutesState(loading: true);
  }

  Future<void> togglePrivacy(RouteEntity route) async {
    final newValue = !route.isPublic;

    state = state.copy(
      routes: [
        for (final r in state.routes)
          if (r.id == route.id) r.copyWith(isPublic: newValue) else r,
      ],
      error: null,
    );

    try {
      await _repo.setPrivacy(route.id, newValue);
    } catch (e) {
      state = state.copy(error: 'Failed to update privacy: $e');
    }
  }

  Future<void> deleteRoute(String id) async {
    state = state.copy(
      routes: [for (final r in state.routes) if (r.id != id) r],
      error: null,
    );

    try {
      await _repo.deleteRoute(id);
    } catch (e) {
      state = state.copy(error: 'Failed to delete route: $e');
    }
  }

  Future<void> reload() async {
    state = state.copy(loading: true);
  }
}
