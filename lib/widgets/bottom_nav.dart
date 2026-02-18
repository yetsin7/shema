/// Barra de navegación inferior con efecto glassmorphism flotante.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';

/// Barra de navegación inferior flotante con efecto glassmorphism.
///
/// Usa [BackdropFilter] con blur para crear transparencia líquida.
/// Contiene 5 pestañas: YouTube, Shorts, Música, Videos, Configuración.
/// Se adapta automáticamente a la navegación Android (gestos vs botones)
/// usando [MediaQuery.viewPadding.bottom].
class CustomBottomNav extends StatelessWidget {
  /// Crea una barra de navegación con el [currentIndex] seleccionado
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

    // Espacio inferior según navegación Android (gestos vs botones)
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final bottomMargin = bottomInset > 0 ? bottomInset + 4 : 12.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              // Fondo translúcido para efecto glass
              color: isDark
                  ? const Color(0xFF1A1A1A).withValues(alpha: 0.92)
                  : const Color(0xFFF4F7F2).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                  blurRadius: 28,
                  spreadRadius: -2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Builder(builder: (context) {
              final s = S.of(context);
              return Row(
                children: [
                  _NavItem(index: 0, currentIndex: currentIndex, icon: Icons.play_circle_outline_rounded, activeIcon: Icons.play_circle_rounded, color: const Color(0xFFE53935), label: s.tabYouTube, onTap: onIndexChanged),
                  _NavItem(index: 1, currentIndex: currentIndex, icon: Icons.slow_motion_video_outlined, activeIcon: Icons.slow_motion_video_rounded, color: const Color(0xFFFF6D00), label: s.tabShorts, onTap: onIndexChanged),
                  _NavItem(index: 2, currentIndex: currentIndex, icon: Icons.music_note_outlined, activeIcon: Icons.music_note_rounded, color: const Color(0xFF1E88E5), label: s.tabMusic, onTap: onIndexChanged),
                  _NavItem(index: 3, currentIndex: currentIndex, icon: Icons.video_library_outlined, activeIcon: Icons.video_library_rounded, color: const Color(0xFFFB8C00), label: s.tabVideos, onTap: onIndexChanged),
                  _NavItem(index: 4, currentIndex: currentIndex, icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, color: const Color(0xFF78909C), label: s.settingsTitle, onTap: onIndexChanged),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Item de navegación solo icono con pill animado
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
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.5);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Vibración sutil al cambiar de pestaña
          HapticFeedback.selectionClick();
          onTap(index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                size: isSelected ? 26 : 23,
                color: isSelected ? color : inactiveColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
