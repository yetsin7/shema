package com.cocibolka.shema

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import com.yausername.ffmpeg.FFmpeg
import kotlinx.coroutines.*
import java.io.File
import android.util.Log

private const val TAG = "Shema_YtDlp"

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.cocibolka.shema/ytdlp"
    private val EVENT_CHANNEL = "com.cocibolka.shema/ytdlp_progress"
    private var eventSink: EventChannel.EventSink? = null
    private val downloadJobs = mutableMapOf<String, Job>()
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Inicializar youtubedl-android y ffmpeg
        try {
            YoutubeDL.getInstance().init(this)
            FFmpeg.getInstance().init(this)
            Log.d(TAG, "YoutubeDL y FFmpeg inicializados correctamente")
        } catch (e: Exception) {
            Log.e(TAG, "Error al inicializar YoutubeDL/FFmpeg", e)
        }


        // Canal de mÃ©todos para control de descargas
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "downloadMedia" -> {
                        val url = call.argument<String>("url") ?: ""
                        val quality = call.argument<String>("quality") ?: "720p"
                        val downloadPath = call.argument<String>("downloadPath") ?: ""
                        val isAudio = call.argument<Boolean>("isAudio") ?: false
                        val downloadId = System.currentTimeMillis().toString()
                        startDownload(downloadId, url, quality, downloadPath, isAudio)
                        result.success(downloadId)
                    }
                    "getVideoInfo" -> {
                        val url = call.argument<String>("url") ?: ""
                        getVideoInfo(url, result)
                    }
                    "cancelDownload" -> {
                        val downloadId = call.argument<String>("downloadId") ?: ""
                        cancelDownload(downloadId)
                        result.success(true)
                    }
                    "updateYtDlp" -> {
                        updateYtDlp(result)
                    }
                    else -> result.notImplemented()
                }
            }

        // Canal de eventos para progreso en tiempo real
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    /// Inicia la descarga de un video o audio usando yt-dlp
    private fun startDownload(
        downloadId: String,
        url: String,
        quality: String,
        downloadPath: String,
        isAudio: Boolean
    ) {
        val job = scope.launch {
            try {
                Log.d(TAG, "=== DESCARGA INICIADA ===")
                Log.d(TAG, "ID: $downloadId")
                Log.d(TAG, "URL: $url")
                Log.d(TAG, "Calidad: $quality")
                Log.d(TAG, "Ruta: $downloadPath")
                Log.d(TAG, "Es audio: $isAudio")

                val request = YoutubeDLRequest(url)
                val outputDir = File(downloadPath)
                if (!outputDir.exists()) outputDir.mkdirs()
                Log.d(TAG, "Directorio existe: ${outputDir.exists()}, escribible: ${outputDir.canWrite()}")

                if (isAudio) {
                    request.addOption("-x")
                    request.addOption("--audio-format", "mp3")
                    val audioKbps = quality.replace("kbps", "", ignoreCase = true).trim().toIntOrNull()
                    val audioQuality = if (audioKbps != null && audioKbps > 0) "${audioKbps}K" else "0"
                    request.addOption("--audio-quality", audioQuality)
                    request.addOption("--embed-thumbnail")
                    Log.d(TAG, "Modo: AUDIO (MP3), calidad: $audioQuality")
                } else {
                    // Descargar video y audio por separado, luego combinar con ffmpeg
                    val height = quality.replace("p", "").toIntOrNull() ?: 720
                    val formatStr = "bestvideo[height<=${height}]+bestaudio/best[height<=${height}]"
                    request.addOption("-f", formatStr)
                    request.addOption("--merge-output-format", "mp4")
                    Log.d(TAG, "Modo: VIDEO, formato: $formatStr (merge a mp4 con ffmpeg)")
                }

                request.addOption("--no-mtime")
                request.addOption("--no-post-overwrites")
                request.addOption("--no-playlist")
                request.addOption("--no-warnings")
                request.addOption("--newline")
                request.addOption("-o", "${outputDir.absolutePath}/%(title)s.%(ext)s")

                sendEvent(mapOf(
                    "downloadId" to downloadId,
                    "progress" to 0.0,
                    "status" to "downloading",
                    "line" to "Iniciando descarga..."
                ))

                Log.d(TAG, "Ejecutando YoutubeDL.execute()...")
                val response = YoutubeDL.getInstance().execute(request, downloadId) { progress, etaInSeconds, line ->
                    Log.d(TAG, "Progreso: $progress%, ETA: ${etaInSeconds}s, lÃ­nea: $line")
                    sendEvent(mapOf(
                        "downloadId" to downloadId,
                        "progress" to progress.toDouble(),
                        "eta" to etaInSeconds,
                        "status" to "downloading",
                        "line" to (line ?: "")
                    ))
                }

                Log.d(TAG, "=== EJECUCIÃ“N COMPLETADA ===")
                Log.d(TAG, "Exit code: ${response.exitCode}")
                Log.d(TAG, "Stdout: ${response.out}")
                Log.d(TAG, "Stderr: ${response.err}")

                // Buscar el archivo descargado
                val downloadedFile = outputDir.listFiles()
                    ?.filter { it.isFile && it.lastModified() > System.currentTimeMillis() - 120000 }
                    ?.maxByOrNull { it.lastModified() }

                Log.d(TAG, "Archivo encontrado: ${downloadedFile?.absolutePath ?: "NINGUNO"}")
                Log.d(TAG, "Archivos en dir: ${outputDir.listFiles()?.map { it.name }}")

                sendEvent(mapOf(
                    "downloadId" to downloadId,
                    "progress" to 100.0,
                    "status" to "completed",
                    "filePath" to (downloadedFile?.absolutePath ?: ""),
                    "fileName" to (downloadedFile?.name ?: ""),
                    "line" to "Descarga completada"
                ))

            } catch (e: Exception) {
                Log.e(TAG, "=== ERROR EN DESCARGA ===", e)
                Log.e(TAG, "Mensaje: ${e.message}")
                Log.e(TAG, "Causa: ${e.cause}")
                sendEvent(mapOf(
                    "downloadId" to downloadId,
                    "progress" to 0.0,
                    "status" to "failed",
                    "error" to (e.message ?: "Error desconocido"),
                    "line" to "Error: ${e.message}"
                ))
            } finally {
                downloadJobs.remove(downloadId)
            }
        }

        downloadJobs[downloadId] = job
    }

    /// Obtiene informaciÃ³n del video sin descargarlo
    private fun getVideoInfo(url: String, result: MethodChannel.Result) {
        scope.launch {
            try {
                val request = YoutubeDLRequest(url)
                request.addOption("--dump-json")
                request.addOption("--no-download")
                request.addOption("--no-playlist")
                request.addOption("--no-warnings")
                val response = YoutubeDL.getInstance().execute(request)
                withContext(Dispatchers.Main) {
                    result.success(response.out)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("INFO_ERROR", e.message, null)
                }
            }
        }
    }

    /// Cancela una descarga en progreso
    private fun cancelDownload(downloadId: String) {
        downloadJobs[downloadId]?.cancel()
        downloadJobs.remove(downloadId)
        YoutubeDL.getInstance().destroyProcessById(downloadId)
        sendEvent(mapOf(
            "downloadId" to downloadId,
            "status" to "cancelled",
            "line" to "Descarga cancelada"
        ))
    }

    /// Actualiza yt-dlp a la Ãºltima versiÃ³n
    private fun updateYtDlp(result: MethodChannel.Result) {
        scope.launch {
            try {
                val status = YoutubeDL.getInstance().updateYoutubeDL(applicationContext)
                withContext(Dispatchers.Main) {
                    result.success(status?.name ?: "DONE")
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("UPDATE_ERROR", e.message, null)
                }
            }
        }
    }

    /// EnvÃ­a eventos al canal de Flutter desde cualquier hilo
    private fun sendEvent(data: Map<String, Any?>) {
        runOnUiThread {
            eventSink?.success(data)
        }
    }

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }
}

