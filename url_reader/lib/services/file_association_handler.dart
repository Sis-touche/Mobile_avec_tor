import 'dart:async';

import 'package:flutter/services.dart';

/// Reçoit les évènements "Ouvrir avec…" déclenchés depuis un gestionnaire de
/// fichiers externe pour un `.epub`.
///
/// Implémenté via un canal de méthode natif plutôt qu'un package tiers : la
/// surface nécessaire est réduite (un seul type de fichier, pas de partage
/// multi-format), ce qui évite une dépendance dont l'API ne correspondrait
/// pas exactement au besoin. Voir `android_patch/MainActivity.kt` pour la
/// partie native correspondante, à copier dans le projet généré par
/// `flutter create` (voir SETUP.md).
class FileAssociationHandler {
  FileAssociationHandler() {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  static const _channel = MethodChannel('url_reader/file_intent');

  final _controller = StreamController<String>.broadcast();

  /// Émet le chemin absolu de chaque fichier `.epub` reçu pendant que l'app
  /// est déjà lancée.
  Stream<String> get onFileReceived => _controller.stream;

  Future<void> _onMethodCall(MethodCall call) async {
    if (call.method == 'onFileReceived' && call.arguments is String) {
      _controller.add(call.arguments as String);
    }
  }

  /// À appeler une fois au démarrage pour récupérer un éventuel fichier ayant
  /// lancé l'app à froid (cas où l'app était fermée avant l'action "Ouvrir
  /// avec").
  Future<String?> getInitialFile() async {
    try {
      return await _channel.invokeMethod<String>('getInitialFile');
    } on PlatformException {
      return null;
    }
  }

  void dispose() => _controller.close();
}
