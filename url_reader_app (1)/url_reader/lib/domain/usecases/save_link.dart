import '../../core/utils/result.dart';
import '../entities/link.dart';
import '../repositories/link_repository.dart';

class SaveLink {
  const SaveLink(this._repository);
  final LinkRepository _repository;

  Future<Result<Link>> call({
    required String url,
    String? title,
    int? folderId,
    bool openedViaTor = false,
  }) {
    return _repository.saveLink(
      url: url,
      title: title,
      folderId: folderId,
      openedViaTor: openedViaTor,
    );
  }
}
