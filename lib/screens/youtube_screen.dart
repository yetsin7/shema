/// Pantalla de YouTube con WebView embebido y personalización de la interfaz.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../l10n.dart';
import '../utils/youtube_js.dart';

/// Widget que muestra YouTube en un WebView con personalización CSS.
///
/// Inyecta JavaScript para ocultar la barra de navegación inferior de YouTube
/// y permite reproducción de video en pantalla completa con rotación automática.
class YouTubeScreen extends StatefulWidget {
  /// Crea un WebView de YouTube con la [initialUrl] dada
  const YouTubeScreen({
    required this.initialUrl,
    super.key,
    this.preloadedController,
    this.onCanGoBackChanged,
    this.onFullScreenChanged,
    this.onUrlChanged,
  });

  /// URL inicial a cargar (ej: 'https://www.youtube.com' o '.../shorts')
  final String initialUrl;

  /// Controlador precargado desde el splash (solo para la pestaña principal)
  final WebViewController? preloadedController;

  /// Callback cuando cambia la capacidad de navegar atrás
  final ValueChanged<bool>? onCanGoBackChanged;

  /// Callback cuando entra/sale de pantalla completa
  final ValueChanged<bool>? onFullScreenChanged;

  /// Callback cuando la URL de la página cambia (al iniciar y terminar de cargar)
  final ValueChanged<String>? onUrlChanged;

  @override
  State<YouTubeScreen> createState() => YouTubeScreenState();
}

/// Estado del WebView de YouTube con control de navegación, fullscreen y errores.
///
/// Expone métodos públicos como [currentUrl], [navigateToSearch], [goBack]
/// para ser llamados desde [HomeScreen] vía GlobalKey.
class YouTubeScreenState extends State<YouTubeScreen> {
  /// Controlador del WebView (accesible desde el padre vía GlobalKey)
  WebViewController? controller;

  /// Progreso de carga de la página (0-100)
  int _progress = 0;

  /// Indica si hay un error de conexión (muestra pantalla offline)
  bool _isOffline = false;

  /// Indica si el video está en modo pantalla completa
  bool _isFullScreen = false;

  /// Widget del reproductor en pantalla completa (proporcionado por Android)
  Widget? _fullScreenWidget;

  /// Callback para salir de pantalla completa
  VoidCallback? _onHideCustomView;

  /// Retorna la URL actual del WebView
  Future<String?> currentUrl() async => controller?.currentUrl();

  /// Navega a la página de búsqueda de YouTube
  void navigateToSearch() {
    controller?.loadRequest(Uri.parse('https://m.youtube.com/results?search_query='));
  }

  /// Pausa la reproducción multimedia del WebView sin perder la página actual
  void pauseWebView() {
    if (controller != null && (Platform.isAndroid || Platform.isIOS)) {
      controller!.runJavaScript(
        "document.querySelectorAll('video, audio').forEach(e => e.pause());",
      );
    }
  }

  /// Reanuda el WebView (no necesita recargar, la página sigue cargada)
  void resumeWebView() {
    // La página se mantiene en memoria, no es necesario recargar
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
      setState(() { _progress = p; if (p > 10) _isOffline = false; });
    },
    onPageStarted: (url) {
      if (!mounted) return;
      setState(() => _isOffline = false);
      if (url.isNotEmpty) widget.onUrlChanged?.call(url);
    },
    onPageFinished: (url) {
      if (!mounted) return;
      _injectCustomizations();
      setState(() => _progress = 100);
      _notifyCanGoBack();
      if (url.isNotEmpty) widget.onUrlChanged?.call(url);
    },
    onWebResourceError: (error) {
      if (!mounted) return;
      if (error.isForMainFrame == false) return;
      final desc = error.description.toLowerCase();
      if (desc.contains('orb') || desc.contains('cors')) return;
      // Detectar errores de red (sin internet)
      if (desc.contains('err_name_not_resolved') ||
          desc.contains('err_internet_disconnected') ||
          desc.contains('err_address_unreachable') ||
          desc.contains('err_network') ||
          desc.contains('err_connection')) {
        setState(() => _isOffline = true);
      }
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
    try { await controller!.runJavaScript(youtubeCustomizationsJs); } catch (_) {}
    _injectDimensions();
    _injectUrlTracker();
  }

  /// Inyecta JS que intercepta history.pushState/replaceState para detectar
  /// cambios de URL sin recarga de página (navegación entre Shorts, por ejemplo)
  void _injectUrlTracker() {
    if (controller == null || widget.onUrlChanged == null) return;
    const js = '''
(function() {
  if (window.__shemaUrlTracker) return;
  window.__shemaUrlTracker = true;
  function notifyUrl() {
    var url = window.location.href;
    if (url && url !== 'about:blank') {
      try { ShemaUrlChannel.postMessage(url); } catch(e) {}
    }
  }
  var origPush = history.pushState;
  history.pushState = function() { origPush.apply(this, arguments); setTimeout(notifyUrl, 0); };
  var origReplace = history.replaceState;
  history.replaceState = function() { origReplace.apply(this, arguments); setTimeout(notifyUrl, 0); };
  window.addEventListener('popstate', notifyUrl);
  notifyUrl();
})();
''';
    try { controller!.runJavaScript(js); } catch (_) {}
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

  /// Verifica si hay conexión a internet haciendo un lookup DNS
  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('youtube.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Inicializa el WebView y configura la plataforma
  void _setupController() {
    controller = widget.preloadedController ?? WebViewController();
    controller!
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF9F9F9))
      ..setNavigationDelegate(_navigationDelegate())
      ..enableZoom(true)
      ..addJavaScriptChannel(
        'ShemaUrlChannel',
        onMessageReceived: (JavaScriptMessage msg) {
          // YouTube usa history.pushState para navegar entre videos (ej: Shorts)
          // Este canal recibe la nueva URL sin necesidad de recargar la página
          final url = msg.message;
          if (mounted && url.isNotEmpty && url != 'about:blank') {
            widget.onUrlChanged?.call(url);
          }
        },
      );

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
  }

  /// Carga la URL inicial o usa el controlador precargado
  void _loadInitialUrl() {
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
  void initState() {
    super.initState();
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    // Verificar conexión antes de cargar el WebView
    unawaited(_hasInternet().then((connected) {
      if (!mounted) return;
      if (connected) {
        _setupController();
        _loadInitialUrl();
        setState(() {});
      } else {
        setState(() => _isOffline = true);
      }
    }));
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

    // Pantalla offline cuando no hay conexión
    if (_isOffline) {
      return _buildOfflineScreen(context);
    }

    // Mientras se verifica la conexión, mostrar indicador de carga
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        WebViewWidget(controller: controller!),
        if (_progress < 100) LinearProgressIndicator(value: _progress / 100),
      ],
    );
  }

  /// Construye una pantalla offline con icono, mensaje y botón de reintentar
  Widget _buildOfflineScreen(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final iconBg = isDark ? const Color(0xFF333336) : const Color(0xFFF3F4F6);
    final titleColor = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1C1C1E);
    final descColor = isDark ? const Color(0xFF8D8D93) : const Color(0xFF6C6C70);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  size: 32,
                  color: descColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                s.noInternetTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.noInternetDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: descColor,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final connected = await _hasInternet();
                    if (!mounted) return;
                    if (connected) {
                      if (controller == null) {
                        _setupController();
                        _loadInitialUrl();
                      } else {
                        controller!.reload();
                      }
                      setState(() => _isOffline = false);
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(s.retry),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
