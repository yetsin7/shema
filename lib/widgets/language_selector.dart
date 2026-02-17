/// Selector de idioma con tarjetas animadas y banderas emoji.
library;

import 'package:flutter/material.dart';
import '../l10n.dart';

/// Selector de idioma con tarjetas horizontales y bandera
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
    final isSystem = currentLocale == null;
    final isEs = currentLocale?.languageCode == 'es';
    final isEn = currentLocale?.languageCode == 'en';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            _LanguageTile(
              flag: '🌐',
              label: s.languageSystem,
              subtitle: null,
              selected: isSystem,
              onTap: () => onChanged(null),
            ),
            _LanguageTile(
              flag: '🇪🇸',
              label: s.languageSpanish,
              subtitle: 'Español',
              selected: isEs,
              onTap: () => onChanged(const Locale('es')),
            ),
            _LanguageTile(
              flag: '🇺🇸',
              label: s.languageEnglish,
              subtitle: 'English',
              selected: isEn,
              onTap: () => onChanged(const Locale('en')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila individual de idioma con emoji de bandera
class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String flag;
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? colorScheme.primaryContainer.withValues(alpha: 0.4) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Text(flag, style: const TextStyle(fontSize: 22)),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        subtitle: subtitle != null
            ? Text(subtitle!, style: const TextStyle(fontSize: 12))
            : null,
        trailing: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: selected
              ? Icon(Icons.check_circle_rounded, color: colorScheme.primary, key: const ValueKey('checked'))
              : Icon(Icons.circle_outlined, size: 20, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4), key: const ValueKey('unchecked')),
        ),
        onTap: onTap,
      ),
    );
  }
}
