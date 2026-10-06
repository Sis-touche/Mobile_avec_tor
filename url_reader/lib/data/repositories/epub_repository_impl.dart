import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:epubx/epubx.dart' as epubx;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/epub_file.dart';
import '../../domain/repositories/epub_repository.dart';
import '../datasources/local/app_database.dart' as db;
import '../models/epub_file_mapper.dart';

class EpubRepositoryImpl implements EpubRepository {
  EpubRepositoryImpl(this._database);
  final db.AppDatabase _database;

  @override
  Future<Result<List<EpubFile>>> getEpubFiles() async {
    try {
      final rows = await _database.allEpubFiles();
      return Success(rows.map((row) => row.toEntity()).toList());
    } catch (e) {
      return Error(DatabaseFailure('Impossible de charger la bibliothèque : $e'));
    }
  }

  @override
  Future<Result<EpubFile>> importEpub(String sourcePath) async {
    try {
      final bytes = await File(sourcePath).readAsBytes();
      // Valide que le fichier est un epub exploitable avant de le copier.
      final book = await epubx.EpubReader.readBook(bytes);

      final docsDir = await getApplicationDocumentsDirectory();
      final epubDir = Directory(p.join(docsDir.path, 'epubs'));
      if (!epubDir.existsSync()) {
        epubDir.createSync(recursive: true);
      }
      final destPath = p.join(epubDir.path, p.basename(sourcePath));
      final destFile = await File(sourcePath).copy(destPath);

      final title = book.Title ?? p.basenameWithoutExtension(sourcePath);
      final addedAt = DateTime.now();

      final id = await _database.insertEpubFile(
        db.EpubFilesCompanion.insert(
          filePath: destFile.path,
          title: Value(title),
          addedAt: addedAt,
        ),
      );

      return Success(
        EpubFile(id: id, filePath: destFile.path, title: title, addedAt: addedAt),
      );
    } catch (e) {
      return Error(EpubParsingFailure("Impossible d'importer ce fichier epub : $e"));
    }
  }

  @override
  Future<Result<void>> saveReadingPosition(int epubId, String position) async {
    try {
      await _database.updateEpubPosition(epubId, position);
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure('Impossible de sauvegarder la position de lecture : $e'));
    }
  }

  @override
  Future<Result<void>> deleteEpub(int id) async {
    try {
      await _database.deleteEpubFileRow(id);
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure('Impossible de supprimer le fichier : $e'));
    }
  }
}
