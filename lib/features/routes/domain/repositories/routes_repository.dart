import '../../../../core/result.dart';
import '../entities/route_entity.dart';


abstract interface class IRoutesRepository {
Future<Result<List<RouteEntity>>> getVisibleRoutes(String userId);
Future<Result<List<RouteEntity>>> getMyRoutes(String userId);
Future<Result<String>> createRoute(RouteEntity route);
Future<Result<void>> togglePrivacy(String routeId, bool isPublic);
}