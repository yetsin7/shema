/// Sistema de internacionalización (i18n) manual para español e inglés.
///
/// Usa la clase [S] para acceder a todas las cadenas traducidas.
/// Usa [SDelegate] como delegate en MaterialApp.localizationsDelegates.
library;

import 'package:flutter/widgets.dart';

/// Clase de localización con todas las cadenas de texto de la app.
///
/// Soporta español (es) e inglés (en). El idioma por defecto es español.
/// Se accede vía [S.of(context)] desde cualquier widget.
class S {
  /// Crea una instancia con el [locale] dado
  S(this.locale);

  /// Idioma activo para esta instancia
  final Locale locale;

  /// Obtiene la instancia de [S] más cercana en el árbol de widgets.
  /// Si no existe, retorna español por defecto.
  static S of(BuildContext context) {
    return Localizations.of<S>(context, S) ?? S(const Locale('es'));
  }

  /// Retorna true si el idioma activo es español
  bool get _isEs => locale.languageCode == 'es';

  // ===== GENERAL =====
  String get appName => 'Shema';
  String get cancel => _isEs ? 'Cancelar' : 'Cancel';
  String get accept => _isEs ? 'Aceptar' : 'Accept';
  String get delete => _isEs ? 'Eliminar' : 'Delete';
  String get play => _isEs ? 'Reproducir' : 'Play';
  String get retry => _isEs ? 'Reintentar' : 'Retry';
  String get error => 'Error';
  String get completed => _isEs ? 'Abrir' : 'Open';
  String get queued => _isEs ? 'En cola' : 'Queued';

  // ===== SPLASH =====
  String get splashSubtitle =>
      _isEs ? 'Descarga tus videos favoritos' : 'Download your favorite videos';
  String get splashInitializing => _isEs ? 'Iniciando...' : 'Starting...';
  String get splashLoadingYouTube =>
      _isEs ? 'Cargando YouTube...' : 'Loading YouTube...';
  String get splashReady => _isEs ? 'Listo!' : 'Ready!';

  // ===== NAVEGACIÓN =====
  String get tabYouTube => 'YouTube';
  String get tabShorts => 'Shorts';
  String get tabMusic => _isEs ? 'Mi música' : 'My music';
  String get tabVideos => _isEs ? 'Mis videos' : 'My videos';

  // ===== DESCARGAS =====
  String get downloadTooltip => _isEs ? 'Descargar' : 'Download';
  String get searchYouTube => _isEs ? 'Buscar en YouTube' : 'Search YouTube';
  String get downloadSettingsTooltip =>
      _isEs ? 'Configurar descargas' : 'Download settings';
  String get backTooltip => _isEs ? 'Volver atrás' : 'Go back';
  String get downloadDialogTitle => _isEs ? 'Descargar' : 'Download';
  String get downloadUrlHint =>
      _isEs ? 'Pega el link del video aqui...' : 'Paste video link here...';
  String get clearTooltip => _isEs ? 'Limpiar' : 'Clear';
  String get pasteClipboard =>
      _isEs ? 'Pegar link del portapapeles' : 'Paste link from clipboard';
  String get cancelDownloadTooltip =>
      _isEs ? 'Cancelar descarga' : 'Cancel download';
  String get shareButton => _isEs ? 'Compartir' : 'Share';

  // ===== ESTADOS DE DESCARGA =====
  String get gettingVideoInfo =>
      _isEs ? 'Obteniendo info del video...' : 'Getting video info...';
  String get waitingSiteLimit =>
      _isEs ? 'Esperando (límite del sitio)...' : 'Waiting (site limit)...';
  String get convertingToMp3 =>
      _isEs ? 'Obteniendo audio...' : 'Getting audio...';
  String get addingMetadata =>
      _isEs ? 'Agregando metadata...' : 'Adding metadata...';
  String get addingCover =>
      _isEs ? 'Agregando portada...' : 'Adding cover art...';
  String get mergingAudioVideo =>
      _isEs ? 'Combinando video y audio...' : 'Merging video and audio...';
  String get startingDownload =>
      _isEs ? 'Iniciando descarga...' : 'Starting download...';
  String downloadStarted(String label, String quality) =>
      _isEs ? 'Descarga iniciada: $label en $quality' : 'Download started: $label at $quality';

  // ===== CALIDAD =====
  String get audioQualityTitle =>
      _isEs ? 'Calidad de audio' : 'Audio quality';
  String get videoQualityTitle =>
      _isEs ? 'Calidad de video' : 'Video quality';
  String get loadingQualities =>
      _isEs ? 'Obteniendo calidades disponibles...' : 'Getting available qualities...';
  String get qualityError =>
      _isEs ? 'No aparecieron calidades disponibles. Intenta nuevamente.' : 'No available qualities found. Please try again.';

  // ===== CARPETA DE DESCARGAS =====
  String get downloadSettingsTitle =>
      _isEs ? 'Configuración de descargas' : 'Download settings';
  String get currentFolder => _isEs ? 'Carpeta actual:' : 'Current folder:';
  String get selectFolderInstruction => _isEs
      ? 'Selecciona una nueva carpeta para guardar las descargas.'
      : 'Select a new folder to save downloads.';
  String get selectFolder =>
      _isEs ? 'Seleccionar carpeta' : 'Select folder';
  String get openFolderTooltip =>
      _isEs ? 'Abrir carpeta' : 'Open folder';
  String get selectFolderDialogTitle =>
      _isEs ? 'Selecciona carpeta para descargas' : 'Select download folder';
  String folderSet(String path) =>
      _isEs ? 'Carpeta: $path' : 'Folder: $path';
  String get folderSelectError =>
      _isEs ? 'Error al seleccionar carpeta.' : 'Error selecting folder.';
  String get folderNotConfigured =>
      _isEs ? 'Carpeta no configurada' : 'Folder not configured';
  String get separateFoldersRequired =>
      _isEs ? 'Música y videos deben guardarse en carpetas diferentes.' : 'Music and videos must be saved in different folders.';
  String folderPath(String path) =>
      _isEs ? 'Carpeta: $path' : 'Folder: $path';
  String get musicFolder => _isEs ? 'Carpeta de música' : 'Music folder';
  String get videoFolder => _isEs ? 'Carpeta de videos' : 'Video folder';
  String get changeFolder =>
      _isEs ? 'Cambiar carpeta' : 'Change folder';
  String get changeMusicFolder =>
      _isEs ? 'Cambiar carpeta de música' : 'Change music folder';
  String get changeVideoFolder =>
      _isEs ? 'Cambiar carpeta de videos' : 'Change video folder';
  String get downloadSettingsDescription => _isEs
      ? 'Todo se descarga en Download/Shema por defecto. Puedes cambiar las carpetas si lo deseas.'
      : 'Everything downloads to Download/Shema by default. You can change the folders if you want.';

  // ===== BIBLIOTECA =====
  String get musicTitle => _isEs ? 'Música' : 'Music';
  String get videosTitle => 'Videos';
  String get noMusicYet =>
      _isEs ? 'Sin música por ahora' : 'No music yet';
  String get noMusicDescription => _isEs
      ? 'No se encontraron audios en la carpeta configurada.'
      : 'No audio files found in the configured folder.';
  String get noVideosYet =>
      _isEs ? 'Sin videos por ahora' : 'No videos yet';
  String get noVideosDescription => _isEs
      ? 'No se encontraron videos en la carpeta configurada.'
      : 'No video files found in the configured folder.';
  String get fileNotAvailable =>
      _isEs ? 'El archivo aún no está disponible.' : 'File not available yet.';
  String get cantOpenFile =>
      _isEs ? 'No se pudo abrir el archivo.' : 'Could not open file.';
  String get cantOpenFolder =>
      _isEs ? 'No se pudo abrir la carpeta.' : 'Could not open folder.';

  // ===== CONFIGURACIÓN =====
  String get settingsTitle => _isEs ? 'Configuración' : 'Settings';
  String get settingsTooltip => _isEs ? 'Configuración' : 'Settings';
  String get themeSection => _isEs ? 'Apariencia' : 'Appearance';
  String get themeSystem => _isEs ? 'Sistema' : 'System';
  String get themeLight => _isEs ? 'Claro' : 'Light';
  String get themeDark => _isEs ? 'Oscuro' : 'Dark';
  String get languageSection => _isEs ? 'Idioma' : 'Language';
  String get languageSystem => _isEs ? 'Sistema' : 'System';
  String get languageSpanish => _isEs ? 'Español' : 'Spanish';
  String get languageEnglish => _isEs ? 'Inglés' : 'English';
  String get downloadFoldersSection => _isEs ? 'Carpetas de descarga' : 'Download folders';

  // ===== SHEMA PLAYER =====
  String get openInPlayer => _isEs ? 'Shema Player' : 'Shema Player';

  // ===== SETUP INICIAL =====
  String get setupWelcome => _isEs ? 'Bienvenido a Shema' : 'Welcome to Shema';
  String get setupPermissionTitle => _isEs ? 'Permiso de almacenamiento' : 'Storage permission';
  String get setupPermissionDesc => _isEs
      ? 'Shema necesita acceso al almacenamiento para guardar tus descargas de música y videos.'
      : 'Shema needs storage access to save your music and video downloads.';
  String get setupGrantPermission => _isEs ? 'Dar permiso' : 'Grant permission';
  String get setupPermissionGranted => _isEs ? 'Permiso concedido' : 'Permission granted';
  String get setupPermissionDenied => _isEs
      ? 'Sin este permiso no podrás descargar. Toca para intentar de nuevo.'
      : 'Without this permission you cannot download. Tap to try again.';
  String get setupFoldersTitle => _isEs ? 'Tus carpetas de descarga' : 'Your download folders';
  String get setupFoldersCreated => _isEs
      ? 'Se crearon las carpetas donde aparecerán tus descargas:'
      : 'The folders where your downloads will appear have been created:';
  String get setupVideoFolder => _isEs ? 'Videos' : 'Videos';
  String get setupMusicFolder => _isEs ? 'Música' : 'Music';
  String get setupChangeable => _isEs
      ? 'Puedes cambiar estas ubicaciones en cualquier momento desde Configuración.'
      : 'You can change these locations anytime from Settings.';
  String get setupStart => _isEs ? 'Empezar' : 'Get started';
  String get setupChangeFolder => _isEs ? 'Cambiar' : 'Change';

  // ===== ELIMINAR =====
  String get deleteFileTitle =>
      _isEs ? 'Eliminar archivo' : 'Delete file';
  String deleteFileConfirm(String name) => _isEs
      ? '¿Eliminar "$name"? Esta acción no se puede deshacer.'
      : 'Delete "$name"? This action cannot be undone.';
  String get fileDeleted =>
      _isEs ? 'Archivo eliminado.' : 'File deleted.';
  String get downloadFailed =>
      _isEs ? 'No se pudo completar la descarga.' : 'Download failed.';
}

/// Delegate que registra [S] en el sistema de localización de Flutter.
///
/// Se usa en MaterialApp.localizationsDelegates para que [S.of(context)]
/// funcione en cualquier widget del árbol.
class SDelegate extends LocalizationsDelegate<S> {
  /// Constructor constante para uso en listas de delegates
  const SDelegate();

  /// Soporta español e inglés
  @override
  bool isSupported(Locale locale) =>
      ['es', 'en'].contains(locale.languageCode);

  /// Carga la instancia de [S] para el idioma dado
  @override
  Future<S> load(Locale locale) async => S(locale);

  /// No necesita recargar al cambiar de delegate
  @override
  bool shouldReload(SDelegate old) => false;
}




