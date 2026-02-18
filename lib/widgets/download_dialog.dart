/// Diálogo de descarga con campo de URL y botones MP3/MP4.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';
import '../theme.dart';

/// Diálogo para ingresar una URL de YouTube y elegir formato MP3 o MP4.
///
/// Botones tipo píldora negros/oscuros para MP4 y MP3.
/// Retorna un Map con 'url' y 'type' ('audio' o 'video') al confirmar,
/// o null si se cancela.
class DownloadDialog extends StatefulWidget {
  /// Crea el diálogo con un [urlController] externo para pre-llenar la URL
  const DownloadDialog({required this.urlController, super.key});

  /// Controlador del campo de texto (manejado externamente para pre-llenar)
  final TextEditingController urlController;

  @override
  State<DownloadDialog> createState() => _DownloadDialogState();
}

/// Estado del diálogo de descarga
class _DownloadDialogState extends State<DownloadDialog> {
  bool _hasUrl = false;

  @override
  void initState() {
    super.initState();
    _hasUrl = widget.urlController.text.trim().isNotEmpty;
    widget.urlController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.urlController.removeListener(_onTextChanged);
    super.dispose();
  }

  /// Actualiza el estado cuando cambia el texto del campo
  void _onTextChanged() {
    final has = widget.urlController.text.trim().isNotEmpty;
    if (has != _hasUrl) setState(() => _hasUrl = has);
  }

  /// Pega el contenido del portapapeles en el campo
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      widget.urlController.text = data.text!.trim();
      widget.urlController.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.urlController.text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Colores del botón primario adaptados al tema
    final btnBg = isDark ? ShemaColors.buttonDark : ShemaColors.buttonLight;
    final btnFg = isDark ? const Color(0xFF0A0A0A) : Colors.white;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado: ícono + título + cerrar
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: ShemaColors.seed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.download_rounded,
                      color: ShemaColors.seed, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.downloadDialogTitle,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800,
                        letterSpacing: -0.4),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.close, size: 18,
                        color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Campo de texto para el link
            TextField(
              controller: widget.urlController,
              decoration: InputDecoration(
                hintText: s.downloadUrlHint,
                prefixIcon: const Icon(Icons.link_rounded,
                    color: ShemaColors.seed, size: 20),
                suffixIcon: IconButton(
                  tooltip: s.clearTooltip,
                  onPressed: () => widget.urlController.clear(),
                  icon: Icon(Icons.clear_rounded, size: 18,
                      color: colorScheme.onSurfaceVariant),
                ),
              ),
              keyboardType: TextInputType.url,
              maxLines: 1,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),

            // Botón de pegar desde portapapeles
            GestureDetector(
              onTap: _pasteFromClipboard,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? ShemaColors.darkBorder : ShemaColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.content_paste_rounded, size: 18,
                        color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      s.pasteClipboard,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botones MP4 y MP3 — estilo píldora negro
            Row(
              children: [
                // MP4
                Expanded(
                  child: _DownloadButton(
                    icon: Icons.videocam_rounded,
                    label: 'MP4',
                    sublabel: 'Video',
                    enabled: _hasUrl,
                    bgColor: btnBg,
                    fgColor: btnFg,
                    accentColor: ShemaColors.youtubeRed,
                    onTap: () => Navigator.pop(context, {
                      'url': widget.urlController.text.trim(),
                      'type': 'video',
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                // MP3
                Expanded(
                  child: _DownloadButton(
                    icon: Icons.graphic_eq_rounded,
                    label: 'MP3',
                    sublabel: 'Audio',
                    enabled: _hasUrl,
                    bgColor: btnBg,
                    fgColor: btnFg,
                    accentColor: ShemaColors.musicBlue,
                    onTap: () => Navigator.pop(context, {
                      'url': widget.urlController.text.trim(),
                      'type': 'audio',
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón de descarga con ícono, etiqueta y subetiqueta de formato
class _DownloadButton extends StatelessWidget {
  const _DownloadButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.enabled,
    required this.bgColor,
    required this.fgColor,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final bool enabled;
  final Color bgColor;
  final Color fgColor;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Ícono con fondo de acento
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  color: fgColor.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
