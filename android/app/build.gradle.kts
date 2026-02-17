import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Cargar propiedades de firma desde key.properties
val keystorePropertiesFile = rootProject.file("app/key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.cocibolka.shema"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.cocibolka.shema"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            // Solo ARM: x86/x86_64 son para emuladores y duplican el tamaño
            // Para probar en emulador, agregar temporalmente "x86_64"
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
        }
    }

    // Evitar que llvm-strip procese archivos .zip.so (no son binarios nativos reales)
    packaging {
        jniLibs {
            keepDebugSymbols += listOf(
                "**/libffmpeg.zip.so",
                "**/libpython.zip.so"
            )
        }
    }

    if (keystorePropertiesFile.exists()) {
        signingConfigs {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // R8 desactivado: yt-dlp/Chaquopy requieren reflexión completa
            // La ofuscación del código Dart se hace con --obfuscate de Flutter
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

// Suprimir warnings de source/target obsoletos en dependencias compiladas con Java 8
tasks.withType<JavaCompile>().configureEach {
    options.compilerArgs.add("-Xlint:-options")
}

val youtubedlAndroidVersion = "0.18.1"

dependencies {
    implementation("io.github.junkfood02.youtubedl-android:library:$youtubedlAndroidVersion")
    implementation("io.github.junkfood02.youtubedl-android:ffmpeg:$youtubedlAndroidVersion")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
}

