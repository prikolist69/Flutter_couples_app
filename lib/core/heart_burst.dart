import 'dart:math';

import 'package:flutter/material.dart';

class FloatingHeart {
  final double x;
  final double startY;
  final double scale;
  final double speed;
  final Color color;

  FloatingHeart({
    required this.x,
    required this.startY,
    required this.scale,
    required this.speed,
    required this.color,
  });
}

class HeartBurstOverlay extends StatefulWidget {
  final Widget child;
  const HeartBurstOverlay({super.key, required this.child});

  static HeartBurstOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<HeartBurstOverlayState>();
  }

  @override
  State<HeartBurstOverlay> createState() => HeartBurstOverlayState();
}

class HeartBurstOverlayState extends State<HeartBurstOverlay>
    with SingleTickerProviderStateMixin {
  final List<FloatingHeart> _hearts = [];
  late AnimationController _animController;
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1400),
        )..addListener(() {
          if (_hearts.isNotEmpty) setState(() {});
        });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void spawnHearts() {
    _hearts.clear();
    final colors = [
      const Color(0xFFFF5E7E),
      const Color(0xFFFF8DA1),
      const Color(0xFFFF4071),
      const Color(0xFFFFA07A),
    ];

    for (int i = 0; i < 14; i++) {
      _hearts.add(
        FloatingHeart(
          x: 0.2 + _rnd.nextDouble() * 0.6,
          startY: 0.75 + _rnd.nextDouble() * 0.1,
          scale: 0.7 + _rnd.nextDouble() * 0.8,
          speed: 0.5 + _rnd.nextDouble() * 0.5,
          color: colors[_rnd.nextInt(colors.length)],
        ),
      );
    }
    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final progress = _animController.value;

    return Stack(
      children: [
        widget.child,
        if (_animController.isAnimating)
          IgnorePointer(
            child: CustomPaint(
              size: size,
              painter: _HeartPainter(hearts: _hearts, progress: progress),
            ),
          ),
      ],
    );
  }
}

class _HeartPainter extends CustomPainter {
  final List<FloatingHeart> hearts;
  final double progress;

  _HeartPainter({required this.hearts, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final h in hearts) {
      final currentY = size.height * (h.startY - (progress * h.speed * 0.6));
      final currentX =
          size.width * (h.x + sin((progress * 4) + h.scale) * 0.04);
      final alpha = ((1.0 - progress) * 255).clamp(0, 255).toInt();

      paint.color = h.color.withAlpha(alpha);

      final path = Path();
      final heartSize = 16.0 * h.scale;
      path.moveTo(currentX, currentY);
      path.cubicTo(
        currentX - heartSize,
        currentY - heartSize,
        currentX - (heartSize * 1.5),
        currentY + (heartSize / 2),
        currentX,
        currentY + (heartSize * 1.2),
      );
      path.cubicTo(
        currentX + (heartSize * 1.5),
        currentY + (heartSize / 2),
        currentX + heartSize,
        currentY - heartSize,
        currentX,
        currentY,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeartPainter oldDelegate) => true;
}
