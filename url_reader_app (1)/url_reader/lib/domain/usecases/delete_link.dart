import '../../core/utils/result.dart';
import '../repositories/link_repository.dart';

class DeleteLink {
  const DeleteLink(this._repository);
  final LinkRepository _repository;

  Future<Result<void>> call(int id) => _repository.deleteLink(id);
}
