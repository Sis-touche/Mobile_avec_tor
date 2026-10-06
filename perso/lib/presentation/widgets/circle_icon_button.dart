import 'package:flutter/material.dart';

/// Palette partagée par les écrans redessinés (Accueil, Bibliothèque,
/// Navigateur, Tableau de bord de lecture, Splash) pour rester visuellement
/// cohérents entre eux.
const kAppBackground = Color(0xFF121212);
const kAppSurface = Color(0xFF1E1E1E);
const kAppAccent = Color(0xFF5865F2);

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.accent = false,
    this.badge,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool accent;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent ? kAppAccent.withOpacity(0.15) : kAppSurface,
      shape: CircleBorder(
        side: BorderSide(color: accent ? kAppAccent.withOpacity(0.4) : Colors.white.withOpacity(0.08)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: accent ? kAppAccent : Colors.white.withOpacity(0.87)),
              if (badge != null && badge! > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: kAppAccent, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      '$badge',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
