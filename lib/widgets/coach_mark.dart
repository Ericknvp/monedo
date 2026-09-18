import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../theme/app_theme.dart';

/// Un paso de un recorrido guiado: qué widget señalar y qué explicarle al
/// usuario sobre él.
class CoachStep {
  const CoachStep({
    required this.key,
    required this.title,
    required this.description,
    this.shape = ShapeLightFocus.RRect,
    this.radius = 16,
    this.align = ContentAlign.bottom,
    this.customPosition,
  }) : assert(align != ContentAlign.custom || customPosition != null);

  final GlobalKey key;
  final String title;
  final String description;
  final ShapeLightFocus shape;
  final double radius;
  final ContentAlign align;

  /// Requerido cuando [align] es [ContentAlign.custom]: posición fija en
  /// pantalla, independiente del tamaño del widget señalado. Se usa para
  /// objetivos muy grandes (p. ej. toda la barra lateral de escritorio),
  /// donde el cálculo automático arriba/abajo relativo al "halo" del
  /// objetivo termina empujando la burbuja fuera de la pantalla.
  final CustomTargetContentPosition? customPosition;
}

bool _tourActive = false;

/// Lanza un recorrido de tooltips con spotlight sobre [steps], en el mismo
/// estilo en toda la app: burbuja oscura, puntos de progreso, "Saltar" y
/// "Siguiente"/"Entendido". Si ya hay un recorrido activo (p. ej. el
/// usuario cambió de pestaña a mitad de otro), no hace nada.
///
/// [onDone] se llama una sola vez —al terminar el recorrido o al saltarlo—
/// para que el llamador marque esa sección como ya vista.
void showCoachMarkTour({
  required BuildContext context,
  required List<CoachStep> steps,
  required VoidCallback onDone,
}) {
  if (_tourActive || steps.isEmpty) return;
  _tourActive = true;

  var done = false;
  void finishOnce() {
    if (done) return;
    done = true;
    _tourActive = false;
    onDone();
  }

  final targets = <TargetFocus>[
    for (var i = 0; i < steps.length; i++)
      TargetFocus(
        identify: 'coach_$i',
        keyTarget: steps[i].key,
        shape: steps[i].shape,
        radius: steps[i].radius,
        contents: [
          TargetContent(
            align: steps[i].align,
            customPosition: steps[i].customPosition,
            padding: const EdgeInsets.all(16),
            builder: (context, controller) => _CoachBubble(
              step: steps[i],
              index: i,
              total: steps.length,
              onSkip: controller.skip,
              onNext: controller.next,
            ),
          ),
        ],
      ),
  ];

  TutorialCoachMark(
    targets: targets,
    colorShadow: AppTheme.navyFixed,
    opacityShadow: 0.78,
    hideSkip: true,
    pulseEnable: false,
    focusAnimationDuration: const Duration(milliseconds: 420),
    unFocusAnimationDuration: const Duration(milliseconds: 280),
    onFinish: finishOnce,
    onSkip: () {
      finishOnce();
      return true;
    },
  ).show(context: context);
}

class _CoachBubble extends StatelessWidget {
  const _CoachBubble({
    required this.step,
    required this.index,
    required this.total,
    required this.onSkip,
    required this.onNext,
  });

  final CoachStep step;
  final int index;
  final int total;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = index == total - 1;
    return Align(
      alignment: Alignment.center,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppTheme.navyFixed,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (total > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: List.generate(total, (i) {
                    final active = i == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: active ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.successFixed
                              : Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            Text(
              step.title,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              step.description,
              style: GoogleFonts.beVietnamPro(
                color: AppTheme.onPrimaryContainer,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Saltar',
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successFixed,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    elevation: 0,
                  ),
                  child: Text(
                    isLast ? 'Entendido' : 'Siguiente',
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
