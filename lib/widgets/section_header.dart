/// Widget reutilizable de encabezado de sección.
library;

import 'package:flutter/material.dart';

/// Encabezado de sección: etiqueta pequeña con estilo premium
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, required this.icon, super.key});

  /// Texto del encabezado de sección
  final String title;

  /// Icono a la izquierda del título
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark
                ? const Color(0xFF8D8D93)
                : const Color(0xFF6B7280),
          ),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark
                  ? const Color(0xFF8D8D93)
                  : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
