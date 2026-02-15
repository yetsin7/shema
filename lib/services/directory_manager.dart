/// Gestión de directorios de música y video.
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n.dart';

/// Gestor de directorios de descarga
class DirectoryManager {
  static const _musicDirKey = 'music_directory_path';
  static const _videoDirKey = 'video_directory_path';

  String? musicDirectory;
  String? videoDirectory;

  /// Normaliza una ruta para comparación
  String _normalizePath(String path) =>
      path.trim().replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '').toLowerCase();

  /// Compara si dos rutas apuntan al mismo directorio
  bool _isSameDirectory(String a, String b) =>
      _normalizePath(a) == _normalizePath(b);

  /// Retorna la carpeta base por defecto
  Future<String> _defaultBaseDir() async {
    if (Platform.isAndroid) {
      final external = await getExternalStorageDirectory();
      if (external != null) return '${external.path}${Platform.pathSeparator}Shema';
    }
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}${Platform.pathSeparator}Shema';
  }

  /// Carga las carpetas desde preferencias
  Future<void> loadDirectories() async {
    final prefs = await SharedPreferences.getInstance();
    final baseDir = await _defaultBaseDir();

    var musicPath = prefs.getString(_musicDirKey)?.trim();
    var videoPath = prefs.getString(_videoDirKey)?.trim();

    musicPath = (musicPath == null || musicPath.isEmpty)
        ? '$baseDir${Platform.pathSeparator}Music'
        : musicPath;
    videoPath = (videoPath == null || videoPath.isEmpty)
        ? '$baseDir${Platform.pathSeparator}Videos'
        : videoPath;

    if (_isSameDirectory(musicPath, videoPath)) {
      if (prefs.getString(_musicDirKey)?.trim().isNotEmpty ?? false) {
        videoPath = '$baseDir${Platform.pathSeparator}Videos';
      } else {
        musicPath = '$baseDir${Platform.pathSeparator}Music';
      }
    }

    await Directory(musicPath).create(recursive: true);
    await Directory(videoPath).create(recursive: true);
    await prefs.setString(_musicDirKey, musicPath);
    await prefs.setString(_videoDirKey, videoPath);

    musicDirectory = musicPath;
    videoDirectory = videoPath;
  }

  /// Selector de carpeta
  Future<bool> pickFolder(BuildContext context, {required bool isMusic}) async {
    final s = S.of(context);
    final selectedPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: isMusic ? s.changeMusicFolder : s.changeVideoFolder,
      initialDirectory: isMusic ? musicDirectory : videoDirectory,
    );

    if (selectedPath == null || selectedPath.isEmpty) return false;
    if (!context.mounted) return false;

    final otherPath = isMusic ? videoDirectory : musicDirectory;
    if (otherPath != null && otherPath.trim().isNotEmpty && _isSameDirectory(selectedPath, otherPath)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.separateFoldersRequired)),
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

  /// Abre la carpeta configurada
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

    final result = await OpenFilex.open(directory.path);
    if (!context.mounted) return;
    if (result.type == ResultType.done) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.cantOpenFolder)),
    );
  }
}
