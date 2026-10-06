import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/tor_status.dart';
import '../../providers/browser_tabs_provider.dart';
import '../../providers/tor_provider.dart';
import '../../providers/usecase_providers.dart';
import '../../widgets/circle_icon_button.dart';
import 'browser_home_page.dart';

class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({super.key});

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  InAppWebViewController? _controller;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(browserTabsProvider.notifier);
      if (ref.read(browserTabsProvider).activeTab == null) {
        notifier.newTab();
      }
      final status = ref.read(torStatusProvider).valueOrNull;
      if (status?.state == TorConnectionState.connected) {
        _applyProxy(status!.socksPort);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final torStatus = ref.watch(torStatusProvider).valueOrNull ?? TorStatus.initial;
    final tabsState = ref.watch(browserTabsProvider);
    final activeTab = tabsState.activeTab;
    final isBrowsing = activeTab != null && !activeTab.isNewTab;

    ref.listen(torStatusProvider, (previous, next) {
      final status = next.valueOrNull;
      if (status?.state == TorConnectionState.connected) {
        _applyProxy(status!.socksPort);
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Comme un vrai navigateur : revient d'abord dans l'historique de la
        // page web visitée avant de quitter l'écran.
        if (isBrowsing && _controller != null && await _controller!.canGoBack()) {
          _controller!.goBack();
        } else if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: kAppBackground,
        // Pas d'AppBar : la page (web ou page de démarrage) occupe tout
        // l'écran, comme dans une vraie app de navigation. Les contrôles
        // qu'affichait l'ancienne AppBar sont maintenant dans la bulle
        // flottante déplaçable (_FloatingControls) superposée à l'écran.
        body: Stack(
          children: [
            Positioned.fill(
              child: isBrowsing
                  ? InAppWebView(
                      key: ValueKey(activeTab.id),
                      initialUrlRequest: URLRequest(url: WebUri(activeTab.url!)),
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                        cacheEnabled: false,
                      ),
                      onWebViewCreated: (controller) => _controller = controller,
                      onLoadStart: (controller, url) => setState(() => _progress = 0),
                      onProgressChanged: (controller, progress) {
                        setState(() => _progress = progress / 100);
                      },
                      onTitleChanged: (controller, title) {
                        ref.read(browserTabsProvider.notifier).updateTab(activeTab.id, title: title);
                      },
                      onUpdateVisitedHistory: (controller, url, isReload) {
                        if (url != null) {
                          ref.read(browserTabsProvider.notifier).updateTab(activeTab.id, url: url.toString());
                        }
                      },
                    )
                  : BrowserHomePage(
                      onMenuTap: () => context.push('/browser-tabs'),
                      onOpenUrl: (url) {
                        final tabId = activeTab?.id;
                        if (tabId != null) {
                          ref.read(browserTabsProvider.notifier).updateTab(tabId, url: url);
                        } else {
                          ref.read(browserTabsProvider.notifier).newTab(url: url);
                        }
                      },
                    ),
            ),
            if (isBrowsing) ...[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      if (_progress > 0 && _progress < 1) LinearProgressIndicator(value: _progress),
                      if (torStatus.state == TorConnectionState.checking) const _TorConnectingBanner(),
                      if (torStatus.state == TorConnectionState.error)
                        _TorErrorBanner(message: torStatus.errorMessage ?? 'Erreur inconnue'),
                    ],
                  ),
                ),
              ),
            ],
            _FloatingControls(
              torStatus: torStatus,
              tabCount: tabsState.tabs.length,
              showPageActions: isBrowsing,
              onClose: () => Navigator.of(context).pop(),
              onTabs: () => context.push('/browser-tabs'),
              onSave: _saveCurrentLink,
              onRefresh: () => _controller?.reload(),
              onTorInfo: () => context.push('/tor-info'),
            ),
          ],
        ),
      ),
    );
  }

  /// Route le trafic de la WebView via le proxy SOCKS5 local d'Orbot.
  /// `ProxyController` s'appuie sur l'API Android `PROXY_OVERRIDE` — fiable
  /// uniquement sur Android 10+. S'applique à TOUTE la WebView de l'app,
  /// donc à tous les onglets simultanément (voir BrowserTab).
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
    final activeTab = ref.read(browserTabsProvider).activeTab;
    if (activeTab == null || activeTab.isNewTab) return;
    final currentUrl = (await _controller?.getUrl())?.toString() ?? activeTab.url;
    if (currentUrl == null) return;
    final torEnabled =
        ref.read(torStatusProvider).valueOrNull?.state == TorConnectionState.connected;
    await ref.read(saveLinkProvider)(
      url: currentUrl,
      title: activeTab.title,
      openedViaTor: torEnabled,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lien enregistré')));
    }
  }
}

/// Bulle flottante déplaçable qui remplace l'ancienne AppBar. Glisse-la où
/// tu veux à l'écran ; un tap l'ouvre pour révéler les contrôles.
class _FloatingControls extends StatefulWidget {
  const _FloatingControls({
    required this.torStatus,
    required this.tabCount,
    required this.showPageActions,
    required this.onClose,
    required this.onTabs,
    required this.onSave,
    required this.onRefresh,
    required this.onTorInfo,
  });

  final TorStatus torStatus;
  final int tabCount;
  final bool showPageActions;
  final VoidCallback onClose;
  final VoidCallback onTabs;
  final VoidCallback onSave;
  final VoidCallback onRefresh;
  final VoidCallback onTorInfo;

  @override
  State<_FloatingControls> createState() => _FloatingControlsState();
}

class _FloatingControlsState extends State<_FloatingControls> {
  Offset? _offset;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _offset ??= Offset(size.width - 72, size.height - 180);
    final dx = _offset!.dx.clamp(8.0, size.width - 64);
    final dy = _offset!.dy.clamp(8.0, size.height - 64);

    final (icon, color) = switch (widget.torStatus.state) {
      TorConnectionState.connected => (Icons.security, Colors.purpleAccent),
      TorConnectionState.checking => (Icons.hourglass_top, Colors.orange),
      TorConnectionState.error => (Icons.error_outline, Colors.redAccent),
      TorConnectionState.disabled => (Icons.public, Colors.grey),
    };

    return Positioned(
      left: dx,
      top: dy,
      child: GestureDetector(
        onPanUpdate: (details) => setState(() => _offset = _offset! + details.delta),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Material(
          color: Colors.transparent,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 150),
            child: _expanded ? _buildExpanded(icon, color) : _buildBubble(icon, color),
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(IconData icon, Color color) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kAppSurface,
        border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildExpanded(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: kAppSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(icon, color: color),
            tooltip: 'Statut Tor',
            onPressed: widget.onTorInfo,
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            tooltip: 'Fermer',
            onPressed: widget.onClose,
          ),
          if (widget.showPageActions) ...[
            IconButton(
              icon: const Icon(Icons.bookmark_add_outlined, color: Colors.white70),
              tooltip: 'Enregistrer ce lien',
              onPressed: widget.onSave,
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              tooltip: 'Actualiser',
              onPressed: widget.onRefresh,
            ),
          ],
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.crop_square_outlined, color: Colors.white70),
                tooltip: 'Onglets',
                onPressed: widget.onTabs,
              ),
              if (widget.tabCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(color: kAppAccent, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '${widget.tabCount}',
                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TorConnectingBanner extends StatelessWidget {
  const _TorConnectingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.withValues(alpha: 0.85),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Text(
        'Vérification de la connexion au proxy Orbot en cours…',
        style: TextStyle(color: Colors.black),
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
      color: Colors.red.withValues(alpha: 0.85),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'Tor indisponible ($message) — navigation directe (non anonymisée).',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
