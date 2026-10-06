import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/link.dart';
import 'repository_providers.dart';

/// Flux réactif des liens sauvegardés : se met à jour automatiquement après
/// insertion/suppression grâce au `.watch()` natif de Drift.
final linksStreamProvider = StreamProvider.autoDispose<List<Link>>((ref) {
  return ref.watch(linkRepositoryProvider).watchLinks();
});
