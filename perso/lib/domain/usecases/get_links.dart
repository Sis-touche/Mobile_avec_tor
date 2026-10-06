import '../../core/utils/result.dart';
import '../entities/link.dart';
import '../repositories/link_repository.dart';

class GetLinks {
  const GetLinks(this._repository);
  final LinkRepository _repository;

  Future<Result<List<Link>>> call({int? folderId}) {
    return _repository.getLinks(folderId: folderId);
  }
}
