import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/links_provider.dart';

/// Page de démarrage du navigateur (onglet vide), inspirée de la maquette
/// "Arcus Browser - Home". La pile "Trending Searches" de la maquette
/// d'origine est remplacée ici par un vrai historique (tes liens
/// effectivement enregistrés) — pas de service de tendances externe, un
/// historique réel est plus utile et plus cohérent avec une app privée.
class BrowserHomePage extends ConsumerStatefulWidget {
  const BrowserHomePage({
    super.key,
    this.onOpenUrl,
    this.onMenuTap,
    this.appName = 'Perso',
    this.tagline = 'RAPIDE · PRIVÉ · SIMPLE',
  });

  /// Appelé quand une URL doit s'ouvrir (recherche validée, raccourci, ou
  /// entrée d'historique). Si `null`, ouvre dans le navigateur externe du
  /// téléphone via `url_launcher`.
  final ValueChanged<String>? onOpenUrl;

  /// Appelé au tap sur l'icône menu (☰) — branché sur l'écran des onglets
  /// depuis `browser_screen.dart`.
  final VoidCallback? onMenuTap;

  final String appName;
  final String tagline;

  @override
  ConsumerState<BrowserHomePage> createState() => _BrowserHomePageState();
}

class _BrowserHomePageState extends ConsumerState<BrowserHomePage> {
  final _searchController = TextEditingController();

  static const _shortcuts = [
    _Shortcut(
      label: 'Amazon',
      url: 'https://www.amazon.com',
      color: Color(0xFFFF9900),
      icon: Icons.shopping_bag_outlined,
    ),
    _Shortcut(
      label: 'Instagram',
      url: 'https://www.instagram.com',
      color: Color(0xFFE1306C),
      icon: Icons.camera_alt_outlined,
    ),
    _Shortcut(
      label: 'Pinterest',
      url: 'https://www.pinterest.com',
      color: Color(0xFFE60023),
      icon: Icons.push_pin_outlined,
    ),
    _Shortcut(
      label: 'Dribbble',
      url: 'https://dribbble.com',
      color: Color(0xFFEA4C89),
      icon: Icons.sports_basketball_outlined,
    ),
    _Shortcut(
      label: 'Twitter',
      url: 'https://twitter.com',
      color: Color(0xFF1DA1F2),
      icon: Icons.chat_bubble_outline,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openUrl(String url) {
    if (widget.onOpenUrl != null) {
      widget.onOpenUrl!(url);
    } else {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _submitSearch() {
    final raw = _searchController.text.trim();
    if (raw.isEmpty) return;
    _openUrl(_resolveQuery(raw));
  }

  /// Transforme une saisie en URL exploitable : l'adresse telle quelle si
  /// elle y ressemble (pas d'espace, contient un domaine), sinon une
  /// recherche Google — comportement standard de barre d'adresse.
  String _resolveQuery(String raw) {
    final looksLikeUrl = !raw.contains(' ') &&
        RegExp(r'^(https?://)|(www\.)|([a-z0-9-]+\.[a-z]{2,})', caseSensitive: false).hasMatch(raw);
    if (looksLikeUrl) {
      return raw.startsWith('http://') || raw.startsWith('https://') ? raw : 'https://$raw';
    }
    return 'https://www.google.com/search?q=${Uri.encodeQueryComponent(raw)}';
  }

  void _voiceSearchNotAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Recherche vocale non connectée — ajoute un package comme "
          "speech_to_text pour l'activer.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final linksAsync = ref.watch(linksStreamProvider);

    return Container(
      color: Colors.black,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            IconButton(
              onPressed: widget.onMenuTap,
              icon: const Icon(Icons.menu, color: Colors.white),
              tooltip: 'Onglets',
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                widget.appName,
                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                widget.tagline,
                style: TextStyle(color: Colors.white.withOpacity(0.5), letterSpacing: 2, fontSize: 12),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(28)),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submitSearch(),
                decoration: InputDecoration(
                  hintText: 'Rechercher ou saisir une URL',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.mic_none, color: Colors.white.withOpacity(0.5)),
                    onPressed: _voiceSearchNotAvailable,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final s in _shortcuts) _ShortcutIcon(shortcut: s, onTap: () => _openUrl(s.url)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.history, color: Colors.white70, size: 18),
                        SizedBox(width: 8),
                        Text('Historique', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                  linksAsync.when(
                    data: (links) {
                      if (links.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Aucun historique pour le moment.',
                            style: TextStyle(color: Colors.white.withOpacity(0.4)),
                          ),
                        );
                      }
                      return Column(
                        children: [
                          for (final link in links.take(10))
                            ListTile(
                              leading: Icon(
                                link.openedViaTor ? Icons.security : Icons.public,
                                color: link.openedViaTor ? Colors.purpleAccent : Colors.white54,
                              ),
                              title: Text(
                                link.title?.isNotEmpty == true ? link.title! : link.url,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                link.url,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white.withOpacity(0.4)),
                              ),
                              onTap: () => _openUrl(link.url),
                            ),
                        ],
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Erreur : $e', style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Shortcut {
  const _Shortcut({required this.label, required this.url, required this.color, required this.icon});
  final String label;
  final String url;
  final Color color;
  final IconData icon;
}

class _ShortcutIcon extends StatelessWidget {
  const _ShortcutIcon({required this.shortcut, required this.onTap});
  final _Shortcut shortcut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: shortcut.color.withOpacity(0.15),
            child: Icon(shortcut.icon, color: shortcut.color),
          ),
          const SizedBox(height: 6),
          Text(shortcut.label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
        ],
      ),
    );
  }
}
