import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/circle_icon_button.dart';

/// Page d'accueil à part : une grille de deux boutons, Lire et Naviguer,
/// rien d'autre. Écran indépendant (route `/home-menu`) — n'affecte aucun
/// des écrans existants.
class HomeMenuScreen extends StatelessWidget {
  const HomeMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Perso',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Que veux-tu faire ?', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _MenuTile(
                      icon: Icons.menu_book_outlined,
                      label: 'Lire',
                      // Ouvre le tableau de bord de lecture — écran existant,
                      // inchangé.
                      onTap: () => context.push('/reading-dashboard'),
                    ),
                    _MenuTile(
                      icon: Icons.public,
                      label: 'Naviguer',
                      // Ouvre l'écran Navigateur ; comme aucun onglet n'a
                      // encore d'URL, c'est BrowserHomePage qui s'affiche
                      // (raccourcis + historique) — écran existant, inchangé.
                      onTap: () => context.push('/browser'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kAppSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(shape: BoxShape.circle, color: kAppAccent.withOpacity(0.15)),
              child: Icon(icon, color: kAppAccent, size: 30),
            ),
            const SizedBox(height: 16),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
