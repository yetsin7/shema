/// Barra de navegación inferior flotante con indicador tipo píldora.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';
import '../theme.dart';

/// Barra de navegación inferior flotante con glassmorphism y pill activo.
///
/// El ítem activo muestra un fondo tipo píldora con el color del tab.
/// Usa [BackdropFilter] con blur para el efecto glass.
class CustomBottomNav extends StatelessWidget {
  /// Crea la barra con el [currentIndex] seleccionado
  const CustomBottomNav({
    required this.currentIndex,
    required this.onIndexChanged,
    super.key,
  });

  /// Índice de la pestaña actualmente seleccionada (0-4)
  final int currentIndex;

  /// Callback cuando el usuario toca una pestaña diferente
  final ValueChanged<int> onIndexChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final bottomMargin = bottomInset > 0 ? bottomInset + 6 : 14.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1C1C1E).withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark
                    ? ShemaColors.darkBorder.withValues(alpha: 0.8)
                    : ShemaColors.lightBorder.withValues(alpha: 0.9),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                  blurRadius: 32,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Builder(builder: (context) {
              final s = S.of(context);
              return Row(
                children: [
                  _NavItem(
                    index: 0,
                    currentIndex: currentIndex,
                    icon: Icons.play_circle_outline_rounded,
                    activeIcon: Icons.play_circle_rounded,
                    color: ShemaColors.youtubeRed,
                    label: s.tabYouTube,
                    onTap: onIndexChanged,
                  ),
                  _NavItem(
                    index: 1,
                    currentIndex: currentIndex,
                    icon: Icons.slow_motion_video_outlined,
                    activeIcon: Icons.slow_motion_video_rounded,
                    color: ShemaColors.shortsOrange,
                    label: s.tabShorts,
                    onTap: onIndexChanged,
                  ),
                  _NavItem(
                    index: 2,
                    currentIndex: currentIndex,
                    icon: Icons.music_note_outlined,
                    activeIcon: Icons.music_note_rounded,
                    color: ShemaColors.musicBlue,
                    label: s.tabMusic,
                    onTap: onIndexChanged,
                  ),
                  _NavItem(
                    index: 3,
                    currentIndex: currentIndex,
                    icon: Icons.video_library_outlined,
                    activeIcon: Icons.video_library_rounded,
                    color: ShemaColors.videoCoral,
                    label: s.tabVideos,
                    onTap: onIndexChanged,
                  ),
                  _NavItem(
                    index: 4,
                    currentIndex: currentIndex,
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    color: const Color(0xFF8E8E93),
                    label: s.settingsTitle,
                    onTap: onIndexChanged,
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Ítem de navegación con pill animado sobre el ícono activo
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final Color color;
  final String label;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark
        ? const Color(0xFF8D8D93)
        : const Color(0xFFAEAEB2);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap(index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Píldora de fondo solo cuando está seleccionado
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              width: isSelected ? 52 : 36,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                size: isSelected ? 22 : 21,
                color: isSelected ? color : inactiveColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : inactiveColor,
                letterSpacing: isSelected ? -0.2 : 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
