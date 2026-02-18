/// Selector de idioma — lista agrupada en tarjeta con radio buttons.
library;

import 'package:flutter/material.dart';
import '../l10n.dart';
import '../theme.dart';

/// Selector de idioma estilo lista iOS dentro de una tarjeta
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    required this.currentLocale,
    required this.onChanged,
    super.key,
  });

  /// Locale actualmente seleccionado (null = sistema)
  final Locale? currentLocale;

  /// Callback al cambiar el idioma
  final void Function(Locale?) onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSystem = currentLocale == null;
    final isEs = currentLocale?.languageCode == 'es';
    final isEn = currentLocale?.languageCode == 'en';

    return _SettingsGroup(
      isDark: isDark,
      children: [
        _LanguageRow(
          flag: '🌐',
          label: s.languageSystem,
          subtitle: s.languageSystemSubtitle,
          selected: isSystem,
          isDark: isDark,
          onTap: () => onChanged(null),
          isLast: false,
        ),
        _LanguageRow(
          flag: '🇪🇸',
          label: s.languageSpanish,
          subtitle: 'Español',
          selected: isEs,
          isDark: isDark,
          onTap: () => onChanged(const Locale('es')),
          isLast: false,
        ),
        _LanguageRow(
          flag: '🇺🇸',
          label: s.languageEnglish,
          subtitle: 'English',
          selected: isEn,
          isDark: isDark,
          onTap: () => onChanged(const Locale('en')),
          isLast: true,
        ),
      ],
    );
  }
}

/// Fila de idioma con bandera, label y check animado
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.flag,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
    required this.isLast,
    this.subtitle,
  });

  final String flag;
  final String label;
  final String? subtitle;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: selected
                ? ShemaColors.seed.withValues(alpha: isDark ? 0.12 : 0.07)
                : Colors.transparent,
            child: Row(
              children: [
                // Emoji bandera
                Text(flag, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 14),
                // Nombre del idioma
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected
                              ? ShemaColors.seed
                              : (isDark
                                  ? const Color(0xFFF5F5F5)
                                  : const Color(0xFF1C1C1E)),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF8D8D93)
                                : const Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Indicador de selección
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                  child: selected
                      ? Icon(Icons.check_circle_rounded,
                          color: ShemaColors.seed,
                          size: 22,
                          key: const ValueKey('check'))
                      : Container(
                          key: const ValueKey('empty'),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF48484A)
                                  : const Color(0xFFD1D1D6),
                              width: 1.5,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        // Divisor entre filas (no en la última)
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            indent: 56,
            color: isDark ? ShemaColors.darkBorder : ShemaColors.lightBorder,
          ),
      ],
    );
  }
}

/// Contenedor agrupado tipo iOS con bordes redondeados
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children, required this.isDark});

  final List<Widget> children;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
