/// Centro de gestión de descargas con cola y concurrencia controlada.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'download_service.dart';

/// Gestor centralizado de descargas con cola automática y límites de concurrencia
class DownloadCenter extends ChangeNotifier {
  /// Constructor que inicia la escucha de eventos de progreso
  DownloadCenter() {
    _listenToProgress();
  }

  /// Máximo de descargas de video simultáneas
  static const _maxConcurrentVideo = 10;

  /// Máximo de descargas de audio simultáneas
  static const _maxConcurrentAudio = 20;

  /// Lista de todas las tareas (activas, en cola, completadas y fallidas)
  final List<DownloadTask> _tasks = <DownloadTask>[];

  /// Instancia del servicio de comunicación con yt-dlp nativo
  final YtDlpService _ytDlp = YtDlpService();

  /// Suscripción al stream de eventos de progreso
  StreamSubscription? _progressSub;

  /// Flag para evitar llamadas duplicadas a notifyListeners en el mismo frame
  bool _notifyScheduled = false;

  /// Notifica a los listeners de forma segura, evitando conflictos con el build.
  /// Llama scheduleFrame() para garantizar que el callback se ejecute aunque la UI esté inactiva.
  void _safeNotify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      notifyListeners();
    });
    // Sin scheduleFrame, addPostFrameCallback nunca se ejecuta si la UI está idle
    WidgetsBinding.instance.scheduleFrame();
  }

  /// Escucha los eventos de progreso del canal nativo
  void _listenToProgress() {
    _progressSub = _ytDlp.progressStream.listen((event) {
      final downloadId = event['downloadId'] as String? ?? '';
      final status = event['status'] as String? ?? '';
      final progress = (event['progress'] as num?)?.toDouble() ?? 0.0;
      final line = event['line'] as String? ?? '';
      final filePath = event['filePath'] as String?;
      final error = event['error'] as String?;

      final idx = _tasks.indexWhere((t) => t.id == downloadId);
      if (idx == -1) return;

      final task = _tasks[idx];

      switch (status) {
        case 'downloading':
          if (progress >= 0) {
            task.progress = progress / 100.0;
          }
          if (line.isNotEmpty) {
            if (line.contains('Downloading item')) {
              task.title = line;
            } else if (line.contains('Downloading webpage') ||
                line.contains('Extracting URL')) {
              task.title = 'Obteniendo info del video...';
            } else if (line.contains('Sleeping')) {
              task.title = 'Esperando (límite del sitio)...';
            } else if (line.contains('ExtractAudio') ||
                line.contains('Destination:')) {
              task.title = 'Obteniendo audio...';
              task.progress = 0.92;
            } else if (line.contains('Metadata')) {
              task.title = 'Agregando metadata...';
              task.progress = 0.95;
            } else if (line.contains('EmbedThumbnail')) {
              task.title = 'Agregando portada...';
              task.progress = 0.98;
            } else if (line.contains('Merging') || line.contains('merge')) {
              task.title = 'Combinando video y audio...';
              task.progress = 0.95;
            } else if (!line.startsWith('[')) {
              task.title = line;
            }
          }
          break;
        case 'completed':
          task.progress = 1.0;
          task.status = DownloadStatus.completed;
          task.filePath = filePath;
          if (filePath != null && filePath.isNotEmpty) {
            task.title = filePath
                .split('/')
                .last
                .replaceAll(RegExp(r'\.\w+$'), '');
          }
          _processQueue();
          break;
        case 'failed':
          task.status = DownloadStatus.failed;
          task.title = '${task.title} - Error: ${error ?? "desconocido"}';
          _processQueue();
          break;
        case 'cancelled':
          task.status = DownloadStatus.failed;
          task.title = '${task.title} (Cancelado)';
          _processQueue();
          break;
      }

      _safeNotify();
    });
  }

  /// Retorna las tareas filtradas por tipo de media
  List<DownloadTask> tasksByKind(MediaKind kind) {
    return _tasks.where((task) => task.kind == kind).toList(growable: false);
  }

  /// Retorna todas las tareas activas (descargando)
  List<DownloadTask> get activeTasks {
    return _tasks
        .where((t) => t.status == DownloadStatus.downloading)
        .toList(growable: false);
  }

  /// Cuenta descargas activas por tipo
  int _activeCountByKind(MediaKind kind) => _tasks
      .where((t) => t.kind == kind && t.status == DownloadStatus.downloading)
      .length;

  /// Inicia las tareas en cola que caben dentro del límite de concurrencia
  void _processQueue() {
    for (final kind in MediaKind.values) {
      final limit = kind == MediaKind.audio
          ? _maxConcurrentAudio
          : _maxConcurrentVideo;
      final active = _activeCountByKind(kind);
      final available = limit - active;
      if (available <= 0) continue;

      final queued = _tasks
          .where((t) => t.kind == kind && t.status == DownloadStatus.queued)
          .take(available);
      for (final task in queued) {
        _startTask(task);
      }
    }
  }

  /// Inicia la descarga real de una tarea
  void _startTask(DownloadTask task) {
    task.status = DownloadStatus.downloading;
    task.title = 'Iniciando descarga...';

    _ytDlp
        .downloadMedia(
          url: task.sourceUrl,
          quality: task.quality,
          downloadPath: task.downloadDirectory,
          isAudio: task.kind == MediaKind.audio,
        )
        .then((downloadId) {
          task.id = downloadId;
          _safeNotify();
        })
        .catchError((e) {
          task.status = DownloadStatus.failed;
          task.title = 'Error al iniciar: $e';
          _safeNotify();
          _processQueue();
        });
  }

  /// Cancela una descarga en progreso
  void cancel(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final task = _tasks[idx];
    task.cancelled = true;
    task.status = DownloadStatus.failed;
    task.title = '${task.title} (Cancelado)';
    _ytDlp.cancelDownload(taskId);
    notifyListeners();
    _processQueue();
  }

  /// Elimina una tarea de la lista y su archivo si existe
  Future<void> removeTask(String taskId) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final task = _tasks[idx];

    if (task.status == DownloadStatus.downloading) {
      task.cancelled = true;
      _ytDlp.cancelDownload(taskId);
    }

    if (task.filePath != null) {
      final file = File(task.filePath!);
      if (await file.exists()) await file.delete();
    }

    _tasks.removeAt(idx);
    notifyListeners();
    _processQueue();
  }

  /// Encola una descarga. Se iniciará automáticamente cuando haya espacio
  void enqueue({
    required MediaKind kind,
    required String quality,
    required String url,
    required String downloadDirectory,
  }) {
    final task = DownloadTask(
      id: '',
      kind: kind,
      quality: quality,
      sourceUrl: url,
      downloadDirectory: downloadDirectory,
      title: 'En cola...',
    );

    _tasks.insert(0, task);
    notifyListeners();
    _processQueue();
  }

  /// Actualiza yt-dlp a la última versión
  Future<String> updateYtDlp() => _ytDlp.updateYtDlp();

  @override
  void dispose() { _progressSub?.cancel(); super.dispose(); }
}
