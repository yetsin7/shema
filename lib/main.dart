/// Punto de entrada principal de la aplicación Shema.
/// Configura temas, idiomas y navegación raíz.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';

/// Función principal que lanza la app
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Barra de navegación del sistema opaca
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0xFFF4F7F2),
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const ShemaApp());
}

/// Widget raíz de la aplicación con soporte de tema e idioma persistentes
class ShemaApp extends StatefulWidget {
  const ShemaApp({super.key});

  /// Permite acceder al estado desde cualquier parte del árbol
  static ShemaAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<ShemaAppState>();

  @override
  State<ShemaApp> createState() => ShemaAppState();
}

/// Estado del widget raíz que maneja tema e idioma
class ShemaAppState extends State<ShemaApp> {
  static const _themePrefKey = 'theme_mode';
  static const _localePrefKey = 'locale_code';

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPreferences());
  }

  /// Carga las preferencias de tema e idioma guardadas
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_themePrefKey);
    final localeStr = prefs.getString(_localePrefKey);

    if (!mounted) return;
    setState(() {
      _themeMode = switch (themeStr) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      _locale = (localeStr != null && localeStr != 'system')
          ? Locale(localeStr)
          : null;
    });
  }

  /// Cambia el tema y lo persiste
  Future<void> setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await prefs.setString(_themePrefKey, value);
  }

  /// Cambia el idioma y lo persiste (null = sistema)
  Future<void> setLocale(Locale? locale) async {
    setState(() => _locale = locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localePrefKey, locale?.languageCode ?? 'system');
  }

  /// Getter del modo de tema actual
  ThemeMode get themeMode => _themeMode;

  /// Getter del idioma actual (null = sistema)
  Locale? get locale => _locale;

  @override
  Widget build(BuildContext context) {
    // Actualizar color de barra de navegación del sistema según tema
    final isDark = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F7F2),
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shema',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: _themeMode,
      locale: _locale,
      localizationsDelegates: const [
        SDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es'), Locale('en')],
      home: const SplashScreen(),
    );
  }
}
