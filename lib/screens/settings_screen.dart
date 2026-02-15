/// Pantalla de configuración: tema, idioma y carpetas de descarga.
library;

import 'package:flutter/material.dart';
import '../l10n.dart';
import '../main.dart';
import '../theme.dart';

/// Pantalla de configuración completa con tema, idioma y carpetas
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.musicDirectory,
    required this.videoDirectory,
    required this.onPickFolder,
    required this.onOpenFolder,
    super.key,
  });

  final String? musicDirectory;
  final String? videoDirectory;
  final Future<void> Function({required bool isMusic}) onPickFolder;
  final Future<void> Function({required bool isMusic}) onOpenFolder;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// Estado de la pantalla de configuración
class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final appState = ShemaApp.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // --- Sección de Tema ---
        _SectionHeader(title: s.themeSection, icon: Icons.palette_outlined),
        const SizedBox(height: 12),
        _ThemeSelector(
          currentMode: appState?.themeMode ?? ThemeMode.system,
          onChanged: (mode) => appState?.setThemeMode(mode),
        ),

        const SizedBox(height: 28),

        // --- Sección de Idioma ---
        _SectionHeader(title: s.languageSection, icon: Icons.language),
        const SizedBox(height: 12),
        _LanguageSelector(
          currentLocale: appState?.locale,
          onChanged: (locale) => appState?.setLocale(locale),
        ),

        const SizedBox(height: 28),

        // --- Sección de Carpetas ---
        _SectionHeader(
          title: s.downloadFoldersSection,
          icon: Icons.folder_outlined,
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            s.downloadSettingsDescription,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _FolderCard(
          icon: Icons.music_note_rounded,
          color: ShemaColors.musicBlue,
          label: s.musicFolder,
          path: widget.musicDirectory ?? '...',
          onTap: () async {
            await widget.onPickFolder(isMusic: true);
            if (mounted) setState(() {});
          },
          onOpen: () => widget.onOpenFolder(isMusic: true),
          openTooltip: s.openFolderTooltip,
        ),
        const SizedBox(height: 10),
        _FolderCard(
          icon: Icons.videocam_rounded,
          color: ShemaColors.videoOrange,
          label: s.videoFolder,
          path: widget.videoDirectory ?? '...',
          onTap: () async {
            await widget.onPickFolder(isMusic: false);
            if (mounted) setState(() {});
          },
          onOpen: () => widget.onOpenFolder(isMusic: false),
          openTooltip: s.openFolderTooltip,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

/// Encabezado de sección con icono y título
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
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

/// Selector visual de tema con 3 tarjetas horizontales
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.currentMode, required this.onChanged});
  final ThemeMode currentMode;
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

/// Tarjeta individual de tema (cuadrada, con icono y label)
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

/// Selector de idioma con tarjetas horizontales y bandera
class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({
    required this.currentLocale,
    required this.onChanged,
  });
  final Locale? currentLocale;
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

/// Tarjeta de carpeta de descarga con diseño mejorado
class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.path,
    required this.onTap,
    required this.onOpen,
    required this.openTooltip,
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
