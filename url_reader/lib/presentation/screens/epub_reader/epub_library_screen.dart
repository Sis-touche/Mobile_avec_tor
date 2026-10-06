import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/epub_file.dart';
import '../../providers/repository_providers.dart';
import '../../providers/usecase_providers.dart';

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
      appBar: AppBar(title: const Text('Bibliothèque epub')),
      body: filesAsync.when(
        data: (files) {
          if (files.isEmpty) {
            return const Center(child: Text('Aucun fichier epub importé.'));
          }
          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(file.title ?? file.filePath.split('/').last),
                subtitle: file.lastPosition != null ? const Text('Reprendre la lecture') : null,
                onTap: () => context.push('/epub-reader', extra: file),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _importEpub(context, ref),
        icon: const Icon(Icons.file_open_outlined),
        label: const Text('Importer un epub'),
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
      failure: (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
    );
  }
}
