/// Biblioteca de medios con lista de archivos y tareas de descarga.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import '../services/download_center.dart';
import '../services/download_service.dart';
import '../l10n.dart';
import '../theme.dart';
import '../widgets/media_card.dart';

/// Pantalla genérica de biblioteca de medios (música o video)
class MediaLibraryScreen extends StatefulWidget {
  const MediaLibraryScreen({
    required this.title,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.extensions,
    required this.icon,
    required this.iconColor,
    required this.tileTint,
    required this.kind,
    required this.downloadCenter,
    required this.downloadDirectory,
    this.isActive = true,
    super.key,
  });
  final String title, emptyTitle, emptyDescription;
  final Set<String> extensions;
  final IconData icon;
  final Color iconColor, tileTint;
  final MediaKind kind;
  final DownloadCenter downloadCenter;
  final String? downloadDirectory;

  /// Si esta pestaña está actualmente visible
  final bool isActive;
  @override
  State<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

/// Estado de la biblioteca de medios
class _MediaLibraryScreenState extends State<MediaLibraryScreen> {
  /// Archivos cargados desde disco (se actualiza sin mostrar spinner)
  List<FileSystemEntity> _files = [];
  int _completedTasksCount = 0;

  /// Identificador del card actualmente expandido (null = ninguno)
  String? _expandedCardId;

  @override
  void initState() {
    super.initState();
    _completedTasksCount = widget.downloadCenter.tasksByKind(widget.kind)
        .where((t) => t.status == DownloadStatus.completed).length;
    widget.downloadCenter.addListener(_onDownloadsUpdated);
    _refresh();
  }

  @override
  void didUpdateWidget(covariant MediaLibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.downloadDirectory != widget.downloadDirectory) _refresh();
    // Contraer cards al salir de la pestaña
    if (!widget.isActive && oldWidget.isActive && _expandedCardId != null) {
      _expandedCardId = null;
    }
  }

  @override
  void dispose() {
    widget.downloadCenter.removeListener(_onDownloadsUpdated);
    super.dispose();
  }

  /// Callback cuando cambian las descargas (progreso, estado, etc.)
  void _onDownloadsUpdated() {
    if (!mounted) return;
    final completed = widget.downloadCenter.tasksByKind(widget.kind)
        .where((t) => t.status == DownloadStatus.completed).length;
    // Recargar archivos del disco cuando una nueva descarga se completa
    if (completed > _completedTasksCount) {
      _completedTasksCount = completed;
      _refresh();
      return;
    }
    _completedTasksCount = completed;
    // Forzar rebuild para mostrar progreso actualizado
    setState(() {});
  }

  /// Carga los archivos de medios desde el disco
  Future<List<FileSystemEntity>> _loadMediaFiles() async {
    final configured = widget.downloadDirectory;
    if (configured == null || configured.trim().isEmpty) return <FileSystemEntity>[];
    final directory = Directory(configured);
    if (!await directory.exists()) return <FileSystemEntity>[];
    final files = <FileSystemEntity>[];
    for (final entry in directory.listSync()) {
      if (entry is! File) continue;
      final lower = entry.path.toLowerCase();
      if (widget.extensions.any(lower.endsWith)) files.add(entry);
    }
    files.sort((a, b) => File(b.path).lastModifiedSync().compareTo(File(a.path).lastModifiedSync()));
    return files;
  }

  /// Refresca la lista sin mostrar spinner (actualiza _files cuando termina)
  Future<void> _refresh() async {
    final loaded = await _loadMediaFiles();
    if (!mounted) return;
    setState(() => _files = loaded);
  }
  static const _channel = MethodChannel('com.cocibolka.shema/ytdlp');

  /// Verifica si Shema Player (com.cocibolka.shemaplayer) está instalado
  Future<bool> _isShemaPlayerInstalled() async {
    try {
      return await _channel.invokeMethod<bool>('isShemaPlayerInstalled') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Abre un archivo: en Shema Player si está instalado, o con el chooser del
  /// sistema si no lo está. En ese segundo caso muestra un banner promocional.
  Future<void> _openMedia(File file) async {
    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).fileNotAvailable)),
      );
      return;
    }

    final shemaInstalled = await _isShemaPlayerInstalled();

    if (shemaInstalled) {
      // Reproducir directamente en Shema Player
      await _channel.invokeMethod('openInShemaPlayer', {'path': file.path});
      return;
    }

    // Abrir con el reproductor que el usuario elija
    final result = await OpenFilex.open(file.path);
    if (!mounted) return;

    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).cantOpenFile)),
      );
      return;
    }

    // Mostrar banner promocional de Shema Player
    _showShemaPlayerPromo();
  }

  /// Muestra un bottom sheet promocionando la instalación de Shema Player
  void _showShemaPlayerPromo() {
    // Altura del nav bar flotante + safe area para que la card quede por encima
    final navOffset = MediaQuery.of(context).viewPadding.bottom + 90.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ShemaPlayerPromoSheet(
            onInstall: () {
              Navigator.pop(ctx);
              _channel.invokeMethod('openInShemaPlayer', {'path': ''});
            },
            onDismiss: () => Navigator.pop(ctx),
          ),
          // Espacio transparente debajo de la card para elevarla sobre el nav bar
          SizedBox(height: navOffset),
        ],
      ),
    );
  }
  /// Abre la carpeta de descargas actual
  Future<void> _openCurrentDownloadDirectory() async {
    final configured = widget.downloadDirectory?.trim();
    if (configured == null || configured.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).folderNotConfigured)));
      return;
    }
    final directory = Directory(configured);
    if (!await directory.exists()) await directory.create(recursive: true);
    final result = await OpenFilex.open(directory.path);
    if (!mounted || result.type == ResultType.done) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).cantOpenFolder)));
  }
  /// Retorna el archivo asociado a una tarea, si existe
  File? _taskFile(DownloadTask task) {
    final path = task.filePath;
    if (path == null || path.isEmpty) return null;
    final f = File(path);
    return f.existsSync() ? f : null;
  }
  /// Reintenta una descarga fallida
  Future<void> _retryFailedTask(DownloadTask task) async {
    final dir = widget.downloadDirectory?.trim();
    if (dir == null || dir.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).folderNotConfigured)));
      return;
    }
    try {
      await Directory(dir).create(recursive: true);
      await widget.downloadCenter.removeTask(task.id);
      widget.downloadCenter.enqueue(kind: task.kind, quality: task.quality, url: task.sourceUrl, downloadDirectory: dir);
      if (!mounted) return;
      final label = task.kind == MediaKind.audio ? 'MP3' : 'MP4';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).downloadStarted(label, task.quality))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).downloadFailed)));
    }
  }
  /// Muestra diálogo de confirmación antes de eliminar
  Future<void> _confirmDelete({DownloadTask? task, File? file, required String name}) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(S.of(context).deleteFileTitle),
      content: Text(S.of(context).deleteFileConfirm(name)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(S.of(context).cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700), child: Text(S.of(context).delete)),
      ],
    ));
    if (confirmed != true || !mounted) return;
    if (task != null) {
      await widget.downloadCenter.removeTask(task.id);
    } else if (file != null && await file.exists()) {
      await file.delete();
    }
    if (!mounted) return;
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).fileDeleted)));
  }
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.downloadCenter,
      builder: (context, _) {
        final tasks = widget.downloadCenter.tasksByKind(widget.kind);
        final taskFilePaths = <String>{};
        for (final t in tasks) {
          if (t.filePath != null && t.filePath!.isNotEmpty) taskFilePaths.add(t.filePath!);
        }
        // Usar _files directamente (sin FutureBuilder) para no mostrar
        // spinner durante refreshes y mantener las tarjetas visibles siempre
        {
            final files = _files;
            final uniqueFiles = files.where((f) => !taskFilePaths.contains(f.path)).toList();
            if (tasks.isEmpty && uniqueFiles.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.iconColor.withValues(alpha: 0.08),
                          widget.tileTint.withValues(alpha: 0.6),
                          widget.iconColor.withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(color: widget.iconColor.withValues(alpha: 0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: widget.iconColor.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: widget.iconColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(widget.icon, size: 36, color: widget.iconColor),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.emptyTitle,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.emptyDescription,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: widget.iconColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.download_rounded, size: 16, color: widget.iconColor),
                              const SizedBox(width: 6),
                              Text(
                                widget.kind == MediaKind.audio
                                    ? S.of(context).emptyMusicHint
                                    : S.of(context).emptyVideoHint,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: widget.iconColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return RefreshIndicator(onRefresh: _refresh, child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                // ── Header Large Title estilo iOS ───────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Ícono grande con gradiente + sombra de color
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              widget.iconColor,
                              HSLColor.fromColor(widget.iconColor)
                                  .withLightness((HSLColor.fromColor(widget.iconColor).lightness - 0.15).clamp(0.0, 1.0))
                                  .toColor(),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: widget.iconColor.withValues(alpha: 0.32),
                              blurRadius: 12,
                              spreadRadius: -2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      // Título grande + contador de elementos
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              S.of(context).itemCount(tasks.length + uniqueFiles.length),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Botón abrir carpeta
                      GestureDetector(
                        onTap: _openCurrentDownloadDirectory,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: widget.iconColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.folder_open_rounded,
                              color: widget.iconColor, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
                ...tasks.map((task) {
                  final cardId = 'task_${task.id}';
                  return MediaCard(task: task, file: _taskFile(task), kind: widget.kind,
                    iconColor: widget.iconColor, tileTint: widget.tileTint, onPlay: _openMedia, onRetry: _retryFailedTask,
                    onDelete: _confirmDelete, onCancel: (task) => widget.downloadCenter.removeTask(task.id),
                    onCancelDownload: (task) => widget.downloadCenter.cancel(task.id),
                    expanded: _expandedCardId == cardId,
                    onToggleExpand: () => setState(() =>
                      _expandedCardId = _expandedCardId == cardId ? null : cardId),
                  );
                }),
                ...uniqueFiles.map((entity) {
                  final cardId = 'file_${entity.path}';
                  return MediaCard(file: File(entity.path), kind: widget.kind,
                    iconColor: widget.iconColor, tileTint: widget.tileTint, onPlay: _openMedia, onDelete: _confirmDelete,
                    expanded: _expandedCardId == cardId,
                    onToggleExpand: () => setState(() =>
                      _expandedCardId = _expandedCardId == cardId ? null : cardId),
                  );
                }),
              ],
            ));
        }
      },
    );
  }
}

/// Bottom sheet promocional que aparece cuando el usuario reproduce con otra app
/// porque Shema Player no está instalado.
class _ShemaPlayerPromoSheet extends StatelessWidget {
  const _ShemaPlayerPromoSheet({
    required this.onInstall,
    required this.onDismiss,
  });

  final VoidCallback onInstall;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: isDark ? ShemaColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ShemaColors.seed.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pill de arrastre
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Fila: icono + textos
            Row(
              children: [
                // Icono real de Shema Player con sombra
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: ShemaColors.seed.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/icon_shema_player.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shema Player',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s.shemaPlayerPromoText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Botones
            Row(
              children: [
                // Botón descartar
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(
                        color: isDark ? ShemaColors.darkBorder : ShemaColors.lightBorder,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      s.shemaPlayerNotNow,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Botón instalar
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onInstall,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text(
                      s.shemaPlayerInstallFree,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: ShemaColors.seed,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
