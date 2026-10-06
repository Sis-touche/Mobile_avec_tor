import 'package:equatable/equatable.dart';

class EpubFile extends Equatable {
  const EpubFile({
    required this.id,
    required this.filePath,
    required this.title,
    required this.addedAt,
    this.lastPosition,
    this.coverPath,
    this.totalChapters,
  });

  final int id;
  final String filePath;
  final String? title;
  final DateTime addedAt;
  final String? lastPosition;
  final String? coverPath;
  final int? totalChapters;

  @override
  List<Object?> get props =>
      [id, filePath, title, addedAt, lastPosition, coverPath, totalChapters];
}
