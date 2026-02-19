/// Componente de tarjeta showcase para archivos de medios y tareas de descarga.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../services/download_service.dart';
import '../l10n.dart';
import '../theme.dart';
import 'media_card_parts.dart';

/// Tarjeta con modo compacto y expandido para tareas de descarga y archivos.
///
/// Modo compacto: header con icono, título, badge y chevrón. Tap reproduce.
/// Modo expandido: muestra metadatos y botones de acción.
class MediaCard extends StatefulWidget {
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
    this.expanded = false,
    this.onToggleExpand,
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

  /// Si la tarjeta está expandida (controlado por el padre)
  final bool expanded;

  /// Callback para expandir/contraer (controlado por el padre)
  final VoidCallback? onToggleExpand;

  @override
  State<MediaCard> createState() => _MediaCardState();
}

/// Estado de la tarjeta con control de expansión
class _MediaCardState extends State<MediaCard> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTask = widget.task != null;
    final queued = isTask && widget.task!.status == DownloadStatus.queued;
    final downloading = isTask && widget.task!.status == DownloadStatus.downloading;
    final completed = isTask ? widget.task!.status == DownloadStatus.completed : true;
    final failed = isTask && widget.task!.status == DownloadStatus.failed;
    final isAudio = widget.kind == MediaKind.audio;
    final mediaFile = widget.file;

    final String name;
    final String? sizeMb, quality;
    DateTime? date;

    if (isTask) {
      name = widget.task!.title;
      quality = widget.task!.quality;
      final f = mediaFile;
      if (f != null && f.existsSync()) {
        sizeMb = (f.statSync().size / (1024 * 1024)).toStringAsFixed(1);
        try { date = f.lastModifiedSync(); } catch (_) {}
      } else {
        sizeMb = null;
      }
      if (completed && date == null && widget.task!.filePath != null) {
        final f = File(widget.task!.filePath!);
        if (f.existsSync()) {
          try { date = f.lastModifiedSync(); } catch (_) {}
        }
      }
    } else {
      final path = widget.file!.path;
      name = path.split(Platform.pathSeparator).last.replaceAll(RegExp(r'\.\w+$'), '');
      sizeMb = (widget.file!.statSync().size / (1024 * 1024)).toStringAsFixed(1);
      quality = null;
      try { date = widget.file!.lastModifiedSync(); } catch (_) {}
    }

    final s = S.of(context);
    final statusText = failed
        ? s.error
        : queued
            ? s.queued
            : downloading
                ? '${(widget.task!.progress * 100).toStringAsFixed(0)}%'
                : s.completed;

    String? dateStr;
    if (date != null) {
      dateStr = DateFormat('d MMM, HH:mm', s.locale.languageCode).format(date);
    }

    final tappable = completed && !failed && mediaFile != null;
    final btnBg = isDark ? ShemaColors.buttonDark : ShemaColors.buttonLight;
    final btnFg = isDark ? const Color(0xFF0A0A0A) : Colors.white;

    // Las tareas en progreso (descargando, en cola, fallidas) siempre expandidas
    final alwaysExpanded = queued || downloading || failed;

    // Badge compacto para el header (sobre el gradiente)
    final statusBadge = buildStatusChip(
      context,
      label: statusText,
      failed: failed,
      completed: completed && !failed,
      queued: queued,
      iconColor: widget.iconColor,
      compact: true,
    );

    final isOpen = widget.expanded || alwaysExpanded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Panel de metadatos detrás del header ────
          // Se posiciona debajo usando padding-top para que el contenido
          // empiece justo debajo del header (52px) sin solaparse
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Container(
              padding: EdgeInsets.fromLTRB(12, 52 + 10.0, 12, 10),
              decoration: BoxDecoration(
                color: isDark ? ShemaColors.darkCard : ShemaColors.lightCard,
                borderRadius: BorderRadius.circular(28),
                boxShadow: ShemaShadow.subtle(isDark: isDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 5, runSpacing: 5, children: [
                    if (quality != null)
                      buildMetaChip(context,
                          icon: Icons.hd_rounded,
                          label: quality,
                          iconColor: widget.iconColor),
                    buildMetaChip(context,
                        icon: isAudio
                            ? Icons.music_note_rounded
                            : Icons.videocam_rounded,
                        label: isAudio ? 'MP3' : 'MP4',
                        iconColor: widget.iconColor),
                    if (sizeMb != null)
                      buildMetaChip(context,
                          icon: Icons.sd_storage_rounded,
                          label: '$sizeMb MB',
                          iconColor: widget.iconColor),
                    if (dateStr != null)
                      buildMetaChip(context,
                          icon: Icons.access_time_rounded,
                          label: dateStr,
                          iconColor: widget.iconColor),
                  ]),
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
            crossFadeState: isOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),

          // ── Header siempre redondeado (encima del panel) ──
          GestureDetector(
            onTap: tappable ? () => widget.onPlay(mediaFile) : null,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: ShemaShadow.deep(isDark: isDark, tintColor: widget.iconColor),
              ),
              child: buildCardHeader(
                context: context,
                isAudio: isAudio,
                accentColor: widget.iconColor,
                task: widget.task,
                title: name,
                statusBadge: statusBadge,
                expanded: false,
                trailing: (completed && !failed) ? GestureDetector(
                  onTap: widget.onToggleExpand,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedRotation(
                      turns: widget.expanded ? 0 : 0.5,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      child: const Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ) : null,
              ),
            ),
          ),
        ],
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
          onTap: () => widget.onCancel?.call(widget.task!),
        ),
      ];
    }

    if (downloading) {
      return [
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: widget.task!.progress,
            minHeight: 5,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(widget.iconColor),
          ),
        ),
        const SizedBox(height: 8),
        _ActionButton(
          label: s.cancel,
          icon: Icons.close_rounded,
          isOutlined: true,
          isDestructive: true,
          onTap: () => widget.onCancelDownload?.call(widget.task!),
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
              onTap: () => widget.onRetry?.call(widget.task!),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              label: s.delete,
              icon: Icons.delete_outline_rounded,
              isOutlined: true,
              isDestructive: true,
              onTap: () => widget.onCancel?.call(widget.task!),
            ),
          ),
        ]),
      ];
    }

    if (completed && !failed) {
      return [
        const SizedBox(height: 10),
        Row(children: [
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
          // Botón eliminar
          GestureDetector(
            onTap: () => widget.onDelete(task: widget.task, file: mediaFile, name: name),
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
          const Spacer(),
          // Botón reproducir — píldora negra/blanca (derecha)
          _ActionButton(
            label: s.play,
            icon: Icons.play_arrow_rounded,
            bgColor: btnBg,
            fgColor: btnFg,
            onTap: mediaFile == null ? null : () => widget.onPlay(mediaFile),
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
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: bgColor ?? ShemaColors.buttonLight,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
