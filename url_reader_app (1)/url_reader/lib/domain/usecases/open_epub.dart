import '../../core/utils/result.dart';
import '../entities/epub_file.dart';
import '../repositories/epub_repository.dart';

class OpenEpub {
  const OpenEpub(this._repository);
  final EpubRepository _repository;

  Future<Result<EpubFile>> call(String sourcePath) {
    return _repository.importEpub(sourcePath);
  }
}
