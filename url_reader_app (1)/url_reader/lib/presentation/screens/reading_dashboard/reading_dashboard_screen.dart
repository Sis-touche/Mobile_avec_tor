import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/epub_file.dart';
import '../../widgets/circle_icon_button.dart';
import '../epub_reader/epub_library_screen.dart' show epubFilesProvider;

class ReadingDashboardScreen extends ConsumerWidget {
  const ReadingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(epubFilesProvider);

    return Scaffold(
      backgroundColor: kAppBackground,
      body: SafeArea(
        child: filesAsync.when(
          data: (files) {
            if (files.isEmpty) {
              return _EmptyDashboard(onImport: () => context.push('/epub-library'));
            }

            final inProgress = files.where((f) => f.lastPosition != null).toList()
              ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
            final current = inProgress.isNotEmpty ? inProgress.first : files.first;
            final doneCount = files.where((f) {
              final pos = int.tryParse(f.lastPosition ?? '');
              final total = f.totalChapters;
              return pos != null && total != null && total > 0 && pos >= total - 1;
            }).length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleIconButton(icon: Icons.arrow_back, onTap: () => context.pop()),
                    CircleIconButton(
                      icon: Icons.menu_book_outlined,
                      onTap: () => context.push('/epub-library'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _CurrentlyReadingCard(
                  file: current,
                  onTap: () => context.push('/epub-reader', extra: current),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _StatTile(icon: Icons.menu_book, value: '${files.length}', label: 'livres')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(icon: Icons.check_circle_outline, value: '$doneCount', label: 'terminés'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Votre bibliothèque',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => context.push('/epub-library'),
                      child: const Text('Voir tout →'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: files.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final file = files[index];
                      return _ShelfThumbnail(
                        file: file,
                        onTap: () => context.push('/epub-reader', extra: file),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e', style: const TextStyle(color: Colors.white))),
        ),
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard({required this.onImport});
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 48, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text('Aucun livre importé pour le moment.', style: TextStyle(color: Colors.white.withOpacity(0.5))),
            const SizedBox(height: 16),
            FilledButton(onPressed: onImport, child: const Text('Aller à la bibliothèque')),
          ],
        ),
      ),
    );
  }
}

class _CurrentlyReadingCard extends StatelessWidget {
  const _CurrentlyReadingCard({required this.file, required this.onTap});
  final EpubFile file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final current = int.tryParse(file.lastPosition ?? '0') ?? 0;
    final total = file.totalChapters;
    final progress = (total != null && total > 0) ? (current + 1) / total : null;
    final hasCover = file.coverPath != null && File(file.coverPath!).existsSync();

    return Material(
      color: kAppSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 90,
                  height: 130,
                  child: hasCover
                      ? Image.file(File(file.coverPath!), fit: BoxFit.cover)
                      : Container(
                          color: kAppBackground,
                          alignment: Alignment.center,
                          child: const Icon(Icons.menu_book_rounded, color: kAppAccent),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('En cours de lecture', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                    const SizedBox(height: 6),
                    Text(
                      file.title ?? 'Sans titre',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (progress != null) ...[
                      Text(
                        '${(progress * 100).clamp(0, 100).toStringAsFixed(0)} %',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Chapitre ${current + 1} / $total',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0, 1),
                          backgroundColor: Colors.white.withOpacity(0.1),
                          color: kAppAccent,
                          minHeight: 6,
                        ),
                      ),
                    ] else
                      Text('Pas encore commencé', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(color: kAppSurface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.7)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        ],
      ),
    );
  }
}

class _ShelfThumbnail extends StatelessWidget {
  const _ShelfThumbnail({required this.file, required this.onTap});
  final EpubFile file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasCover = file.coverPath != null && File(file.coverPath!).existsSync();
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 100,
          child: hasCover
              ? Image.file(File(file.coverPath!), fit: BoxFit.cover)
              : Container(
                  color: kAppSurface,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    file.title ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
        ),
      ),
    );
  }
}
