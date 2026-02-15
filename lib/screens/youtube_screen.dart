/// Pantalla de YouTube con WebView embebido y personalización de la interfaz.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Script JS que oculta elementos de YouTube y mantiene los menús funcionales
const _youtubeCustomizationsJs = '''
(function() {
  const style = document.createElement('style');
  style.id = 'shema-custom-style';
  style.textContent = `
    /* Ocultar solo la barra de navegación inferior de YouTube */
    ytm-pivot-bar-renderer, ytm-mobile-bottom-bar-renderer {
      display: none !important;
      height: 0 !important;
      overflow: hidden !important;
    }
    body, html { overflow-x: hidden !important; }
  `;
  const oldStyle = document.getElementById('shema-custom-style');
  if (oldStyle) oldStyle.remove();
  document.head.appendChild(style);
})();
''';

/// Widget que muestra YouTube en un WebView personalizado
class YouTubeScreen extends StatefulWidget {
  const YouTubeScreen({
    required this.initialUrl,
    super.key,
    this.preloadedController,
    this.onCanGoBackChanged,
    this.onFullScreenChanged,
  });

  final String initialUrl;
  final WebViewController? preloadedController;
  final ValueChanged<bool>? onCanGoBackChanged;
  final ValueChanged<bool>? onFullScreenChanged;

  @override
  State<YouTubeScreen> createState() => YouTubeScreenState();
}

/// Estado del WebView de YouTube con control de navegación y errores
class YouTubeScreenState extends State<YouTubeScreen> {
  WebViewController? controller;
  int _progress = 0;
  String? _errorMessage;
  bool _isFullScreen = false;
  Widget? _fullScreenWidget;
  VoidCallback? _onHideCustomView;

  /// Retorna la URL actual del WebView
  Future<String?> currentUrl() async => controller?.currentUrl();

  /// Navega a la página de búsqueda de YouTube
  void navigateToSearch() {
    controller?.loadRequest(Uri.parse('https://m.youtube.com/results?search_query='));
  }

  /// Pausa la reproducción multimedia del WebView para ahorrar recursos
  void pauseWebView() {
    if (controller != null && (Platform.isAndroid || Platform.isIOS)) {
      controller!.runJavaScript(
        "document.querySelectorAll('video, audio').forEach(e => e.pause());",
      );
    }
  }

  /// Obtiene la altura del video en reproducción (para determinar calidad)
  Future<int?> currentPlaybackHeight() async {
    if (controller == null) return null;
    try {
      final raw = await controller!.runJavaScriptReturningResult(
        '(() => { const v = document.querySelector("video"); '
        'if (!v) return null; const h = Number(v.videoHeight || 0); '
        'return Number.isFinite(h) && h > 0 ? h : null; })();');
      final text = raw.toString().replaceAll('"', '').trim();
      if (text.isEmpty || text == 'null' || text == 'undefined') return null;
      return int.tryParse(text);
    } catch (_) {
      return null;
    }
  }

  /// Navega hacia atrás en el historial del WebView
  Future<void> goBack() async => controller?.goBack();

  /// Verifica si puede navegar hacia atrás
  Future<bool> canGoBack() async => controller != null ? await controller!.canGoBack() : false;

  /// Notifica al padre si se puede navegar atrás
  Future<void> _notifyCanGoBack() async => widget.onCanGoBackChanged?.call(await canGoBack());

  /// Crea el delegado de navegación con manejo de errores y progreso
  NavigationDelegate _navigationDelegate() => NavigationDelegate(
    onProgress: (p) {
      if (!mounted) return;
      setState(() { _progress = p; _errorMessage = null; });
    },
    onPageStarted: (_) {
      if (!mounted) return;
      setState(() => _errorMessage = null);
    },
    onPageFinished: (_) {
      if (!mounted) return;
      _injectCustomizations();
      setState(() => _progress = 100);
      _notifyCanGoBack();
    },
    onWebResourceError: (error) {
      if (!mounted) return;
      if (error.isForMainFrame == false) return;
      final desc = error.description.toLowerCase();
      if (desc.contains('orb') || desc.contains('cors')) return;
      setState(() => _errorMessage = 'Error: ${error.description}');
    },
    onNavigationRequest: (request) {
      Future.delayed(const Duration(milliseconds: 800), _injectCustomizations);
      Future.delayed(const Duration(milliseconds: 1500), _injectCustomizations);
      return NavigationDecision.navigate;
    },
  );

  /// Inyecta CSS y JavaScript para personalizar la interfaz de YouTube
  Future<void> _injectCustomizations() async {
    if (controller == null) return;
    try { await controller!.runJavaScript(_youtubeCustomizationsJs); } catch (_) {}
    _injectDimensions();
  }

  /// Inyecta las dimensiones reales del área visible como CSS variables
  void _injectDimensions() {
    if (controller == null || !mounted) return;
    final mq = MediaQuery.of(context);
    final topInset = mq.padding.top + kToolbarHeight;
    final bottomNavHeight = 90.0; // 66px nav + margins
    final visibleHeight = mq.size.height - topInset - bottomNavHeight;
    final js = '''
      document.documentElement.style.setProperty('--shema-bottom-inset', '${bottomNavHeight.toInt()}px');
      document.documentElement.style.setProperty('--shema-visible-height', '${visibleHeight.toInt()}px');
    ''';
    try { controller!.runJavaScript(js); } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    controller = widget.preloadedController ?? WebViewController();
    controller!
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF9F9F9))
      ..setNavigationDelegate(_navigationDelegate())
      ..enableZoom(true);

    // Configurar plataforma Android para soporte de video inline y fullscreen
    if (Platform.isAndroid && controller!.platform is AndroidWebViewController) {
      final androidController = controller!.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      androidController.setCustomWidgetCallbacks(
        onShowCustomWidget: (Widget widget, VoidCallback hideCallback) {
          if (!mounted) return;
          setState(() => _isFullScreen = true);
          this.widget.onFullScreenChanged?.call(true);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
            DeviceOrientation.portraitUp,
          ]);
          _fullScreenWidget = widget;
          _onHideCustomView = hideCallback;
          setState(() {});
        },
        onHideCustomWidget: () {
          if (!mounted) return;
          setState(() {
            _isFullScreen = false;
            _fullScreenWidget = null;
          });
          widget.onFullScreenChanged?.call(false);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        },
      );
    }
    if (widget.preloadedController == null) {
      final mobileUrl = widget.initialUrl.replaceAll('www.youtube.com', 'm.youtube.com');
      controller!.loadRequest(Uri.parse(mobileUrl));
    } else {
      setState(() => _progress = 100);
      unawaited(() async {
        await controller?.currentUrl();
        _injectCustomizations();
      }());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return const Center(child: Text('YouTube WebView disponible en Android/iOS.'));
    }

    // Modo pantalla completa para video
    if (_isFullScreen && _fullScreenWidget != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onHideCustomView?.call();
        },
        child: Container(
          color: Colors.black,
          child: _fullScreenWidget!,
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: controller!),
        if (_progress < 100) LinearProgressIndicator(value: _progress / 100),
        if (_errorMessage != null)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text(_errorMessage!,
                    style: TextStyle(color: Colors.red.shade900, fontSize: 13))),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _errorMessage = null);
                      controller?.reload();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Recargar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
