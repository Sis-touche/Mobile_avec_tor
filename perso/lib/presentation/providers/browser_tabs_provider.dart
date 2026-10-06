import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/browser_tab.dart';

class BrowserTabsState {
  const BrowserTabsState({required this.tabs, required this.activeTabId});

  final List<BrowserTab> tabs;
  final String? activeTabId;

  BrowserTab? get activeTab {
    if (activeTabId == null) return null;
    for (final tab in tabs) {
      if (tab.id == activeTabId) return tab;
    }
    return null;
  }

  BrowserTabsState copyWith({List<BrowserTab>? tabs, String? activeTabId}) {
    return BrowserTabsState(tabs: tabs ?? this.tabs, activeTabId: activeTabId ?? this.activeTabId);
  }
}

/// Gère les onglets du navigateur en mémoire (non persistés entre les
/// redémarrages complets de l'app — simplification assumée pour cette
/// itération ; voir docs/notes_readme.md).
class BrowserTabsNotifier extends StateNotifier<BrowserTabsState> {
  BrowserTabsNotifier() : super(const BrowserTabsState(tabs: [], activeTabId: null));

  int _counter = 0;
  String _nextId() => 'tab_${_counter++}';

  /// Ouvre une URL : réutilise l'onglet actif s'il est vide (nouvel onglet),
  /// sinon crée un nouvel onglet.
  String openUrl(String url) {
    final active = state.activeTab;
    if (active != null && active.isNewTab) {
      updateTab(active.id, url: url);
      return active.id;
    }
    return newTab(url: url);
  }

  String newTab({String? url}) {
    final tab = BrowserTab(id: _nextId(), url: url);
    state = state.copyWith(tabs: [...state.tabs, tab], activeTabId: tab.id);
    return tab.id;
  }

  void switchTab(String id) {
    state = state.copyWith(activeTabId: id);
  }

  void updateTab(String id, {String? url, String? title}) {
    state = state.copyWith(
      tabs: [
        for (final t in state.tabs)
          if (t.id == id) t.copyWith(url: url, title: title) else t,
      ],
    );
  }

  void closeTab(String id) {
    final remaining = state.tabs.where((t) => t.id != id).toList();
    var newActive = state.activeTabId;
    if (state.activeTabId == id) {
      newActive = remaining.isNotEmpty ? remaining.last.id : null;
    }
    state = BrowserTabsState(tabs: remaining, activeTabId: newActive);
  }

  void closeAll() {
    state = const BrowserTabsState(tabs: [], activeTabId: null);
  }
}

final browserTabsProvider = StateNotifierProvider<BrowserTabsNotifier, BrowserTabsState>((ref) {
  return BrowserTabsNotifier();
});
