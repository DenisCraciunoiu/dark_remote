import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class TrackpadControls extends StatelessWidget {
  const TrackpadControls({
    super.key,
    required this.onCommand,
    required this.onOpenMenu,
  });

  final ValueChanged<String> onCommand;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: surfaceColor(context),
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _RockerColumn(
              action: _ActionButton(
                icon: Icons.settings,
                tooltip: 'Open menu',
                onPressed: onOpenMenu,
              ),
              rocker: _Rocker(
                topIcon: Icons.add,
                bottomIcon: Icons.remove,
                onTop: () => onCommand('volume_up'),
                onBottom: () => onCommand('volume_down'),
              ),
            ),
            _ClickWheel(onCommand: onCommand),
            _RockerColumn(
              action: _ActionButton(
                icon: Icons.volume_off,
                tooltip: 'Mute',
                onPressed: () => onCommand('mute'),
              ),
              rocker: _Rocker(
                topIcon: Icons.keyboard_arrow_up,
                bottomIcon: Icons.keyboard_arrow_down,
                onTop: () => onCommand('scroll_up'),
                onBottom: () => onCommand('scroll_down'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RockerColumn extends StatelessWidget {
  const _RockerColumn({required this.action, required this.rocker});

  final Widget action;
  final Widget rocker;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [action, const SizedBox(height: 12), rocker],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: surfaceColor(context),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          children: [
            Center(
              child: IconButton(
                icon: Icon(icon),
                color: iconColor.withValues(alpha: 0.7),
                tooltip: tooltip,
                onPressed: onPressed,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ActionButtonSeamPainter(
                    dark: seamDark(context),
                    light: seamLight(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rocker extends StatelessWidget {
  const _Rocker({
    required this.topIcon,
    required this.bottomIcon,
    required this.onTop,
    required this.onBottom,
  });

  final IconData topIcon;
  final IconData bottomIcon;
  final VoidCallback onTop;
  final VoidCallback onBottom;

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: surfaceColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 56,
        height: 160,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onTop,
                    child: Center(
                      child: Icon(
                        topIcon,
                        color: iconColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: onBottom,
                    child: Center(
                      child: Icon(
                        bottomIcon,
                        color: iconColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _RockerSeamPainter(
                    dark: seamDark(context),
                    light: seamLight(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClickWheel extends StatelessWidget {
  const _ClickWheel({required this.onCommand});

  final ValueChanged<String> onCommand;

  @override
  Widget build(BuildContext context) {
    const double size = 220;
    const double centerSize = 90;
    final iconColor = Theme.of(context).colorScheme.onSurface;

    Widget wedge({
      required IconData icon,
      required Alignment iconAlignment,
      required double startAngle,
      required String command,
    }) {
      return Positioned.fill(
        child: ClipPath(
          clipper: _WedgeClipper(startAngle),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onCommand(command),
              child: Align(
                alignment: iconAlignment,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Icon(
                    icon,
                    color: iconColor.withValues(alpha: 0.54),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: surfaceColor(context),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            wedge(
              icon: Icons.keyboard_arrow_up,
              iconAlignment: Alignment.topCenter,
              startAngle: -3 * math.pi / 4,
              command: 'up',
            ),
            wedge(
              icon: Icons.keyboard_arrow_right,
              iconAlignment: Alignment.centerRight,
              startAngle: -math.pi / 4,
              command: 'right',
            ),
            wedge(
              icon: Icons.keyboard_arrow_down,
              iconAlignment: Alignment.bottomCenter,
              startAngle: math.pi / 4,
              command: 'down',
            ),
            wedge(
              icon: Icons.keyboard_arrow_left,
              iconAlignment: Alignment.centerLeft,
              startAngle: 3 * math.pi / 4,
              command: 'left',
            ),
            Material(
              color: surfaceColor(context),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onCommand('space'),
                child: SizedBox(
                  width: centerSize,
                  height: centerSize,
                  child: Center(
                    child: Icon(
                      Icons.space_bar,
                      color: iconColor.withValues(alpha: 0.54),
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _WheelSeamPainter(
                    centerRadius: centerSize / 2,
                    dark: seamDark(context),
                    light: seamLight(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WedgeClipper extends CustomClipper<Path> {
  const _WedgeClipper(this.startAngle);

  final double startAngle;

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    return Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        math.pi / 2,
        false,
      )
      ..close();
  }

  @override
  bool shouldReclip(covariant _WedgeClipper oldClipper) =>
      oldClipper.startAngle != startAngle;
}

class _ActionButtonSeamPainter extends CustomPainter {
  const _ActionButtonSeamPainter({required this.dark, required this.light});

  final Color dark;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    SeamPainter.paint(
      canvas,
      Path()..addOval(Rect.fromLTWH(1, 1, size.width - 2, size.height - 2)),
      dark: dark,
      light: light,
    );
  }

  @override
  bool shouldRepaint(covariant _ActionButtonSeamPainter oldDelegate) => false;
}

class SeamPainter {
  const SeamPainter._();

  static void paint(
    Canvas canvas,
    Path path, {
    required Color dark,
    required Color light,
    double width = 1.2,
  }) {
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = light;
    final darkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = dark;

    canvas.drawPath(path.shift(const Offset(0, 1)), highlightPaint);
    canvas.drawPath(path, darkPaint);
  }
}

class _RockerSeamPainter extends CustomPainter {
  const _RockerSeamPainter({required this.dark, required this.light});

  final Color dark;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(30),
        ).deflate(1.0),
      );
    SeamPainter.paint(canvas, outline, dark: dark, light: light);

    final middle = Path()
      ..moveTo(1.0, size.height / 2)
      ..lineTo(size.width - 1.0, size.height / 2);
    SeamPainter.paint(canvas, middle, dark: dark, light: light);
  }

  @override
  bool shouldRepaint(covariant _RockerSeamPainter oldDelegate) => false;
}

class _WheelSeamPainter extends CustomPainter {
  const _WheelSeamPainter({
    required this.centerRadius,
    required this.dark,
    required this.light,
  });

  final double centerRadius;
  final Color dark;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 - 1.0;

    SeamPainter.paint(
      canvas,
      Path()..addOval(Rect.fromCircle(center: c, radius: outerR)),
      dark: dark,
      light: light,
    );
    SeamPainter.paint(
      canvas,
      Path()..addOval(Rect.fromCircle(center: c, radius: centerRadius)),
      dark: dark,
      light: light,
    );

    final d = math.cos(math.pi / 4);
    final diagonals = Path();
    for (final dir in const [
      Offset(-1, -1),
      Offset(1, -1),
      Offset(1, 1),
      Offset(-1, 1),
    ]) {
      final unit = Offset(dir.dx * d, dir.dy * d);
      diagonals
        ..moveTo(c.dx + unit.dx * centerRadius, c.dy + unit.dy * centerRadius)
        ..lineTo(c.dx + unit.dx * outerR, c.dy + unit.dy * outerR);
    }
    SeamPainter.paint(canvas, diagonals, dark: dark, light: light);
  }

  @override
  bool shouldRepaint(covariant _WheelSeamPainter oldDelegate) =>
      oldDelegate.centerRadius != centerRadius;
}
