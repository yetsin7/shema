/// Biblioteca de medios con lista de archivos y tareas de descarga.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../services/download_center.dart';
import '../services/download_service.dart';
import '../l10n.dart';
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
    super.key,
  });
  final String title, emptyTitle, emptyDescription;
  final Set<String> extensions;
  final IconData icon;
  final Color iconColor, tileTint;
  final MediaKind kind;
  final DownloadCenter downloadCenter;
  final String? downloadDirectory;
  @override
  State<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

/// Estado de la biblioteca de medios
class _MediaLibraryScreenState extends State<MediaLibraryScreen> {
  late Future<List<FileSystemEntity>> _mediaFilesFuture;
  int _completedTasksCount = 0;
  @override
  void initState() {
    super.initState();
    _mediaFilesFuture = _loadMediaFiles();
    _completedTasksCount = widget.downloadCenter.tasksByKind(widget.kind).where((t) => t.status == DownloadStatus.completed).length;
    widget.downloadCenter.addListener(_onDownloadsUpdated);
  }
  @override
  void didUpdateWidget(covariant MediaLibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.downloadDirectory != widget.downloadDirectory) _refresh();
  }
  @override
  void dispose() {
    widget.downloadCenter.removeListener(_onDownloadsUpdated);
    super.dispose();
  }
  /// Callback cuando cambian las descargas
  void _onDownloadsUpdated() {
    if (!mounted) return;
    final completed = widget.downloadCenter.tasksByKind(widget.kind).where((t) => t.status == DownloadStatus.completed).length;
    if (completed > _completedTasksCount) _refresh();
    _completedTasksCount = completed;
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
  /// Refresca la lista de archivos
  Future<void> _refresh() async {
    setState(() => _mediaFilesFuture = _loadMediaFiles());
    await _mediaFilesFuture;
  }
  /// Abre un archivo de medios con la app predeterminada
  Future<void> _openMedia(File file) async {
    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).fileNotAvailable)));
      return;
    }
    final result = await OpenFilex.open(file.path);
    if (!mounted || result.type == ResultType.done) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).cantOpenFile)));
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
    if (task != null) await widget.downloadCenter.removeTask(task.id);
    else if (file != null && await file.exists()) await file.delete();
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
        return FutureBuilder<List<FileSystemEntity>>(
          future: _mediaFilesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final files = snapshot.data ?? <FileSystemEntity>[];
            final uniqueFiles = files.where((f) => !taskFilePaths.contains(f.path)).toList();
            if (tasks.isEmpty && uniqueFiles.isEmpty) return Center(child: Text(widget.emptyDescription));
            return RefreshIndicator(onRefresh: _refresh, child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [widget.iconColor.withValues(alpha: 0.12), widget.tileTint]),
                    border: Border.all(color: widget.iconColor.withValues(alpha: 0.18)),
                  ),
                  child: Row(children: [
                    Container(width: 42, height: 42,
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12)),
                      child: Icon(widget.icon, color: widget.iconColor)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(widget.downloadDirectory == null ? S.of(context).folderNotConfigured : S.of(context).folderPath(widget.downloadDirectory!),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)),
                    ])),
                    IconButton(tooltip: S.of(context).openFolderTooltip, onPressed: _openCurrentDownloadDirectory,
                      icon: const Icon(Icons.folder_open_rounded), color: widget.iconColor),
                  ]),
                ),
                const SizedBox(height: 10),
                ...tasks.map((task) => MediaCard(task: task, file: _taskFile(task), kind: widget.kind,
                  iconColor: widget.iconColor, tileTint: widget.tileTint, onPlay: _openMedia, onRetry: _retryFailedTask,
                  onDelete: _confirmDelete, onCancel: (task) => widget.downloadCenter.removeTask(task.id),
                  onCancelDownload: (task) => widget.downloadCenter.cancel(task.id))),
                ...uniqueFiles.map((entity) => MediaCard(file: File(entity.path), kind: widget.kind,
                  iconColor: widget.iconColor, tileTint: widget.tileTint, onPlay: _openMedia, onDelete: _confirmDelete)),
              ],
            ));
          },
        );
      },
    );
  }
}
