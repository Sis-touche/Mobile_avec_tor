import 'package:equatable/equatable.dart';

class Link extends Equatable {
  const Link({
    required this.id,
    required this.url,
    required this.title,
    required this.createdAt,
    this.folderId,
    this.openedViaTor = false,
  });

  final int id;
  final String url;
  final String? title;
  final DateTime createdAt;
  final int? folderId;
  final bool openedViaTor;

  Link copyWith({
    String? url,
    String? title,
    int? folderId,
    bool? openedViaTor,
  }) {
    return Link(
      id: id,
      url: url ?? this.url,
      title: title ?? this.title,
      createdAt: createdAt,
      folderId: folderId ?? this.folderId,
      openedViaTor: openedViaTor ?? this.openedViaTor,
    );
  }

  @override
  List<Object?> get props => [id, url, title, createdAt, folderId, openedViaTor];
}
