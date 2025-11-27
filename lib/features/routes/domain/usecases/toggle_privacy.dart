import 'package:offroad_nav/core/usecase.dart';
import 'package:offroad_nav/core/result.dart';
import '../repositories/routes_repository.dart';


class TogglePrivacy implements UseCase<void, ({String id, bool isPublic})> {
final RoutesRepository repo;
TogglePrivacy(this.repo);
@override
Future<Result<void>> call(({String id, bool isPublic}) p) =>
repo.togglePrivacy(p.id, p.isPublic);
}