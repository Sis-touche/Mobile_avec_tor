import '../../core/utils/result.dart';
import '../repositories/epub_repository.dart';

class SaveReadingPosition {
  const SaveReadingPosition(this._repository);
  final EpubRepository _repository;

  Future<Result<void>> call(int epubId, String position) =>
      _repository.saveReadingPosition(epubId, position);
}
