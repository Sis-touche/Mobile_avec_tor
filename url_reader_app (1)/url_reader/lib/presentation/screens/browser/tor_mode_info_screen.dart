import 'package:flutter/material.dart';

import '../../widgets/circle_icon_button.dart';

/// Écran explicatif du mode Tor, adapté de la maquette "Incognito Mode"
/// fournie, mais avec un contenu honnête sur ce que fait réellement l'app
/// (pas de fausses promesses de type "aucune trace") :
/// - le domaine visité est masqué au réseau WiFi local ;
/// - l'historique des liens reste stocké localement sur cet appareil,
///   exactement comme sans Tor ;
/// - le réglage s'applique à TOUS les onglets ouverts en même temps (le
///   proxy WebView d'Android est global, pas configurable par onglet) ;
/// - Orbot doit être installé et lancé séparément pour que ça fonctionne.
class TorModeInfoScreen extends StatelessWidget {
  const TorModeInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kAppAccent.withOpacity(0.1),
                  border: Border.all(color: kAppAccent.withOpacity(0.4)),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.security, color: kAppAccent, size: 52),
              ),
              const SizedBox(height: 24),
              const Text(
                'Mode Tor',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "Quand ce mode est actif, le trafic de navigation passe par le proxy local "
                "d'Orbot avant de sortir sur Internet, ce qui masque le nom de domaine visité "
                'aux autres appareils de ton réseau WiFi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
              const SizedBox(height: 32),
              const _InfoRow(
                icon: Icons.wifi_off,
                title: 'Masqué à ton réseau WiFi',
                subtitle: 'Le domaine visité ne peut pas être lu par les autres appareils du réseau',
              ),
              const _InfoRow(
                icon: Icons.storage,
                title: "Toujours stocké sur cet appareil",
                subtitle: "L'historique de tes liens reste enregistré localement, comme sans Tor",
              ),
              const _InfoRow(
                icon: Icons.tab_unselected,
                title: 'Concerne tous les onglets à la fois',
                subtitle: "Ce n'est pas un choix par onglet — le réglage Paramètres s'applique globalement",
              ),
              const _InfoRow(
                icon: Icons.speed,
                title: 'Navigation plus lente',
                subtitle: 'Le trafic passe par plusieurs relais Tor avant sa destination',
              ),
              const _InfoRow(
                icon: Icons.power_settings_new,
                title: "Nécessite qu'Orbot tourne",
                subtitle: "Sans Orbot lancé sur ce téléphone, la navigation échoue plutôt que de continuer en clair",
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: kAppSurface, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, color: kAppAccent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
