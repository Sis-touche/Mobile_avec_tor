import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'circle_icon_button.dart';

/// Paire de boutons d'accès rapide : "Lire" (tableau de bord de lecture) et
/// "Naviguer" (navigateur). Autonome — peut être placé sur n'importe quel
/// écran, il gère lui-même la navigation.
class ReadBrowseActions extends StatelessWidget {
  const ReadBrowseActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.menu_book_outlined,
            label: 'Lire',
            onTap: () => context.push('/reading-dashboard'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.public,
            label: 'Naviguer',
            onTap: () => context.push('/browser'),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kAppSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: kAppAccent),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
