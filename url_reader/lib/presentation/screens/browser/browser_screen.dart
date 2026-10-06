import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/tor_status.dart';
import '../../providers/tor_provider.dart';
import '../../providers/usecase_providers.dart';

class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({super.key, required this.initialUrl});

  final String initialUrl;

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  InAppWebViewController? _controller;
  double _progress = 0;
  String? _currentTitle;

  @override
  void initState() {
    super.initState();
    // Si Tor est déjà connecté au moment où cet écran s'ouvre, `ref.listen`
    // ne se déclenchera pas (il ne réagit qu'aux changements) : on vérifie
    // donc aussi l'état courant une fois le premier frame posé.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final status = ref.read(torStatusProvider).valueOrNull;
      if (status?.state == TorConnectionState.connected) {
        _applyProxy(status!.socksPort);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final torStatus = ref.watch(torStatusProvider).valueOrNull ?? TorStatus.initial;

    ref.listen(torStatusProvider, (previous, next) {
      final status = next.valueOrNull;
      if (status?.state == TorConnectionState.connected) {
        _applyProxy(status!.socksPort);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle ?? widget.initialUrl, overflow: TextOverflow.ellipsis),
        actions: [
          _TorBadge(status: torStatus),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Enregistrer ce lien',
            onPressed: _saveCurrentLink,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller?.reload(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_progress < 1) LinearProgressIndicator(value: _progress == 0 ? null : _progress),
          if (torStatus.state == TorConnectionState.checking) const _TorConnectingBanner(),
          if (torStatus.state == TorConnectionState.error)
            _TorErrorBanner(message: torStatus.errorMessage ?? 'Erreur inconnue'),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                cacheEnabled: false, // évite de garder une trace locale des pages visitées
              ),
              onWebViewCreated: (controller) => _controller = controller,
              onLoadStart: (controller, url) => setState(() => _progress = 0),
              onProgressChanged: (controller, progress) {
                setState(() => _progress = progress / 100);
              },
              onTitleChanged: (controller, title) {
                setState(() => _currentTitle = title);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Route le trafic de la WebView via le proxy SOCKS5 local de Tor.
  ///
  /// `ProxyController` (flutter_inappwebview) s'appuie sur l'API Android
  /// `PROXY_OVERRIDE` — fiable uniquement sur Android 10+ (voir README §2).
  /// Aucun équivalent fiable n'existe sur iOS à ce jour.
  Future<void> _applyProxy(int? socksPort) async {
    if (socksPort == null) return;
    try {
      final supported = await WebViewFeature.isFeatureSupported(WebViewFeature.PROXY_OVERRIDE);
      if (!supported) {
        throw Exception('PROXY_OVERRIDE non supporté par ce WebView système.');
      }
      await ProxyController.instance().setProxyOverride(
        settings: ProxySettings(
          proxyRules: [ProxyRule(url: 'socks5://127.0.0.1:$socksPort')],
          bypassRules: ['localhost', '127.0.0.1'],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Impossible d'appliquer le proxy Tor : $e")),
        );
      }
    }
  }

  Future<void> _saveCurrentLink() async {
    final currentUrl = (await _controller?.getUrl())?.toString() ?? widget.initialUrl;
    final torEnabled =
        ref.read(torStatusProvider).valueOrNull?.state == TorConnectionState.connected;
    await ref.read(saveLinkProvider)(
      url: currentUrl,
      title: _currentTitle,
      openedViaTor: torEnabled,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lien enregistré')));
    }
  }
}

class _TorBadge extends StatelessWidget {
  const _TorBadge({required this.status});
  final TorStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status.state) {
      TorConnectionState.connected => (Icons.security, Colors.purple),
      TorConnectionState.checking => (Icons.hourglass_top, Colors.orange),
      TorConnectionState.error => (Icons.error_outline, Colors.red),
      TorConnectionState.disabled => (Icons.public, Colors.grey),
    };
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Icon(icon, color: color),
    );
  }
}

class _TorConnectingBanner extends StatelessWidget {
  const _TorConnectingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Text(
        'Vérification de la connexion au proxy Orbot en cours…',
      ),
    );
  }
}

class _TorErrorBanner extends StatelessWidget {
  const _TorErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.red.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text('Tor indisponible ($message) — navigation directe (non anonymisée).'),
    );
  }
}
