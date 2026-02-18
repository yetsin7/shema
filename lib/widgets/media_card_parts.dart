/// Componentes auxiliares para la tarjeta de medios: header showcase, chips y estado.
library;

import 'package:flutter/material.dart';
import '../services/download_service.dart';
import '../theme.dart';

/// Construye la cabecera compacta de 60px de la tarjeta showcase.
///
/// Icono del tipo de medio a la izquierda, título con scroll marquee al centro,
/// badge de estado a la derecha. Fondo de gradiente o thumbnail.
Widget buildCardHeader({
  required BuildContext context,
  required bool isAudio,
  required Color accentColor,
  required String title,
  required Widget statusBadge,
  DownloadTask? task,
}) {
  final thumbUrl = task?.thumbnailUrl ?? '';
  final hasThumbnail = !isAudio && thumbUrl.isNotEmpty;

  final Color gradTop = isAudio
      ? accentColor
      : accentColor.withValues(alpha: 0.95);
  final Color gradBottom = HSLColor.fromColor(accentColor)
      .withLightness(
          (HSLColor.fromColor(accentColor).lightness - (isAudio ? 0.18 : 0.14))
              .clamp(0.0, 1.0))
      .toColor();

  const titleStyle = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.0,
    shadows: [Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 1))],
  );

  return ClipRRect(
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(ShemaRadius.card),
      topRight: Radius.circular(ShemaRadius.card),
    ),
    child: SizedBox(
      height: 60,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo: thumbnail o gradiente
          if (hasThumbnail)
            Image.network(
              thumbUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildGradient(gradTop, gradBottom),
            )
          else
            _buildGradient(gradTop, gradBottom),

          // Scrim de legibilidad sobre toda la cabecera
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),

          // Fila: icono | título marquee | badge
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icono del tipo de medio — fondo blanco sólido con ícono de color
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      isAudio
                          ? Icons.graphic_eq_rounded
                          : Icons.movie_creation_outlined,
                      color: accentColor,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Título con efecto marquee (scroll horizontal si no cabe)
                  Expanded(child: _MarqueeText(text: title, style: titleStyle)),
                  const SizedBox(width: 6),
                  statusBadge,
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Fondo de gradiente diagonal para la cabecera
Widget _buildGradient(Color top, Color bottom) {
  return DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [top, bottom],
      ),
    ),
  );
}

/// Texto con efecto marquee: espera 1.5s al entrar, luego scroll continuo,
/// pausa 1s al completar cada ciclo completo.
///
/// Si el texto cabe en el ancho se muestra estático.
/// Si no cabe, aguarda 1.5s (para que el usuario pueda leer el título al llegar
/// a la pantalla), luego empieza a desplazarse. Al completar un ciclo pausa 1s
/// y repite. Un ClipRect evita que el texto pinte sobre el icono a su izquierda.
class _MarqueeText extends StatefulWidget {
  const _MarqueeText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  /// Velocidad de desplazamiento en píxeles por segundo
  static const _speed = 38.0;

  /// Espacio entre el final del texto y el inicio de la siguiente copia
  static const _gap = 44.0;

  bool _loopStarted = false;

  /// Incrementar al resetear invalida cualquier _runLoop anterior en vuelo
  int _generation = 0;

  /// Estado anterior del TickerMode para detectar cuando el tab se vuelve visible
  /// Inicia en true para que el primer didChangeDependencies no dispare un reset
  bool _tickerWasEnabled = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = TickerMode.of(context);
    // Cuando el tab pasa de oculto a visible, reiniciar el marquee con delay
    if (enabled && !_tickerWasEnabled) {
      _resetMarquee();
    }
    _tickerWasEnabled = enabled;
  }

  /// Detiene la animación y restablece el estado para el próximo delay inicial
  void _resetMarquee() {
    _generation++;
    _ctrl.stop();
    _ctrl.reset();
    _loopStarted = false;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _startLoop(double cycleW) {
    if (_loopStarted) return;
    _loopStarted = true;
    _ctrl.duration = Duration(milliseconds: (cycleW / _speed * 1000).round());
    _runLoop(_generation);
  }

  Future<void> _runLoop(int gen) async {
    if (!mounted || gen != _generation) return;
    // Pausa de 1.5s al llegar: el usuario puede leer el título antes de que empiece a moverse
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted || gen != _generation) return;
    // Desplaza un ciclo completo (texto + hueco)
    try {
      await _ctrl.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted || gen != _generation) return;
    // Pausa 1s cuando la primera letra está de nuevo en la posición del icono
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted || gen != _generation) return;
    _ctrl.reset();
    _runLoop(gen);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final tp = TextPainter(
        text: TextSpan(text: widget.text, style: widget.style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(minWidth: 0, maxWidth: double.infinity);

      final textW = tp.width;
      final boxW = constraints.maxWidth;

      if (textW <= boxW) {
        return Text(widget.text, style: widget.style, maxLines: 1);
      }

      // Un ciclo completo = ancho del texto + hueco hasta la siguiente copia
      const gap = _gap;
      final cycleW = textW + gap;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startLoop(cycleW);
      });

      // ClipRect garantiza que el texto animado no pinte fuera de su área
      // y no se superponga sobre el icono a la izquierda
      return ClipRect(
        child: ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.white, Colors.white, Colors.transparent],
            stops: [0.0, 0.82, 1.0],
          ).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Placeholder invisible que le da altura al Stack
              Opacity(
                opacity: 0,
                child: Text(widget.text, style: widget.style, maxLines: 1),
              ),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, _) {
                    final shift = _ctrl.value * cycleW;
                    return OverflowBox(
                      alignment: Alignment.centerLeft,
                      maxWidth: double.infinity,
                      child: Transform.translate(
                        offset: Offset(-shift, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(widget.text,
                                style: widget.style,
                                maxLines: 1,
                                softWrap: false),
                            SizedBox(width: gap),
                            // Segunda copia: aparece por la derecha cuando la
                            // primera sale por la izquierda (loop seamless)
                            Text(widget.text,
                                style: widget.style,
                                maxLines: 1,
                                softWrap: false),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Construye un chip de metadatos (calidad, formato, tamaño, fecha)
Widget buildMetaChip(
  BuildContext context, {
  required IconData icon,
  required String label,
  required Color iconColor,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: isDark ? ShemaColors.darkCardElevated : ShemaColors.lightBg,
      borderRadius: BorderRadius.circular(ShemaRadius.chip),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: iconColor.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

/// Construye el badge de estado (en cola, descargando, completado, error)
///
/// [compact] = true para el badge de esquina dentro del header de la card.
Widget buildStatusChip(
  BuildContext context, {
  required String label,
  required bool failed,
  required bool completed,
  required bool queued,
  required Color iconColor,
  bool compact = false,
}) {
  final Color base = failed
      ? const Color(0xFFEF4444)
      : completed
          ? ShemaColors.seed
          : queued
              ? const Color(0xFF8E8E93)
              : iconColor;

  final hPad = compact ? 7.0 : 9.0;
  final vPad = compact ? 3.0 : 4.0;

  final bgAlpha = compact ? 0.85 : 0.14;
  final fgColor = compact ? Colors.white : base;
  final bgColor = compact ? Colors.black.withValues(alpha: bgAlpha) : base.withValues(alpha: bgAlpha);

  return Container(
    padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(compact ? 6 : 8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (failed) ...[
          Icon(Icons.error_outline_rounded, size: 11, color: fgColor),
          const SizedBox(width: 3),
        ] else if (completed && !compact) ...[
          Icon(Icons.check_circle_outline_rounded, size: 11, color: fgColor),
          const SizedBox(width: 3),
        ],
        Text(
          label,
          style: TextStyle(
            color: fgColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
