/// Normalise une saisie utilisateur en URL exploitable par la WebView.
/// Retourne `null` si la saisie est vide après nettoyage.
String? normalizeUrlInput(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final hasScheme = trimmed.startsWith('http://') || trimmed.startsWith('https://');
  return hasScheme ? trimmed : 'https://$trimmed';
}
