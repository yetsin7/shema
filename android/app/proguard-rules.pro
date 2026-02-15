# Reglas de ProGuard/R8 para Shema

# Desactivar ofuscación de nombres (mantiene minificación y tree-shaking)
-dontobfuscate

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# youtubedl-android (yt-dlp) y Python embebido - no ofuscar nada de estas libs
-keep,allowoptimization class com.yausername.youtubedl_android.** { *; }
-keep,allowoptimization class com.yausername.ffmpeg.** { *; }
-keep class com.chaquo.** { *; }
-keep class org.chaquopy.** { *; }
-dontwarn com.chaquo.**

# Chaquopy Python runtime necesita reflexión completa
-keepnames class * implements com.chaquo.python.**
-keepclassmembers class * { @com.chaquo.python.** *; }

# Apache Commons Compress (usado por Chaquopy para descomprimir Python)
-keep class org.apache.commons.compress.** { *; }
-dontwarn org.apache.commons.compress.**
-dontwarn org.tukaani.xz.**

# Coroutines
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# No ofuscar la MainActivity (platform channels)
-keep class com.cocibolka.shema.MainActivity { *; }

# Google Play Core (referenciado por Flutter pero no usado en esta app)
-dontwarn com.google.android.play.core.**
