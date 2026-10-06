import '../../core/utils/result.dart';
import '../entities/folder.dart';

abstract interface class FolderRepository {
  Future<Result<List<Folder>>> getFolders();
  Future<Result<Folder>> createFolder(String name);
  Future<Result<void>> deleteFolder(int id);
}
