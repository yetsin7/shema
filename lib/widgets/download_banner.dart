/// Banner de descargas activas.
library;

import 'package:flutter/material.dart';

import '../services/download_center.dart';
import '../services/download_service.dart';
import '../l10n.dart';

/// Banner que muestra las descargas activas
class DownloadBanner extends StatelessWidget {
  /// Crea un banner de descargas activas
  const DownloadBanner({required this.downloadCenter, super.key});

  final DownloadCenter downloadCenter;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: downloadCenter,
      builder: (context, _) {
        final active = downloadCenter.activeTasks;
        if (active.isEmpty) return const SizedBox.shrink();

        return Container(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1B3A1C)
              : const Color(0xFF1B5E20),
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

/// Item individual de tarea de descarga
class _DownloadTaskItem extends StatelessWidget {
  const _DownloadTaskItem({required this.task, required this.onCancel});

  final DownloadTask task;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final percent = (task.progress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(
            task.kind == MediaKind.audio
                ? Icons.graphic_eq
                : Icons.movie_creation_outlined,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
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
                  ),
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: task.progress,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$percent%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close, color: Colors.white70, size: 18),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            tooltip: S.of(context).cancelDownloadTooltip,
          ),
        ],
      ),
    );
  }
}
