import 'package:flutter/material.dart';

class RippleEffect extends StatelessWidget {
  final Animation<double> controller;
  final Color color;
  final double baseSize;

  const RippleEffect({
    super.key,
    required this.controller,
    required this.color,
    required this.baseSize,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          width: baseSize * (1.0 + (controller.value * 0.6)),
          height: baseSize * (1.0 + (controller.value * 0.6)),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(1.0 - controller.value),
              width: 3,
            ),
          ),
        );
      },
    );
  }
}
