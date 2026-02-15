/// Pantalla principal con navegación por pestañas y gestión de descargas.
library;

import 'dart:async';
import 'dart:ui';

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

/// Pantalla principal de la aplicación con navegación de pestañas
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.preloadedYouTubeController});
  final WebViewController? preloadedYouTubeController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Estado de la pantalla principal
class _HomeScreenState extends State<HomeScreen> {
  final DownloadCenter _downloadCenter = DownloadCenter();
  final DirectoryManager _dirManager = DirectoryManager();
  final GlobalKey<YouTubeScreenState> _youtubeKey = GlobalKey();
  final GlobalKey<YouTubeScreenState> _shortsKey = GlobalKey();
  late final QualityPicker _qualityPicker;
  int _currentIndex = 0;
  bool _isFullScreen = false;

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

  /// Navega a la pestaña YouTube y abre la búsqueda
  void _openSearch() {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
    }
    // Pequeño delay para asegurar que el WebView esté visible
    Future.delayed(const Duration(milliseconds: 100), () {
      _youtubeKey.currentState?.navigateToSearch();
    });
  }

  /// Construye la barra de búsqueda en el AppBar
  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _openSearch,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                S.of(context).searchYouTube,
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
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
          titleSpacing: 8,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          leading: Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/icon_shema.png', fit: BoxFit.cover),
            ),
          ),
          title: const Text('Shema'),
          actions: [
            IconButton(
              tooltip: S.of(context).downloadTooltip,
              onPressed: _openDownloadOptions,
              icon: const Icon(Icons.download),
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
                        ),
                        YouTubeScreen(
                          key: _shortsKey,
                          initialUrl: 'https://www.youtube.com/shorts',
                          onFullScreenChanged: (fs) => setState(() => _isFullScreen = fs),
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
                  onIndexChanged: (index) {
                    // Si ya está en YouTube y toca el botón otra vez, volver al inicio
                    if (index == 0 && _currentIndex == 0) {
                      _youtubeKey.currentState?.controller?.loadRequest(
                        Uri.parse('https://m.youtube.com'),
                      );
                    } else if (index == 1 && _currentIndex == 1) {
                      _shortsKey.currentState?.controller?.loadRequest(
                        Uri.parse('https://m.youtube.com/shorts'),
                      );
                    }
                    setState(() => _currentIndex = index);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
