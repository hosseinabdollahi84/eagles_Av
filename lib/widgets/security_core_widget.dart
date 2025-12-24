import 'dart:math';
import 'package:flutter/material.dart';

class SecuritySegmentRing extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final double size;

  const SecuritySegmentRing({
    super.key,
    required this.animation,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return Transform.rotate(
          angle: animation.value * pi * 0.6,
          child: CustomPaint(
            size: Size(size, size),
            painter: _SegmentRingPainter(color),
          ),
        );
      },
    );
  }
}

class _SegmentRingPainter extends CustomPainter {
  final Color color;

  _SegmentRingPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final radius = size.width / 2;
    final rect = Rect.fromCircle(
      center: Offset(radius, radius),
      radius: radius,
    );

    const int segments = 5;
    const double gap = 0.4;

    for (int i = 0; i < segments; i++) {
      final startAngle = (2 * pi / segments) * i;
      canvas.drawArc(rect, startAngle, (2 * pi / segments) - gap, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SecurityEnergyGlow extends StatelessWidget {
  final Color color;
  final double size;

  const SecurityEnergyGlow({
    super.key,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.28),
            blurRadius: 10,
            spreadRadius: 3,
          ),
        ],
      ),
    );
  }
}

class SecurityReactorCore extends StatelessWidget {
  final double size;
  final Color color;
  final IconData icon;

  const SecurityReactorCore({
    super.key,
    required this.size,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,

        border: Border.all(color: color.withOpacity(0.9), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: color,
          size: size * 0.45,
          shadows: [Shadow(color: color)],
        ),
      ),
    );
  }
}
