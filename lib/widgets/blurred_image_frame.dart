import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'branded_loading_screen.dart';

/// Reemplazo del "gris genérico" para cuando una imagen todavía está
/// cargando o no se pudo mostrar: logo de Monedo como marca de agua sobre
/// un fondo con el tono de marca, en vez de un rectángulo vacío.
class MonedoImagePlaceholder extends StatelessWidget {
  final bool loading;

  const MonedoImagePlaceholder({super.key, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryContainer.withOpacity(0.08),
      alignment: Alignment.center,
      child: loading
          ? const BrandedInlineLoader(size: 36)
          : Opacity(
              opacity: 0.35,
              child: Image.asset(
                'assets/images/logomonedo_new.png',
                width: 44,
                height: 44,
                fit: BoxFit.contain,
              ),
            ),
    );
  }
}

/// Muestra una imagen completa sin recortarla (BoxFit.contain), con una
/// versión difuminada y ampliada de sí misma de fondo (BoxFit.cover +
/// blur) llenando el espacio sobrante — el mismo tratamiento que usan
/// Spotify/Apple Music para portadas que no calzan con el marco. Así
/// cualquier proporción de foto se ve bien, sin recortar partes importantes
/// ni necesitar que el usuario ajuste manualmente el encuadre.
///
/// Mientras carga o si falla, muestra [MonedoImagePlaceholder] en vez de un
/// espacio gris vacío (a menos que se pase un [errorBuilder] propio).
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
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const MonedoImagePlaceholder(loading: true);
      },
      errorBuilder: (context, _, __) => errorBuilder != null
          ? errorBuilder!(context)
          : const MonedoImagePlaceholder(),
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
