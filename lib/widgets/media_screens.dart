/// Pantallas de música y videos que envuelven MediaLibraryScreen.
library;

import 'package:flutter/material.dart';

import '../services/download_center.dart';
import '../services/download_service.dart';
import '../l10n.dart';
import '../screens/media_library.dart';

/// Pantalla de música que muestra archivos MP3
class MusicScreen extends StatelessWidget {
  const MusicScreen({
    required this.downloadCenter,
    required this.downloadDirectory,
    this.isActive = true,
    super.key,
  });

  final DownloadCenter downloadCenter;
  final String? downloadDirectory;
  final bool isActive;

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
      isActive: isActive,
    );
  }
}

/// Pantalla de videos que muestra archivos MP4
class VideosScreen extends StatelessWidget {
  const VideosScreen({
    required this.downloadCenter,
    required this.downloadDirectory,
    this.isActive = true,
    super.key,
  });

  final DownloadCenter downloadCenter;
  final String? downloadDirectory;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return MediaLibraryScreen(
      title: s.videosTitle,
      emptyTitle: s.noVideosYet,
      emptyDescription: s.noVideosDescription,
      extensions: const <String>{'.mp4', '.webm', '.mkv'},
      icon: Icons.movie_creation_outlined,
      iconColor: const Color(0xFFE11D48),
      tileTint: const Color(0xFFFCE4EC),
      kind: MediaKind.video,
      downloadCenter: downloadCenter,
      downloadDirectory: downloadDirectory,
      isActive: isActive,
    );
  }
}
