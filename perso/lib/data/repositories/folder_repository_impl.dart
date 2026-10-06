import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/folder.dart';
import '../../domain/repositories/folder_repository.dart';
import '../datasources/local/app_database.dart' as db;
import '../models/folder_mapper.dart';

class FolderRepositoryImpl implements FolderRepository {
  FolderRepositoryImpl(this._database);
  final db.AppDatabase _database;

  @override
  Future<Result<List<Folder>>> getFolders() async {
    try {
      final rows = await _database.allFolders();
      return Success(rows.map((row) => row.toEntity()).toList());
    } catch (e) {
      return Error(DatabaseFailure('Impossible de charger les dossiers : $e'));
    }
  }

  @override
  Future<Result<Folder>> createFolder(String name) async {
    try {
      final id = await _database.insertFolder(db.FoldersCompanion.insert(name: name));
      return Success(Folder(id: id, name: name));
    } catch (e) {
      return Error(DatabaseFailure('Impossible de créer le dossier : $e'));
    }
  }

  @override
  Future<Result<void>> deleteFolder(int id) async {
    try {
      await _database.deleteFolderRow(id);
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure('Impossible de supprimer le dossier : $e'));
    }
  }
}
