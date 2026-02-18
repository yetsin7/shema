/// Componentes auxiliares para la tarjeta de medios: thumbnail, chips y estado.
library;

import 'package:flutter/material.dart';
import '../services/download_service.dart';

/// Construye el thumbnail del card: icono para audio, portada para video
Widget buildMediaThumbnail({
  required BuildContext context,
  required bool isAudio,
  required bool completed,
  DownloadTask? task,
}) {
  const double size = 56;
  final borderRadius = BorderRadius.circular(14);

  /// Audio: caja azul con icono de ecualizador
  if (isAudio) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: borderRadius,
      ),
      child: const Icon(Icons.graphic_eq_rounded, color: Color(0xFF1565C0), size: 28),
    );
  }

  /// Video completado con thumbnail de red
  if (completed && task?.thumbnailUrl != null && task!.thumbnailUrl!.isNotEmpty) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        task.thumbnailUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _videoIconBox(size, borderRadius),
      ),
    );
  }

  return _videoIconBox(size, borderRadius);
}

/// Caja con icono de video (fallback cuando no hay thumbnail)
Widget _videoIconBox(double size, BorderRadius borderRadius) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3E0),
      borderRadius: borderRadius,
    ),
    child: const Icon(Icons.movie_creation_outlined, color: Color(0xFFEF6C00), size: 28),
  );
}

/// Construye un chip de metadatos (calidad, formato, tamaño)
Widget buildMetaChip(
  BuildContext context, {
  required IconData icon,
  required String label,
  required Color iconColor,
}) {
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
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

/// Construye el chip de estado (en cola, descargando, completado, error)
Widget buildStatusChip(
  BuildContext context, {
  required String label,
  required bool failed,
  required bool completed,
  required bool queued,
  required Color iconColor,
}) {
  final Color base = failed
      ? const Color(0xFFC62828)
      : completed
          ? const Color(0xFF2E7D32)
          : queued
              ? Colors.grey
              : iconColor;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: base.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: base.withValues(alpha: 0.32)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (completed) ...[
          Icon(Icons.folder_open_rounded, size: 14, color: base),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(color: base, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
