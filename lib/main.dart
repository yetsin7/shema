import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:file_picker/file_picker.dart';

import 'l10n.dart';
import 'theme.dart';

void main() {
  runApp(const ShemaApp());
}

class ShemaApp extends StatelessWidget {
  const ShemaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shema',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        SDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      home: const SplashScreen(),
    );
  }
}

/// Pantalla de splash con precarga de YouTube
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  WebViewController? _preloadedController;
  bool _isYouTubeLoaded = false;
  bool _isYtDlpReady = false;

  @override
  void initState() {
    super.initState();

    // Controlador de animaciÃ³n para el fade del logo
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();

    // Iniciar precarga y animaciÃ³n de progreso
    _startLoading();
  }

  /// Inicia la precarga de YouTube, actualización de yt-dlp y el progreso animado
  Future<void> _startLoading() async {
    // Precargar YouTube en segundo plano
    if (Platform.isAndroid || Platform.isIOS) {
      _preloadYouTube();
    }

    // Actualizar yt-dlp en segundo plano
    _updateYtDlp();

    // Progreso gradual sincronizado con las tareas reales
    const steps = 100;
    const stepDuration = Duration(milliseconds: 35);

    for (int i = 0; i <= steps; i++) {
      if (!mounted) return;

      await Future.delayed(stepDuration);

      if (!mounted) return;

      setState(() {
        _progress = i / steps;
      });

      // Al 50%, esperar a que yt-dlp termine de actualizarse
      if (i == 50 && !_isYtDlpReady) {
        while (!_isYtDlpReady && mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      // Al 95%, esperar a que YouTube termine de cargar
      if (i == 95 && !_isYouTubeLoaded) {
        while (!_isYouTubeLoaded && mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    }

    // Al completar, navegar a HomeScreen
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          preloadedYouTubeController: _preloadedController,
        ),
      ),
    );
  }

  /// Actualiza yt-dlp a la última versión disponible durante el splash
  Future<void> _updateYtDlp() async {
    try {
      debugPrint('[Splash] Buscando actualizaciones de yt-dlp...');
      final ytDlp = YtDlpService();
      final result = await ytDlp.updateYtDlp();
      debugPrint('[Splash] yt-dlp actualizado: $result');
    } catch (e) {
      debugPrint('[Splash] No se pudo actualizar yt-dlp: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isYtDlpReady = true;
        });
      }
    }
  }

  /// Precarga el WebViewController de YouTube
  Future<void> _preloadYouTube() async {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (url) {
              if (!mounted) return;
              setState(() {
                _isYouTubeLoaded = true;
              });
            },
            onWebResourceError: (error) {
              // Error cargando YouTube silenciado
            },
          ),
        )
        ..enableZoom(true)
        ..loadRequest(Uri.parse('https://m.youtube.com'));

      if (!mounted) return;

      setState(() {
        _preloadedController = controller;
      });
    } catch (e) {
      // Error en precarga silenciado
      // Si falla la precarga, marcar como cargado para continuar
      if (!mounted) return;
      setState(() {
        _isYouTubeLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2E7D32),
              const Color(0xFF1B5E20),
              const Color(0xFF388E3C),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Logo animado
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/icon_shema.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // TÃ­tulo de la app
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      'Shema',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // SubtÃ­tulo
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Builder(
                      builder: (context) => Text(
                        S.of(context).splashSubtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Barra de progreso (mÃ¡s cerca del Ã­cono)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 8,
                            width: double.infinity,
                            child: LinearProgressIndicator(
                              value: _progress,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            final s = S.of(context);
                            return Text(
                              _progress < 0.5
                                  ? s.splashInitializing
                                  : _progress < 0.95
                                      ? s.splashLoadingYouTube
                                      : s.splashReady,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum MediaKind { audio, video }

enum DownloadStatus { downloading, completed, failed }

class DownloadTask {
  DownloadTask({
    required this.id,
    required this.kind,
    required this.quality,
    required this.sourceUrl,
    required this.title,
    this.thumbnailUrl,
    this.progress = 0,
    this.status = DownloadStatus.downloading,
    this.filePath,
  });

  String id;
  final MediaKind kind;
  final String quality;
  final String sourceUrl;
  String title;
  String? thumbnailUrl;
  double progress;
  DownloadStatus status;
  String? filePath;
  bool cancelled = false;
}

/// Servicio que se comunica con yt-dlp via platform channels (Android nativo)
class YtDlpService {
  static const _channel = MethodChannel('com.example.baja_videos/ytdlp');
  static const _eventChannel = EventChannel('com.example.baja_videos/ytdlp_progress');

  /// Stream de eventos de progreso desde el lado nativo
  Stream<Map<dynamic, dynamic>> get progressStream =>
      _eventChannel.receiveBroadcastStream().map((e) => e as Map<dynamic, dynamic>);

  /// Inicia una descarga y retorna el downloadId asignado
  Future<String> downloadMedia({
    required String url,
    required String quality,
    required String downloadPath,
    required bool isAudio,
  }) async {
    final result = await _channel.invokeMethod<String>('downloadMedia', {
      'url': url,
      'quality': quality,
      'downloadPath': downloadPath,
      'isAudio': isAudio,
    });
    return result ?? '';
  }

  /// Cancela una descarga en progreso
  Future<void> cancelDownload(String downloadId) async {
    await _channel.invokeMethod('cancelDownload', {'downloadId': downloadId});
  }

  /// Actualiza yt-dlp a la última versión disponible
  Future<String> updateYtDlp() async {
    final result = await _channel.invokeMethod<String>('updateYtDlp');
    return result ?? 'UNKNOWN';
  }
}

/// Centro de descargas que usa yt-dlp via platform channels
class DownloadCenter extends ChangeNotifier {
  DownloadCenter() {
    _listenToProgress();
  }

  final List<DownloadTask> _tasks = <DownloadTask>[];
  final YtDlpService _ytDlp = YtDlpService();
  StreamSubscription? _progressSub;
  bool _notifyScheduled = false;

  /// Notifica a los listeners de forma segura, evitando conflictos con el build
  void _safeNotify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  /// Escucha los eventos de progreso del canal nativo
  void _listenToProgress() {
    _progressSub = _ytDlp.progressStream.listen((event) {
      final downloadId = event['downloadId'] as String? ?? '';
      final status = event['status'] as String? ?? '';
      final progress = (event['progress'] as num?)?.toDouble() ?? 0.0;
      final line = event['line'] as String? ?? '';
      final filePath = event['filePath'] as String?;
      final error = event['error'] as String?;

      debugPrint('[DownloadCenter] Evento recibido: status=$status, progress=$progress, id=$downloadId');
      debugPrint('[DownloadCenter] line=$line, filePath=$filePath, error=$error');

      final idx = _tasks.indexWhere((t) => t.id == downloadId);
      if (idx == -1) {
        debugPrint('[DownloadCenter] WARN: No se encontró tarea con id=$downloadId. IDs actuales: ${_tasks.map((t) => t.id).toList()}');
        return;
      }

      final task = _tasks[idx];

      switch (status) {
        case 'downloading':
          // yt-dlp envía 0-100, -1 significa sin progreso aún (metadatos)
          if (progress >= 0) {
            task.progress = progress / 100.0;
          }
          // Mostrar info útil en el título según la fase
          if (line.isNotEmpty) {
            if (line.contains('Downloading item')) {
              task.title = line;
            } else if (line.contains('Downloading webpage') || line.contains('Extracting URL')) {
              task.title = 'Obteniendo info del video...';
            } else if (line.contains('Sleeping')) {
              task.title = 'Esperando (límite del sitio)...';
            } else if (line.contains('ExtractAudio') || line.contains('Destination:')) {
              task.title = 'Convirtiendo a MP3...';
              task.progress = 0.92;
            } else if (line.contains('Metadata')) {
              task.title = 'Agregando metadata...';
              task.progress = 0.95;
            } else if (line.contains('EmbedThumbnail')) {
              task.title = 'Agregando portada...';
              task.progress = 0.98;
            } else if (line.contains('Merging') || line.contains('merge')) {
              task.title = 'Combinando video y audio...';
              task.progress = 0.95;
            } else if (!line.startsWith('[')) {
              task.title = line;
            }
          }
          break;
        case 'completed':
          task.progress = 1.0;
          task.status = DownloadStatus.completed;
          task.filePath = filePath;
          // Mostrar nombre limpio del archivo descargado
          if (filePath != null && filePath.isNotEmpty) {
            task.title = filePath.split('/').last.replaceAll(RegExp(r'\.\w+$'), '');
          }
          break;
        case 'failed':
          task.status = DownloadStatus.failed;
          task.title = '${task.title} - Error: ${error ?? "desconocido"}';
          break;
        case 'cancelled':
          task.status = DownloadStatus.failed;
          task.title = '${task.title} (Cancelado)';
          break;
      }

      _safeNotify();
    });
  }

  /// Retorna las tareas filtradas por tipo de media
  List<DownloadTask> tasksByKind(MediaKind kind) {
    return _tasks.where((task) => task.kind == kind).toList(growable: false);
  }

  /// Retorna todas las tareas activas (descargando)
  List<DownloadTask> get activeTasks {
    return _tasks.where((t) => t.status == DownloadStatus.downloading).toList(growable: false);
  }

  /// Cancela una descarga en progreso
  void cancel(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final task = _tasks[idx];
    task.cancelled = true;
    task.status = DownloadStatus.failed;
    task.title = '${task.title} (Cancelado)';
    _ytDlp.cancelDownload(taskId);
    notifyListeners();
  }

  /// Elimina una tarea de la lista y su archivo si existe
  Future<void> removeTask(String taskId) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final task = _tasks[idx];

    // Si está descargando, cancelar primero
    if (task.status == DownloadStatus.downloading) {
      task.cancelled = true;
      _ytDlp.cancelDownload(taskId);
    }

    // Eliminar archivo si existe
    if (task.filePath != null) {
      final file = File(task.filePath!);
      if (await file.exists()) await file.delete();
    }

    _tasks.removeAt(idx);
    notifyListeners();
  }

  /// Encola una descarga usando yt-dlp (via platform channel)
  void enqueue({
    required MediaKind kind,
    required String quality,
    required String url,
    required String downloadDirectory,
  }) {
    final task = DownloadTask(
      id: '', // Se asignará desde el lado nativo
      kind: kind,
      quality: quality,
      sourceUrl: url,
      title: 'Iniciando descarga...',
    );

    _tasks.insert(0, task);
    notifyListeners();

    debugPrint('[DownloadCenter] Encolando descarga: url=$url, kind=$kind, quality=$quality, dir=$downloadDirectory');

    // Iniciar descarga via platform channel
    _ytDlp.downloadMedia(
      url: url,
      quality: quality,
      downloadPath: downloadDirectory,
      isAudio: kind == MediaKind.audio,
    ).then((downloadId) {
      debugPrint('[DownloadCenter] ID asignado por nativo: $downloadId');
      // Actualizar el ID de la tarea con el asignado por el nativo
      task.id = downloadId;
      _safeNotify();
    }).catchError((e) {
      debugPrint('[DownloadCenter] ERROR al iniciar descarga: $e');
      task.status = DownloadStatus.failed;
      task.title = 'Error al iniciar: $e';
      _safeNotify();
    });
  }

  /// Actualiza yt-dlp a la última versión
  Future<String> updateYtDlp() => _ytDlp.updateYtDlp();

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }
}
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.preloadedYouTubeController,
  });

  final WebViewController? preloadedYouTubeController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _downloadDirKey = 'download_directory_path';

  final DownloadCenter _downloadCenter = DownloadCenter();
  final GlobalKey<_YouTubeScreenState> _youtubeKey =
      GlobalKey<_YouTubeScreenState>();
  final GlobalKey<_YouTubeScreenState> _shortsKey =
      GlobalKey<_YouTubeScreenState>();

  int _currentIndex = 0;
  String? _downloadDirectory;

  static const _videoQualities = <String>[
    '144p',
    '240p',
    '360p',
    '480p',
    '720p',
    '1080p',
  ];
  static const _audioQualities = <String>[
    '64 kbps',
    '128 kbps',
    '192 kbps',
    '256 kbps',
    '320 kbps',
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_loadDownloadDirectory());
  }

  @override
  void dispose() {
    _downloadCenter.dispose();
    super.dispose();
  }

  Future<String> _defaultDir() async {
    // Usar carpeta interna de la app que siempre tiene permisos
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}${Platform.pathSeparator}Shema';
  }

  Future<void> _loadDownloadDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_downloadDirKey);
    final path = (saved == null || saved.trim().isEmpty)
        ? await _defaultDir()
        : saved.trim();
    await Directory(path).create(recursive: true);
    if (!mounted) return;
    setState(() {
      _downloadDirectory = path;
    });
  }

  Future<void> _openDownloadSettings() async {
    final initial = _downloadDirectory ?? await _defaultDir();
    if (!mounted) return;

    // Mostrar diÃ¡logo con opciÃ³n de navegar
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).downloadSettingsTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.of(context).currentFolder, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(initial, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            Text(S.of(context).selectFolderInstruction),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(S.of(context).cancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, 'select'),
            icon: const Icon(Icons.folder_open),
            label: Text(S.of(context).selectFolder),
          ),
        ],
      ),
    );

    // Si se cancela o el widget ya no estÃ¡ montado, salir
    if (action != 'select') return;
    if (!mounted) return;

    // Abrir selector de carpeta
    final selectedPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: S.of(context).selectFolderDialogTitle,
      initialDirectory: initial,
    );

    // Si se cancela la selecciÃ³n o el widget ya no estÃ¡ montado, salir silenciosamente
    if (selectedPath == null || selectedPath.isEmpty) return;
    if (!mounted) return;

    try {
      await Directory(selectedPath).create(recursive: true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_downloadDirKey, selectedPath);

      if (!mounted) return;

      setState(() {
        _downloadDirectory = selectedPath;
      });

      // Verificar mounted antes de usar ScaffoldMessenger
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).folderSet(selectedPath))),
      );
    } catch (e) {
      // Verificar mounted antes de mostrar error
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).folderSelectError)),
      );
    }
  }

  /// Abre el modal de descarga con campo para pegar link
  Future<void> _openDownloadOptions() async {
    if (_downloadDirectory == null || _downloadDirectory!.isEmpty) {
      await _openDownloadSettings();
      if (_downloadDirectory == null || _downloadDirectory!.isEmpty || !mounted) {
        return;
      }
    }

    final urlController = TextEditingController();

    // Intentar obtener la URL actual del WebView como valor inicial
    final activeKey = _currentIndex == 0
        ? _youtubeKey
        : _currentIndex == 1
        ? _shortsKey
        : null;
    final currentUrl = await activeKey?.currentState?.currentUrl();
    if (currentUrl != null && currentUrl.contains('youtube.com/watch')) {
      urlController.text = currentUrl;
    }

    if (!mounted) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => _DownloadDialog(
        urlController: urlController,
      ),
    );

    urlController.dispose();

    if (result == null || !mounted) return;

    final url = result['url'] ?? '';
    final type = result['type'] ?? 'video';

    if (url.isEmpty) return;

    // Seleccionar calidad
    final quality = await _pickQuality(type == 'audio');
    if (quality == null || !mounted) return;

    _downloadCenter.enqueue(
      kind: type == 'audio' ? MediaKind.audio : MediaKind.video,
      quality: quality,
      url: url,
      downloadDirectory: _downloadDirectory!,
    );

    if (!mounted) return;
    final label = type == 'audio' ? 'MP3' : 'MP4';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).downloadStarted(label, quality))),
    );
  }

  /// Navega hacia atrÃ¡s en el historial del WebView
  Future<void> _goBackInWebView() async {
    final activeKey = _currentIndex == 0
        ? _youtubeKey
        : _currentIndex == 1
        ? _shortsKey
        : null;

    final state = activeKey?.currentState;
    if (state != null) {
      final canGoBack = await state.canGoBack();
      if (canGoBack) {
        await state.goBack();
      }
    }
  }

  /// Construye un item de navegaciÃ³n personalizado
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color color,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono con animaciÃ³n
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: EdgeInsets.all(isSelected ? 6 : 4),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                size: isSelected ? 24 : 22,
                color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            // Label con animaciÃ³n
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              style: TextStyle(
                fontSize: isSelected ? 11 : 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.2,
                height: 1.1,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickQuality(bool isAudio) async {
    final options = isAudio ? _audioQualities : _videoQualities;
    String selected = options.first;

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text(isAudio ? S.of(context).audioQualityTitle : S.of(context).videoQualityTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((q) {
              final isSelected = selected == q;
              return ListTile(
                dense: true,
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? const Color(0xFF2E7D32) : null,
                ),
                title: Text(q),
                onTap: () => setLocalState(() => selected = q),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.of(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selected),
              child: Text(S.of(context).accept),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Shema';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Solo interceptar en YouTube y Shorts
        if (_currentIndex == 0 || _currentIndex == 1) {
          final activeKey = _currentIndex == 0 ? _youtubeKey : _shortsKey;
          final state = activeKey.currentState;

          if (state != null && state._controller != null) {
            final canGoBack = await state._controller!.canGoBack();
            if (canGoBack) {
              // Hay historial, volver atrÃ¡s en el WebView
              await state._controller!.goBack();
              return;
            }
          }
        }

        // Si no hay historial o estÃ¡ en otra pestaÃ±a, cerrar la app
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        extendBody: false,
        appBar: AppBar(
        leading: (_currentIndex == 0 || _currentIndex == 1)
            ? IconButton(
                tooltip: S.of(context).backTooltip,
                onPressed: _goBackInWebView,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icon_shema.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        actions: [
          IconButton(
            tooltip: S.of(context).downloadSettingsTooltip,
            onPressed: _openDownloadSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: S.of(context).downloadTooltip,
            onPressed: _openDownloadOptions,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de descargas activas visible en todas las pestanas
          ListenableBuilder(
            listenable: _downloadCenter,
            builder: (context, _) {
              final active = _downloadCenter.activeTasks;
              if (active.isEmpty) return const SizedBox.shrink();

              return Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1B3A1C)
                    : const Color(0xFF1B5E20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: active.map((task) {
                    final percent = (task.progress * 100).toInt();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          // Icono de tipo
                          Icon(
                            task.kind == MediaKind.audio ? Icons.graphic_eq : Icons.movie_creation_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          // Titulo y progreso
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 3),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: task.progress,
                                    backgroundColor: Colors.white24,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Porcentaje
                          Text(
                            '$percent%',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          // Boton cancelar
                          IconButton(
                            onPressed: () => _downloadCenter.cancel(task.id),
                            icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                            tooltip: S.of(context).cancelDownloadTooltip,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          // Contenido principal
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                YouTubeScreen(
                  key: _youtubeKey,
                  initialUrl: 'https://www.youtube.com',
                  preloadedController: widget.preloadedYouTubeController,
                ),
                YouTubeScreen(
                  key: _shortsKey,
                  initialUrl: 'https://www.youtube.com/shorts',
                ),
                MusicScreen(
                  downloadCenter: _downloadCenter,
                  downloadDirectory: _downloadDirectory,
                ),
                VideosScreen(
                  downloadCenter: _downloadCenter,
                  downloadDirectory: _downloadDirectory,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.play_circle_outline,
                  activeIcon: Icons.play_circle,
                  label: 'YouTube',
                  color: const Color(0xFFD32F2F),
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.slow_motion_video_outlined,
                  activeIcon: Icons.slow_motion_video,
                  label: 'Shorts',
                  color: const Color(0xFFFF5722),
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.music_note_outlined,
                  activeIcon: Icons.music_note,
                  label: 'MP3',
                  color: const Color(0xFF1565C0),
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.video_library_outlined,
                  activeIcon: Icons.video_library,
                  label: 'MP4',
                  color: const Color(0xFFEF6C00),
                ),
              ],
            ),
          ),
        ),
      );
        },
      ),
      ),
    );
  }
}

/// Modal flotante para pegar link y elegir formato de descarga
class _DownloadDialog extends StatefulWidget {
  const _DownloadDialog({required this.urlController});

  final TextEditingController urlController;

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  bool _hasUrl = false;

  @override
  void initState() {
    super.initState();
    _hasUrl = widget.urlController.text.trim().isNotEmpty;
    widget.urlController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.urlController.removeListener(_onTextChanged);
    super.dispose();
  }

  /// Actualiza el estado cuando cambia el texto del campo
  void _onTextChanged() {
    final has = widget.urlController.text.trim().isNotEmpty;
    if (has != _hasUrl) {
      setState(() => _hasUrl = has);
    }
  }

  /// Pega el contenido del portapapeles en el campo
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      widget.urlController.text = data.text!.trim();
      widget.urlController.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.urlController.text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título
            Row(
              children: [
                const Icon(Icons.download_rounded, color: Color(0xFF2E7D32), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    S.of(context).downloadDialogTitle,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                // Botón cerrar
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Campo de texto para el link
            TextField(
              controller: widget.urlController,
              decoration: InputDecoration(
                hintText: S.of(context).downloadUrlHint,
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                prefixIcon: const Icon(Icons.link, color: Color(0xFF2E7D32)),
                suffixIcon: IconButton(
                  tooltip: S.of(context).clearTooltip,
                  onPressed: () => widget.urlController.clear(),
                  icon: const Icon(Icons.clear, size: 20),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              keyboardType: TextInputType.url,
              maxLines: 1,
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 12),

            // Botón de pegar desde portapapeles
            OutlinedButton.icon(
              onPressed: _pasteFromClipboard,
              icon: const Icon(Icons.content_paste, size: 20),
              label: Text(S.of(context).pasteClipboard),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
                side: const BorderSide(color: Color(0xFF2E7D32)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 20),

            // Botones de descarga MP4 y MP3
            Row(
              children: [
                // Botón MP4
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _hasUrl
                        ? () => Navigator.pop(context, {
                              'url': widget.urlController.text.trim(),
                              'type': 'video',
                            })
                        : null,
                    icon: const Icon(Icons.movie_creation_outlined, size: 20),
                    label: const Text('MP4'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      disabledBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Botón MP3
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _hasUrl
                        ? () => Navigator.pop(context, {
                              'url': widget.urlController.text.trim(),
                              'type': 'audio',
                            })
                        : null,
                    icon: const Icon(Icons.graphic_eq, size: 20),
                    label: const Text('MP3'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      disabledBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class YouTubeScreen extends StatefulWidget {
  const YouTubeScreen({
    required this.initialUrl,
    super.key,
    this.preloadedController,
  });

  final String initialUrl;
  final WebViewController? preloadedController;

  @override
  State<YouTubeScreen> createState() => _YouTubeScreenState();
}

class _YouTubeScreenState extends State<YouTubeScreen> {
  WebViewController? _controller;
  int _progress = 0;
  String? _errorMessage;

  Future<String?> currentUrl() async => _controller?.currentUrl();

  /// Navega hacia atrÃ¡s en el historial del WebView
  Future<void> goBack() async {
    if (_controller != null) {
      await _controller!.goBack();
    }
  }

  /// Verifica si puede navegar hacia atrÃ¡s
  Future<bool> canGoBack() async {
    if (_controller != null) {
      return await _controller!.canGoBack();
    }
    return false;
  }

  /// Inyecta CSS y JavaScript para personalizar YouTube
  Future<void> _injectCustomizations() async {
    if (_controller == null) return;

    // JavaScript para ocultar elementos de YouTube y observar cambios en el DOM
    const hideElementsJS = '''
      (function() {
        // Crear estilo CSS
        const style = document.createElement('style');
        style.id = 'baja-videos-custom-style';
        style.innerHTML = `
          /* Ocultar SOLO la barra de navegación inferior de YouTube (Principal, Shorts, Tú) */
          c3-tab-bar-renderer,
          ytm-pivot-bar-renderer,
          ytm-mobile-bottom-bar-renderer,
          .pivot-bar-renderer,
          ytm-pivot-bar-item-renderer,
          .mobile-topbar-header-content {
            display: none !important;
            visibility: hidden !important;
            height: 0 !important;
            max-height: 0 !important;
            overflow: hidden !important;
            margin: 0 !important;
            padding: 0 !important;
            position: absolute !important;
            left: -9999px !important;
          }

          /* Ocultar SOLO botones especÃ­ficos de like/dislike (NO menÃºs contextuales) */
          ytm-like-button-renderer,
          ytm-dislike-button-renderer,
          .like-button-renderer,
          .dislike-button-renderer {
            display: none !important;
            visibility: hidden !important;
            opacity: 0 !important;
          }

          /* IMPORTANTE: NO aplicar estilos que oculten menÃºs contextuales */
          /* Permitir que YouTube maneje sus propios estilos de menÃº */

          /* Ajustar el contenido para que use todo el espacio */
          ytm-app {
            padding-bottom: 0 !important;
          }

          ytm-browse {
            margin-bottom: 0 !important;
            padding-bottom: 0 !important;
          }

          /* Hacer scroll mÃ¡s fluido */
          body, html {
            overflow-x: hidden !important;
          }

          /* IMPORTANTE: NO ocultar bottom sheets ni diÃ¡logos para que los menÃºs contextuales funcionen */
        `;

        // Remover estilo anterior si existe
        const oldStyle = document.getElementById('baja-videos-custom-style');
        if (oldStyle) oldStyle.remove();

        document.head.appendChild(style);

        // FunciÃ³n para ocultar SOLO elementos especÃ­ficos de YouTube
        function hideYouTubeElements() {
          const selectors = [
            // Barra de navegación inferior (Principal, Shorts, Tú)
            'c3-tab-bar-renderer',
            'ytm-pivot-bar-renderer',
            'ytm-mobile-bottom-bar-renderer',
            '.pivot-bar-renderer',
            'ytm-pivot-bar-item-renderer',
            '.mobile-topbar-header-content',
            // Botones de like/dislike
            'ytm-like-button-renderer',
            'ytm-dislike-button-renderer',
          ];

          selectors.forEach(selector => {
            const elements = document.querySelectorAll(selector);
            elements.forEach(el => {
              if (el) {
                // NO eliminar del DOM, solo ocultar con CSS
                el.style.setProperty('display', 'none', 'important');
                el.style.setProperty('visibility', 'hidden', 'important');
                el.style.setProperty('height', '0', 'important');
                el.style.setProperty('max-height', '0', 'important');
                el.style.setProperty('overflow', 'hidden', 'important');
                el.style.setProperty('opacity', '0', 'important');
              }
            });
          });
        }

        // FunciÃ³n para asegurar que los menÃºs contextuales siempre funcionen
        function ensureMenusWork() {
          const menuSelectors = [
            'ytm-bottom-sheet-renderer',
            'ytm-menu-renderer',
            'ytm-menu-item-renderer',
            'ytm-menu-service-item-renderer',
            'ytm-menu-navigation-item-renderer',
            'ytm-unified-share-panel-renderer',
            'ytm-share-panel-renderer',
            'tp-yt-paper-dialog',
            'tp-yt-paper-item',
            'ytm-sheet-controller',
            'ytm-overflow-menu-renderer',
            'ytm-engagement-panel-section-list-renderer',
            '[role="dialog"]',
            '[role="menu"]',
            '[role="menuitem"]',
          ];

          menuSelectors.forEach(selector => {
            const elements = document.querySelectorAll(selector);
            elements.forEach(el => {
              if (el && el.style) {
                // Solo quitar estilos que puedan estar ocultando los menÃºs
                if (el.style.display === 'none') el.style.display = '';
                if (el.style.visibility === 'hidden') el.style.visibility = '';
                if (el.style.opacity === '0') el.style.opacity = '';
                if (el.style.height === '0' || el.style.height === '0px') el.style.height = '';
                if (el.style.maxHeight === '0' || el.style.maxHeight === '0px') el.style.maxHeight = '';
                // Quitar posicionamiento fuera de pantalla
                if (el.style.position === 'absolute' && el.style.left === '-9999px') {
                  el.style.position = '';
                  el.style.left = '';
                }
              }
            });
          });
        }
        // Agrega un botÃ³n Compartir cuando YouTube no lo muestra en el menÃº de 3 puntos
        let lastMenuVideoUrl = '';

        function findVideoUrlFromElement(element) {
          if (!element) return '';

          const videoHost = element.closest(
            'ytm-video-with-context-renderer, ytm-rich-item-renderer, ytm-compact-video-renderer, ytm-shorts-lockup-view-model'
          );
          if (!videoHost) return '';

          const link = videoHost.querySelector('a[href*="/watch?v="], a[href*="/shorts/"]');
          if (!link) return '';

          try {
            return new URL(link.getAttribute('href') || '', location.origin).toString();
          } catch (_) {
            return '';
          }
        }

        function getBestVideoUrlFromMenu(menu) {
          if (lastMenuVideoUrl) return lastMenuVideoUrl;
          const menuRoot = menu ? (menu.closest('ytm-app') || document) : document;
          const candidates = [
            'a[href*="/watch?v="]',
            'a[href*="/shorts/"]',
            'link[rel="canonical"]',
          ];

          for (const selector of candidates) {
            const node = menuRoot.querySelector(selector) || document.querySelector(selector);
            if (!node) continue;
            const rawUrl = node.getAttribute('href') || node.getAttribute('content') || '';
            if (!rawUrl) continue;
            try {
              return new URL(rawUrl, location.origin).toString();
            } catch (_) {}
          }

          return location.href;
        }

        function createShareButton(url) {
          const button = document.createElement('button');
          button.type = 'button';
          button.setAttribute('data-baja-share', '1');
          button.innerHTML = '<span style="margin-right:12px;font-size:20px">&#x2197;</span> Compartir';
          button.style.width = '100%';
          button.style.padding = '14px 16px';
          button.style.border = '0';
          button.style.borderTop = '1px solid rgba(0,0,0,0.08)';
          button.style.background = 'transparent';
          button.style.textAlign = 'left';
          button.style.fontSize = '15px';
          button.style.fontWeight = '400';
          button.style.cursor = 'pointer';
          button.style.display = 'flex';
          button.style.alignItems = 'center';
          button.style.color = '#0f0f0f';

          button.addEventListener('click', async (ev) => {
            ev.preventDefault();
            ev.stopPropagation();

            const shareUrl = url || location.href;

            try {
              if (navigator.share) {
                await navigator.share({ url: shareUrl, text: shareUrl });
                return;
              }
            } catch (_) {}

            try {
              if (navigator.clipboard && navigator.clipboard.writeText) {
                await navigator.clipboard.writeText(shareUrl);
                return;
              }
            } catch (_) {}

            location.href = shareUrl;
          });

          return button;
        }

        function ensureShareButtonInMenus() {
          // Buscar en bottom sheets y menús de YouTube
          const containers = document.querySelectorAll(
            'ytm-bottom-sheet-renderer, ytm-overflow-menu-renderer, ytm-menu-renderer, [role="menu"], [role="dialog"], ytm-sheet-controller'
          );
          containers.forEach(container => {
            if (!container || container.querySelector('[data-baja-share="1"]')) return;

            const menuText = (container.textContent || '').toLowerCase();
            if (menuText.includes('compartir') || menuText.includes('share')) return;

            // Solo inyectar si el menú tiene items visibles (está abierto)
            const items = container.querySelectorAll('ytm-menu-item, ytm-menu-service-item-renderer, ytm-menu-navigation-item-renderer, tp-yt-paper-item, button');
            if (items.length === 0) return;

            const shareUrl = getBestVideoUrlFromMenu(container);
            const button = createShareButton(shareUrl);

            // Intentar insertar dentro del contenedor de items del menú
            const itemList = container.querySelector('.menu-item-list, .sheet-content, [role="list"]');
            if (itemList) {
              itemList.appendChild(button);
            } else {
              container.appendChild(button);
            }
          });
        }

        document.addEventListener('click', (event) => {
          const trigger = event.target && event.target.closest
            ? event.target.closest(
                'ytm-menu-button-renderer button, ytm-menu-renderer button, button[aria-label*="M"], button[aria-label*="m"]'
              )
            : null;

          if (!trigger) return;

          const urlFromCard = findVideoUrlFromElement(trigger);
          if (urlFromCard) {
            lastMenuVideoUrl = urlFromCard;
          } else {
            lastMenuVideoUrl = '';
          }

          setTimeout(() => {
            ensureShareButtonInMenus();
          }, 120);
        }, true);

        // Ejecutar inmediatamente
        hideYouTubeElements();
        ensureMenusWork();
        ensureShareButtonInMenus();

        // Ejecutar cada 500ms para capturar elementos que se cargan dinÃ¡micamente
        setInterval(() => {
          hideYouTubeElements();
          ensureMenusWork(); // Asegurar que los menÃºs siempre funcionen
          ensureShareButtonInMenus();
        }, 500);

        // Observar cambios en el DOM para ocultar elementos que se agreguen dinÃ¡micamente
        const observer = new MutationObserver((mutations) => {
          hideYouTubeElements();
          ensureMenusWork(); // Asegurar que los menÃºs siempre funcionen
          ensureShareButtonInMenus();
        });

        // Configurar el observador
        observer.observe(document.body, {
          childList: true,
          subtree: true
        });

        // Personalizaciones aplicadas
      })();
    ''';

    try {
      await _controller!.runJavaScript(hideElementsJS);
      // Personalizaciones inyectadas correctamente
    } catch (e) {
      // Error al inyectar personalizaciones silenciado
    }
  }

  @override
  void initState() {
    super.initState();
    // Inicialización del WebView

    if (Platform.isAndroid || Platform.isIOS) {
      // Si hay un controller precargado, usarlo
      if (widget.preloadedController != null) {
        // Usando controller precargado
        _controller = widget.preloadedController;

        // Inyectar personalizaciones en el controller precargado
        _injectCustomizations();

        setState(() {
          _progress = 100; // Ya estÃ¡ cargado
        });
      } else {
        // Crear un nuevo controller
        // Creando nuevo WebViewController

        _controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (p) {
                // Progreso de carga
                if (!mounted) return;
                setState(() {
                  _progress = p;
                  _errorMessage = null;
                });
              },
              onPageStarted: (url) {
                // Página iniciada
                if (!mounted) return;
                setState(() => _errorMessage = null);
              },
              onPageFinished: (url) {
                // Página finalizada
                if (!mounted) return;

                // Inyectar personalizaciones cuando la pÃ¡gina termine de cargar
                _injectCustomizations();

                setState(() => _progress = 100);
              },
              onWebResourceError: (error) {
                // Error de recurso web
                if (!mounted) return;
                setState(() {
                  _errorMessage = 'Error: \${error.description}';
                });
              },
              onNavigationRequest: (request) {
                // Navegando a nueva URL

                // Inyectar personalizaciones en cada navegaciÃ³n (con delay)
                Future.delayed(const Duration(milliseconds: 800), () {
                  _injectCustomizations();
                });
                Future.delayed(const Duration(milliseconds: 1500), () {
                  _injectCustomizations();
                });

                return NavigationDecision.navigate;
              },
            ),
          )
          ..enableZoom(true);

        // Cargando URL
        // Cargar directamente la versiÃ³n mÃ³vil de YouTube para mejor rendimiento
        final mobileUrl = widget.initialUrl.replaceAll('www.youtube.com', 'm.youtube.com');
        _controller!.loadRequest(Uri.parse(mobileUrl));
      }
    } else {
      // Plataforma no soportada para WebView
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return Stack(
        children: [
          WebViewWidget(controller: _controller!),
          if (_progress < 100)
            LinearProgressIndicator(value: _progress / 100),
          if (_errorMessage != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.red.shade100,
                padding: const EdgeInsets.all(12),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            ),
        ],
      );
    }
    return const Center(
      child: Text('YouTube WebView disponible en Android/iOS.'),
    );
  }
}

class MusicScreen extends StatelessWidget {
  const MusicScreen({
    required this.downloadCenter,
    required this.downloadDirectory,
    super.key,
  });

  final DownloadCenter downloadCenter;
  final String? downloadDirectory;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return MediaLibraryScreen(
      title: s.musicTitle,
      emptyTitle: s.noMusicYet,
      emptyDescription: s.noMusicDescription,
      extensions: const <String>{'.mp3', '.m4a', '.wav'},
      icon: Icons.graphic_eq_rounded,
      iconColor: const Color(0xFF1565C0),
      tileTint: const Color(0xFFE3F2FD),
      kind: MediaKind.audio,
      downloadCenter: downloadCenter,
      downloadDirectory: downloadDirectory,
    );
  }
}

class VideosScreen extends StatelessWidget {
  const VideosScreen({
    required this.downloadCenter,
    required this.downloadDirectory,
    super.key,
  });

  final DownloadCenter downloadCenter;
  final String? downloadDirectory;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return MediaLibraryScreen(
      title: s.videosTitle,
      emptyTitle: s.noVideosYet,
      emptyDescription: s.noVideosDescription,
      extensions: const <String>{'.mp4', '.webm', '.mkv'},
      icon: Icons.movie_creation_outlined,
      iconColor: const Color(0xFFEF6C00),
      tileTint: const Color(0xFFFFF3E0),
      kind: MediaKind.video,
      downloadCenter: downloadCenter,
      downloadDirectory: downloadDirectory,
    );
  }
}

class MediaLibraryScreen extends StatefulWidget {
  const MediaLibraryScreen({
    required this.title,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.extensions,
    required this.icon,
    required this.iconColor,
    required this.tileTint,
    required this.kind,
    required this.downloadCenter,
    required this.downloadDirectory,
    super.key,
  });

  final String title;
  final String emptyTitle;
  final String emptyDescription;
  final Set<String> extensions;
  final IconData icon;
  final Color iconColor;
  final Color tileTint;
  final MediaKind kind;
  final DownloadCenter downloadCenter;
  final String? downloadDirectory;

  @override
  State<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends State<MediaLibraryScreen> {
  late Future<List<FileSystemEntity>> _mediaFilesFuture;
  int _completedTasksCount = 0;

  @override
  void initState() {
    super.initState();
    _mediaFilesFuture = _loadMediaFiles();
    _completedTasksCount = widget.downloadCenter
        .tasksByKind(widget.kind)
        .where((task) => task.status == DownloadStatus.completed)
        .length;
    widget.downloadCenter.addListener(_onDownloadsUpdated);
  }

  @override
  void didUpdateWidget(covariant MediaLibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.downloadDirectory != widget.downloadDirectory) {
      _refresh();
    }
  }

  @override
  void dispose() {
    widget.downloadCenter.removeListener(_onDownloadsUpdated);
    super.dispose();
  }

  void _onDownloadsUpdated() {
    if (!mounted) return;
    final completed = widget.downloadCenter
        .tasksByKind(widget.kind)
        .where((task) => task.status == DownloadStatus.completed)
        .length;
    if (completed > _completedTasksCount) {
      _refresh();
    }
    _completedTasksCount = completed;
  }

  Future<List<FileSystemEntity>> _loadMediaFiles() async {
    final configured = widget.downloadDirectory;
    if (configured == null || configured.trim().isEmpty) {
      return <FileSystemEntity>[];
    }

    final directory = Directory(configured);
    if (!await directory.exists()) return <FileSystemEntity>[];

    final files = <FileSystemEntity>[];
    for (final entry in directory.listSync()) {
      if (entry is! File) continue;
      final lower = entry.path.toLowerCase();
      if (widget.extensions.any(lower.endsWith)) {
        files.add(entry);
      }
    }

    files.sort(
      (a, b) => File(
        b.path,
      ).lastModifiedSync().compareTo(File(a.path).lastModifiedSync()),
    );
    return files;
  }

  Future<void> _refresh() async {
    setState(() {
      _mediaFilesFuture = _loadMediaFiles();
    });
    await _mediaFilesFuture;
  }

  Future<void> _openMedia(File file) async {
    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).fileNotAvailable)),
      );
      return;
    }

    final result = await OpenFilex.open(file.path);
    if (!mounted) return;
    if (result.type == ResultType.done) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).cantOpenFile)),
    );
  }


  File? _taskFile(DownloadTask task) {
    final path = task.filePath;
    if (path == null || path.isEmpty) return null;
    final f = File(path);
    return f.existsSync() ? f : null;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.downloadCenter,
      builder: (context, _) {
        final tasks = widget.downloadCenter.tasksByKind(widget.kind);
        // Rutas de archivos que ya tienen una tarea asociada (para no duplicar)
        final taskFilePaths = <String>{};
        for (final t in tasks) {
          if (t.filePath != null && t.filePath!.isNotEmpty) {
            taskFilePaths.add(t.filePath!);
          }
        }

        return FutureBuilder<List<FileSystemEntity>>(
          future: _mediaFilesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final files = snapshot.data ?? <FileSystemEntity>[];
            // Filtrar archivos que ya aparecen como tarea completada
            final uniqueFiles = files.where((f) => !taskFilePaths.contains(f.path)).toList();
            final hasContent = tasks.isNotEmpty || uniqueFiles.isNotEmpty;

            if (!hasContent) {
              return Center(child: Text(widget.emptyDescription));
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                children: [
                  _buildLibraryHeader(),
                  const SizedBox(height: 10),
                  ...tasks.map((task) => _buildUnifiedCard(task: task)),
                  ...uniqueFiles.map((entity) {
                    final file = File(entity.path);
                    return _buildUnifiedCard(file: file);
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Card unificado para tareas de descarga y archivos en disco
  Widget _buildUnifiedCard({DownloadTask? task, File? file}) {
    // Determinar estado y datos
    final bool isTask = task != null;
    final bool downloading = isTask && task.status == DownloadStatus.downloading;
    final bool completed = isTask ? task.status == DownloadStatus.completed : true;
    final bool failed = isTask && task.status == DownloadStatus.failed;
    final bool isAudio = widget.kind == MediaKind.audio;

    // Archivo asociado
    final File? mediaFile = isTask ? _taskFile(task) : file;
    final String name;
    final String? sizeMb;
    final String? quality;

    if (isTask) {
      name = task.title;
      quality = task.quality;
      final f = mediaFile;
      if (f != null && f.existsSync()) {
        sizeMb = (f.statSync().size / (1024 * 1024)).toStringAsFixed(2);
      } else {
        sizeMb = null;
      }
    } else {
      final path = file!.path;
      name = path.split(Platform.pathSeparator).last.replaceAll(RegExp(r'\.\w+$'), '');
      sizeMb = (file.statSync().size / (1024 * 1024)).toStringAsFixed(2);
      quality = null;
    }

    // Texto de estado
    final s = S.of(context);
    final statusText = failed
        ? s.error
        : downloading
            ? '${(task!.progress * 100).toStringAsFixed(0)}%'
            : s.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: downloading
              ? widget.iconColor.withValues(alpha: 0.4)
              : widget.tileTint.withValues(alpha: 0.85),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail o icono (solo portada para video completado)
            _buildThumbnail(
              isAudio: isAudio,
              completed: completed && !failed,
              task: task,
            ),
            const SizedBox(width: 12),
            // Contenido principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y chip de estado
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildStatusChip(statusText, failed, completed && !failed),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Chips de info (calidad, formato, tamaño)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (quality != null)
                        _buildMetaChip(
                          icon: Icons.high_quality_rounded,
                          label: quality,
                        ),
                      _buildMetaChip(
                        icon: isAudio ? Icons.music_note_rounded : Icons.videocam_rounded,
                        label: isAudio ? 'MP3' : 'MP4',
                      ),
                      if (sizeMb != null)
                        _buildMetaChip(
                          icon: Icons.data_usage_rounded,
                          label: '$sizeMb MB',
                        ),
                    ],
                  ),
                  // Barra de progreso (solo descargando)
                  if (downloading) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: task!.progress,
                        minHeight: 6,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(widget.iconColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => widget.downloadCenter.cancel(task.id),
                        icon: const Icon(Icons.close, size: 16),
                        label: Text(s.cancel),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade200),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                  ],
                  // Error
                  if (failed) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => widget.downloadCenter.removeTask(task!.id),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: Text(s.delete),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade200),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                  ],
                  // Completado: botones reproducir y eliminar
                  if (completed && !failed) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: mediaFile == null ? null : () => _openMedia(mediaFile),
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: Text(s.play),
                            style: FilledButton.styleFrom(
                              backgroundColor: widget.iconColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmDelete(
                              task: task,
                              file: mediaFile,
                              name: name,
                            ),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: Text(s.delete),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade200),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thumbnail del card: icono para audio, portada para video completado
  Widget _buildThumbnail({
    required bool isAudio,
    required bool completed,
    DownloadTask? task,
  }) {
    const double size = 56;
    final borderRadius = BorderRadius.circular(14);

    // Audio siempre muestra icono
    if (isAudio) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: borderRadius,
        ),
        child: const Icon(
          Icons.graphic_eq_rounded,
          color: Color(0xFF1565C0),
          size: 28,
        ),
      );
    }

    // Video completado con thumbnail
    if (completed && task?.thumbnailUrl != null && task!.thumbnailUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.network(
          task.thumbnailUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _videoIconBox(size, borderRadius),
        ),
      );
    }

    return _videoIconBox(size, borderRadius);
  }

  /// Caja con icono de video (fallback)
  Widget _videoIconBox(double size, BorderRadius borderRadius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: borderRadius,
      ),
      child: const Icon(
        Icons.movie_creation_outlined,
        color: Color(0xFFEF6C00),
        size: 28,
      ),
    );
  }

  /// Confirmación antes de eliminar
  Future<void> _confirmDelete({
    DownloadTask? task,
    File? file,
    required String name,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).deleteFileTitle),
        content: Text(S.of(context).deleteFileConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: Text(S.of(context).delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Eliminar tarea si existe
    if (task != null) {
      await widget.downloadCenter.removeTask(task.id);
    } else if (file != null) {
      // Eliminar archivo directo
      if (await file.exists()) await file.delete();
    }

    if (!mounted) return;
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).fileDeleted)),
    );
  }

  Widget _buildLibraryHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.iconColor.withOpacity(0.12),
            widget.tileTint,
          ],
        ),
        border: Border.all(color: widget.iconColor.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.icon, color: widget.iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.downloadDirectory == null
                      ? S.of(context).folderNotConfigured
                      : S.of(context).folderPath(widget.downloadDirectory!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: widget.iconColor.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: widget.iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, bool failed, bool completed) {
    final Color base = failed
        ? const Color(0xFFC62828)
        : completed
        ? const Color(0xFF2E7D32)
        : widget.iconColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: base.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: base.withOpacity(0.32)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: base,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}


