import 'dart:async';
import 'dart:io';

import 'package:epubx/epubx.dart' as epubx;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/epub_file.dart';
import '../../providers/usecase_providers.dart';

class EpubReaderScreen extends ConsumerStatefulWidget {
  const EpubReaderScreen({super.key, required this.epubFile});

  final EpubFile epubFile;

  @override
  ConsumerState<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends ConsumerState<EpubReaderScreen> {
  epubx.EpubBook? _book;
  int _chapterIndex = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    try {
      final bytes = await File(widget.epubFile.filePath).readAsBytes();
      final book = await epubx.EpubReader.readBook(bytes);
      final savedIndex = int.tryParse(widget.epubFile.lastPosition ?? '') ?? 0;
      final chapterCount = book.Chapters?.length ?? 1;
      setState(() {
        _book = book;
        _chapterIndex = savedIndex.clamp(0, chapterCount - 1);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Impossible d'ouvrir ce fichier epub : $e";
        _loading = false;
      });
    }
  }

  List<epubx.EpubChapter> get _chapters => _book?.Chapters ?? const [];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lecteur')),
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!))),
      );
    }

    final chapter = _chapters.isNotEmpty ? _chapters[_chapterIndex] : null;
    final htmlContent = chapter?.HtmlContent ?? '<p>Chapitre vide.</p>';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          chapter?.Title ?? widget.epubFile.title ?? 'Lecteur',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      // Rendu HTML simple, scroll continu — pas de pagination avancée en V1
      // (voir non-objectifs V1 du README).
      body: InAppWebView(
        initialData: InAppWebViewInitialData(data: htmlContent, mimeType: 'text/html'),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _chapterIndex > 0 ? () => _goToChapter(_chapterIndex - 1) : null,
            ),
            Text('Chapitre ${_chapterIndex + 1} / ${_chapters.length}'),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed:
                  _chapterIndex < _chapters.length - 1 ? () => _goToChapter(_chapterIndex + 1) : null,
            ),
          ],
        ),
      ),
    );
  }

  void _goToChapter(int index) {
    setState(() => _chapterIndex = index);
    unawaited(ref.read(saveReadingPositionProvider)(widget.epubFile.id, '$index'));
  }
}
