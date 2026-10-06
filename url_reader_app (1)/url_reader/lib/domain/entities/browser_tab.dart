/// Un onglet du navigateur. `url == null` signifie un nouvel onglet vide
/// (affiche la page de démarrage plutôt qu'une WebView).
///
/// Limite technique importante : le proxy Tor (`ProxyController` de
/// flutter_inappwebview) s'applique globalement au moteur WebView d'Android,
/// pas par onglet — impossible d'avoir certains onglets via Tor et d'autres
/// en direct simultanément. Le réglage "Utiliser Tor" (écran Paramètres)
/// s'applique donc à tous les onglets ouverts en même temps.
class BrowserTab {
  const BrowserTab({required this.id, this.url, this.title});

  final String id;
  final String? url;
  final String? title;

  bool get isNewTab => url == null;

  BrowserTab copyWith({String? url, String? title}) {
    return BrowserTab(id: id, url: url ?? this.url, title: title ?? this.title);
  }
}
