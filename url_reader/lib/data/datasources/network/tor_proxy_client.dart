import 'dart:async';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Interface avec le proxy Tor local d'Orbot (app séparée, installée par
/// l'utilisateur — voir docs/orbot_setup.md).
///
/// Cette classe ne démarre RIEN : Orbot gère son propre cycle de vie en
/// dehors de cette app. Le rôle de cette classe se limite à :
///   - retenir le port SOCKS5 sur lequel Orbot est censé écouter localement
///     (port configurable par l'utilisateur, 9050 par défaut) ;
///   - vérifier qu'un service répond bien sur ce port.
///
/// C'est un choix délibéré, pas une simplification par facilité : l'ancienne
/// API "Intent" qui permettait de démarrer/détecter Orbot automatiquement
/// s'est cassée entre versions par le passé (voir
/// github.com/guardianproject/orbot-android/issues/638). La configuration
/// manuelle du port, elle, ne peut pas casser — c'est la méthode que suivent
/// des apps activement maintenues comme RethinkDNS.
class TorProxyClient {
  static const _portKey = 'tor_socks_port';
  static const _enabledKey = 'tor_enabled';

  /// Port SOCKS5 par défaut d'Orbot en mode "Power User" (non-VPN).
  static const defaultPort = 9050;

  Future<int> getPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_portKey) ?? defaultPort;
  }

  Future<void> setPort(int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_portKey, port);
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  /// Test TCP simple : un service répond-il sur `127.0.0.1:port` ?
  /// Ne garantit pas qu'il s'agit d'un proxy SOCKS5 valide — juste qu'un
  /// programme y écoute. Pour une vérification complète du routage réel,
  /// voir `exitIpProvider` (network_providers.dart) qui fait un vrai appel
  /// HTTP au travers de ce port.
  Future<bool> checkPort(int port, {Duration timeout = const Duration(seconds: 3)}) async {
    Socket? socket;
    try {
      socket = await Socket.connect('127.0.0.1', port, timeout: timeout);
      return true;
    } catch (_) {
      return false;
    } finally {
      socket?.destroy();
    }
  }
}
