import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/network/http_client_provider.dart';
import 'tor_provider.dart';

/// Vérifie l'IP de sortie visible depuis Internet, à travers le proxy Tor si
/// actif. Équivalent du test `curl` du spike Phase 0, directement accessible
/// depuis l'écran Paramètres pour un contrôle manuel rapide.
final exitIpProvider = FutureProvider.autoDispose<String>((ref) async {
  final socksPort = ref.watch(torSocksPortProvider);
  final dio = buildDioClient(socksPort: socksPort);
  final response = await dio.get<String>(
    'https://api.ipify.org',
    options: Options(responseType: ResponseType.plain),
  );
  return response.data ?? 'Inconnue';
});
