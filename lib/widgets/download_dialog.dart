/// Diálogo de descarga con campo de URL y botones MP3/MP4.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';

/// Diálogo para ingresar una URL de YouTube y elegir formato MP3 o MP4.
///
/// Incluye campo de texto con botón de pegar desde portapapeles.
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
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título con icono y botón cerrar
            Row(
              children: [
                const Icon(Icons.download_rounded,
                    color: Color(0xFF2E7D32), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.downloadDialogTitle,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campo de texto para el link
            TextField(
              controller: widget.urlController,
              decoration: InputDecoration(
                hintText: s.downloadUrlHint,
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                prefixIcon:
                    const Icon(Icons.link, color: Color(0xFF2E7D32)),
                suffixIcon: IconButton(
                  tooltip: s.clearTooltip,
                  onPressed: () => widget.urlController.clear(),
                  icon: const Icon(Icons.clear, size: 20),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF2E7D32), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              keyboardType: TextInputType.url,
              maxLines: 1,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Botón de pegar desde portapapeles
            OutlinedButton.icon(
              onPressed: _pasteFromClipboard,
              icon: const Icon(Icons.content_paste, size: 20),
              label: Text(s.pasteClipboard),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
                side: const BorderSide(color: Color(0xFF2E7D32)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            // Botones de descarga MP4 y MP3
            Row(
              children: [
                // Botón MP4
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _hasUrl
                        ? () => Navigator.pop(context, {
                              'url': widget.urlController.text.trim(),
                              'type': 'video',
                            })
                        : null,
                    icon: const Icon(Icons.movie_creation_outlined, size: 20),
                    label: const Text('MP4'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      disabledBackgroundColor:
                          colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Botón MP3
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _hasUrl
                        ? () => Navigator.pop(context, {
                              'url': widget.urlController.text.trim(),
                              'type': 'audio',
                            })
                        : null,
                    icon: const Icon(Icons.graphic_eq, size: 20),
                    label: const Text('MP3'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      disabledBackgroundColor:
                          colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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
