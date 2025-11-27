import 'package:offroad_nav/core/usecase.dart';
import 'package:offroad_nav/core/result.dart';
import '../entities/route_entity.dart';
import '../repositories/routes_repository.dart';


class CreateRoute implements UseCase<String, RouteEntity> {
final RoutesRepository repo;
CreateRoute(this.repo);
@override
Future<Result<String>> call(RouteEntity route) => repo.createRoute(route);
}