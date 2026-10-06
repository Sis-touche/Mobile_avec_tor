import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epubx/epubx.dart' as epubx;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/epub_file.dart';
import '../../providers/usecase_providers.dart';

// ---------------------------------------------------------------------------
// Écran de lecture EPUB — V2 (+ correctif écran de chargement bloqué)
//
// Correctif ajouté après coup : `_onLoadStop` pouvait ne jamais appeler son
// `setState(() => _pageLoading = false)` final si `evaluateJavascript`
// échouait ou ne se résolvait jamais, laissant l'overlay de chargement
// affiché indéfiniment par-dessus un contenu pourtant chargé en dessous.
// Ajout d'un `try/finally` dans `_onLoadStop` et d'un minuteur de sécurité
// (`_loadingSafetyTimer`) qui force la disparition de l'overlay au bout de
// quelques secondes quoi qu'il arrive.
// ---------------------------------------------------------------------------

enum ReaderTheme { light, sepia, dark, black }

extension ReaderThemeStyle on ReaderTheme {
  Color get background {
    switch (this) {
      case ReaderTheme.light:
        return const Color(0xFFFFFFFF);
      case ReaderTheme.sepia:
        return const Color(0xFFF4ECD8);
      case ReaderTheme.dark:
        return const Color(0xFF1E1E1E);
      case ReaderTheme.black:
        return const Color(0xFF000000);
    }
  }

  Color get foreground {
    switch (this) {
      case ReaderTheme.light:
        return const Color(0xFF1A1A1A);
      case ReaderTheme.sepia:
        return const Color(0xFF3B2F1E);
      case ReaderTheme.dark:
        return const Color(0xFFE0E0E0);
      case ReaderTheme.black:
        return const Color(0xFFC9C9C9);
    }
  }

  Color get accent {
    switch (this) {
      case ReaderTheme.light:
        return const Color(0xFF3D5AFE);
      case ReaderTheme.sepia:
        return const Color(0xFF8B5E34);
      case ReaderTheme.dark:
        return const Color(0xFF82AAFF);
      case ReaderTheme.black:
        return const Color(0xFF6E8BFF);
    }
  }

  String get label {
    switch (this) {
      case ReaderTheme.light:
        return 'Clair';
      case ReaderTheme.sepia:
        return 'Sépia';
      case ReaderTheme.dark:
        return 'Sombre';
      case ReaderTheme.black:
        return 'Nuit';
    }
  }

  IconData get icon {
    switch (this) {
      case ReaderTheme.light:
        return Icons.light_mode_outlined;
      case ReaderTheme.sepia:
        return Icons.menu_book_outlined;
      case ReaderTheme.dark:
        return Icons.dark_mode_outlined;
      case ReaderTheme.black:
        return Icons.bedtime_outlined;
    }
  }
}

enum ReaderFontFamily { serif, sans }

/// Préférences de lecture (en mémoire pour la session en cours).
class _ReaderSettings {
  const _ReaderSettings({
    this.theme = ReaderTheme.light,
    this.fontSize = 17,
    this.lineHeight = 1.6,
    this.fontFamily = ReaderFontFamily.serif,
    this.justify = true,
  });

  final ReaderTheme theme;
  final double fontSize;
  final double lineHeight;
  final ReaderFontFamily fontFamily;
  final bool justify;

  _ReaderSettings copyWith({
    ReaderTheme? theme,
    double? fontSize,
    double? lineHeight,
    ReaderFontFamily? fontFamily,
    bool? justify,
  }) {
    return _ReaderSettings(
      theme: theme ?? this.theme,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      fontFamily: fontFamily ?? this.fontFamily,
      justify: justify ?? this.justify,
    );
  }
}

class EpubReaderScreen extends ConsumerStatefulWidget {
  const EpubReaderScreen({super.key, required this.epubFile});

  final EpubFile epubFile;

  @override
  ConsumerState<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends ConsumerState<EpubReaderScreen> {
  static final RegExp _bodyPattern =
  RegExp(r'<body[^>]*>(.*)</body>', dotAll: true, caseSensitive: false);
  static final RegExp _stylePattern =
  RegExp(r'<style[^>]*>.*?</style>', dotAll: true, caseSensitive: false);
  static final RegExp _linkStylePattern = RegExp(
    '''<link[^>]*rel=["']stylesheet["'][^>]*>''',
    caseSensitive: false,
  );
  static final RegExp _imgPattern = RegExp(
    '''<img([^>]*)src=["']([^"']+)["']([^>]*)>''',
    caseSensitive: false,
  );

  epubx.EpubBook? _book;
  int _chapterIndex = 0;
  double _scrollRatio = 0.0;
  bool _loading = true;
  bool _pageLoading = true;
  bool _chromeVisible = true;
  String? _error;
  String _currentHtml = '';
  _ReaderSettings _settings = const _ReaderSettings();
  InAppWebViewController? _webController;
  Timer? _persistDebounce;

  /// Filet de sécurité : force la disparition de l'overlay de chargement au
  /// bout de quelques secondes même si `_onLoadStop` n'a jamais pu terminer
  /// normalement (ex. `evaluateJavascript` qui échoue silencieusement).
  Timer? _loadingSafetyTimer;

  List<epubx.EpubChapter> get _chapters => _book?.Chapters ?? const [];

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  @override
  void dispose() {
    _persistDebounce?.cancel();
    _loadingSafetyTimer?.cancel();
    super.dispose();
  }

  void _armLoadingSafety() {
    _loadingSafetyTimer?.cancel();
    _loadingSafetyTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _pageLoading) setState(() => _pageLoading = false);
    });
  }

  Future<void> _loadBook() async {
    try {
      final bytes = await File(widget.epubFile.filePath).readAsBytes();
      final book = await epubx.EpubReader.readBook(bytes);
      final chapterCount = book.Chapters?.length ?? 1;
      final parsed = _parsePosition(widget.epubFile.lastPosition, chapterCount);

      _book = book;
      _chapterIndex = parsed.chapterIndex;
      _scrollRatio = parsed.scrollRatio;
      _currentHtml = _buildHtmlDocument(
        _chapters.isNotEmpty ? _chapters[_chapterIndex] : null,
      );

      _armLoadingSafety();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Impossible d'ouvrir ce fichier epub : $e";
          _loading = false;
        });
      }
    }
  }

  /// Format persisté : "<indexChapitre>:<ratioScroll>", ex. "3:0.4210".
  /// Reste compatible avec l'ancien format (juste un entier).
  ({int chapterIndex, double scrollRatio}) _parsePosition(
      String? raw,
      int chapterCount,
      ) {
    if (raw == null || raw.isEmpty) {
      return (chapterIndex: 0, scrollRatio: 0.0);
    }
    final parts = raw.split(':');
    final idx = (int.tryParse(parts[0]) ?? 0).clamp(0, chapterCount - 1);
    final ratio = parts.length > 1
        ? (double.tryParse(parts[1]) ?? 0.0).clamp(0.0, 1.0)
        : 0.0;
    return (chapterIndex: idx, scrollRatio: ratio);
  }

  // ---------------------------------------------------------------------
  // Construction du document HTML injecté dans la WebView
  // ---------------------------------------------------------------------

  String _buildHtmlDocument(epubx.EpubChapter? chapter) {
    final raw = chapter?.HtmlContent ?? '<p style="opacity:.6">Chapitre vide.</p>';

    var innerHtml = raw;
    final bodyMatch = _bodyPattern.firstMatch(raw);
    if (bodyMatch != null) {
      innerHtml = bodyMatch.group(1) ?? raw;
    }
    // On retire les styles d'origine de l'epub pour garder un rendu cohérent
    // et entièrement pilotable depuis les réglages de lecture.
    innerHtml = innerHtml.replaceAll(_stylePattern, '');
    innerHtml = innerHtml.replaceAll(_linkStylePattern, '');
    innerHtml = _inlineImages(innerHtml);

    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
<style id="reader-vars">${_buildCss(_settings)}</style>
</head>
<body>
$innerHtml
<script>${_bridgeScript()}</script>
</body>
</html>
''';
  }

  /// Remplace les `<img src="...">` par des data URI base64 résolues depuis
  /// les ressources embarquées de l'epub. Sans ça, les images ne s'affichent
  /// pas : les chemins relatifs ne se résolvent pas dans une WebView chargée
  /// via `initialData` / `loadData`.
  String _inlineImages(String html) {
    try {
      final images = _book?.Content?.Images;
      if (images == null || images.isEmpty) return html;

      return html.replaceAllMapped(_imgPattern, (match) {
        final before = match.group(1) ?? '';
        final src = match.group(2) ?? '';
        final after = match.group(3) ?? '';
        final fileName = src.split('/').last;

        epubx.EpubByteContentFile? found;
        for (final entry in images.entries) {
          if (entry.key.split('/').last.toLowerCase() == fileName.toLowerCase()) {
            found = entry.value;
            break;
          }
        }

        final bytes = found?.Content;
        if (bytes == null) return match.group(0) ?? '';

        final mime = _guessMimeType(fileName);
        final base64Data = base64Encode(bytes);
        return '<img$before src="data:$mime;base64,$base64Data"$after>';
      });
    } catch (_) {
      // Si la structure d'epubx diffère de ce qui est attendu (version du
      // package différente), on garde le HTML original plutôt que de casser
      // l'affichage du chapitre.
      return html;
    }
  }

  String _guessMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _buildCss(_ReaderSettings s) {
    final bg = _cssColor(s.theme.background);
    final fg = _cssColor(s.theme.foreground);
    final accent = _cssColor(s.theme.accent);
    final family = s.fontFamily == ReaderFontFamily.serif
        ? "Georgia, 'Times New Roman', serif"
        : "-apple-system, Roboto, 'Segoe UI', sans-serif";

    return '''
      html, body { background:$bg !important; color:$fg !important; }
      body {
        font-family:$family;
        font-size:${s.fontSize.round()}px;
        line-height:${s.lineHeight};
        text-align:${s.justify ? 'justify' : 'left'};
        -webkit-hyphens:auto; hyphens:auto;
        padding:28px 22px 100px;
        max-width:720px; margin:0 auto;
        word-wrap:break-word;
        transition:background 0.25s ease, color 0.25s ease;
      }
      p { margin:0 0 1.1em 0; text-indent:1.2em; }
      h1, h2, h3, h4 { line-height:1.3; margin:1.5em 0 0.6em; color:$fg; }
      img, svg { max-width:100%; height:auto; display:block; margin:1.6em auto; border-radius:10px; }
      a { color:$accent; }
      blockquote { border-left:3px solid $accent; margin:1.2em 0; padding:0.3em 1.2em; opacity:0.88; font-style:italic; }
      ::selection { background:$accent; color:#fff; }
    ''';
  }

  String _cssColor(Color c) =>
      '#${(c.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  String _bridgeScript() {
    return '''
      (function() {
        var lastRatio = -1;
        function reportScroll() {
          var scrollTop = window.scrollY || document.documentElement.scrollTop;
          var maxScroll = document.documentElement.scrollHeight - window.innerHeight;
          var ratio = maxScroll > 0 ? Math.min(1, Math.max(0, scrollTop / maxScroll)) : 0;
          if (Math.abs(ratio - lastRatio) > 0.002 && window.flutter_inappwebview) {
            lastRatio = ratio;
            window.flutter_inappwebview.callHandler('onScroll', ratio);
          }
        }
        var ticking = false;
        window.addEventListener('scroll', function() {
          if (!ticking) {
            window.requestAnimationFrame(function() {
              reportScroll();
              ticking = false;
            });
            ticking = true;
          }
        }, { passive: true });
        document.body.addEventListener('click', function() {
          if (window.flutter_inappwebview) {
            window.flutter_inappwebview.callHandler('onTap');
          }
        });
      })();
    ''';
  }

  // ---------------------------------------------------------------------
  // Navigation & persistance
  // ---------------------------------------------------------------------

  Future<void> _goToChapter(int index) async {
    if (index < 0 || index >= _chapters.length || index == _chapterIndex) return;
    HapticFeedback.selectionClick();

    final html = _buildHtmlDocument(_chapters[index]);
    setState(() {
      _chapterIndex = index;
      _scrollRatio = 0.0;
      _pageLoading = true;
      _currentHtml = html;
    });
    _armLoadingSafety();

    // Recharge explicitement le contenu : `initialData` ne suffit pas ici,
    // il n'est pris en compte qu'à la création du widget WebView.
    await _webController?.loadData(data: html, mimeType: 'text/html');
    _persistPosition();
  }

  void _persistPosition() {
    final pos = '$_chapterIndex:${_scrollRatio.toStringAsFixed(4)}';
    unawaited(ref.read(saveReadingPositionProvider)(widget.epubFile.id, pos));
  }

  void _debouncePersist() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 1200), _persistPosition);
  }

  void _handleSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -250) {
      _goToChapter(_chapterIndex + 1);
    } else if (velocity > 250) {
      _goToChapter(_chapterIndex - 1);
    }
  }

  void _updateSettings(_ReaderSettings next) {
    setState(() => _settings = next);
    _pushSettingsToWebView();
  }

  /// Applique les nouveaux réglages (thème, police, taille...) en direct,
  /// sans recharger la page ni perdre la position de scroll.
  Future<void> _pushSettingsToWebView() async {
    final css = _buildCss(_settings).replaceAll("'", "\\'").replaceAll('\n', ' ');
    await _webController?.evaluateJavascript(source: '''
      (function() {
        var el = document.getElementById('reader-vars');
        if (el) { el.innerHTML = '$css'; }
      })();
    ''');
  }

  // ---------------------------------------------------------------------
  // Callbacks WebView
  // ---------------------------------------------------------------------

  void _onScrollFromJs(List<dynamic> args) {
    if (args.isEmpty) return;
    final ratio = (args.first as num).toDouble().clamp(0.0, 1.0);
    _scrollRatio = ratio;
    _debouncePersist();
    if (mounted) setState(() {});
  }

  Future<void> _onLoadStop(InAppWebViewController controller, WebUri? url) async {
    try {
      if (_scrollRatio > 0) {
        await controller.evaluateJavascript(source: '''
          (function() {
            var h = document.documentElement.scrollHeight - window.innerHeight;
            if (h > 0) { window.scrollTo(0, ${_scrollRatio} * h); }
          })();
        ''');
      }
    } catch (_) {
      // Une erreur ici ne doit jamais bloquer l'affichage — au pire, la
      // position de scroll ne sera pas restaurée pour cette ouverture.
    } finally {
      _loadingSafetyTimer?.cancel();
      if (mounted) setState(() => _pageLoading = false);
    }
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoadingScaffold();
    if (_error != null) return _buildErrorScaffold();

    final chapter = _chapters.isNotEmpty ? _chapters[_chapterIndex] : null;
    final theme = _settings.theme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: _chromeVisible ? _buildAppBar(chapter, theme) : null,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Container(color: theme.background),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: _handleSwipe,
              child: InAppWebView(
                initialData: InAppWebViewInitialData(
                  data: _currentHtml,
                  mimeType: 'text/html',
                ),
                initialSettings: InAppWebViewSettings(
                  transparentBackground: true,
                  javaScriptEnabled: true,
                ),
                gestureRecognizers: {
                  Factory<HorizontalDragGestureRecognizer>(
                        () => HorizontalDragGestureRecognizer(),
                  ),
                },
                onWebViewCreated: (controller) {
                  _webController = controller;
                  controller.addJavaScriptHandler(
                    handlerName: 'onScroll',
                    callback: _onScrollFromJs,
                  );
                  controller.addJavaScriptHandler(
                    handlerName: 'onTap',
                    callback: (_) => setState(() => _chromeVisible = !_chromeVisible),
                  );
                },
                onLoadStop: _onLoadStop,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_pageLoading,
                child: AnimatedOpacity(
                  opacity: _pageLoading ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Container(
                    color: theme.background,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildProgressBar(theme),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedOpacity(
        opacity: _chromeVisible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !_chromeVisible,
          child: _buildBottomBar(theme),
        ),
      ),
    );
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Ouverture du livre…', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScaffold() {
    return Scaffold(
      appBar: AppBar(title: const Text('Lecteur')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadBook();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(epubx.EpubChapter? chapter, ReaderTheme theme) {
    return AppBar(
      backgroundColor: theme.background,
      foregroundColor: theme.foreground,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        chapter?.Title ?? widget.epubFile.title ?? 'Lecteur',
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.menu_book_outlined),
          tooltip: 'Sommaire',
          onPressed: _openToc,
        ),
        IconButton(
          icon: const Icon(Icons.text_fields),
          tooltip: 'Apparence',
          onPressed: _openSettings,
        ),
      ],
    );
  }

  Widget _buildBottomBar(ReaderTheme theme) {
    final hasMultipleChapters = _chapters.length > 1;
    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        border: Border(top: BorderSide(color: theme.foreground.withOpacity(0.08))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              color: theme.foreground,
              onPressed: _chapterIndex > 0 ? () => _goToChapter(_chapterIndex - 1) : null,
            ),
            Expanded(
              child: Slider(
                value: _chapterIndex.toDouble(),
                min: 0,
                max: hasMultipleChapters ? (_chapters.length - 1).toDouble() : 1,
                divisions: hasMultipleChapters ? _chapters.length - 1 : null,
                activeColor: theme.accent,
                label: 'Chapitre ${_chapterIndex + 1}',
                onChanged: hasMultipleChapters ? (v) => _goToChapter(v.round()) : null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              color: theme.foreground,
              onPressed: _chapterIndex < _chapters.length - 1
                  ? () => _goToChapter(_chapterIndex + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(ReaderTheme theme) {
    final overall =
    _chapters.isEmpty ? 0.0 : (_chapterIndex + _scrollRatio) / _chapters.length;
    return AnimatedOpacity(
      opacity: _chromeVisible ? 1 : 0.35,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        height: 3,
        child: LinearProgressIndicator(
          value: overall.clamp(0.0, 1.0),
          backgroundColor: theme.foreground.withOpacity(0.08),
          valueColor: AlwaysStoppedAnimation(theme.accent),
        ),
      ),
    );
  }

  void _openToc() {
    final theme = _settings.theme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (ctx, scrollController) {
            return ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _chapters.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: theme.foreground.withOpacity(0.08),
              ),
              itemBuilder: (ctx, i) {
                final active = i == _chapterIndex;
                return ListTile(
                  title: Text(
                    _chapters[i].Title ?? 'Chapitre ${i + 1}',
                    style: TextStyle(
                      color: theme.foreground,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: active ? theme.accent : theme.foreground.withOpacity(0.1),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        color: active ? Colors.white : theme.foreground,
                      ),
                    ),
                  ),
                  selected: active,
                  onTap: () {
                    Navigator.pop(ctx);
                    _goToChapter(i);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Apparence de lecture', style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    children: ReaderTheme.values.map((t) {
                      final selected = t == _settings.theme;
                      return ChoiceChip(
                        label: Text(t.label),
                        avatar: Icon(t.icon, size: 16),
                        selected: selected,
                        onSelected: (_) {
                          setSheetState(() {});
                          _updateSettings(_settings.copyWith(theme: t));
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('Taille du texte', style: Theme.of(ctx).textTheme.labelLarge),
                  Slider(
                    value: _settings.fontSize,
                    min: 13,
                    max: 26,
                    divisions: 13,
                    label: '${_settings.fontSize.round()}',
                    onChanged: (v) {
                      setSheetState(() {});
                      _updateSettings(_settings.copyWith(fontSize: v));
                    },
                  ),
                  Text('Interligne', style: Theme.of(ctx).textTheme.labelLarge),
                  Slider(
                    value: _settings.lineHeight,
                    min: 1.2,
                    max: 2.2,
                    divisions: 10,
                    label: _settings.lineHeight.toStringAsFixed(1),
                    onChanged: (v) {
                      setSheetState(() {});
                      _updateSettings(_settings.copyWith(lineHeight: v));
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {});
                            _updateSettings(
                              _settings.copyWith(fontFamily: ReaderFontFamily.serif),
                            );
                          },
                          child: const Text('Serif', style: TextStyle(fontFamily: 'Georgia')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {});
                            _updateSettings(
                              _settings.copyWith(fontFamily: ReaderFontFamily.sans),
                            );
                          },
                          child: const Text('Sans-serif'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}