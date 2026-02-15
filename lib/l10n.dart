import 'package:flutter/widgets.dart';

/// Clase de localizaciÃ³n simple para espaÃ±ol e inglÃ©s
class S {
  S(this.locale);

  final Locale locale;

  /// Obtiene la instancia de S del contexto actual
  static S of(BuildContext context) {
    return Localizations.of<S>(context, S) ?? S(const Locale('es'));
  }

  /// Verifica si el idioma es espaÃ±ol
  bool get _isEs => locale.languageCode == 'es';

  // ===== GENERAL =====
  String get appName => 'Shema';
  String get cancel => _isEs ? 'Cancelar' : 'Cancel';
  String get accept => _isEs ? 'Aceptar' : 'Accept';
  String get delete => _isEs ? 'Eliminar' : 'Delete';
  String get play => _isEs ? 'Reproducir' : 'Play';
  String get retry => _isEs ? 'Reintentar' : 'Retry';
  String get error => 'Error';
  String get completed => _isEs ? 'Completado' : 'Completed';
  String get queued => _isEs ? 'En cola' : 'Queued';

  // ===== SPLASH =====
  String get splashSubtitle =>
      _isEs ? 'Descarga tus videos favoritos' : 'Download your favorite videos';
  String get splashInitializing => _isEs ? 'Iniciando...' : 'Starting...';
  String get splashLoadingYouTube =>
      _isEs ? 'Cargando YouTube...' : 'Loading YouTube...';
  String get splashReady => _isEs ? 'Listo!' : 'Ready!';

  // ===== NAVEGACIÃ“N =====
  String get tabYouTube => 'YouTube';
  String get tabShorts => 'Shorts';
  String get tabMusic => _isEs ? 'Mi mÃºsica' : 'My music';
  String get tabVideos => _isEs ? 'Mis videos' : 'My videos';

  // ===== DESCARGAS =====
  String get downloadTooltip => _isEs ? 'Descargar' : 'Download';
  String get searchYouTube => _isEs ? 'Buscar en YouTube' : 'Search YouTube';
  String get downloadSettingsTooltip =>
      _isEs ? 'Configurar descargas' : 'Download settings';
  String get backTooltip => _isEs ? 'Volver atrÃ¡s' : 'Go back';
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
      _isEs ? 'Esperando (lÃ­mite del sitio)...' : 'Waiting (site limit)...';
  String get convertingToMp3 =>
      _isEs ? 'Convirtiendo a MP3...' : 'Converting to MP3...';
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
      ? 'La música y los videos se guardan en carpetas separadas para mantener el orden.'
      : 'Music and videos are saved in separate folders to keep things organized.';

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
      _isEs ? 'El archivo aÃºn no estÃ¡ disponible.' : 'File not available yet.';
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

  // ===== ELIMINAR =====
  String get deleteFileTitle =>
      _isEs ? 'Eliminar archivo' : 'Delete file';
  String deleteFileConfirm(String name) => _isEs
      ? 'Â¿Eliminar "$name"? Esta acciÃ³n no se puede deshacer.'
      : 'Delete "$name"? This action cannot be undone.';
  String get fileDeleted =>
      _isEs ? 'Archivo eliminado.' : 'File deleted.';
  String get downloadFailed =>
      _isEs ? 'No se pudo completar la descarga.' : 'Download failed.';
}

/// Delegate para el sistema de localizaciÃ³n de Flutter
class SDelegate extends LocalizationsDelegate<S> {
  const SDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['es', 'en'].contains(locale.languageCode);

  @override
  Future<S> load(Locale locale) async => S(locale);

  @override
  bool shouldReload(SDelegate old) => false;
}




