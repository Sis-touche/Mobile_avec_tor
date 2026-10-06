import '../../domain/entities/epub_file.dart';
import '../datasources/local/app_database.dart' as db;

extension EpubFileRowMapper on db.EpubFile {
  EpubFile toEntity() {
    return EpubFile(
      id: id,
      filePath: filePath,
      title: title,
      addedAt: addedAt,
      lastPosition: lastPosition,
      coverPath: coverPath,
      totalChapters: totalChapters,
    );
  }
}
