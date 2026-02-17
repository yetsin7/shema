/// Tarjeta de carpeta de descarga con icono, ruta y botón para abrir.
library;

import 'package:flutter/material.dart';

/// Tarjeta de carpeta de descarga con diseño gradient
class FolderCard extends StatelessWidget {
  const FolderCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.path,
    required this.onTap,
    required this.onOpen,
    required this.openTooltip,
    super.key,
  });

  /// Icono representativo de la carpeta (música/video)
  final IconData icon;

  /// Color principal del icono y gradiente
  final Color color;

  /// Etiqueta descriptiva (ej. "Carpeta de música")
  final String label;

  /// Ruta actual de la carpeta
  final String path;

  /// Callback al tocar la tarjeta para seleccionar carpeta
  final VoidCallback onTap;

  /// Callback al presionar el botón de abrir carpeta
  final VoidCallback onOpen;

  /// Tooltip del botón de abrir
  final String openTooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.08)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      path,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  tooltip: openTooltip,
                  onPressed: onOpen,
                  icon: Icon(Icons.folder_open_rounded, color: color, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
