/// Gestión de selección y caché de calidades de video/audio.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'download_service.dart';
import '../l10n.dart';

/// Opción de calidad disponible para un video o audio
class QualityOption {
  const QualityOption({required this.label, required this.value});

  final String label;
  final String value;
}

/// Gestor de selección de calidades con caché y precarga
class QualityPicker {
  /// Crea un nuevo gestor de calidades
  QualityPicker(this._ytDlp);

  final YtDlpService _ytDlp;

  static const _qualityFetchTimeout = Duration(seconds: 45);
  static const _qualityPrefetchDebounce = Duration(milliseconds: 900);

  final Map<String, List<QualityOption>> _qualityCache = {};
  final Map<String, Future<List<QualityOption>>> _qualityPending = {};

  Timer? _qualityPrefetchTimer;
  String? _lastPrefetchUrl;

  /// Cancela el timer de precarga
  void dispose() {
    _qualityPrefetchTimer?.cancel();
  }

  /// Callback cuando cambia la URL en el WebView de YouTube
  void onWebVideoUrlChanged(String canonicalUrl, bool isLikelyVideo) {
    if (!isLikelyVideo || _lastPrefetchUrl == canonicalUrl) return;

    _lastPrefetchUrl = canonicalUrl;
    _qualityPrefetchTimer?.cancel();
    _qualityPrefetchTimer = Timer(_qualityPrefetchDebounce, () {
      unawaited(_prefetchQualitiesForUrl(canonicalUrl));
    });
  }

  /// Precarga las calidades disponibles para una URL en segundo plano
  Future<void> _prefetchQualitiesForUrl(String url) async {
    try {
      await Future.wait<void>([
        getRealQualities(url, false).then((_) {}),
        getRealQualities(url, true).then((_) {}),
      ]);
    } catch (_) {}
  }

  /// Genera clave de caché para calidades
  String _qualityCacheKey(String url, bool isAudio) =>
      '${isAudio ? 'a' : 'v'}::${url.trim()}';

  /// Obtiene las calidades reales usando caché y evitando peticiones duplicadas
  Future<List<QualityOption>> getRealQualities(String url, bool isAudio) async {
    final key = _qualityCacheKey(url, isAudio);

    final cached = _qualityCache[key];
    if (cached != null && cached.isNotEmpty) {
      debugPrint('[QualityPicker] CACHE HIT for $key (${cached.length} options)');
      return cached;
    }
    debugPrint('[QualityPicker] CACHE MISS for $key (cache keys: ${_qualityCache.keys.toList()})');

    final pending = _qualityPending[key];
    if (pending != null) return pending;

    final future = _fetchRealQualities(url, isAudio).timeout(
      _qualityFetchTimeout,
      onTimeout: () => const <QualityOption>[],
    );

    _qualityPending[key] = future;
    try {
      final result = await future;
      if (result.isNotEmpty) _qualityCache[key] = result;
      return result;
    } finally {
      _qualityPending.remove(key);
    }
  }

  /// Obtiene formatos disponibles llamando a yt-dlp y extrae calidades
  Future<List<QualityOption>> _fetchRealQualities(String url, bool isAudio) async {
    debugPrint('[QualityPicker] Fetching qualities for: $url (isAudio=$isAudio)');
    try {
      final raw = await _ytDlp.getVideoInfo(url);
      debugPrint('[QualityPicker] Response length: ${raw.length}');
      if (raw.trim().isEmpty) {
        debugPrint('[QualityPicker] Empty response from getVideoInfo');
        return const <QualityOption>[];
      }

      final decoded = jsonDecode(raw);
      final root = _extractInfoRoot(decoded);
      if (root == null) {
        debugPrint('[QualityPicker] Could not extract info root');
        return const <QualityOption>[];
      }

      final formats = root['formats'];
      if (formats is! List) {
        debugPrint('[QualityPicker] No formats list found');
        return const <QualityOption>[];
      }

      debugPrint('[QualityPicker] Found ${formats.length} formats');
      final result = isAudio ? _extractAudioQualities(formats) : _extractVideoQualities(formats);
      debugPrint('[QualityPicker] Extracted ${result.length} quality options');
      return result;
    } catch (e) {
      debugPrint('[QualityPicker] Error: $e');
      return const <QualityOption>[];
    }
  }

  /// Extrae calidades de audio de los formatos
  List<QualityOption> _extractAudioQualities(List<dynamic> formats) {
    final bitrates = <int>{};
    for (final item in formats) {
      if (item is! Map) continue;
      final vcodec = item['vcodec']?.toString() ?? '';
      final acodec = item['acodec']?.toString() ?? '';
      if (vcodec != 'none' || acodec.isEmpty || acodec == 'none') continue;

      final abr = _asNum(item['abr']) ?? _asNum(item['tbr']);
      if (abr != null && abr > 0) bitrates.add(abr.round());
    }

    final sorted = bitrates.toList()..sort();
    return sorted
        .map((b) => QualityOption(label: '$b kbps', value: '$b kbps'))
        .toList(growable: false);
  }

  /// Extrae calidades de video de los formatos
  List<QualityOption> _extractVideoQualities(List<dynamic> formats) {
    final heights = <int>{};
    for (final item in formats) {
      if (item is! Map) continue;
      final vcodec = item['vcodec']?.toString() ?? '';
      if (vcodec.isEmpty || vcodec == 'none') continue;
      final height = _asInt(item['height']);
      if (height != null && height > 0) heights.add(height);
    }

    final sorted = heights.toList()..sort();
    return sorted
        .map((h) => QualityOption(label: '${h}p', value: '${h}p'))
        .toList(growable: false);
  }

  /// Muestra diálogo para seleccionar calidad de descarga
  Future<String?> pickQuality(BuildContext context, bool isAudio, String url) async {
    final s = S.of(context);
    var closedByCode = false;
    var cancelledByUser = false;
    var loadingDialogClosed = false;

    final loadingDialogFuture = showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _CountdownLoadingDialog(
        message: s.loadingQualities,
        seconds: 45,
      ),
    ).then((_) {
      loadingDialogClosed = true;
      if (!closedByCode) cancelledByUser = true;
    });

    List<QualityOption> options = const <QualityOption>[];
    try {
      options = await getRealQualities(url, isAudio);
    } catch (_) {} finally {
      await Future<void>.delayed(Duration.zero);
      if (context.mounted && !loadingDialogClosed) {
        closedByCode = true;
        Navigator.of(context, rootNavigator: true).pop();
      }
      await loadingDialogFuture.timeout(const Duration(milliseconds: 300), onTimeout: () {});
    }

    if (cancelledByUser) return null;

    if (options.isEmpty) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.qualityError)));
      return null;
    }

    if (!context.mounted) return null;
    String selected = options.first.value;

    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: Text(isAudio ? S.of(ctx).audioQualityTitle : S.of(ctx).videoQualityTitle),
          content: SizedBox(
            width: double.maxFinite,
            height: 320,
            child: ListView(
              children: options.map((q) {
                final isSelected = selected == q.value;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? const Color(0xFF2E7D32) : null,
                  ),
                  title: Text(q.label),
                  onTap: () => setLocalState(() => selected = q.value),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.of(ctx).cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, selected), child: Text(S.of(ctx).accept)),
          ],
        ),
      ),
    );
  }

  /// Extrae la raíz de información de yt-dlp (maneja playlists)
  Map<String, dynamic>? _extractInfoRoot(dynamic decoded) {
    if (decoded is! Map) return null;
    final root = Map<String, dynamic>.from(decoded);
    final type = root['_type']?.toString();
    final entries = root['entries'];
    if (type == 'playlist' && entries is List && entries.isNotEmpty) {
      final first = entries.first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return root;
  }

  /// Convierte un valor dinámico a num
  num? _asNum(dynamic value) => value is num ? value : (value is String ? num.tryParse(value) : null);

  /// Convierte un valor dinámico a int
  int? _asInt(dynamic value) =>
      value is int ? value : (value is num ? value.toInt() : (value is String ? int.tryParse(value) : null));
}

/// Diálogo de carga con cuenta regresiva
class _CountdownLoadingDialog extends StatefulWidget {
  const _CountdownLoadingDialog({required this.message, required this.seconds});

  final String message;
  final int seconds;

  @override
  State<_CountdownLoadingDialog> createState() => _CountdownLoadingDialogState();
}

class _CountdownLoadingDialogState extends State<_CountdownLoadingDialog> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining > 0) {
        setState(() => _remaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(child: Text(widget.message)),
          Text('${_remaining}s', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
