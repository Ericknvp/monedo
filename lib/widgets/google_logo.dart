import 'package:flutter/material.dart';

/// Logo de Google dibujado con [CustomPainter], sin depender de assets
/// externos ni paquetes de iconos adicionales.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.22;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    Paint ringPaint(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    const fullTurn = 6.28319;
    canvas.drawArc(rect, -0.35, fullTurn * 0.24, false, ringPaint(_blue));
    canvas.drawArc(rect, 1.20, fullTurn * 0.22, false, ringPaint(_green));
    canvas.drawArc(rect, 2.60, fullTurn * 0.27, false, ringPaint(_yellow));
    canvas.drawArc(rect, -2.85, fullTurn * 0.24, false, ringPaint(_red));

    final barPaint = Paint()..color = _blue;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.50,
        size.height * 0.44,
        size.width * 0.46,
        size.height * 0.14,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
