import 'package:flutter/material.dart';

/// Custom painter to draw triangular sawtooth serrated ticket edge between dark top and light bottom
class SawtoothTicketPainter extends CustomPainter {
  final Color darkColor;
  final Color lightColor;

  SawtoothTicketPainter({required this.darkColor, required this.lightColor});

  @override
  void paint(Canvas canvas, Size size) {
    final darkPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;

    final lightPaint = Paint()
      ..color = lightColor
      ..style = PaintingStyle.fill;

    // Fill background with light color
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), lightPaint);

    // Draw dark top portion with triangular sawtooth teeth at bottom
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height - 10);

    const toothWidth = 22.0;
    const toothHeight = 8.0;
    final teethCount = (size.width / toothWidth).ceil();

    for (int i = 0; i < teethCount; i++) {
      final startX = i * toothWidth;
      final midX = startX + (toothWidth / 2);
      final endX = startX + toothWidth;
      path.lineTo(midX, size.height);
      path.lineTo(endX, size.height - toothHeight);
    }

    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, darkPaint);
  }

  @override
  bool shouldRepaint(covariant SawtoothTicketPainter oldDelegate) {
    return oldDelegate.darkColor != darkColor ||
        oldDelegate.lightColor != lightColor;
  }
}

/// Custom painter for thin dashed line divider
class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0.0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset((startX + dashWidth).clamp(0, size.width), 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
