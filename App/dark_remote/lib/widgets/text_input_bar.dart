import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class TextInputBar extends StatelessWidget {
  const TextInputBar({
    super.key,
    required this.controller,
    required this.onSubmit,
    required this.onBackspace,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: surfaceColor(context),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: surfaceColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: 52,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: TextField(
                        controller: controller,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        cursorColor: Theme.of(context).colorScheme.onSurface,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => onSubmit(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Type to write...',
                          hintStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.35),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _InputSeamPainter(
                            dark: seamDark(context),
                            light: seamLight(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _TextActionButton(
            icon: Icons.backspace_outlined,
            tooltip: 'Backspace',
            onPressed: onBackspace,
          ),
          const SizedBox(width: 8),
          _TextActionButton(
            icon: Icons.send,
            tooltip: 'Send',
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _TextActionButton extends StatelessWidget {
  const _TextActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surfaceColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 52,
        height: 52,
        child: Stack(
          children: [
            Center(
              child: IconButton(
                icon: Icon(icon),
                color: Theme.of(context).colorScheme.onSurface,
                tooltip: tooltip,
                onPressed: onPressed,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _TextActionSeamPainter(
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

class _InputSeamPainter extends CustomPainter {
  const _InputSeamPainter({required this.dark, required this.light});

  final Color dark;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    _paintSeam(
      canvas,
      Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
            const Radius.circular(16),
          ),
        ),
      dark: dark,
      light: light,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TextActionSeamPainter extends CustomPainter {
  const _TextActionSeamPainter({required this.dark, required this.light});

  final Color dark;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    _paintSeam(
      canvas,
      Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(1, 1, rect.width - 2, rect.height - 2),
            const Radius.circular(16),
          ),
        ),
      dark: dark,
      light: light,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _paintSeam(
  Canvas canvas,
  Path path, {
  required Color dark,
  required Color light,
}) {
  final highlightPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round
    ..color = light;
  final darkPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round
    ..color = dark;

  canvas.drawPath(path.shift(const Offset(0, 1)), highlightPaint);
  canvas.drawPath(path, darkPaint);
}
