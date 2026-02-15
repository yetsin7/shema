import 'package:flutter/material.dart';

/// Colores base de la app
class ShemaColors {
  static const seedColor = Color(0xFF2E7D32);

  // Colores de marca para las pestañas
  static const youtubeRed = Color(0xFFD32F2F);
  static const shortsOrange = Color(0xFFFF5722);
  static const musicBlue = Color(0xFF1565C0);
  static const videoOrange = Color(0xFFEF6C00);
}

/// Genera el tema claro
ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: ShemaColors.seedColor,
    brightness: Brightness.light,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF4F7F2),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFF4F7F2).withValues(alpha: 0.92),
      foregroundColor: const Color(0xFF1B1B1B),
      iconTheme: const IconThemeData(color: Color(0xFF1B1B1B)),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

/// Genera el tema oscuro
ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: ShemaColors.seedColor,
    brightness: Brightness.dark,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1A1A1A).withValues(alpha: 0.92),
      foregroundColor: const Color(0xFFE8E8E8),
      iconTheme: const IconThemeData(color: Color(0xFFE8E8E8)),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
