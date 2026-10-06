import '../../core/utils/result.dart';
import '../entities/epub_file.dart';

abstract interface class EpubRepository {
  Future<Result<List<EpubFile>>> getEpubFiles();
  Future<Result<EpubFile>> importEpub(String sourcePath);
  Future<Result<void>> saveReadingPosition(int epubId, String position);
  Future<Result<void>> deleteEpub(int id);
}
