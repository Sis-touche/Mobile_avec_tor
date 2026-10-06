import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:socks5_proxy/socks_client.dart';

/// Construit un client Dio, routé via le proxy SOCKS5 local de Tor si
/// [socksPort] est fourni. Utilisé pour les appels HTTP hors WebView, en
/// particulier la vérification manuelle de l'IP de sortie (spike Phase 0 et
/// bouton de diagnostic dans l'écran Paramètres).
Dio buildDioClient({int? socksPort}) {
  final dio = Dio();
  if (socksPort != null) {
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      SocksTCPClient.assignToHttpClient(client, [
        ProxySettings(InternetAddress.loopbackIPv4, socksPort),
      ]);
      return client;
    };
  }
  return dio;
}
