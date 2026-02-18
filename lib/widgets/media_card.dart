/// Componente de tarjeta showcase para archivos de medios y tareas de descarga.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/download_service.dart';
import '../l10n.dart';
import '../theme.dart';
import 'media_card_parts.dart';

/// Tarjeta vertical showcase para tareas de descarga y archivos en disco.
///
/// Diseño premium: cabecera de 120px con gradiente/thumbnail + scrim + título,
/// chips de metadatos e botones de acción debajo. Sin borde, shadow profunda.
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

  final DownloadTask? task;
  final File? file;
  final MediaKind kind;
  final Color iconColor;
  final Color tileTint;
  final Future<void> Function(File) onPlay;
  final Future<void> Function(DownloadTask)? onRetry;
  final Future<void> Function({DownloadTask? task, File? file, required String name}) onDelete;
  final void Function(DownloadTask)? onCancel;
  final void Function(DownloadTask)? onCancelDownload;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        sizeMb = (f.statSync().size / (1024 * 1024)).toStringAsFixed(1);
        try { date = f.lastModifiedSync(); } catch (_) {}
      } else {
        sizeMb = null;
      }
      if (completed && date == null && task!.filePath != null) {
        final f = File(task!.filePath!);
        if (f.existsSync()) {
          try { date = f.lastModifiedSync(); } catch (_) {}
        }
      }
    } else {
      final path = file!.path;
      name = path.split(Platform.pathSeparator).last.replaceAll(RegExp(r'\.\w+$'), '');
      sizeMb = (file!.statSync().size / (1024 * 1024)).toStringAsFixed(1);
      quality = null;
      try { date = file!.lastModifiedSync(); } catch (_) {}
    }

    final s = S.of(context);
    final statusText = failed
        ? s.error
        : queued
            ? s.queued
            : downloading
                ? '${(task!.progress * 100).toStringAsFixed(0)}%'
                : s.completed;

    String? dateStr;
    if (date != null) {
      dateStr = DateFormat('d MMM, HH:mm', s.locale.languageCode).format(date);
    }

    final tappable = completed && !failed && mediaFile != null;
    final btnBg = isDark ? ShemaColors.buttonDark : ShemaColors.buttonLight;
    final btnFg = isDark ? const Color(0xFF0A0A0A) : Colors.white;

    // Badge compacto para el header (sobre el gradiente)
    final statusBadge = buildStatusChip(
      context,
      label: statusText,
      failed: failed,
      completed: completed && !failed,
      queued: queued,
      iconColor: iconColor,
      compact: true,
    );

    return GestureDetector(
      onTap: tappable
          ? () => const MethodChannel('com.cocibolka.shema/ytdlp')
              .invokeMethod('openFolder', {'path': mediaFile.parent.path})
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ShemaRadius.card),
          color: isDark ? ShemaColors.darkCard : ShemaColors.lightCard,
          // Sin border — la profundidad viene de la shadow
          boxShadow: ShemaShadow.deep(isDark: isDark, tintColor: iconColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabecera visual 120px ─────────────────────
            buildCardHeader(
              context: context,
              isAudio: isAudio,
              accentColor: iconColor,
              task: task,
              title: name,
              statusBadge: statusBadge,
            ),

            // ── Metadatos + acciones ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chips de metadatos
                  Wrap(spacing: 5, runSpacing: 5, children: [
                    if (quality != null)
                      buildMetaChip(context,
                          icon: Icons.hd_rounded,
                          label: quality,
                          iconColor: iconColor),
                    buildMetaChip(context,
                        icon: isAudio
                            ? Icons.music_note_rounded
                            : Icons.videocam_rounded,
                        label: isAudio ? 'MP3' : 'MP4',
                        iconColor: iconColor),
                    if (sizeMb != null)
                      buildMetaChip(context,
                          icon: Icons.sd_storage_rounded,
                          label: '$sizeMb MB',
                          iconColor: iconColor),
                    if (dateStr != null)
                      buildMetaChip(context,
                          icon: Icons.access_time_rounded,
                          label: dateStr,
                          iconColor: iconColor),
                  ]),

                  // Botones de acción según estado
                  ..._buildActions(
                    context,
                    s,
                    queued: queued,
                    downloading: downloading,
                    completed: completed,
                    failed: failed,
                    mediaFile: mediaFile,
                    name: name,
                    btnBg: btnBg,
                    btnFg: btnFg,
                  ),
                ],
              ),
            ),
          ],
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
    required Color btnBg,
    required Color btnFg,
  }) {
    if (queued) {
      return [
        const SizedBox(height: 10),
        _ActionButton(
          label: s.cancel,
          icon: Icons.close_rounded,
          isOutlined: true,
          onTap: () => onCancel?.call(task!),
        ),
      ];
    }

    if (downloading) {
      return [
        const SizedBox(height: 10),
        // Barra de progreso con color de acento
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: task!.progress,
            minHeight: 5,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(iconColor),
          ),
        ),
        const SizedBox(height: 8),
        _ActionButton(
          label: s.cancel,
          icon: Icons.close_rounded,
          isOutlined: true,
          isDestructive: true,
          onTap: () => onCancelDownload?.call(task!),
        ),
      ];
    }

    if (failed) {
      return [
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: _ActionButton(
              label: s.retry,
              icon: Icons.refresh_rounded,
              bgColor: btnBg,
              fgColor: btnFg,
              onTap: () => onRetry?.call(task!),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              label: s.delete,
              icon: Icons.delete_outline_rounded,
              isOutlined: true,
              isDestructive: true,
              onTap: () => onCancel?.call(task!),
            ),
          ),
        ]),
      ];
    }

    if (completed && !failed) {
      return [
        const SizedBox(height: 10),
        Row(children: [
          // Botón reproducir — píldora negra/blanca
          Expanded(
            child: _ActionButton(
              label: s.play,
              icon: Icons.play_arrow_rounded,
              bgColor: btnBg,
              fgColor: btnFg,
              onTap: mediaFile == null ? null : () => onPlay(mediaFile),
            ),
          ),
          const SizedBox(width: 8),
          // Botón compartir
          GestureDetector(
            onTap: mediaFile == null
                ? null
                : () => SharePlus.instance
                    .share(ShareParams(files: [XFile(mediaFile.path)])),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.share_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          // Botón Shema Player
          GestureDetector(
            onTap: mediaFile == null
                ? null
                : () => const MethodChannel('com.cocibolka.shema/ytdlp')
                    .invokeMethod('openInShemaPlayer', {'path': mediaFile.path}),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ShemaColors.seed.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_circle_outline_rounded,
                  color: ShemaColors.seed, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          // Botón eliminar
          GestureDetector(
            onTap: () => onDelete(task: task, file: mediaFile, name: name),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444), size: 20),
            ),
          ),
        ]),
      ];
    }

    return [];
  }
}

/// Botón de acción reutilizable: relleno o contorno
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    this.bgColor,
    this.fgColor,
    this.isOutlined = false,
    this.isDestructive = false,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color? bgColor;
  final Color? fgColor;
  final bool isOutlined;
  final bool isDestructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const destructiveColor = Color(0xFFEF4444);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isOutlined) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isDestructive
                ? destructiveColor.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(ShemaRadius.button),
            border: Border.all(
              color: isDestructive
                  ? destructiveColor.withValues(alpha: 0.3)
                  : (isDark ? ShemaColors.darkBorder : ShemaColors.lightBorder),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isDestructive
                      ? destructiveColor
                      : Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDestructive
                      ? destructiveColor
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: bgColor ?? ShemaColors.buttonLight,
            borderRadius: BorderRadius.circular(ShemaRadius.button),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fgColor ?? Colors.white),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: fgColor ?? Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
