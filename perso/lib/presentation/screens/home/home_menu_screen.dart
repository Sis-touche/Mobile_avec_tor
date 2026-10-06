import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_reader/presentation/widgets/circle_icon_button.dart';

/// Contenu réutilisable : la grille "Lire / Naviguer".
/// N'a pas son propre Scaffold — utilisable aussi bien embarqué
/// dans un autre écran (HomeScreen) qu'à l'intérieur d'une route dédiée.
class HomeMenuGrid extends StatelessWidget {
  const HomeMenuGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1,
      children: [
        _MenuTile(
          icon: Icons.menu_book_outlined,
          label: 'Lire',
          onTap: () => context.push('/reading-dashboard'),
        ),
        _MenuTile(
          icon: Icons.public,
          label: 'Naviguer',
          onTap: () => context.push('/browser'),
        ),
      ],
    );
  }
}

/// Écran indépendant (route `/home-menu`), pour un accès direct
/// hors de HomeScreen si besoin. Enveloppe HomeMenuGrid dans un Scaffold.
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
            children: const [
              SizedBox(height: 12),
              Expanded(child: HomeMenuGrid()),
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