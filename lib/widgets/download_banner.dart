/// Banner de descargas activas — estilo píldora flotante.
library;

import 'package:flutter/material.dart';

import '../services/download_center.dart';
import '../services/download_service.dart';
import '../theme.dart';

/// Banner compacto que muestra las descargas activas con progreso.
///
/// Se ubica debajo del AppBar como una tira compacta con fondo oscuro.
/// Se oculta automáticamente cuando no hay descargas activas.
class DownloadBanner extends StatelessWidget {
  /// Crea un banner de descargas que escucha al [downloadCenter]
  const DownloadBanner({required this.downloadCenter, super.key});

  /// Centro de descargas del que obtiene las tareas activas
  final DownloadCenter downloadCenter;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: downloadCenter,
      builder: (context, _) {
        final active = downloadCenter.activeTasks;
        if (active.isEmpty) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          decoration: BoxDecoration(
            color: isDark ? ShemaColors.darkCard : ShemaColors.buttonLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? ShemaColors.darkBorder : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: active
                .map((task) => _DownloadTaskItem(
                      task: task,
                      onCancel: () => downloadCenter.cancel(task.id),
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}

/// Ítem individual de tarea de descarga dentro del banner
class _DownloadTaskItem extends StatelessWidget {
  const _DownloadTaskItem({required this.task, required this.onCancel});

  final DownloadTask task;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final percent = (task.progress * 100).toInt();
    final isAudio = task.kind == MediaKind.audio;
    // Color de acento según tipo
    final accentColor = isAudio ? ShemaColors.musicBlue : ShemaColors.youtubeRed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // Ícono con fondo de acento
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              isAudio ? Icons.graphic_eq_rounded : Icons.movie_creation_outlined,
              color: accentColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),
                // Barra de progreso delgada y redondeada
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: task.progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Porcentaje
          Text(
            '$percent%',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          // Botón cancelar
          GestureDetector(
            onTap: onCancel,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.close_rounded,
                  color: Colors.white.withValues(alpha: 0.7), size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
