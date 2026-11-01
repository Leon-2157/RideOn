import 'package:flutter/material.dart';

/// CustomPainter untuk bingkai siku-siku Figma [1:8904] & Masker Panduan Lingkaran Profil
class CropFramePainter extends CustomPainter {
  final double padding;
  final double bracketLength;
  final double strokeWidth;

  CropFramePainter({
    this.padding = 24.0,
    this.bracketLength = 28.0,
    this.strokeWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final frameRect = Rect.fromLTWH(
      padding,
      padding,
      size.width - (2 * padding),
      size.height - (2 * padding),
    );
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - (2 * padding)) / 2;

    // 1. Redupkan seluruh area di luar LINGKARAN fokus foto profil
    final dimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final circlePath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    final maskPath = Path.combine(PathOperation.difference, outerPath, circlePath);
    canvas.drawPath(maskPath, dimPaint);

    // 2. Garis lingkar panduan avatar (putih halus)
    final circleBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, circleBorderPaint);

    // 3. Empat sudut siku-siku L putih tebal (corner brackets) sesuai Figma node [1:8904]
    final bracketPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square;

    final l = bracketLength;
    final left = frameRect.left;
    final top = frameRect.top;
    final right = frameRect.right;
    final bottom = frameRect.bottom;

    // Kiri Atas
    canvas.drawLine(Offset(left, top), Offset(left + l, top), bracketPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + l), bracketPaint);

    // Kanan Atas
    canvas.drawLine(Offset(right, top), Offset(right - l, top), bracketPaint);
    canvas.drawLine(Offset(right, top), Offset(right, top + l), bracketPaint);

    // Kiri Bawah
    canvas.drawLine(Offset(left, bottom), Offset(left + l, bottom), bracketPaint);
    canvas.drawLine(Offset(left, bottom), Offset(left, bottom - l), bracketPaint);

    // Kanan Bawah
    canvas.drawLine(Offset(right, bottom), Offset(right - l, bottom), bracketPaint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom + l), bracketPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
