/// Selector de tema — control segmentado tipo píldora.
library;

import 'package:flutter/material.dart';
import '../l10n.dart';
import '../theme.dart';

/// Selector visual de tema como control segmentado en una píldora
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 58,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? ShemaColors.darkCardElevated : ShemaColors.lightBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _Segment(
            icon: Icons.brightness_auto_rounded,
            label: s.themeSystem,
            selected: currentMode == ThemeMode.system,
            isDark: isDark,
            onTap: () => onChanged(ThemeMode.system),
          ),
          _Segment(
            icon: Icons.light_mode_rounded,
            label: s.themeLight,
            selected: currentMode == ThemeMode.light,
            isDark: isDark,
            onTap: () => onChanged(ThemeMode.light),
          ),
          _Segment(
            icon: Icons.dark_mode_rounded,
            label: s.themeDark,
            selected: currentMode == ThemeMode.dark,
            isDark: isDark,
            onTap: () => onChanged(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

/// Segmento individual del control
class _Segment extends StatelessWidget {
  const _Segment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Activo: píldora verde. Inactivo: transparente
    const activeBg = ShemaColors.seed;
    const activeFg = Colors.white;
    final inactiveFg = isDark
        ? const Color(0xFF8D8D93)
        : const Color(0xFF8E8E93);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: selected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: ShemaColors.seed.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? activeFg : inactiveFg,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? activeFg : inactiveFg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
