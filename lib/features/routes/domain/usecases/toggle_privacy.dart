import '../../../../core/usecase.dart';
import '../../../../core/result.dart';
import '../repositories/routes_repository.dart';


class TogglePrivacy implements UseCase<void, ({String id, bool isPublic})> {
final IRoutesRepository repo;
TogglePrivacy(this.repo);
@override
Future<Result<void>> call(({String id, bool isPublic}) p) =>
repo.togglePrivacy(p.id, p.isPublic);
}