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
/// Paso 2: El usuario DEBE elegir manualmente la carpeta de videos y la de música.
///         No se puede avanzar sin haber elegido ambas.
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

  /// Indica si el usuario ya eligió manualmente la carpeta de videos
  bool _videoChosen = false;

  /// Indica si el usuario ya eligió manualmente la carpeta de música
  bool _musicChosen = false;

  /// Ruta elegida para videos (vacía hasta que el usuario la seleccione)
  String _videoPath = '';

  /// Ruta elegida para música (vacía hasta que el usuario la seleccione)
  String _musicPath = '';

  /// True mientras se migran los archivos viejos al terminar el setup
  bool _migrating = false;

  /// Rutas guardadas de la versión anterior, capturadas ANTES de que el usuario
  /// elija las nuevas (para moverlas al destino correcto al finalizar)
  String? _oldMusicPath;
  String? _oldVideoPath;

  /// Future que garantiza que los paths viejos se leen antes de que _finishSetup los use
  late final Future<void> _oldPathsFuture;

  @override
  void initState() {
    super.initState();
    _checkExistingPermission();
    // Capturar paths viejos AHORA, antes de que pickFolder() los sobreescriba
    _oldPathsFuture = _captureOldPaths();
  }

  /// Lee los paths guardados de la versión anterior sin modificar SharedPreferences
  Future<void> _captureOldPaths() async {
    final (music, video) = await _dirManager.readSavedDirectories();
    _oldMusicPath = music;
    _oldVideoPath = video;
  }

  /// Verifica si ya tiene permisos (por si el usuario los dio antes)
  Future<void> _checkExistingPermission() async {
    final has = await _dirManager.hasStoragePermission();
    if (has && mounted) {
      setState(() {
        _permissionGranted = true;
        _step = 1;
      });
    }
  }

  /// Solicita permisos de almacenamiento y avanza al paso de carpetas
  Future<void> _requestPermission() async {
    final granted = await _dirManager.requestStoragePermission();
    if (!mounted) return;
    setState(() => _permissionGranted = granted);
    if (granted) {
      setState(() => _step = 1);
    }
  }

  /// Abre el selector de carpeta y, si el usuario elige una válida, la marca como seleccionada
  Future<void> _pickFolder({required bool isMusic}) async {
    final changed = await _dirManager.pickFolder(context, isMusic: isMusic);
    if (!changed || !mounted) return;

    final newPath = isMusic
        ? _dirManager.musicDirectory ?? ''
        : _dirManager.videoDirectory ?? '';

    // Verificar que no coincida con la otra carpeta ya elegida
    final otherPath = isMusic ? _videoPath : _musicPath;
    if (otherPath.isNotEmpty && newPath == otherPath) {
      // El DirectoryManager ya mostró el snackbar; no marcar como elegida
      return;
    }

    setState(() {
      if (isMusic) {
        _musicPath = newPath;
        _musicChosen = true;
      } else {
        _videoPath = newPath;
        _videoChosen = true;
      }
    });
  }

  /// Completa el setup: migra archivos viejos a las carpetas elegidas y navega al home
  Future<void> _finishSetup() async {
    setState(() => _migrating = true);

    // Asegurar que los paths viejos ya fueron leídos
    await _oldPathsFuture;

    // Mover archivos de la versión anterior a las carpetas que el usuario eligió
    await _dirManager.migrateFromOldPaths(
      oldMusicPath: _oldMusicPath,
      oldVideoPath: _oldVideoPath,
    );

    await _dirManager.markSetupCompleted();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            HomeScreen(preloadedYouTubeController: widget.preloadedYouTubeController),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  /// Acorta una ruta larga para mostrarla en la UI
  String _shortPath(String path) {
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
                  style: const TextStyle(
                      color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(s.splashSubtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 40),

              // Contenido según el paso actual
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
                    label: Text(s.setupGrantPermission,
                        style: const TextStyle(fontSize: 16)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF2E7D32), size: 24),
                    const SizedBox(width: 8),
                    Text(s.setupPermissionGranted,
                        style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Paso 2: El usuario elige manualmente ambas carpetas antes de continuar
  Widget _buildFoldersStep(S s) {
    final bothChosen = _videoChosen && _musicChosen;
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
            children: [
              Text(s.setupChooseFolders,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(s.setupChooseFoldersDesc,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),

              // Tarjeta de carpeta de videos
              _buildPickFolderCard(
                icon: Icons.videocam_rounded,
                color: const Color(0xFFEF6C00),
                bgColor: const Color(0xFFFFF3E0),
                label: s.setupVideoFolder,
                chosen: _videoChosen,
                path: _videoPath,
                onTap: () => _pickFolder(isMusic: false),
                s: s,
              ),
              const SizedBox(height: 16),

              // Tarjeta de carpeta de música
              _buildPickFolderCard(
                icon: Icons.music_note_rounded,
                color: const Color(0xFF1565C0),
                bgColor: const Color(0xFFE3F2FD),
                label: s.setupMusicFolder,
                chosen: _musicChosen,
                path: _musicPath,
                onTap: () => _pickFolder(isMusic: true),
                s: s,
              ),
            ],
          ),
        ),
        const Spacer(),

        // Botón empezar: desactivado hasta que ambas carpetas estén elegidas;
        // muestra spinner mientras se migran los archivos al terminar
        Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: (bothChosen && !_migrating) ? _finishSetup : null,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1B5E20),
                disabledBackgroundColor: Colors.white24,
                disabledForegroundColor: Colors.white38,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: _migrating
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF1B5E20),
                      ),
                    )
                  : Text(bothChosen ? s.setupStart : s.setupChooseBothFirst),
            ),
          ),
        ),
      ],
    );
  }

  /// Tarjeta interactiva para elegir una carpeta (videos o música)
  Widget _buildPickFolderCard({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String label,
    required bool chosen,
    required String path,
    required VoidCallback onTap,
    required S s,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: chosen ? bgColor.withValues(alpha: 0.6) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: chosen ? color.withValues(alpha: 0.5) : Colors.grey.shade300,
          width: chosen ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icono con fondo dinámico según si fue elegida
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: chosen ? bgColor : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    color: chosen ? color : Colors.grey.shade500, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: chosen ? color : Colors.grey.shade700,
                        )),
                    const SizedBox(height: 2),
                    if (chosen)
                      Text(
                        _shortPath(path),
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(s.setupNotSelected,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade400)),
                  ],
                ),
              ),
              // Checkmark cuando ya fue elegida
              if (chosen)
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32), size: 24),
            ],
          ),
          const SizedBox(height: 14),

          // Botón de selección/cambio
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(
                  chosen ? Icons.edit_rounded : Icons.folder_open_rounded,
                  size: 18),
              label: Text(chosen ? s.setupChangeFolder : s.setupSelectFolder),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    chosen ? color : const Color(0xFF2E7D32),
                side: BorderSide(
                    color: chosen
                        ? color.withValues(alpha: 0.6)
                        : const Color(0xFF2E7D32).withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
