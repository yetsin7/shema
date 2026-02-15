/// Componente de tarjeta para mostrar archivos de medios y tareas de descarga.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/download_service.dart';
import '../l10n.dart';

/// Tarjeta unificada para mostrar tareas de descarga y archivos en disco.
///
/// Puede representar una tarea de descarga ([task]) o un archivo local ([file]).
/// Muestra estado (en cola, descargando, completado, error), metadatos
/// (calidad, formato, tamaño), y acciones contextuales (reproducir, eliminar,
/// reintentar, cancelar).
class MediaCard extends StatelessWidget {
  /// Crea una tarjeta de medio. Debe tener al menos [task] o [file].
  const MediaCard({
    this.task,
    this.file,
    required this.kind,
    required this.iconColor,
    required this.tileTint,
    required this.onPlay,
    this.onRetry,
    required this.onDelete,
    this.onCancel,
    this.onCancelDownload,
    super.key,
  });

  /// Tarea de descarga asociada (null si es solo un archivo local)
  final DownloadTask? task;

  /// Archivo en disco (null si la descarga no ha completado)
  final File? file;

  /// Tipo de medio para determinar iconos y colores
  final MediaKind kind;

  /// Color principal del icono según tipo (azul para audio, naranja para video)
  final Color iconColor;

  /// Color de fondo tenue para el borde y decoraciones
  final Color tileTint;

  /// Callback para reproducir un archivo completado
  final Future<void> Function(File) onPlay;

  /// Callback para reintentar una descarga fallida
  final Future<void> Function(DownloadTask)? onRetry;

  /// Callback para eliminar archivo/tarea con confirmación
  final Future<void> Function({DownloadTask? task, File? file, required String name}) onDelete;

  /// Callback para cancelar una tarea en cola (antes de iniciar)
  final void Function(DownloadTask)? onCancel;

  /// Callback para cancelar una descarga en progreso
  final void Function(DownloadTask)? onCancelDownload;

  @override
  Widget build(BuildContext context) {
    final isTask = task != null;
    final queued = isTask && task!.status == DownloadStatus.queued;
    final downloading = isTask && task!.status == DownloadStatus.downloading;
    final completed = isTask ? task!.status == DownloadStatus.completed : true;
    final failed = isTask && task!.status == DownloadStatus.failed;
    final isAudio = kind == MediaKind.audio;
    final mediaFile = file;
    final String name;
    final String? sizeMb, quality;
    if (isTask) {
      name = task!.title;
      quality = task!.quality;
      final f = mediaFile;
      if (f != null && f.existsSync()) {
        sizeMb = (f.statSync().size / (1024 * 1024)).toStringAsFixed(2);
      } else {
        sizeMb = null;
      }
    } else {
      final path = file!.path;
      name = path.split(Platform.pathSeparator).last.replaceAll(RegExp(r'\.\w+$'), '');
      sizeMb = (file!.statSync().size / (1024 * 1024)).toStringAsFixed(2);
      quality = null;
    }
    final s = S.of(context);
    final statusText = failed ? s.error : queued ? s.queued : downloading ? '${(task!.progress * 100).toStringAsFixed(0)}%' : s.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        border: Border.all(color: downloading ? iconColor.withValues(alpha: 0.4) : tileTint.withValues(alpha: 0.85)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(context: context, isAudio: isAudio, completed: completed && !failed, task: task),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                      const SizedBox(width: 6),
                      _buildStatusChip(context, statusText, failed, completed && !failed, queued),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    if (quality != null) _buildMetaChip(context, icon: Icons.high_quality_rounded, label: quality),
                    _buildMetaChip(context, icon: isAudio ? Icons.music_note_rounded : Icons.videocam_rounded, label: isAudio ? 'MP3' : 'MP4'),
                    if (sizeMb != null) _buildMetaChip(context, icon: Icons.data_usage_rounded, label: '$sizeMb MB'),
                  ]),
                  if (queued) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => onCancel?.call(task!),
                        icon: const Icon(Icons.close, size: 16),
                        label: Text(s.cancel),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.grey.shade600, side: BorderSide(color: Colors.grey.shade300), padding: const EdgeInsets.symmetric(vertical: 6)),
                      ),
                    ),
                  ],
                  if (downloading) ...[
                    const SizedBox(height: 10),
                    ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(
                      value: task!.progress, minHeight: 6,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    )),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => onCancelDownload?.call(task!),
                        icon: const Icon(Icons.close, size: 16),
                        label: Text(s.cancel),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700, side: BorderSide(color: Colors.red.shade200), padding: const EdgeInsets.symmetric(vertical: 6)),
                      ),
                    ),
                  ],
                  if (failed) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: FilledButton.icon(
                        onPressed: () => onRetry?.call(task!), icon: const Icon(Icons.refresh_rounded, size: 16), label: Text(s.retry),
                        style: FilledButton.styleFrom(backgroundColor: iconColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton.icon(
                        onPressed: () => onCancel?.call(task!), icon: const Icon(Icons.delete_outline, size: 16), label: Text(s.delete),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700, side: BorderSide(color: Colors.red.shade200), padding: const EdgeInsets.symmetric(vertical: 8)),
                      )),
                    ]),
                  ],
                  if (completed && !failed) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: FilledButton.icon(
                        onPressed: mediaFile == null ? null : () => onPlay(mediaFile), icon: const Icon(Icons.play_arrow_rounded, size: 18), label: Text(s.play),
                        style: FilledButton.styleFrom(backgroundColor: iconColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton.icon(
                        onPressed: () => onDelete(task: task, file: mediaFile, name: name), icon: const Icon(Icons.delete_outline, size: 18), label: Text(s.delete),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700, side: BorderSide(color: Colors.red.shade200), padding: const EdgeInsets.symmetric(vertical: 8)),
                      )),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el thumbnail del card: icono para audio, portada para video
  Widget _buildThumbnail({required BuildContext context, required bool isAudio, required bool completed, DownloadTask? task}) {
    const double size = 56;
    final borderRadius = BorderRadius.circular(14);
    if (isAudio) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: borderRadius),
        child: const Icon(Icons.graphic_eq_rounded, color: Color(0xFF1565C0), size: 28),
      );
    }
    if (completed && task?.thumbnailUrl != null && task!.thumbnailUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.network(
          task.thumbnailUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _videoIconBox(size, borderRadius),
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
      decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: borderRadius),
      child: const Icon(Icons.movie_creation_outlined, color: Color(0xFFEF6C00), size: 28),
    );
  }

  /// Construye un chip de metadatos (calidad, formato, tamaño)
  Widget _buildMetaChip(BuildContext context, {required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: iconColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  /// Construye el chip de estado (en cola, descargando, completado, error)
  Widget _buildStatusChip(BuildContext context, String label, bool failed, bool completed, bool queued) {
    final Color base = failed ? const Color(0xFFC62828) : completed ? const Color(0xFF2E7D32) : queued ? Colors.grey : iconColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: base.withValues(alpha: 0.32)),
      ),
      child: Text(label, style: TextStyle(color: base, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
