/// Gestión de directorios de música y video.
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n.dart';

/// Gestor de directorios de descarga para música y videos.
///
/// Maneja la persistencia de rutas en SharedPreferences,
/// la selección de carpetas con FilePicker, y la apertura
/// de carpetas con OpenFilex. Garantiza que música y videos
/// se guarden en carpetas diferentes.
class DirectoryManager {
  /// Clave de SharedPreferences para la carpeta de música
  static const _musicDirKey = 'music_directory_path';

  /// Clave de SharedPreferences para la carpeta de videos
  static const _videoDirKey = 'video_directory_path';

  /// Clave para saber si el setup inicial ya fue completado
  static const _setupCompletedKey = 'setup_completed';

  /// Ruta actual de la carpeta de música (null si no se ha cargado)
  String? musicDirectory;

  /// Ruta actual de la carpeta de videos (null si no se ha cargado)
  String? videoDirectory;

  /// Retorna la carpeta base por defecto para música
  Future<String> defaultMusicDir() async {
    if (Platform.isAndroid) {
      final candidates = [
        '/storage/emulated/0/Download/Shema/Music',
        '/sdcard/Download/Shema/Music',
      ];
      for (final candidate in candidates) {
        final parent = Directory(candidate.substring(0, candidate.lastIndexOf('/')));
        if (await parent.exists()) return candidate;
      }
      final external = await getExternalStorageDirectory();
      if (external != null) return '${external.path}${Platform.pathSeparator}Shema${Platform.pathSeparator}Music';
    }
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}${Platform.pathSeparator}Shema${Platform.pathSeparator}Music';
  }

  /// Retorna la carpeta base por defecto para videos
  Future<String> defaultVideoDir() async {
    if (Platform.isAndroid) {
      final candidates = [
        '/storage/emulated/0/Download/Shema/Videos',
        '/sdcard/Download/Shema/Videos',
      ];
      for (final candidate in candidates) {
        final parent = Directory(candidate.substring(0, candidate.lastIndexOf('/')));
        if (await parent.exists()) return candidate;
      }
      final external = await getExternalStorageDirectory();
      if (external != null) return '${external.path}${Platform.pathSeparator}Shema${Platform.pathSeparator}Videos';
    }
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}${Platform.pathSeparator}Shema${Platform.pathSeparator}Videos';
  }

  /// Verifica si el setup inicial ya fue completado
  Future<bool> isSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_setupCompletedKey) ?? false;
  }

  /// Marca el setup inicial como completado
  Future<void> markSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_setupCompletedKey, true);
  }

  /// Solicita permisos de almacenamiento según la versión de Android
  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Android 13+ usa permisos granulares de media
    if (await Permission.videos.request().isGranted &&
        await Permission.audio.request().isGranted) {
      return true;
    }

    // Android 10-12 usa permiso de almacenamiento clásico
    final storage = await Permission.storage.request();
    if (storage.isGranted) return true;

    return false;
  }

  /// Verifica si ya tiene permisos de almacenamiento
  Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;
    // Verificar permisos granulares (Android 13+)
    if (await Permission.videos.isGranted && await Permission.audio.isGranted) {
      return true;
    }
    // Verificar permiso clásico (Android 10-12)
    if (await Permission.storage.isGranted) return true;
    return false;
  }

  /// Carga las carpetas desde preferencias
  Future<void> loadDirectories() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultMusic = await defaultMusicDir();
    final defaultVideo = await defaultVideoDir();

    var musicPath = prefs.getString(_musicDirKey)?.trim();
    var videoPath = prefs.getString(_videoDirKey)?.trim();

    // Migrar rutas viejas (almacenamiento privado de la app) al nuevo default público
    bool isOldAppPath(String? p) =>
        p != null && p.contains('/Android/data/');

    final oldMusicPath = isOldAppPath(musicPath) ? musicPath : null;
    final oldVideoPath = isOldAppPath(videoPath) ? videoPath : null;

    if (oldMusicPath != null) musicPath = null;
    if (oldVideoPath != null) videoPath = null;

    // Migrar carpetas que apunten al viejo default unificado (Download/Shema sin subcarpeta)
    if (musicPath != null && musicPath.endsWith('/Shema') && !musicPath.endsWith('/Shema/Music')) {
      musicPath = null;
    }
    if (videoPath != null && videoPath.endsWith('/Shema') && !videoPath.endsWith('/Shema/Videos')) {
      videoPath = null;
    }

    musicPath = (musicPath == null || musicPath.isEmpty) ? defaultMusic : musicPath;
    videoPath = (videoPath == null || videoPath.isEmpty) ? defaultVideo : videoPath;

    await Directory(musicPath).create(recursive: true);
    await Directory(videoPath).create(recursive: true);

    // Mover archivos de las carpetas viejas a las nuevas
    await _migrateFiles(oldMusicPath, musicPath);
    await _migrateFiles(oldVideoPath, videoPath);

    await prefs.setString(_musicDirKey, musicPath);
    await prefs.setString(_videoDirKey, videoPath);

    musicDirectory = musicPath;
    videoDirectory = videoPath;
  }

  /// Mueve archivos de una carpeta vieja a la nueva (migración silenciosa)
  Future<void> _migrateFiles(String? oldPath, String newPath) async {
    if (oldPath == null || oldPath.isEmpty) return;
    final oldDir = Directory(oldPath);
    if (!await oldDir.exists()) return;

    try {
      await for (final entity in oldDir.list()) {
        if (entity is File) {
          final name = entity.path.split(Platform.pathSeparator).last;
          final dest = File('$newPath${Platform.pathSeparator}$name');
          // No sobreescribir si ya existe en destino
          if (!await dest.exists()) {
            await entity.copy(dest.path);
          }
          await entity.delete();
        }
      }
    } catch (_) {
      // Si falla la migración, no bloquear el inicio de la app
    }
  }

  /// Selector de carpeta con validación de carpetas distintas
  Future<bool> pickFolder(BuildContext context, {required bool isMusic}) async {
    final s = S.of(context);
    final selectedPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: isMusic ? s.changeMusicFolder : s.changeVideoFolder,
    );

    if (selectedPath == null || selectedPath.isEmpty) return false;
    if (!context.mounted) return false;

    // Rechazar si el usuario elige la misma carpeta que ya usa el otro tipo
    final otherPath = isMusic ? videoDirectory : musicDirectory;
    if (otherPath != null &&
        otherPath.isNotEmpty &&
        _normalizePath(selectedPath) == _normalizePath(otherPath)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.separateFoldersRequired),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return false;
    }

    try {
      await Directory(selectedPath).create(recursive: true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(isMusic ? _musicDirKey : _videoDirKey, selectedPath);

      if (isMusic) {
        musicDirectory = selectedPath;
      } else {
        videoDirectory = selectedPath;
      }

      if (!context.mounted) return true;
      final label = isMusic ? '🎵' : '🎬';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label ${s.folderSet(selectedPath)}')),
      );
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.folderSelectError)),
      );
      return false;
    }
  }

  /// Normaliza una ruta eliminando slashes finales para comparación segura
  String _normalizePath(String path) =>
      path.trim().replaceAll(RegExp(r'[\\/]+$'), '');

  /// Abre la carpeta configurada usando el canal nativo de Android para navegación exacta
  Future<void> openConfiguredFolder(BuildContext context, {required bool isMusic}) async {
    final s = S.of(context);
    final configured = (isMusic ? musicDirectory : videoDirectory)?.trim();

    if (configured == null || configured.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.folderNotConfigured)),
      );
      return;
    }

    final directory = Directory(configured);
    if (!await directory.exists()) await directory.create(recursive: true);

    // En Android usamos el MethodChannel que construye la URI correcta de DocumentsContract
    // (igual que media_card.dart cuando abre la carpeta de un archivo)
    if (Platform.isAndroid) {
      try {
        await const MethodChannel('com.cocibolka.shema/ytdlp')
            .invokeMethod('openFolder', {'path': directory.path});
        return;
      } catch (_) {
        // Si falla el canal nativo, continúa al fallback
      }
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.cantOpenFolder)),
    );
  }
}
