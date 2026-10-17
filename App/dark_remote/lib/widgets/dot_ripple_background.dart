import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/theme/app_colors.dart';

class DotRippleBackground extends StatefulWidget {
  const DotRippleBackground({super.key, required this.connected});

  final bool connected;

  @override
  State<DotRippleBackground> createState() => _DotRippleBackgroundState();
}

class _Ripple {
  const _Ripple({
    required this.origin,
    required this.start,
    required this.maxRadius,
    required this.duration,
    required this.strength,
  });

  final Offset origin;
  final Duration start;
  final double maxRadius;
  final Duration duration;
  final double strength;
}

class _DotRippleBackgroundState extends State<DotRippleBackground>
    with TickerProviderStateMixin {
  static const int _maxRipples = 24;
  static const double _dragSpacing = 26;

  late final Ticker _ticker = createTicker(_onTick);
  late final AnimationController _connect = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
    value: widget.connected ? 1.0 : 0.0,
  );
  final ValueNotifier<Duration> _now = ValueNotifier(Duration.zero);
  final List<_Ripple> _ripples = [];
  double _dragAccum = 0;

  @override
  void didUpdateWidget(DotRippleBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.connected != oldWidget.connected) {
      if (widget.connected) {
        _connect.forward();
      } else {
        _ripples.clear();
        _connect.reverse();
      }
    }
  }

  void _addRipple(
    Offset origin, {
    required double maxRadius,
    required Duration duration,
    required double strength,
  }) {
    if (_ripples.length >= _maxRipples) {
      _ripples.removeAt(0);
    }
    final bool wasActive = _ticker.isActive;
    if (!wasActive) {
      _now.value = Duration.zero;
    }
    _ripples.add(
      _Ripple(
        origin: origin,
        start: wasActive ? _now.value : Duration.zero,
        maxRadius: maxRadius,
        duration: duration,
        strength: strength,
      ),
    );
    if (!wasActive) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    _now.value = elapsed;
    _ripples.removeWhere((r) => (elapsed - r.start) > r.duration);
    if (_ripples.isEmpty) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _connect.dispose();
    _now.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        if (!widget.connected) return;
        _dragAccum = 0;
        _addRipple(
          e.localPosition,
          maxRadius: 160,
          duration: const Duration(milliseconds: 900),
          strength: 1.0,
        );
      },
      onPointerMove: (e) {
        if (!widget.connected) return;
        _dragAccum += e.delta.distance;
        if (_dragAccum >= _dragSpacing) {
          _dragAccum = 0;
          _addRipple(
            e.localPosition,
            maxRadius: 90,
            duration: const Duration(milliseconds: 700),
            strength: 0.6,
          );
        }
      },
      child: ColoredBox(
        color: surfaceColor(context),
        child: SizedBox.expand(
          child: CustomPaint(
            painter: _DotRipplePainter(
              ripples: _ripples,
              now: _now,
              connect: _connect,
              surface: surfaceColor(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _DotRipplePainter extends CustomPainter {
  static const double spacing = 14;
  static const double baseRadius = 1.5;
  static const double growRadius = 1.1;
  static const double ringWidth = 40;
  static const double connectEdge = 90;
  static const Color dotDark = Color.fromARGB(255, 0, 0, 0);
  static const Color dotConnected = Color.fromARGB(255, 25, 25, 25);
  static const Color dotPeak = Color.fromARGB(255, 90, 90, 90);
  static const double squircle = 4.5;
  static const double fadeStart = 0.25;
  static const double fadeEnd = 1.20;

  _DotRipplePainter({
    required this.ripples,
    required this.now,
    required this.connect,
    required this.surface,
  }) : super(repaint: Listenable.merge([now, connect]));

  final List<_Ripple> ripples;
  final ValueNotifier<Duration> now;
  final Animation<double> connect;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final current = now.value;
    final center = Offset(size.width / 2, size.height / 2);
    final maxDist = math.sqrt(center.dx * center.dx + center.dy * center.dy);
    final progress = Curves.easeInOutCubic.transform(connect.value);
    final waveRadius = progress * (maxDist + connectEdge);

    for (double y = spacing / 2; y < size.height; y += spacing) {
      for (double x = spacing / 2; x < size.width; x += spacing) {
        final dot = Offset(x, y);
        final signed = waveRadius - (dot - center).distance;
        final edge = (signed / connectEdge).clamp(0.0, 1.0);
        final coverage = edge * edge * (3 - 2 * edge);
        final front = (signed > 0 && signed < connectEdge)
            ? math.sin(math.pi * signed / connectEdge)
            : 0.0;

        double touch = 0;
        for (final r in ripples) {
          final t =
              ((current - r.start).inMicroseconds / r.duration.inMicroseconds)
                  .clamp(0.0, 1.0);
          final d = ((dot - r.origin).distance - t * r.maxRadius).abs();
          if (d < ringWidth) {
            final wave = 0.5 * (1 + math.cos(math.pi * d / ringWidth));
            touch += wave * (1 - t) * r.strength;
          }
        }

        final lit = (touch + front * 0.9).clamp(0.0, 1.0);
        final base = Color.lerp(dotDark, dotConnected, coverage)!;
        final nx = (dot.dx - center.dx).abs() / center.dx;
        final ny = (dot.dy - center.dy).abs() / center.dy;
        final shape = math
            .pow(math.pow(nx, squircle) + math.pow(ny, squircle), 1 / squircle)
            .toDouble();
        final f = ((shape - fadeStart) / (fadeEnd - fadeStart)).clamp(0.0, 1.0);
        final fade = 1 - f * f * (3 - 2 * f);
        final dotColor = Color.lerp(base, dotPeak, lit)!;
        paint.color = Color.lerp(surface, dotColor, fade)!;
        canvas.drawCircle(
          dot,
          (baseRadius + growRadius * lit) * (0.6 + 0.4 * fade),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotRipplePainter oldDelegate) => false;
}
