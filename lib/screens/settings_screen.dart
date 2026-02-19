/// Pantalla de configuración: tema, idioma y carpetas de descarga.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n.dart';
import '../main.dart';
import '../theme.dart';

/// Pantalla de configuración — diseño limpio tipo lista iOS
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

class _SettingsScreenState extends State<SettingsScreen> {
  /// Acordeón abierto: 'theme', 'lang', o null (ninguno)
  String? _openAccordion;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final appState = ShemaApp.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = appState?.themeMode ?? ThemeMode.system;
    final locale = appState?.locale;
    final subColor =
        isDark ? const Color(0xFF8D8D93) : const Color(0xFF6C6C70);

    // Etiqueta del tema activo
    final themeLabel = switch (themeMode) {
      ThemeMode.system => s.themeSystem,
      ThemeMode.light => s.themeLight,
      ThemeMode.dark => s.themeDark,
    };

    // Etiqueta del idioma activo
    final langLabel = locale == null
        ? s.languageSystem
        : locale.languageCode == 'es'
            ? s.languageSpanish
            : s.languageEnglish;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [

        // ══════════════════════════════
        // Título grande
        // ══════════════════════════════
        Text(
          s.settingsTitle,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 28),

        // ══════════════════════════════
        // Acordeón: Tema
        // ══════════════════════════════
        _SettingsGroup(
          isDark: isDark,
          children: [
            _PopupRow(
              icon: Icons.contrast_rounded,
              iconColor: ShemaColors.seed,
              title: s.themeSection,
              currentValue: themeLabel,
              isOpen: _openAccordion == 'theme',
              onToggle: () => setState(() =>
                  _openAccordion =
                      _openAccordion == 'theme' ? null : 'theme'),
              isDark: isDark,
              items: [
                _PopupItem(label: s.themeSystem,
                    selected: themeMode == ThemeMode.system),
                _PopupItem(label: s.themeLight,
                    selected: themeMode == ThemeMode.light),
                _PopupItem(label: s.themeDark,
                    selected: themeMode == ThemeMode.dark),
              ],
              onSelected: (idx) {
                const modes = [
                  ThemeMode.system,
                  ThemeMode.light,
                  ThemeMode.dark,
                ];
                appState?.setThemeMode(modes[idx]);
                setState(() => _openAccordion = null);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ══════════════════════════════
        // Acordeón: Idioma
        // ══════════════════════════════
        _SettingsGroup(
          isDark: isDark,
          children: [
            _PopupRow(
              icon: Icons.language_rounded,
              iconColor: const Color(0xFF3B82F6),
              title: s.languageSection,
              currentValue: langLabel,
              isOpen: _openAccordion == 'lang',
              onToggle: () => setState(() =>
                  _openAccordion =
                      _openAccordion == 'lang' ? null : 'lang'),
              isDark: isDark,
              items: [
                _PopupItem(label: s.languageSystem,
                    selected: locale == null),
                _PopupItem(label: s.languageSpanish,
                    selected: locale?.languageCode == 'es'),
                _PopupItem(label: s.languageEnglish,
                    selected: locale?.languageCode == 'en'),
              ],
              onSelected: (idx) {
                const locales = [null, Locale('es'), Locale('en')];
                appState?.setLocale(locales[idx]);
                setState(() => _openAccordion = null);
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ══════════════════════════════
        // Sección: Carpetas de descarga
        // ══════════════════════════════
        _SectionLabel(s.downloadFoldersSection, isDark: isDark),
        const SizedBox(height: 8),
        _SettingsGroup(
          isDark: isDark,
          children: [
            _FolderRow(
              icon: Icons.music_note_rounded,
              iconColor: ShemaColors.musicBlue,
              label: s.musicFolder,
              path: widget.musicDirectory,
              isDark: isDark,
              onTap: () => widget.onOpenFolder(isMusic: true),
              onEdit: () async {
                await widget.onPickFolder(isMusic: true);
                if (mounted) setState(() {});
              },
            ),
            _GroupDivider(isDark: isDark),
            _FolderRow(
              icon: Icons.videocam_rounded,
              iconColor: ShemaColors.videoCoral,
              label: s.videoFolder,
              path: widget.videoDirectory,
              isDark: isDark,
              onTap: () => widget.onOpenFolder(isMusic: false),
              onEdit: () async {
                await widget.onPickFolder(isMusic: false);
                if (mounted) setState(() {});
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            s.downloadSettingsDescription,
            style: TextStyle(fontSize: 12, color: subColor, height: 1.5),
          ),
        ),
        const SizedBox(height: 32),

        // ══════════════════════════════
        // Sección: Acerca de
        // ══════════════════════════════
        _SectionLabel(s.aboutSection, isDark: isDark),
        const SizedBox(height: 8),
        _SettingsGroup(
          isDark: isDark,
          children: [
            // Shema — versión
            _AppRow(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.asset(
                  'assets/icon_shema.png',
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                ),
              ),
              title: s.appName,
              subtitle: s.appTagline,
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ShemaColors.seed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'v1.0.2',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ShemaColors.seed,
                  ),
                ),
              ),
              isDark: isDark,
            ),
            _GroupDivider(isDark: isDark, indent: 70),
            // Shema Player — enlace
            _AppRow(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.asset(
                  'assets/icon_shema_player.png',
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                ),
              ),
              title: s.openInPlayer,
              subtitle: s.shemaPlayerTagline,
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  s.getOnPlayStore,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
              onTap: () async {
                final market = Uri.parse(
                    'market://details?id=com.cocibolka.shemaplayer');
                final web = Uri.parse(
                    'https://play.google.com/store/apps/details?id=com.cocibolka.shemaplayer');
                if (await canLaunchUrl(market)) {
                  await launchUrl(market,
                      mode: LaunchMode.externalApplication);
                } else {
                  await launchUrl(web, mode: LaunchMode.externalApplication);
                }
              },
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Modelo y widget para fila con popup flotante
// ──────────────────────────────────────────────────────────────

/// Dato de cada opción del menú flotante
class _PopupItem {
  const _PopupItem({required this.label, required this.selected});

  final String label;
  final bool selected;
}

/// Fila con acordeón — estado controlado desde el padre para cierre mutuo
class _PopupRow extends StatelessWidget {
  const _PopupRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.currentValue,
    required this.isOpen,
    required this.onToggle,
    required this.items,
    required this.onSelected,
    required this.isDark,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String currentValue;
  final bool isOpen;
  final VoidCallback onToggle;
  final List<_PopupItem> items;
  final void Function(int index) onSelected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final subColor =
        isDark ? const Color(0xFF8D8D93) : const Color(0xFF8E8E93);
    final textColor =
        isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1C1C1E);
    final divColor =
        isDark ? ShemaColors.darkBorder : ShemaColors.lightBorder;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header ────────────────────────────────────────
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            splashColor: iconColor.withValues(alpha: 0.08),
            highlightColor: iconColor.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.13),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                  Text(
                    currentValue,
                    style: TextStyle(
                      fontSize: 14,
                      color: isOpen ? iconColor : subColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Chevron rota 90° al abrir
                  AnimatedRotation(
                    turns: isOpen ? 0.25 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: isOpen ? iconColor : subColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Opciones en cascada (alineadas a la derecha) ─
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
          child: isOpen
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Divisor bajo el header
                    Divider(
                        height: 1,
                        thickness: 0.5,
                        color: divColor),
                    ...items.asMap().entries.map((e) {
                      final idx = e.key;
                      final item = e.value;
                      final isLast = idx == items.length - 1;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => onSelected(idx),
                              splashColor:
                                  iconColor.withValues(alpha: 0.08),
                              highlightColor:
                                  iconColor.withValues(alpha: 0.04),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    top: 13,
                                    bottom: 13),
                                child: Row(
                                  children: [
                                    // Espacio vacío a la izquierda —
                                    // las opciones "caen" desde la derecha
                                    const Expanded(
                                        child: SizedBox()),
                                    Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: item.selected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: item.selected
                                            ? iconColor
                                            : textColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Check animado
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                          milliseconds: 180),
                                      transitionBuilder:
                                          (child, anim) =>
                                              ScaleTransition(
                                                  scale: anim,
                                                  child: child),
                                      child: item.selected
                                          ? Icon(
                                              Icons
                                                  .check_circle_rounded,
                                              color: iconColor,
                                              size: 20,
                                              key: const ValueKey(
                                                  'check'))
                                          : const SizedBox(
                                              width: 20,
                                              key: ValueKey('none')),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Divisor parcial entre opciones (solo zona derecha)
                          if (!isLast)
                            LayoutBuilder(
                              builder: (_, c) => Divider(
                                height: 1,
                                thickness: 0.5,
                                indent: c.maxWidth * 0.42,
                                endIndent: 16,
                                color: divColor,
                              ),
                            ),
                        ],
                      );
                    }),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Etiqueta de sección — texto gris sin mayúsculas forzadas
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color:
              isDark ? const Color(0xFF8D8D93) : const Color(0xFF6C6C70),
        ),
      ),
    );
  }
}

/// Card agrupada sin borde explícito — solo sombra suave
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children, required this.isDark});

  final List<Widget> children;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? ShemaColors.darkCard : ShemaColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.07),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Divisor fino entre filas del grupo
class _GroupDivider extends StatelessWidget {
  const _GroupDivider({required this.isDark, this.indent = 60});

  final bool isDark;
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: indent,
      color: isDark ? ShemaColors.darkBorder : ShemaColors.lightBorder,
    );
  }
}

/// Fila de carpeta — toca para abrir, botón de editar para cambiar ruta
class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.path,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? path;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1C1C1E);
    final subColor =
        isDark ? const Color(0xFF8D8D93) : const Color(0xFF8E8E93);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: iconColor.withValues(alpha: 0.08),
        highlightColor: iconColor.withValues(alpha: 0.04),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    Text(
                      path ?? '—',
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Botón para cambiar la carpeta
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.edit_rounded,
                      color: iconColor, size: 16),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark
                    ? const Color(0xFF48484A)
                    : const Color(0xFFD1D1D6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de app en sección Acerca de
class _AppRow extends StatelessWidget {
  const _AppRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.isDark,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1C1C1E);
    final subColor =
        isDark ? const Color(0xFF8D8D93) : const Color(0xFF8E8E93);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
