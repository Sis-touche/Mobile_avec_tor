import '../../core/utils/result.dart';
import '../entities/tor_status.dart';

/// Cette app ne fait pas tourner Tor elle-même : elle se connecte au proxy
/// SOCKS5 local exposé par Orbot (app séparée, installée par l'utilisateur).
/// Voir docs/orbot_setup.md.
abstract interface class TorRepository {
  Stream<TorStatus> watchStatus();
  TorStatus get currentStatus;

  /// Active/désactive le routage de la WebView via le port configuré.
  /// À l'activation, déclenche automatiquement un [checkConnection].
  Future<Result<TorStatus>> setEnabled(bool enabled);

  /// Teste si un service répond sur le port SOCKS5 configuré (test TCP
  /// simple — ne garantit pas qu'il s'agit bien d'un proxy SOCKS5
  /// fonctionnel, seulement qu'un programme y écoute).
  Future<Result<TorStatus>> checkConnection();

  Future<Result<void>> setPort(int port);
  Future<int> getPort();
}
