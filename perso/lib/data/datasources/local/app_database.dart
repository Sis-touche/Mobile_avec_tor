import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/epub_files_table.dart';
import 'tables/folders_table.dart';
import 'tables/links_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Links, Folders, EpubFiles])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructeur nommé pour les tests : on passe un exécuteur en mémoire
  /// (`NativeDatabase.memory()`) au lieu du fichier sqlite réel.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(epubFiles, epubFiles.coverPath);
          await m.addColumn(epubFiles, epubFiles.totalChapters);
        }
      },
    );
  }

  // --- Links ---------------------------------------------------------

  Future<List<Link>> allLinks({int? folderId}) {
    final query = select(links);
    if (folderId != null) {
      query.where((t) => t.folderId.equals(folderId));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.get();
  }

  Stream<List<Link>> watchLinks({int? folderId}) {
    final query = select(links);
    if (folderId != null) {
      query.where((t) => t.folderId.equals(folderId));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch();
  }

  Future<int> insertLink(LinksCompanion entry) => into(links).insert(entry);

  Future<bool> updateLinkRow(Link entry) => update(links).replace(entry);

  Future<int> deleteLinkRow(int id) =>
      (delete(links)..where((t) => t.id.equals(id))).go();

  // --- Folders ---------------------------------------------------------

  Future<List<Folder>> allFolders() => select(folders).get();

  Future<int> insertFolder(FoldersCompanion entry) => into(folders).insert(entry);

  Future<int> deleteFolderRow(int id) =>
      (delete(folders)..where((t) => t.id.equals(id))).go();

  // --- Epub files ---------------------------------------------------------

  Future<List<EpubFile>> allEpubFiles() => select(epubFiles).get();

  Future<int> insertEpubFile(EpubFilesCompanion entry) => into(epubFiles).insert(entry);

  Future<int> updateEpubPosition(int id, String position) {
    return (update(epubFiles)..where((t) => t.id.equals(id)))
        .write(EpubFilesCompanion(lastPosition: Value(position)));
  }

  Future<int> deleteEpubFileRow(int id) =>
      (delete(epubFiles)..where((t) => t.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'url_reader.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
