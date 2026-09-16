import 'package:flutter/material.dart';

/// Logo de Google dibujado con [CustomPainter] a partir de la geometría
/// exacta del ícono oficial de 18x18 usado en los botones "Sign in with
/// Google" (mismas rutas y mismo orden de dibujado que el SVG original),
/// sin depender de assets externos ni paquetes de íconos adicionales.
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

  static final Path _bluePath = Path()
    ..moveTo(17.64, 9.2045)
    ..cubicTo(17.64, 8.5664, 17.5827, 7.9527, 17.4764, 7.3636)
    ..lineTo(9, 7.3636)
    ..lineTo(9, 10.845)
    ..lineTo(13.8436, 10.845)
    ..cubicTo(13.635, 11.97, 13.0009, 12.9232, 12.0477, 13.5614)
    ..lineTo(12.0477, 15.8195)
    ..lineTo(14.9564, 15.8195)
    ..cubicTo(16.6582, 14.2527, 17.64, 11.9455, 17.64, 9.2045)
    ..close();

  static final Path _greenPath = Path()
    ..moveTo(9, 18)
    ..cubicTo(11.43, 18, 13.4673, 17.194, 14.9564, 15.8195)
    ..lineTo(12.0477, 13.5614)
    ..cubicTo(11.2417, 14.1014, 10.2109, 14.4205, 9.0, 14.4205)
    ..cubicTo(6.656, 14.4205, 4.6718, 12.8374, 3.964, 10.7101)
    ..lineTo(0.9573, 10.7101)
    ..lineTo(0.9573, 13.0419)
    ..cubicTo(2.4382, 15.9832, 5.4818, 18, 9, 18)
    ..close();

  static final Path _yellowPath = Path()
    ..moveTo(3.964, 10.71)
    ..cubicTo(3.784, 10.17, 3.6818, 9.5932, 3.6818, 9.0)
    ..cubicTo(3.6818, 8.4068, 3.7841, 7.83, 3.964, 7.29)
    ..lineTo(3.964, 4.9582)
    ..lineTo(0.9573, 4.9582)
    ..cubicTo(0.3477, 6.1732, 0, 7.5477, 0, 9)
    ..cubicTo(0, 10.4523, 0.3477, 11.8268, 0.9573, 13.0418)
    ..lineTo(3.964, 10.71)
    ..close();

  static final Path _redPath = Path()
    ..moveTo(9, 3.5795)
    ..cubicTo(10.3214, 3.5795, 11.5077, 4.0336, 12.4405, 4.9255)
    ..lineTo(15.0218, 2.3441)
    ..cubicTo(13.4632, 0.891, 11.426, 0, 9, 0)
    ..cubicTo(5.4818, 0, 2.4382, 2.0168, 0.9573, 4.9582)
    ..lineTo(3.964, 7.29)
    ..cubicTo(4.6718, 5.1627, 6.6559, 3.5795, 9, 3.5795)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 18, size.height / 18);
    final fill = Paint()..style = PaintingStyle.fill;
    // Mismo orden que el SVG original: cada ruta se solapa ligeramente con
    // la anterior en su territorio y la siguiente la recorta al pintar
    // encima, tal cual hace el archivo fuente real.
    canvas.drawPath(_bluePath, fill..color = _blue);
    canvas.drawPath(_greenPath, fill..color = _green);
    canvas.drawPath(_yellowPath, fill..color = _yellow);
    canvas.drawPath(_redPath, fill..color = _red);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
