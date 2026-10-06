import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../../domain/entities/epub_file.dart';
import '../../providers/repository_providers.dart';
import '../../providers/usecase_providers.dart';
import '../../widgets/circle_icon_button.dart';

final epubFilesProvider = FutureProvider.autoDispose<List<EpubFile>>((ref) async {
  final result = await ref.watch(epubRepositoryProvider).getEpubFiles();
  return result.when(success: (files) => files, failure: (_) => const []);
});

class EpubLibraryScreen extends ConsumerWidget {
  const EpubLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(epubFilesProvider);

    return Scaffold(
      backgroundColor: kAppBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleIconButton(icon: Icons.arrow_back, onTap: () => context.pop()),
                  CircleIconButton(
                    icon: Icons.add_rounded,
                    accent: true,
                    onTap: () => _importEpub(context, ref),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Ma bibliothèque',
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  filesAsync.maybeWhen(
                    data: (files) => Row(
                      children: [
                        Icon(Icons.menu_book_outlined, color: Colors.white.withOpacity(0.6), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${files.length} livre${files.length > 1 ? 's' : ''}',
                          style: TextStyle(color: Colors.white.withOpacity(0.6)),
                        ),
                      ],
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filesAsync.when(
                data: (files) {
                  if (files.isEmpty) {
                    return Center(
                      child: Text(
                        'Aucun fichier epub importé.',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 162 / 238,
                    ),
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      return _BookCard(
                        file: file,
                        onTap: () => context.push('/epub-reader', extra: file),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Erreur : $e', style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importEpub(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );
    final path = picked?.files.single.path;
    if (path == null) return;

    final result = await ref.read(openEpubProvider)(path);
    if (!context.mounted) return;
    result.when(
      success: (_) => ref.invalidate(epubFilesProvider),
      failure: (f) =>
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.file, required this.onTap});

  final EpubFile file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final coverFile = file.coverPath != null ? File(file.coverPath!) : null;
    final hasCover = coverFile != null && coverFile.existsSync();
    final inProgress = file.lastPosition != null;
    final displayTitle = file.title ?? p.basenameWithoutExtension(file.filePath);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kAppSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasCover)
              Image.file(coverFile, fit: BoxFit.cover)
            else
              _PlaceholderCover(title: displayTitle),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withOpacity(0.08), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    if (inProgress)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: kAppAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kAppAccent.withOpacity(0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded, size: 12, color: Color(0xFFB4BAF8)),
                            SizedBox(width: 4),
                            Text(
                              'En cours',
                              style: TextStyle(color: Color(0xFFB4BAF8), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        'Non commencé',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  const _PlaceholderCover({required this.title});

  final String title;

  static const _palette = [
    Color(0xFF5865F2),
    Color(0xFFEF4444),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[title.hashCode.abs() % _palette.length];
    return DecoratedBox(
      decoration: const BoxDecoration(color: kAppSurface),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded, color: color.withOpacity(0.8), size: 40),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16, height: 1.25),
            ),
          ],
        ),
      ),
    );
  }
}
