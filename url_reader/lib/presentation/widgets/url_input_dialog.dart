import 'package:flutter/material.dart';

Future<String?> showUrlInputDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Ouvrir une URL'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'https://exemple.com'),
          onSubmitted: (value) => Navigator.of(context).pop(_normalize(value)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_normalize(controller.text)),
            child: const Text('Ouvrir'),
          ),
        ],
      );
    },
  );
}

String? _normalize(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final hasScheme = trimmed.startsWith('http://') || trimmed.startsWith('https://');
  return hasScheme ? trimmed : 'https://$trimmed';
}
