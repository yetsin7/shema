/// Utilidades para manejo de URLs de YouTube y calidad de medios.
library;

/// Calidad de video por defecto
const String defaultVideoQuality = '720p';

/// Calidad de audio por defecto
const String defaultAudioQuality = '320 kbps';

/// Determina si una URL parece ser un video de YouTube válido
bool isLikelyYouTubeVideoUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return false;

  final uri = Uri.tryParse(trimmed);
  if (uri == null) return false;

  final host = uri.host.toLowerCase();
  if (host.contains('youtu.be')) {
    return uri.pathSegments.isNotEmpty;
  }

  if (!host.contains('youtube.com')) return false;

  final firstPath = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
  if (firstPath == 'watch') {
    final videoId = uri.queryParameters['v']?.trim() ?? '';
    return videoId.isNotEmpty;
  }

  if (firstPath == 'shorts') {
    return uri.pathSegments.length >= 2 &&
        uri.pathSegments[1].trim().isNotEmpty;
  }

  return false;
}

/// Convierte la altura de reproducción en calidad estándar (ej: 720 -> '720p')
String videoQualityFromPlaybackHeight(int? height) {
  if (height == null || height <= 0) return defaultVideoQuality;
  return '${height}p';
}

/// Canonicaliza una URL de YouTube a su forma estándar
///
/// - Convierte youtu.be a youtube.com/watch
/// - Convierte shorts a URL de shorts
/// - Remueve fragmentos y parámetros innecesarios
String canonicalizeYouTubeUrl(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return trimmed;

  final uri = Uri.tryParse(trimmed);
  if (uri == null) return trimmed;

  final host = uri.host.toLowerCase();

  if (host.contains('youtu.be')) {
    if (uri.pathSegments.isEmpty) return trimmed;
    final id = uri.pathSegments.first.trim();
    if (id.isEmpty) return trimmed;
    return 'https://www.youtube.com/watch?v=$id';
  }

  if (!host.contains('youtube.com')) {
    return uri.removeFragment().toString();
  }

  final firstPath = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';

  if (firstPath == 'watch') {
    final id = uri.queryParameters['v']?.trim() ?? '';
    if (id.isNotEmpty) {
      return 'https://www.youtube.com/watch?v=$id';
    }
  }

  if (firstPath == 'shorts' && uri.pathSegments.length >= 2) {
    final id = uri.pathSegments[1].trim();
    if (id.isNotEmpty) {
      return 'https://www.youtube.com/shorts/$id';
    }
  }

  return uri.removeFragment().toString();
}
