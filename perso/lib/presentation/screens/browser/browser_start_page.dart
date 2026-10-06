import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/url_utils.dart';
import '../../providers/links_provider.dart';
import '../../widgets/circle_icon_button.dart';

/// Page affichée dans un onglet vide ("nouvel onglet"), à la place d'une
/// WebView. Remplace les raccourcis génériques (réseaux sociaux) qu'on
/// trouverait dans un navigateur classique par les propres liens enregistrés
/// de l'utilisateur — pas de service de "recherches tendances" externe, ce
/// qui irait à l'encontre de l'esprit privé de l'app.
class BrowserStartPage extends ConsumerStatefulWidget {
  const BrowserStartPage({super.key, required this.onSubmitUrl, this.focusNode});

  final ValueChanged<String> onSubmitUrl;
  final FocusNode? focusNode;

  @override
  ConsumerState<BrowserStartPage> createState() => _BrowserStartPageState();
}

class _BrowserStartPageState extends ConsumerState<BrowserStartPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final url = normalizeUrlInput(_controller.text);
    if (url != null) widget.onSubmitUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final linksAsync = ref.watch(linksStreamProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      children: [
        const Center(
          child: Text('Perso', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'RAPIDE · PRIVÉ · SIMPLE',
            style: TextStyle(color: Colors.white.withOpacity(0.5), letterSpacing: 2, fontSize: 12),
          ),
        ),
        const SizedBox(height: 28),
        Container(
          decoration: BoxDecoration(
            color: kAppSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextField(
            controller: _controller,
            focusNode: widget.focusNode,
            autofocus: true,
            keyboardType: TextInputType.url,
            style: const TextStyle(color: Colors.white),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Rechercher ou saisir une URL',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward, color: kAppAccent),
                onPressed: _submit,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Liens enregistrés',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        linksAsync.when(
          data: (links) {
            if (links.isEmpty) {
              return Text(
                'Aucun lien enregistré pour le moment.',
                style: TextStyle(color: Colors.white.withOpacity(0.4)),
              );
            }
            return Column(
              children: [
                for (final link in links.take(8))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      link.openedViaTor ? Icons.security : Icons.public,
                      color: link.openedViaTor ? Colors.purple[200] : Colors.white54,
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
                    onTap: () => widget.onSubmitUrl(link.url),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Erreur : $e', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
