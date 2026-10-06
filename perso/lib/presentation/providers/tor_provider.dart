import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tor_status.dart';
import 'repository_providers.dart';

final torStatusProvider = StreamProvider.autoDispose<TorStatus>((ref) {
  return ref.watch(torRepositoryProvider).watchStatus();
});

final torSocksPortProvider = Provider.autoDispose<int?>((ref) {
  return ref.watch(torStatusProvider).valueOrNull?.socksPort;
});
