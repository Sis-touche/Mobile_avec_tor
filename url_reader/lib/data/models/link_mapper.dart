import '../../domain/entities/link.dart';
import '../datasources/local/app_database.dart' as db;

extension LinkRowMapper on db.Link {
  Link toEntity() {
    return Link(
      id: id,
      url: url,
      title: title,
      createdAt: createdAt,
      folderId: folderId,
      openedViaTor: openedViaTor,
    );
  }
}
