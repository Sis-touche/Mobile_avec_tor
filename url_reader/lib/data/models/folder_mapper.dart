import '../../domain/entities/folder.dart';
import '../datasources/local/app_database.dart' as db;

extension FolderRowMapper on db.Folder {
  Folder toEntity() => Folder(id: id, name: name);
}
