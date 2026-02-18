/// Componente de tarjeta para mostrar archivos de medios y tareas de descarga.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/download_service.dart';
import '../l10n.dart';
import 'media_card_parts.dart';

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
    DateTime? date;

    if (isTask) {
      name = task!.title;
      quality = task!.quality;
      final f = mediaFile;
      if (f != null && f.existsSync()) {
        sizeMb = (f.statSync().size / (1024 * 1024)).toStringAsFixed(2);
        try {
          date = f.lastModifiedSync();
        } catch (_) {}
      } else {
        sizeMb = null;
      }
      
      // Si la tarea está completada pero no tenemos archivo cargado, intentamos buscarlo
      if (completed && date == null && task!.filePath != null) {
        final f = File(task!.filePath!);
        if (f.existsSync()) {
             try {
               date = f.lastModifiedSync();
             } catch (_) {}
        }
      }
    } else {
      final path = file!.path;
      name = path.split(Platform.pathSeparator).last.replaceAll(RegExp(r'\.\w+$'), '');
      sizeMb = (file!.statSync().size / (1024 * 1024)).toStringAsFixed(2);
      quality = null;
      try {
        date = file!.lastModifiedSync();
      } catch (_) {}
    }
    
    final s = S.of(context);
    final statusText = failed ? s.error : queued ? s.queued : downloading ? '${(task!.progress * 100).toStringAsFixed(0)}%' : s.completed;

    String? dateStr;
    if (date != null) {
      dateStr = DateFormat('d MMM, HH:mm', s.locale.languageCode).format(date);
    }

    // Determinar si el card es tappeable (archivo completado disponible)
    final tappable = completed && !failed && mediaFile != null;

    return GestureDetector(
      onTap: tappable ? () => const MethodChannel('com.cocibolka.shema/ytdlp')
          .invokeMethod('openFolder', {'path': mediaFile!.parent.path}) : null,
      child: Container(
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
              // Columna izquierda: thumbnail + botón compartir debajo
              Column(
                children: [
                  buildMediaThumbnail(context: context, isAudio: isAudio, completed: completed && !failed, task: task),
                  if (tappable) ...[
                    const SizedBox(height: 6),
                    SizedBox(width: 40, height: 36, child: IconButton(
                      onPressed: () => SharePlus.instance.share(ShareParams(files: [XFile(mediaFile.path)])),
                      icon: const Icon(Icons.share_rounded, size: 16),
                      style: IconButton.styleFrom(
                        foregroundColor: iconColor,
                        side: BorderSide(color: iconColor.withValues(alpha: 0.3)),
                        padding: EdgeInsets.zero,
                      ),
                    )),
                  ],
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: tappable ? () => const MethodChannel('com.cocibolka.shema/ytdlp')
                              .invokeMethod('openFolder', {'path': mediaFile!.parent.path}) : null,
                          child: buildStatusChip(context, label: statusText, failed: failed, completed: completed && !failed, queued: queued, iconColor: iconColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      if (quality != null) buildMetaChip(context, icon: Icons.high_quality_rounded, label: quality, iconColor: iconColor),
                      buildMetaChip(context, icon: isAudio ? Icons.music_note_rounded : Icons.videocam_rounded, label: isAudio ? 'MP3' : 'MP4', iconColor: iconColor),
                      if (sizeMb != null) buildMetaChip(context, icon: Icons.data_usage_rounded, label: '$sizeMb MB', iconColor: iconColor),
                      if (dateStr != null) buildMetaChip(context, icon: Icons.calendar_today_rounded, label: dateStr, iconColor: iconColor),
                    ]),
                    ..._buildActions(context, s, queued: queued, downloading: downloading, completed: completed, failed: failed, mediaFile: mediaFile, name: name),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye los botones de acción según el estado de la descarga
  List<Widget> _buildActions(
    BuildContext context,
    S s, {
    required bool queued,
    required bool downloading,
    required bool completed,
    required bool failed,
    required File? mediaFile,
    required String name,
  }) {
    if (queued) {
      return [
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
      ];
    }
    if (downloading) {
      return [
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
      ];
    }
    if (failed) {
      return [
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
      ];
    }
    if (completed && !failed) {
      return [
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
      ];
    }
    return [];
  }
}
