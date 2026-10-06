import '../../core/utils/result.dart';
import '../entities/folder.dart';
import '../repositories/folder_repository.dart';

class CreateFolder {
  const CreateFolder(this._repository);
  final FolderRepository _repository;

  Future<Result<Folder>> call(String name) => _repository.createFolder(name);
}
