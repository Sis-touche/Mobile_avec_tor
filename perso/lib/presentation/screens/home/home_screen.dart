import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_reader/presentation/screens/home/home_menu_screen.dart';

import '../../../core/utils/date_format.dart';
import '../../../core/utils/url_utils.dart';
import '../../../domain/entities/link.dart';
import '../../../domain/entities/tor_status.dart';
import '../../providers/browser_tabs_provider.dart';
import '../../providers/links_provider.dart';
import '../../providers/storage_stats_provider.dart';
import '../../providers/tor_provider.dart';
import '../../providers/usecase_providers.dart';
import '../../widgets/circle_icon_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _urlController = TextEditingController();
  final _urlFocusNode = FocusNode();

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  void _openUrl(String raw) {
    final url = normalizeUrlInput(raw);
    if (url == null) return;
    ref.read(browserTabsProvider.notifier).openUrl(url);
    context.push('/browser');
    _urlController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final linksAsync = ref.watch(linksStreamProvider);
    final torStatus = ref.watch(torStatusProvider).valueOrNull ?? TorStatus.initial;

    return Scaffold(
      backgroundColor: kAppBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    CircleIconButton(icon: Icons.shield_outlined, onTap: () => context.push('/tor-info')),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'PERSO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    CircleIconButton(
                      icon: Icons.menu_book_outlined,
                      onTap: () => context.push('/reading-dashboard'),
                    ),
                    const SizedBox(width: 8),
                    CircleIconButton(icon: Icons.settings_outlined, onTap: () => context.push('/settings')),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _TorStatusCard(status: torStatus),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: HomeMenuGrid(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Lectures récentes',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            linksAsync.when(
              data: (links) {
                if (links.isEmpty) {
                  return const SliverToBoxAdapter(child: _EmptyState());
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final link = links[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _LinkCard(
                          link: link,
                          onOpen: () => _openUrl(link.url),
                          onDelete: () => ref.read(deleteLinkProvider)(link.id),
                        ),
                      );
                    },
                    childCount: links.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(child: Text('Erreur : $e', style: const TextStyle(color: Colors.white))),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            const SliverToBoxAdapter(child: _StorageFooter()),
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
    );
  }
}

class _TorStatusCard extends StatelessWidget {
  const _TorStatusCard({required this.status});
  final TorStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (status.state) {
      TorConnectionState.connected => ('Tor actif · port ${status.socksPort}', Icons.security, Colors.greenAccent),
      TorConnectionState.checking => ('Vérification du proxy…', Icons.hourglass_top, Colors.orange),
      TorConnectionState.error => (status.errorMessage ?? 'Proxy Tor indisponible', Icons.error_outline, Colors.redAccent),
      TorConnectionState.disabled => ('Navigation directe (Tor désactivé)', Icons.public, Colors.white54),
    };

    return Material(
      color: kAppSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/settings'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
              Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.link, required this.onOpen, required this.onDelete});
  final Link link;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(link.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      onDismissed: (_) => onDelete(),
      child: Material(
        color: kAppSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.08),
                  child: Icon(
                    link.openedViaTor ? Icons.security : Icons.public,
                    color: link.openedViaTor ? Colors.purple[200] : Colors.white54,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.title?.isNotEmpty == true ? link.title! : link.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        link.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (link.openedViaTor ? Colors.green : Colors.white).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              link.openedViaTor ? 'Tor' : 'Direct',
                              style: TextStyle(
                                color: link.openedViaTor ? Colors.greenAccent : Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatRelativeDate(link.createdAt),
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TextButton(onPressed: onOpen, child: const Text('Lire')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.link_off, size: 48, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('Aucun lien enregistré pour le moment.', style: TextStyle(color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }
}

class _StorageFooter extends ConsumerWidget {
  const _StorageFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(storageStatsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.storage, size: 16, color: Colors.white.withOpacity(0.3)),
              const SizedBox(width: 6),
              stats.when(
                data: (bytes) => Text(
                  '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo utilisés',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                ),
                loading: () => Text('Calcul…', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          Text('Stockage local uniquement', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
        ],
      ),
    );
  }
}
