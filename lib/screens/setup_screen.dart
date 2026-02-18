/// Pantalla de configuración inicial que guía al usuario con permisos y carpetas.
library;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../l10n.dart';
import '../services/directory_manager.dart';
import 'home_screen.dart';

/// Pantalla de setup inicial que se muestra la primera vez que se abre la app.
///
/// Paso 1: Solicitar permisos de almacenamiento.
/// Paso 2: Mostrar carpetas creadas y permitir cambiarlas.
class SetupScreen extends StatefulWidget {
  /// Crea la pantalla de setup con el controlador de YouTube precargado
  const SetupScreen({super.key, this.preloadedYouTubeController});

  /// Controlador precargado durante el splash
  final WebViewController? preloadedYouTubeController;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final DirectoryManager _dirManager = DirectoryManager();

  /// Paso actual del wizard (0 = permisos, 1 = carpetas)
  int _step = 0;

  /// Estado del permiso de almacenamiento
  bool _permissionGranted = false;

  /// Indica si se están creando las carpetas
  bool _foldersReady = false;

  /// Rutas de las carpetas creadas
  String _musicPath = '';
  String _videoPath = '';

  @override
  void initState() {
    super.initState();
    _checkExistingPermission();
  }

  /// Verifica si ya tiene permisos (por si el usuario los dio antes)
  Future<void> _checkExistingPermission() async {
    final has = await _dirManager.hasStoragePermission();
    if (has && mounted) {
      setState(() {
        _permissionGranted = true;
        _step = 1;
      });
      await _createFolders();
    }
  }

  /// Solicita permisos de almacenamiento
  Future<void> _requestPermission() async {
    final granted = await _dirManager.requestStoragePermission();
    if (!mounted) return;
    setState(() => _permissionGranted = granted);
    if (granted) {
      setState(() => _step = 1);
      await _createFolders();
    }
  }

  /// Crea las carpetas por defecto y carga los directorios
  Future<void> _createFolders() async {
    await _dirManager.loadDirectories();
    if (!mounted) return;
    setState(() {
      _musicPath = _dirManager.musicDirectory ?? '';
      _videoPath = _dirManager.videoDirectory ?? '';
      _foldersReady = true;
    });
  }

  /// Permite cambiar la carpeta de música o videos
  Future<void> _changeFolder({required bool isMusic}) async {
    final changed = await _dirManager.pickFolder(context, isMusic: isMusic);
    if (changed && mounted) {
      setState(() {
        _musicPath = _dirManager.musicDirectory ?? '';
        _videoPath = _dirManager.videoDirectory ?? '';
      });
    }
  }

  /// Completa el setup y navega al home
  Future<void> _finishSetup() async {
    await _dirManager.markSetupCompleted();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            HomeScreen(preloadedYouTubeController: widget.preloadedYouTubeController),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  /// Obtiene un nombre corto de la ruta para mostrar al usuario
  String _shortPath(String path) {
    // Mostrar desde Download/ en adelante
    final idx = path.indexOf('Download/');
    if (idx != -1) return path.substring(idx);
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo y título
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset('assets/icon_shema.png', width: 80, height: 80),
              ),
              const SizedBox(height: 16),
              Text(s.setupWelcome,
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(s.splashSubtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 40),

              // Contenido según el paso
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _step == 0 ? _buildPermissionStep(s) : _buildFoldersStep(s),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Paso 1: Solicitar permisos de almacenamiento
  Widget _buildPermissionStep(S s) {
    return Column(
      key: const ValueKey('permission'),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.folder_rounded, size: 48, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 20),
              Text(s.setupPermissionTitle,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(s.setupPermissionDesc,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (!_permissionGranted)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _requestPermission,
                    icon: const Icon(Icons.security_rounded),
                    label: Text(s.setupGrantPermission, style: const TextStyle(fontSize: 16)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 24),
                    const SizedBox(width: 8),
                    Text(s.setupPermissionGranted,
                      style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w700, fontSize: 16)),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Paso 2: Mostrar carpetas creadas y permitir cambiarlas
  Widget _buildFoldersStep(S s) {
    return Column(
      key: const ValueKey('folders'),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF2E7D32)),
                ),
              ),
              const SizedBox(height: 20),
              Center(child: Text(s.setupFoldersTitle,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center)),
              const SizedBox(height: 8),
              Center(child: Text(s.setupFoldersCreated,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center)),
              const SizedBox(height: 20),

              // Carpeta de videos
              _buildFolderRow(
                icon: Icons.videocam_rounded,
                color: const Color(0xFFEF6C00),
                bgColor: const Color(0xFFFFF3E0),
                label: s.setupVideoFolder,
                path: _shortPath(_videoPath),
                onChangeTap: () => _changeFolder(isMusic: false),
                changeLabel: s.setupChangeFolder,
              ),
              const SizedBox(height: 12),

              // Carpeta de música
              _buildFolderRow(
                icon: Icons.music_note_rounded,
                color: const Color(0xFF1565C0),
                bgColor: const Color(0xFFE3F2FD),
                label: s.setupMusicFolder,
                path: _shortPath(_musicPath),
                onChangeTap: () => _changeFolder(isMusic: true),
                changeLabel: s.setupChangeFolder,
              ),

              const SizedBox(height: 16),
              Center(child: Text(s.setupChangeable,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                textAlign: TextAlign.center)),
            ],
          ),
        ),
        const Spacer(),
        // Botón empezar
        if (_foldersReady)
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _finishSetup,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1B5E20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: Text(s.setupStart),
              ),
            ),
          ),
      ],
    );
  }

  /// Fila que muestra una carpeta con su icono, ruta y botón de cambiar
  Widget _buildFolderRow({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String label,
    required String path,
    required VoidCallback onChangeTap,
    required String changeLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
                const SizedBox(height: 2),
                Text(path,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          TextButton(
            onPressed: onChangeTap,
            style: TextButton.styleFrom(
              foregroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(changeLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
