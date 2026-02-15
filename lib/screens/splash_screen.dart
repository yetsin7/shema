/// Pantalla de splash con precarga de YouTube y actualización de yt-dlp.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/download_service.dart';
import 'home_screen.dart';
import '../l10n.dart';

/// Pantalla de inicio que muestra progreso mientras precarga recursos
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// Estado del splash con animación de fade y progreso
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
    // Controlador de animación para el fade del logo
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
    // Iniciar precarga y animación de progreso
    _startLoading();
  }

  /// Inicia la precarga de YouTube, actualización de yt-dlp y el progreso animado
  Future<void> _startLoading() async {
    if (Platform.isAndroid || Platform.isIOS) {
      _preloadYouTube();
    }
    _updateYtDlp();

    // Progreso gradual sincronizado con las tareas reales
    const steps = 100;
    const stepDuration = Duration(milliseconds: 35);

    for (int i = 0; i <= steps; i++) {
      if (!mounted) return;
      await Future.delayed(stepDuration);
      if (!mounted) return;
      setState(() => _progress = i / steps);

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

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // Navegar a la pantalla principal
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            HomeScreen(preloadedYouTubeController: _preloadedController),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  /// Actualiza yt-dlp a la última versión disponible durante el splash
  Future<void> _updateYtDlp() async {
    try {
      final ytDlp = YtDlpService();
      await ytDlp.updateYtDlp();
    } catch (_) {
      // Error silenciado; se puede usar la versión existente
    } finally {
      if (mounted) setState(() => _isYtDlpReady = true);
    }
  }

  /// Precarga el WebViewController de YouTube para arranque rápido
  Future<void> _preloadYouTube() async {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFF9F9F9))
        ..enableZoom(true)
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isYouTubeLoaded = true);
          },
        ))
        ..loadRequest(Uri.parse('https://m.youtube.com'));
      _preloadedController = controller;
    } catch (_) {
      if (mounted) setState(() => _isYouTubeLoaded = true);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // Texto de estado según el progreso
    final statusText = _progress < 0.3
        ? s.splashInitializing
        : _progress < 0.9
            ? s.splashLoadingYouTube
            : s.splashReady;

    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/icon_shema.png',
                  width: 100,
                  height: 100,
                ),
              ),
              const SizedBox(height: 20),
              // Nombre de la app
              const Text(
                'Shema',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Subtítulo
              Text(
                s.splashSubtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 30),
              // Barra de progreso
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Estado actual
              Text(
                statusText,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
