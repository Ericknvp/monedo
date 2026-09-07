import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Pantalla de carga con la identidad de Monedo (logo, blobs y gradiente de
/// marca), en vez del círculo de carga genérico de Flutter. Se usa en los
/// puntos donde la app espera datos antes de decidir qué mostrar: estado de
/// sesión, si ya vio el onboarding, o si le falta configuración inicial.
class BrandedLoadingScreen extends StatefulWidget {
  const BrandedLoadingScreen({super.key});

  @override
  State<BrandedLoadingScreen> createState() => _BrandedLoadingScreenState();
}

class _BrandedLoadingScreenState extends State<BrandedLoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            Positioned(top: -110, left: -100, child: _blob(300, AppTheme.secondaryFixed, 0.18)),
            Positioned(bottom: -130, right: -90, child: _blob(340, AppTheme.secondary, 0.16)),
            Positioned(top: 220, right: -70, child: _blob(200, AppTheme.onSecondaryContainer, 0.12)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: CurvedAnimation(parent: _entrance, curve: Curves.easeOutBack),
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                          parent: _entrance, curve: const Interval(0, 0.6)),
                      child: Container(
                        width: 92,
                        height: 92,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.secondaryFixed.withOpacity(0.28),
                              blurRadius: 32,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logomonedo_new.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: CurvedAnimation(
                        parent: _entrance, curve: const Interval(0.3, 1)),
                    child: Text(
                      'Monedo',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (i) {
                          final phase = (_pulse.value + i * 0.25) % 1.0;
                          final scale = 0.5 + 0.5 * math.sin(phase * math.pi);
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Opacity(
                              opacity: 0.4 + 0.6 * scale,
                              child: Transform.scale(
                                scale: 0.7 + 0.3 * scale,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.secondaryFixed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(opacity)),
    );
  }
}

/// Versión chica del loader de marca, para usar dentro de una pantalla que
/// ya está montada (una pestaña, una lista) mientras llega su propia data —
/// el logo de Monedo respirando en vez del círculo verde genérico.
class BrandedInlineLoader extends StatefulWidget {
  final double size;

  const BrandedInlineLoader({super.key, this.size = 40});

  @override
  State<BrandedInlineLoader> createState() => _BrandedInlineLoaderState();
}

class _BrandedInlineLoaderState extends State<BrandedInlineLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Opacity(
          opacity: 0.45 + 0.55 * t,
          child: Transform.scale(
            scale: 0.9 + 0.1 * t,
            child: Image.asset(
              'assets/images/logomonedo_new.png',
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
}
