import 'package:flutter/material.dart';

/// Custom painter to draw the expanding gradient circle without being clamped
/// by layout constraints on tall mobile screens (such as 20:9 or 20.5:9 aspect ratios).
class ExpandingCirclePainter extends CustomPainter {
  final double radius;
  final Gradient gradient;

  const ExpandingCirclePainter({
    required this.radius,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant ExpandingCirclePainter oldDelegate) {
    return oldDelegate.radius != radius;
  }
}
