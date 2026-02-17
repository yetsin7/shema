/// Widget reutilizable de encabezado de sección con icono y título.
library;

import 'package:flutter/material.dart';

/// Encabezado de sección con icono y título estilizado
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, required this.icon, super.key});

  /// Texto del encabezado
  final String title;

  /// Icono a mostrar a la izquierda del título
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
