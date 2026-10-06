import 'package:drift/drift.dart' show Value;

import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/link.dart';
import '../../domain/repositories/link_repository.dart';
import '../datasources/local/app_database.dart' as db;
import '../models/link_mapper.dart';

class LinkRepositoryImpl implements LinkRepository {
  LinkRepositoryImpl(this._database);
  final db.AppDatabase _database;

  @override
  Future<Result<List<Link>>> getLinks({int? folderId}) async {
    try {
      final rows = await _database.allLinks(folderId: folderId);
      return Success(rows.map((row) => row.toEntity()).toList());
    } catch (e) {
      return Error(DatabaseFailure('Impossible de charger les liens : $e'));
    }
  }

  @override
  Stream<List<Link>> watchLinks({int? folderId}) {
    return _database
        .watchLinks(folderId: folderId)
        .map((rows) => rows.map((row) => row.toEntity()).toList());
  }

  @override
  Future<Result<Link>> saveLink({
    required String url,
    String? title,
    int? folderId,
    bool openedViaTor = false,
  }) async {
    try {
      final createdAt = DateTime.now();
      final id = await _database.insertLink(
        db.LinksCompanion.insert(
          url: url,
          title: Value(title),
          createdAt: createdAt,
          folderId: Value(folderId),
          openedViaTor: Value(openedViaTor),
        ),
      );
      return Success(
        Link(
          id: id,
          url: url,
          title: title,
          createdAt: createdAt,
          folderId: folderId,
          openedViaTor: openedViaTor,
        ),
      );
    } catch (e) {
      return Error(DatabaseFailure("Impossible d'enregistrer le lien : $e"));
    }
  }

  @override
  Future<Result<void>> deleteLink(int id) async {
    try {
      await _database.deleteLinkRow(id);
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure('Impossible de supprimer le lien : $e'));
    }
  }

  @override
  Future<Result<Link>> updateLink(Link link) async {
    try {
      await _database.updateLinkRow(
        db.Link(
          id: link.id,
          url: link.url,
          title: link.title,
          createdAt: link.createdAt,
          folderId: link.folderId,
          openedViaTor: link.openedViaTor,
        ),
      );
      return Success(link);
    } catch (e) {
      return Error(DatabaseFailure('Impossible de mettre à jour le lien : $e'));
    }
  }
}
