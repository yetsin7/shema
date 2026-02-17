/// Selector visual de tema con tarjetas animadas (Sistema/Claro/Oscuro).
library;

import 'package:flutter/material.dart';
import '../l10n.dart';

/// Selector visual de tema con 3 tarjetas horizontales
class ThemeSelector extends StatelessWidget {
  const ThemeSelector({
    required this.currentMode,
    required this.onChanged,
    super.key,
  });

  /// Modo de tema actualmente seleccionado
  final ThemeMode currentMode;

  /// Callback al cambiar el tema
  final void Function(ThemeMode) onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      children: [
        _ThemeCard(
          icon: Icons.brightness_auto,
          label: s.themeSystem,
          selected: currentMode == ThemeMode.system,
          onTap: () => onChanged(ThemeMode.system),
        ),
        const SizedBox(width: 10),
        _ThemeCard(
          icon: Icons.light_mode_rounded,
          label: s.themeLight,
          selected: currentMode == ThemeMode.light,
          onTap: () => onChanged(ThemeMode.light),
        ),
        const SizedBox(width: 10),
        _ThemeCard(
          icon: Icons.dark_mode_rounded,
          label: s.themeDark,
          selected: currentMode == ThemeMode.dark,
          onTap: () => onChanged(ThemeMode.dark),
        ),
      ],
    );
  }
}

/// Tarjeta individual de tema con animación de selección
class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor =
        selected
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final fgColor =
        selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant;
    final borderColor =
        selected ? colorScheme.primary : Colors.transparent;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: selected ? 2 : 0),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: selected ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(icon, color: fgColor, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: fgColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
