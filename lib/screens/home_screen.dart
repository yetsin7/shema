/// Pantalla principal con navegación por pestañas y gestión de descargas.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/directory_manager.dart';
import '../services/download_center.dart';
import '../widgets/download_dialog.dart';
import '../services/download_service.dart';
import '../l10n.dart';
import '../widgets/media_screens.dart';
import '../services/quality_picker.dart';
import 'settings_screen.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/download_banner.dart';
import 'youtube_screen.dart';
import '../utils/youtube_utils.dart';

/// Pantalla principal con 5 pestañas: YouTube, Shorts, Música, Videos, Configuración.
///
/// Usa [IndexedStack] para mantener el estado de cada pestaña.
/// Recibe opcionalmente un [WebViewController] precargado desde el splash.
class HomeScreen extends StatefulWidget {
  /// Crea la pantalla principal con un controlador de YouTube opcional
  const HomeScreen({super.key, this.preloadedYouTubeController});

  /// Controlador precargado durante el splash para arranque rápido
  final WebViewController? preloadedYouTubeController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Estado de la pantalla principal que coordina todas las pestañas y servicios
class _HomeScreenState extends State<HomeScreen> {
  /// Centro de descargas compartido por todas las pestañas
  final DownloadCenter _downloadCenter = DownloadCenter();

  /// Gestor de carpetas de música y video
  final DirectoryManager _dirManager = DirectoryManager();

  /// Clave global para acceder al WebView de YouTube principal
  final GlobalKey<YouTubeScreenState> _youtubeKey = GlobalKey();

  /// Clave global para acceder al WebView de Shorts
  final GlobalKey<YouTubeScreenState> _shortsKey = GlobalKey();

  /// Selector de calidades con caché y precarga
  late final QualityPicker _qualityPicker;

  /// Índice de la pestaña activa (0=YouTube, 1=Shorts, 2=Música, 3=Videos, 4=Config)
  int _currentIndex = 0;

  /// Indica si un video está en pantalla completa (oculta AppBar y nav)
  bool _isFullScreen = false;

  /// URL actual del WebView de YouTube (para mostrar/ocultar el botón Bajar)
  String _youtubeUrl = '';

  /// URL actual del WebView de Shorts (para mostrar/ocultar el botón Bajar)
  String _shortsUrl = '';

  /// El botón Bajar solo se muestra cuando la pestaña activa tiene una URL de video
  bool get _showDownloadButton {
    if (_currentIndex == 0) return isLikelyYouTubeVideoUrl(_youtubeUrl);
    if (_currentIndex == 1) return isLikelyYouTubeVideoUrl(_shortsUrl);
    return false;
  }

  @override
  void initState() {
    super.initState();
    _qualityPicker = QualityPicker(YtDlpService());
    unawaited(_dirManager.loadDirectories().then((_) {
      if (mounted) setState(() {});
    }));
  }

  @override
  void dispose() {
    _qualityPicker.dispose();
    _downloadCenter.dispose();
    super.dispose();
  }

  /// Selector de carpeta para música o video
  Future<void> _pickFolder({required bool isMusic}) async {
    final changed = await _dirManager.pickFolder(context, isMusic: isMusic);
    if (changed && mounted) setState(() {});
  }

  /// Abre la carpeta configurada en el explorador de archivos
  Future<void> _openConfiguredFolder({required bool isMusic}) async {
    await _dirManager.openConfiguredFolder(context, isMusic: isMusic);
  }

  /// Abre el diálogo de descarga con campo para pegar link
  Future<void> _openDownloadOptions() async {
    if (_dirManager.musicDirectory == null || _dirManager.videoDirectory == null) {
      _openSettings();
      return;
    }

    final urlController = TextEditingController();
    final activeKey = _currentIndex == 0 ? _youtubeKey : (_currentIndex == 1 ? _shortsKey : null);
    final currentUrl = await activeKey?.currentState?.currentUrl();
    if (currentUrl != null && isLikelyYouTubeVideoUrl(currentUrl)) {
      urlController.text = canonicalizeYouTubeUrl(currentUrl);
    }

    if (!mounted) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => DownloadDialog(urlController: urlController),
    );

    urlController.dispose();
    if (result == null || !mounted) return;

    final rawUrl = result['url'] ?? '';
    final type = result['type'] ?? 'video';
    if (rawUrl.isEmpty) return;

    final url = canonicalizeYouTubeUrl(rawUrl);
    final quality = await _qualityPicker.pickQuality(context, type == 'audio', url);
    if (quality == null || !mounted) return;

    final isAudio = type == 'audio';
    _downloadCenter.enqueue(
      kind: isAudio ? MediaKind.audio : MediaKind.video,
      quality: quality,
      url: url,
      downloadDirectory: isAudio ? _dirManager.musicDirectory! : _dirManager.videoDirectory!,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).downloadStarted(type == 'audio' ? 'MP3' : 'MP4', quality))),
    );
  }

  /// Cambia a la pestaña de configuración
  void _openSettings() => setState(() => _currentIndex = 4);

  /// Cambia la pestaña activa; pausa WebViews al salir de YouTube/Shorts
  void _onTabChanged(int index) {
    if (index == 0 && _currentIndex == 0) {
      _youtubeKey.currentState?.controller?.loadRequest(Uri.parse('https://m.youtube.com'));
    } else if (index == 1 && _currentIndex == 1) {
      _shortsKey.currentState?.controller?.loadRequest(Uri.parse('https://m.youtube.com/shorts'));
    }

    final wasOnWebView = _currentIndex == 0 || _currentIndex == 1;
    final goingToWebView = index == 0 || index == 1;

    // Pausar WebViews al salir de pestañas de YouTube/Shorts
    if (wasOnWebView && !goingToWebView) {
      _youtubeKey.currentState?.pauseWebView();
      _shortsKey.currentState?.pauseWebView();
    }

    // Reanudar el WebView correspondiente al volver
    if (!wasOnWebView && goingToWebView) {
      if (index == 0) {
        _youtubeKey.currentState?.resumeWebView();
      } else {
        _shortsKey.currentState?.resumeWebView();
      }
    }

    // Si cambia entre YouTube y Shorts, pausar el que se deja y reanudar el nuevo
    if (wasOnWebView && goingToWebView && _currentIndex != index) {
      if (_currentIndex == 0) {
        _youtubeKey.currentState?.pauseWebView();
        _shortsKey.currentState?.resumeWebView();
      } else {
        _shortsKey.currentState?.pauseWebView();
        _youtubeKey.currentState?.resumeWebView();
      }
    }

    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_currentIndex == 0 || _currentIndex == 1) {
          final state = (_currentIndex == 0 ? _youtubeKey : _shortsKey).currentState;
          if (state?.controller != null) {
            final canGoBack = await state!.controller!.canGoBack();
            if (canGoBack) {
              await state.controller!.goBack();
              return;
            }
          }
        }
        if (mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: _isFullScreen ? null : AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          // Logo + título + subtítulo premium
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.asset('assets/icon_shema.png',
                    width: 36, height: 36, fit: BoxFit.cover),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Shema',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'YouTube Downloader',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // Botón Bajar: solo visible cuando hay un video de YouTube activo
            if (_showDownloadButton)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: _openDownloadOptions,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.38),
                          blurRadius: 10,
                          spreadRadius: -2,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.download_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 5),
                        Text('Bajar',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                DownloadBanner(downloadCenter: _downloadCenter),
                Expanded(
                  child: Padding(
                    // Espacio inferior para que el contenido no quede detrás del nav flotante
                    padding: EdgeInsets.only(
                      left: 8,
                      right: 8,
                      bottom: _isFullScreen ? 0 : 66 + (MediaQuery.of(context).viewPadding.bottom > 0
                          ? MediaQuery.of(context).viewPadding.bottom + 4
                          : 12),
                    ),
                    child: IndexedStack(
                      index: _currentIndex,
                      children: [
                        YouTubeScreen(
                          key: _youtubeKey,
                          initialUrl: 'https://www.youtube.com',
                          preloadedController: widget.preloadedYouTubeController,
                          onFullScreenChanged: (fs) => setState(() => _isFullScreen = fs),
                          onUrlChanged: (url) => setState(() => _youtubeUrl = url),
                        ),
                        YouTubeScreen(
                          key: _shortsKey,
                          initialUrl: 'https://www.youtube.com/shorts',
                          onFullScreenChanged: (fs) => setState(() => _isFullScreen = fs),
                          onUrlChanged: (url) => setState(() => _shortsUrl = url),
                        ),
                        MusicScreen(downloadCenter: _downloadCenter, downloadDirectory: _dirManager.musicDirectory),
                        VideosScreen(downloadCenter: _downloadCenter, downloadDirectory: _dirManager.videoDirectory),
                        SettingsScreen(
                          musicDirectory: _dirManager.musicDirectory,
                          videoDirectory: _dirManager.videoDirectory,
                          onPickFolder: _pickFolder,
                          onOpenFolder: _openConfiguredFolder,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Barra de navegación flotante con glassmorphism
            if (!_isFullScreen)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: CustomBottomNav(
                  currentIndex: _currentIndex,
                  onIndexChanged: _onTabChanged,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
