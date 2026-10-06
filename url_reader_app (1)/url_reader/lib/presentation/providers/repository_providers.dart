import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/network/tor_proxy_client.dart';
import '../../data/repositories/epub_repository_impl.dart';
import '../../data/repositories/folder_repository_impl.dart';
import '../../data/repositories/link_repository_impl.dart';
import '../../data/repositories/tor_repository_impl.dart';
import '../../domain/repositories/epub_repository.dart';
import '../../domain/repositories/folder_repository.dart';
import '../../domain/repositories/link_repository.dart';
import '../../domain/repositories/tor_repository.dart';
import 'database_provider.dart';

final linkRepositoryProvider = Provider<LinkRepository>((ref) {
  return LinkRepositoryImpl(ref.watch(appDatabaseProvider));
});

final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  return FolderRepositoryImpl(ref.watch(appDatabaseProvider));
});

final epubRepositoryProvider = Provider<EpubRepository>((ref) {
  return EpubRepositoryImpl(ref.watch(appDatabaseProvider));
});

final torProxyClientProvider = Provider<TorProxyClient>((ref) {
  return TorProxyClient();
});

final torRepositoryProvider = Provider<TorRepository>((ref) {
  final repo = TorRepositoryImpl(ref.watch(torProxyClientProvider));
  ref.onDispose(repo.dispose);
  return repo;
});
