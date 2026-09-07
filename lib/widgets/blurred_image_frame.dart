import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Muestra una imagen completa sin recortarla (BoxFit.contain), con una
/// versión difuminada y ampliada de sí misma de fondo (BoxFit.cover +
/// blur) llenando el espacio sobrante — el mismo tratamiento que usan
/// Spotify/Apple Music para portadas que no calzan con el marco. Así
/// cualquier proporción de foto se ve bien, sin recortar partes importantes
/// ni necesitar que el usuario ajuste manualmente el encuadre.
class BlurredImageFrame extends StatelessWidget {
  final Uint8List? bytes;
  final String? url;
  final BorderRadius? borderRadius;
  final WidgetBuilder? errorBuilder;

  const BlurredImageFrame({
    super.key,
    this.bytes,
    this.url,
    this.borderRadius,
    this.errorBuilder,
  }) : assert(bytes != null || url != null,
            'BlurredImageFrame necesita bytes o url');

  Widget _image(BoxFit fit) {
    if (bytes != null) {
      return Image.memory(bytes!, fit: fit);
    }
    return Image.network(
      url!,
      fit: fit,
      errorBuilder: errorBuilder == null
          ? null
          : (context, _, __) => errorBuilder!(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter:
                ImageFilter.blur(sigmaX: 22, sigmaY: 22, tileMode: TileMode.decal),
            child: _image(BoxFit.cover),
          ),
          Container(color: Colors.black.withOpacity(0.28)),
          _image(BoxFit.contain),
        ],
      ),
    );
  }
}
