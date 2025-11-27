import 'package:offroad_nav/core/failure.dart';
import 'package:offroad_nav/core/result.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/repositories/routes_repository.dart';
import '../models/route_model.dart';
import '../datasources/routes_remote_ds.dart';


class RoutesRepositoryImpl implements RoutesRepository {
final RoutesRemoteDataSource remote;
RoutesRepositoryImpl(this.remote);

@override
Future<Result<List<RouteEntity>>> getVisibleRoutes(String userId) async {
  try {
    final models = await remote.fetchVisibleForUser(userId);
    final entities =
        models.map((m) => m.toEntity(m.id!)).toList();
    return Result.ok(entities);
  } on Failure catch (f) {
    return Result.err(f);
  } catch (e) {
    return Result.err(ServerFailure(e.toString()));
  }
}

@override
Future<Result<List<RouteEntity>>> getMyRoutes(String userId) async {
try {
final models = await remote.fetchByOwner(userId);
return Result.ok(models.map((m) => m.toEntity(m.id!)).toList());
} on Failure catch (f) {
return Result.err(f);
} catch (e) {
return Result.err(ServerFailure(e.toString()));
}
}


@override
Future<Result<String>> createRoute(RouteEntity e) async {
try {
final id = await remote.create(RouteModel.fromEntity(e));
return Result.ok(id);
} on Failure catch (f) {
return Result.err(f);
} catch (e) {
return Result.err(ServerFailure(e.toString()));
}
}


@override
Future<Result<void>> togglePrivacy(String routeId, bool isPublic) async {
try {
await remote.setPrivacy(routeId, isPublic);
return Result.okVoid(); 
} on Failure catch (f) {
return Result.err(f);
} catch (e) {
return Result.err(ServerFailure(e.toString()));
}
}
}