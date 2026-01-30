import 'package:flutter/material.dart';

class CarIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CarIcon({
    super.key,
    this.size = 40, // Matches the width/height="40" from your SVG
    this.color = Colors.white, // Matches text-white
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CarIconPainter(color: color),
    );
  }
}

class _CarIconPainter extends CustomPainter {
  final Color color;

  _CarIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Scale the canvas to match the SVG viewbox (24x24)
    // This allows us to use the exact coordinate numbers from the SVG data.
    final double scale = size.width / 24;
    canvas.scale(scale, scale);

    // 2. Define the exact paths from the SVG 'd' attributes
    final path = Path();

    // --- Car Body ---
    // d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 2 12v4c0 .6.4 1 1 1h2"
    path.moveTo(19, 17);
    path.lineTo(21, 17); // h2
    path.cubicTo(21.6, 17, 22, 16.6, 22, 16); // c.6 0 1-.4 1-1
    path.lineTo(22, 13); // v-3
    path.cubicTo(22, 12.1, 21.3, 11.3, 20.5, 11.1); // c0-.9-.7-1.7-1.5-1.9
    path.cubicTo(18.7, 10.6, 16, 10, 16, 10); // C18.7 10.6 16 10 16 10
    // s-1.3-1.4-2.2-2.3 (Reflected control point logic)
    path.cubicTo(16, 10, 14.7, 8.6, 13.8, 7.7);
    path.cubicTo(
      13.3,
      7.3,
      12.7,
      7,
      12,
      7,
    ); // c-.5-.4-1.1-.7-1.8-.7 (Approx 12 instead of 11.1 for pixel perf)
    path.lineTo(5, 7); // H5
    path.cubicTo(4.4, 7, 3.9, 7.4, 3.6, 7.9); // c-.6 0-1.1.4-1.4.9
    path.lineTo(2.2, 10.8); // l-1.4 2.9
    // A3.7 3.7 0 0 0 2 12
    path.arcToPoint(
      const Offset(2, 12),
      radius: const Radius.circular(3.7),
      clockwise: false,
    );
    path.lineTo(2, 16); // v4
    path.cubicTo(2, 16.6, 2.4, 17, 3, 17); // c0 .6.4 1 1 1
    path.lineTo(5, 17); // h2

    // --- Bottom Line ---
    // d="M9 17h6"
    final linePath = Path();
    linePath.moveTo(9, 17);
    linePath.lineTo(15, 17);

    // --- Setup Paints ---

    // The main stroke paint
    final Paint strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // The shadow paint (Simulating drop-shadow-md)
    // CSS drop-shadow-md is roughly: 0 4px 3px -1px rgba(0, 0, 0, 0.1)
    final Paint shadowPaint = Paint()
      ..color = Colors.black
          .withOpacity(0.05) // Further decreased from 0.1
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        0.5,
      ); // Further decreased from 1.0

    // 3. Drawing

    // Draw Shadows first (offset slightly down)
    canvas.save();
    canvas.translate(0, 1); // Reduced Y offset from 2px to 1px
    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(linePath, shadowPaint);
    canvas.drawCircle(const Offset(7, 17), 2, shadowPaint);
    canvas.drawCircle(const Offset(17, 17), 2, shadowPaint);
    canvas.restore();

    // Draw Main Strokes
    canvas.drawPath(path, strokePaint); // Body
    canvas.drawPath(linePath, strokePaint); // Line

    // Wheels (cx="7" cy="17" r="2") and (cx="17" cy="17" r="2")
    // We draw circles directly as they are more efficient than paths
    strokePaint.style = PaintingStyle.stroke; // Ensure it stays stroke
    canvas.drawCircle(const Offset(7, 17), 2, strokePaint);
    canvas.drawCircle(const Offset(17, 17), 2, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _CarIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
