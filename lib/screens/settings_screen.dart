/// Pantalla de configuración: tema, idioma y carpetas de descarga.
library;

import 'package:flutter/material.dart';
import '../l10n.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets/folder_card.dart';
import '../widgets/language_selector.dart';
import '../widgets/section_header.dart';
import '../widgets/theme_selector.dart';

/// Pantalla de configuración completa con tema, idioma y carpetas
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.musicDirectory,
    required this.videoDirectory,
    required this.onPickFolder,
    required this.onOpenFolder,
    super.key,
  });

  /// Ruta de la carpeta de música configurada
  final String? musicDirectory;

  /// Ruta de la carpeta de video configurada
  final String? videoDirectory;

  /// Callback para seleccionar carpeta (música o video)
  final Future<void> Function({required bool isMusic}) onPickFolder;

  /// Callback para abrir carpeta en explorador de archivos
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
        SectionHeader(title: s.themeSection, icon: Icons.palette_outlined),
        const SizedBox(height: 12),
        ThemeSelector(
          currentMode: appState?.themeMode ?? ThemeMode.system,
          onChanged: (mode) => appState?.setThemeMode(mode),
        ),

        const SizedBox(height: 28),

        // --- Sección de Idioma ---
        SectionHeader(title: s.languageSection, icon: Icons.language),
        const SizedBox(height: 12),
        LanguageSelector(
          currentLocale: appState?.locale,
          onChanged: (locale) => appState?.setLocale(locale),
        ),

        const SizedBox(height: 28),

        // --- Sección de Carpetas ---
        SectionHeader(
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
        FolderCard(
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
        FolderCard(
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
