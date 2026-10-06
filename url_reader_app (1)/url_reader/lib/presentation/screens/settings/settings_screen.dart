import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/entities/tor_status.dart';
import '../../providers/network_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/tor_provider.dart';
import '../../providers/usecase_providers.dart';

const _orbotPlayStoreUrl = 'https://play.google.com/store/apps/details?id=org.torproject.android';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final port = await ref.read(torRepositoryProvider).getPort();
      if (mounted) _portController.text = '$port';
    });
  }

  @override
  void dispose() {
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final torStatus = ref.watch(torStatusProvider).valueOrNull ?? TorStatus.initial;
    final isChecking = torStatus.state == TorConnectionState.checking;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Navigation via Tor (Orbot)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            "Cette app ne fait pas tourner Tor elle-même : elle se connecte au proxy "
            "local exposé par Orbot, l'app officielle du Tor Project.\n\n"
            '1. Installe Orbot (bouton ci-dessous).\n'
            '2. Ouvre Orbot et démarre-le en mode proxy standard (pas en mode VPN).\n'
            "3. Note le port SOCKS5 affiché sur l'écran d'accueil d'Orbot (9050 par défaut).\n"
            '4. Renseigne ce port ci-dessous et vérifie la connexion.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _openOrbotOnStore,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Installer Orbot (Play Store)'),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _portController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Port SOCKS5 (Orbot)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: isChecking ? null : _saveAndCheck,
            child: isChecking
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer et vérifier'),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Utiliser Tor pour la navigation'),
            subtitle: Text(_statusLabel(torStatus)),
            secondary: isChecking
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    torStatus.state == TorConnectionState.connected
                        ? Icons.security
                        : Icons.security_outlined,
                  ),
            value: torStatus.state != TorConnectionState.disabled,
            onChanged: isChecking ? null : (enable) => ref.read(toggleTorProvider)(enable),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.travel_explore),
            title: const Text("Vérifier l'IP de sortie"),
            subtitle: const Text('Confirme que le trafic sort bien via Tor quand activé'),
            onTap: () => _showExitIpDialog(context),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndCheck() async {
    final port = int.tryParse(_portController.text.trim());
    if (port == null || port <= 0 || port > 65535) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Port invalide')));
      }
      return;
    }
    await ref.read(setTorPortProvider)(port);
    await ref.read(checkTorConnectionProvider)();
  }

  Future<void> _openOrbotOnStore() async {
    final uri = Uri.parse(_orbotPlayStoreUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir le Play Store")),
      );
    }
  }

  String _statusLabel(TorStatus status) {
    return switch (status.state) {
      TorConnectionState.disabled => 'Désactivé — navigation directe',
      TorConnectionState.checking => 'Vérification du proxy…',
      TorConnectionState.connected => 'Orbot détecté sur le port ${status.socksPort}',
      TorConnectionState.error => status.errorMessage ?? 'Proxy introuvable sur ce port',
    };
  }

  void _showExitIpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('IP de sortie'),
          content: Consumer(
            builder: (context, ref, _) {
              final exitIp = ref.watch(exitIpProvider);
              return exitIp.when(
                data: (ip) => Text(ip),
                loading: () => const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (e, _) => Text('Erreur : $e'),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
          ],
        );
      },
    );
  }
}
