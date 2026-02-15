/// Modelos de datos y servicio de comunicación con yt-dlp.
library;

import 'package:flutter/services.dart';

/// Tipos de media soportados
enum MediaKind { audio, video }

/// Estados posibles de una descarga
enum DownloadStatus { queued, downloading, completed, failed }

/// Modelo que representa una tarea de descarga
class DownloadTask {
  /// Crea una tarea de descarga con los datos necesarios
  DownloadTask({
    required this.id,
    required this.kind,
    required this.quality,
    required this.sourceUrl,
    required this.downloadDirectory,
    required this.title,
    this.thumbnailUrl,
    this.progress = 0,
    this.status = DownloadStatus.queued,
    this.filePath,
  });

  /// Identificador único asignado por el lado nativo
  String id;

  /// Tipo de medio (audio o video)
  final MediaKind kind;

  /// Calidad seleccionada (ej: "720p", "320 kbps")
  final String quality;

  /// URL de origen del contenido
  final String sourceUrl;

  /// Directorio donde se guardará el archivo
  final String downloadDirectory;

  /// Título mostrado en la UI (cambia según el progreso)
  String title;

  /// URL de la miniatura del video
  String? thumbnailUrl;

  /// Progreso de la descarga (0.0 a 1.0)
  double progress;

  /// Estado actual de la descarga
  DownloadStatus status;

  /// Ruta del archivo descargado (disponible al completar)
  String? filePath;

  /// Indica si la descarga fue cancelada por el usuario
  bool cancelled = false;
}

/// Servicio que se comunica con yt-dlp vía platform channels (Android nativo)
class YtDlpService {
  /// Canal de métodos para invocar funciones nativas
  static const _channel = MethodChannel('com.cocibolka.shema/ytdlp');

  /// Canal de eventos para recibir progreso en tiempo real
  static const _eventChannel = EventChannel(
    'com.cocibolka.shema/ytdlp_progress',
  );

  /// Stream de eventos de progreso desde el lado nativo
  Stream<Map<dynamic, dynamic>> get progressStream => _eventChannel
      .receiveBroadcastStream()
      .map((e) => e as Map<dynamic, dynamic>);

  /// Inicia una descarga y retorna el downloadId asignado
  Future<String> downloadMedia({
    required String url,
    required String quality,
    required String downloadPath,
    required bool isAudio,
  }) async {
    final result = await _channel.invokeMethod<String>('downloadMedia', {
      'url': url,
      'quality': quality,
      'downloadPath': downloadPath,
      'isAudio': isAudio,
    });
    return result ?? '';
  }

  /// Cancela una descarga en progreso
  Future<void> cancelDownload(String downloadId) async {
    await _channel.invokeMethod('cancelDownload', {'downloadId': downloadId});
  }

  /// Obtiene info del video (JSON de yt-dlp --dump-json)
  Future<String> getVideoInfo(String url) async {
    final result = await _channel.invokeMethod<String>('getVideoInfo', {
      'url': url,
    });
    return result ?? '';
  }

  /// Actualiza yt-dlp a la última versión disponible
  Future<String> updateYtDlp() async {
    final result = await _channel.invokeMethod<String>('updateYtDlp');
    return result ?? 'UNKNOWN';
  }
}
