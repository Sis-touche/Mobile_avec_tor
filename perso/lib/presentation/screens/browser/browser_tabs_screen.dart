import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/browser_tab.dart';
import '../../providers/browser_tabs_provider.dart';
import '../../widgets/circle_icon_button.dart';

class BrowserTabsScreen extends ConsumerWidget {
  const BrowserTabsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(browserTabsProvider);

    return Scaffold(
      backgroundColor: kAppBackground,
      appBar: AppBar(
        backgroundColor: kAppBackground,
        title: const Text('Onglets'),
      ),
      body: Column(
        children: [
          Expanded(
            child: state.tabs.isEmpty
                ? Center(
                    child: Text(
                      'Aucun onglet ouvert.',
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.tabs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tab = state.tabs[index];
                      final isActive = tab.id == state.activeTabId;
                      return _TabCard(
                        tab: tab,
                        isActive: isActive,
                        onTap: () {
                          ref.read(browserTabsProvider.notifier).switchTab(tab.id);
                          context.pop();
                        },
                        onClose: () => ref.read(browserTabsProvider.notifier).closeTab(tab.id),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: kAppAccent),
                onPressed: () {
                  ref.read(browserTabsProvider.notifier).newTab();
                  context.pop();
                },
                icon: const Icon(Icons.add),
                label: const Text('Nouvel onglet'),
              ),
            ),
          ),
          if (state.tabs.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(browserTabsProvider.notifier).closeAll(),
              child: const Text('Tout fermer'),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TabCard extends StatelessWidget {
  const _TabCard({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  final BrowserTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? kAppAccent.withOpacity(0.12) : kAppSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.08),
                child: Icon(
                  tab.isNewTab ? Icons.tab_unselected : Icons.public,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tab.isNewTab
                          ? 'Nouvel onglet'
                          : (tab.title?.isNotEmpty == true ? tab.title! : tab.url!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    if (!tab.isNewTab)
                      Text(
                        tab.url!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
