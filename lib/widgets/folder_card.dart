/// Tarjeta de carpeta de descarga — diseño moderno con ícono y ruta.
library;

import 'package:flutter/material.dart';
import '../theme.dart';

/// Tarjeta de carpeta de descarga con diseño limpio y redondeado
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

  final IconData icon;
  final Color color;
  final String label;
  final String path;
  final VoidCallback onTap;
  final VoidCallback onOpen;
  final String openTooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? ShemaColors.darkCard : ShemaColors.lightCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? ShemaColors.darkBorder : ShemaColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ícono con fondo de color
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: -0.1),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    path,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Botón abrir carpeta
            GestureDetector(
              onTap: onOpen,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.folder_open_rounded, color: color, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
