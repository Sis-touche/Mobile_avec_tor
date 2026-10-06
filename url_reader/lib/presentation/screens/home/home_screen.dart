import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/links_provider.dart';
import '../../providers/usecase_providers.dart';
import '../../widgets/link_tile.dart';
import '../../widgets/url_input_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(linksStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes liens'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Bibliothèque epub',
            onPressed: () => context.push('/epub-library'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Paramètres',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: linksAsync.when(
        data: (links) {
          if (links.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: links.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final link = links[index];
              return LinkTile(
                link: link,
                onTap: () => context.push('/browser', extra: link.url),
                onDelete: () => ref.read(deleteLinkProvider)(link.id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final url = await showUrlInputDialog(context);
          if (url != null && context.mounted) {
            context.push('/browser', extra: url);
          }
        },
        icon: const Icon(Icons.add_link),
        label: const Text('Ouvrir une URL'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_off, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Aucun lien enregistré pour le moment.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
