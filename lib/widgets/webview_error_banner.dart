/// Banner de error para WebView con botón de recarga.
library;

import 'package:flutter/material.dart';

/// Banner rojo posicionado en la parte inferior que muestra un error del WebView
class WebViewErrorBanner extends StatelessWidget {
  const WebViewErrorBanner({
    required this.message,
    required this.onReload,
    super.key,
  });

  /// Mensaje de error a mostrar
  final String message;

  /// Callback al presionar el botón de recargar
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.red.shade100,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.red.shade900, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onReload,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Recargar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
