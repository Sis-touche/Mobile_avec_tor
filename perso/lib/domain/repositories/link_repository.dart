import '../../core/utils/result.dart';
import '../entities/link.dart';

abstract interface class LinkRepository {
  Future<Result<List<Link>>> getLinks({int? folderId});
  Future<Result<Link>> saveLink({
    required String url,
    String? title,
    int? folderId,
    bool openedViaTor = false,
  });
  Future<Result<void>> deleteLink(int id);
  Future<Result<Link>> updateLink(Link link);
  Stream<List<Link>> watchLinks({int? folderId});
}
