import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Taille totale réelle (en octets) des données stockées localement par
/// l'app (base sqlite, epubs importés, couvertures extraites) — calculée en
/// parcourant le dossier documents de l'app, pas une estimation.
final storageStatsProvider = FutureProvider.autoDispose<int>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  if (!dir.existsSync()) return 0;
  var total = 0;
  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      try {
        total += await entity.length();
      } catch (_) {
        // Fichier supprimé/inaccessible entre-temps : ignorer.
      }
    }
  }
  return total;
});
