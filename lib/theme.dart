/// Definición de temas claro y oscuro para la app Shema.
///
/// Sistema de diseño moderno inspirado en apps premium:
/// fondos muy limpios, tarjetas flotantes, botones tipo píldora negros.
library;

import 'package:flutter/material.dart';

/// Paleta de colores de marca y sistema de diseño de Shema.
class ShemaColors {
  /// Verde principal — acento y seed de Material 3
  static const seed = Color(0xFF16A34A);

  /// Rojo YouTube para la pestaña principal
  static const youtubeRed = Color(0xFFEF4444);

  /// Naranja para la pestaña de Shorts
  static const shortsOrange = Color(0xFFF97316);

  /// Azul para la pestaña de música
  static const musicBlue = Color(0xFF3B82F6);

  /// Ámbar para la pestaña de videos
  static const videoCoral = Color(0xFFE11D48);

  // ── Light mode ─────────────────────────────────────
  /// Fondo general claro (iOS-like off-white)
  static const lightBg = Color(0xFFF2F2F7);

  /// Superficie de tarjeta en modo claro
  static const lightCard = Color(0xFFFFFFFF);

  /// Borde suave en modo claro
  static const lightBorder = Color(0xFFE5E5EA);

  // ── Dark mode ──────────────────────────────────────
  /// Fondo general oscuro (negro profundo)
  static const darkBg = Color(0xFF121212);

  /// Superficie de tarjeta en modo oscuro (iOS dark)
  static const darkCard = Color(0xFF252528);

  /// Superficie elevada en modo oscuro
  static const darkCardElevated = Color(0xFF333336);

  /// Borde sutil en modo oscuro
  static const darkBorder = Color(0xFF3A3A3C);

  // ── Botones primarios ──────────────────────────────
  /// Botón primario en modo claro (negro píldora)
  static const buttonLight = Color(0xFF1C1C1E);

  /// Botón primario en modo oscuro (blanco píldora)
  static const buttonDark = Color(0xFFF5F5F5);

  // Alias legacy para compatibilidad
  static const seedColor = seed;
  static const musicBlueOld = Color(0xFF1565C0);
  static const videoOrange = Color(0xFFEF6C00);
}

/// Genera el tema claro — fondo #F2F2F7, tarjetas blancas, tipografía oscura.
ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: ShemaColors.seed,
    brightness: Brightness.light,
    surface: ShemaColors.lightCard,
    surfaceContainerLowest: ShemaColors.lightBg,
    surfaceContainerLow: const Color(0xFFEFEFF4),
    surfaceContainer: ShemaColors.lightCard,
    surfaceContainerHigh: const Color(0xFFE8E8ED),
    surfaceContainerHighest: const Color(0xFFDFDFE4),
    outline: ShemaColors.lightBorder,
    outlineVariant: const Color(0xFFD1D1D6),
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: ShemaColors.lightBg,
    fontFamily: null, // usa la fuente del sistema

    // AppBar sin elevación, casi transparente
    appBarTheme: AppBarTheme(
      backgroundColor: ShemaColors.lightBg.withValues(alpha: 0.94),
      foregroundColor: const Color(0xFF1C1C1E),
      iconTheme: const IconThemeData(color: Color(0xFF1C1C1E)),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: const TextStyle(
        color: Color(0xFF1C1C1E),
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),

    // Tarjetas blancas sin elevación, borde sutil
    cardTheme: CardThemeData(
      color: ShemaColors.lightCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: ShemaColors.lightBorder),
      ),
    ),

    // Botones rellenos negros (estilo premium)
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ShemaColors.buttonLight,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),

    // Botones de contorno con borde sutil
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1C1C1E),
        side: const BorderSide(color: ShemaColors.lightBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),

    // SnackBars flotantes
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1C1C1E),
      contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 88),
    ),

    // Diálogos redondeados
    dialogTheme: DialogThemeData(
      backgroundColor: ShemaColors.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
    ),

    // Inputs limpios
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ShemaColors.lightBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ShemaColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ShemaColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ShemaColors.seed, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

/// Genera el tema oscuro — fondo #0A0A0A, tarjetas #1C1C1E, tipografía clara.
ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: ShemaColors.seed,
    brightness: Brightness.dark,
    surface: ShemaColors.darkCard,
    surfaceContainerLowest: ShemaColors.darkBg,
    surfaceContainerLow: const Color(0xFF111111),
    surfaceContainer: ShemaColors.darkCard,
    surfaceContainerHigh: ShemaColors.darkCardElevated,
    surfaceContainerHighest: const Color(0xFF3A3A3C),
    outline: ShemaColors.darkBorder,
    outlineVariant: const Color(0xFF48484A),
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: ShemaColors.darkBg,
    fontFamily: null,

    // AppBar oscuro semi-transparente
    appBarTheme: AppBarTheme(
      backgroundColor: ShemaColors.darkBg.withValues(alpha: 0.94),
      foregroundColor: const Color(0xFFF5F5F5),
      iconTheme: const IconThemeData(color: Color(0xFFF5F5F5)),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: const TextStyle(
        color: Color(0xFFF5F5F5),
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),

    // Tarjetas oscuras con borde sutil
    cardTheme: CardThemeData(
      color: ShemaColors.darkCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: ShemaColors.darkBorder),
      ),
    ),

    // Botones rellenos blancos (oscuro)
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ShemaColors.buttonDark,
        foregroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),

    // Botones de contorno en modo oscuro
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFF5F5F5),
        side: const BorderSide(color: ShemaColors.darkBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),

    // SnackBars flotantes en oscuro
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ShemaColors.darkCardElevated,
      contentTextStyle: const TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 88),
    ),

    // Diálogos oscuros redondeados
    dialogTheme: DialogThemeData(
      backgroundColor: ShemaColors.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
    ),

    // Inputs oscuros
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF111111),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ShemaColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ShemaColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ShemaColors.seed, width: 2),
      ),
      hintStyle: const TextStyle(color: Color(0xFF8D8D93)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// Sistema de diseño — tokens de radio, sombra y elevación
// ══════════════════════════════════════════════════════════════

/// Radios de borde estándar del sistema de diseño Shema
class ShemaRadius {
  /// Tarjetas showcase (media cards)
  static const double card = 24.0;

  /// Chips de metadatos
  static const double chip = 8.0;

  /// Botones de acción
  static const double button = 14.0;

  /// Píldoras (bottom nav, pill buttons)
  static const double pill = 50.0;

  /// Contenedores generales (settings cards, etc.)
  static const double container = 18.0;

  /// Headers y secciones
  static const double header = 16.0;
}

/// Sombras estándar del sistema de diseño Shema
class ShemaShadow {
  /// Sombra profunda con tinte de color — para tarjetas showcase
  static List<BoxShadow> deep({bool isDark = false, Color? tintColor}) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.13),
      blurRadius: 24,
      spreadRadius: -4,
      offset: const Offset(0, 8),
    ),
    if (tintColor != null)
      BoxShadow(
        color: tintColor.withValues(alpha: isDark ? 0.18 : 0.10),
        blurRadius: 20,
        spreadRadius: -6,
        offset: const Offset(0, 10),
      ),
  ];

  /// Sombra media — para cards interactivas
  static List<BoxShadow> medium({bool isDark = false}) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.09),
      blurRadius: 16,
      spreadRadius: -3,
      offset: const Offset(0, 5),
    ),
  ];

  /// Sombra sutil — para elementos en reposo
  static List<BoxShadow> subtle({bool isDark = false}) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
      blurRadius: 10,
      spreadRadius: -2,
      offset: const Offset(0, 3),
    ),
  ];
}
