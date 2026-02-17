/// Diálogo de carga con cuenta regresiva visible.
library;

import 'dart:async';
import 'package:flutter/material.dart';

/// Diálogo de carga con cuenta regresiva en segundos
class CountdownLoadingDialog extends StatefulWidget {
  const CountdownLoadingDialog({
    required this.message,
    required this.seconds,
    super.key,
  });

  /// Mensaje descriptivo mostrado durante la carga
  final String message;

  /// Segundos totales de la cuenta regresiva
  final int seconds;

  @override
  State<CountdownLoadingDialog> createState() => _CountdownLoadingDialogState();
}

/// Estado que gestiona el timer de cuenta regresiva
class _CountdownLoadingDialogState extends State<CountdownLoadingDialog> {
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
          Text(
            '${_remaining}s',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
