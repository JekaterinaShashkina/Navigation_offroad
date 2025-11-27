import 'package:offroad_nav/core/usecase.dart';
import 'package:offroad_nav/core/result.dart';
import '../entities/route_entity.dart';
import '../repositories/routes_repository.dart';


class GetMyRoutes implements UseCase<List<RouteEntity>, String> {
final RoutesRepository repo;
GetMyRoutes(this.repo);
@override
Future<Result<List<RouteEntity>>> call(String userId) => repo.getMyRoutes(userId);
}