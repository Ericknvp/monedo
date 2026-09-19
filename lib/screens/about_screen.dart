import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../utils/onboarding_tour.dart';
import '../utils/web_redirect.dart' if (dart.library.io) '../utils/web_redirect_stub.dart';
import '../widgets/preferences_section.dart';
import '../widgets/app_toast.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

const _kSupportEmail = 'appmonedo@gmail.com';

/// Cuenta del equipo usada para probar la app: las herramientas de prueba
/// de esta pantalla (repetir tour, repetir configuración inicial) solo se
/// muestran a este correo, para que ningún otro usuario las vea.
const _kTestAccountEmail = 'narvaezvegaerick@gmail.com';

const _months = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

String _formatFullDate(DateTime d) => '${d.day} de ${_months[d.month - 1]} de ${d.year}';

class AboutScreen extends StatelessWidget {
  /// En escritorio, Preferencias vive en su propia sección del menú, así
  /// que aquí no se repite. En móvil sigue mostrándose dentro de Ajustes.
  final bool showPreferences;

  /// Fecha de registro del usuario, para mostrar "Cuenta creada el...".
  final DateTime? memberSince;

  /// Se llama tras guardar un nombre de usuario nuevo, para que el dashboard
  /// refresque el usuario que tiene en caché (saludo, avatar, etc.).
  final VoidCallback? onUsernameChanged;

  const AboutScreen({
    super.key,
    this.showPreferences = true,
    this.memberSince,
    this.onUsernameChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 40 : 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Logo
              Center(
                child: Image.asset(
                  'assets/images/logomonedo_new.png',
                  width: 52,
                  height: 52,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Monedo',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'v2.5.0',
                style: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                'Tu app de finanzas personales',
                style: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant, fontSize: 16),
              ),
              const SizedBox(height: 40),

              // Aviso persistente si hay una versión más nueva: sigue visible
              // aquí aunque el usuario haya descartado el diálogo emergente
              // con "Más tarde" al abrir la app.
              if (!isDesktop) ...[
                _buildUpdateBanner(),
                const SizedBox(height: 24),
              ],

              // About app card
              if (showPreferences) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.surfaceVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preferencias',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      PreferencesSection(onUsernameChanged: onUsernameChanged),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Support card
              Builder(builder: (context) {
                final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.surfaceVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Soporte',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '¿Tienes un problema o encontraste un error? Repórtalo junto con tu ID de usuario.',
                        style: GoogleFonts.beVietnamPro(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.badge_outlined,
                                color: AppTheme.onSurfaceVariant, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tu ID de usuario',
                                    style: GoogleFonts.beVietnamPro(
                                      color: AppTheme.onSurfaceVariant,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    userId,
                                    style: GoogleFonts.beVietnamPro(
                                      color: AppTheme.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.copy_rounded,
                                  color: AppTheme.secondary, size: 18),
                              tooltip: 'Copiar ID',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: userId));
                                showAppToast(
                                  context,
                                  message: 'ID copiado',
                                  icon: Icons.check_circle_rounded,
                                  accentColor: AppTheme.secondary,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      if (memberSince != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.event_available_outlined,
                                  color: AppTheme.onSurfaceVariant, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cuenta creada el',
                                      style: GoogleFonts.beVietnamPro(
                                        color: AppTheme.onSurfaceVariant,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatFullDate(memberSince!),
                                      style: GoogleFonts.beVietnamPro(
                                        color: AppTheme.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _reportProblem(userId),
                          icon: const Icon(Icons.support_agent_rounded, size: 19),
                          label: const Text('Reportar un problema'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successFixed,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Herramientas de prueba: solo visibles para la cuenta de
              // pruebas del equipo (ver [_kTestAccountEmail]), nunca para
              // otros usuarios.
              if (FirebaseAuth.instance.currentUser?.email ==
                  _kTestAccountEmail) ...[
                Builder(builder: (context) {
                  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.surfaceVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Herramientas de prueba',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Solo visibles para la cuenta de pruebas.',
                          style: GoogleFonts.beVietnamPro(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await OnboardingTour.resetAll(userId);
                              if (context.mounted) {
                                showAppToast(
                                  context,
                                  message:
                                      'Tour reiniciado: cambia de pestaña para verlo de nuevo',
                                  icon: Icons.replay_rounded,
                                  accentColor: AppTheme.secondary,
                                );
                              }
                            },
                            icon: const Icon(Icons.replay_rounded, size: 18),
                            label: const Text('Repetir tour guiado'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.secondary,
                              side: BorderSide(color: AppTheme.secondary),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                // `onFinish` se llama recién cuando el
                                // usuario termina el asistente, quizá varios
                                // minutos después de tocar este botón. Usar
                                // el `context` de "Acerca de" capturado aquí
                                // arriba para el pop es fràgil: si esa
                                // pantalla llegó a reconstruirse mientras
                                // tanto, `Navigator.pop` puede fallar con un
                                // "Null check operator used on a null value"
                                // (contexto obsoleto). El `context` que trae
                                // el propio `builder` de la ruta pertenece al
                                // OnboardingScreen recién empujado y sigue
                                // siendo válido mientras esa ruta exista.
                                builder: (routeContext) => OnboardingScreen(
                                  showWelcome: false,
                                  showCurrency: true,
                                  showAccounts: true,
                                  showCategories: true,
                                  onFinish: () => Navigator.pop(routeContext),
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.restart_alt_rounded, size: 18),
                            label: const Text('Repetir configuración inicial'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.secondary,
                              side: BorderSide(color: AppTheme.secondary),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        if (!kIsWeb) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _pickTestNotification(context),
                              icon: const Icon(
                                  Icons.notifications_active_outlined,
                                  size: 18),
                              label: const Text('Probar notificación'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.secondary,
                                side: BorderSide(color: AppTheme.secondary),
                                shape: const StadiumBorder(),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],

              // Logout button (solo en móvil: en escritorio ya vive en el
              // pie del menú lateral).
              if (!isDesktop) ...[
                Builder(builder: (context) {
                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmAndLogout(context),
                      icon: const Icon(Icons.logout_rounded, size: 19),
                      label: const Text('Cerrar sesión'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorRed,
                        side: BorderSide(color: AppTheme.errorRed),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],

              // Footer
              Divider(color: AppTheme.surfaceVariant),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sobre el creador',
                    style: GoogleFonts.beVietnamPro(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  InkWell(
                    onTap: () => openExternalUrl('https://ericknvp-dev.vercel.app'),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.language_rounded,
                              color: AppTheme.secondary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Portafolio',
                            style: GoogleFonts.beVietnamPro(
                              color: AppTheme.secondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () => openExternalUrl('https://instagram.com/ericknvp'),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(FontAwesomeIcons.instagram,
                              color: AppTheme.onSurfaceVariant, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Contacto con el desarrollador: @ericknvp',
                            style: GoogleFonts.beVietnamPro(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('¿Cerrar sesión?',
            style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary, fontWeight: FontWeight.w600)),
        content: Text('¿Seguro que quieres salir de tu cuenta?',
            style: GoogleFonts.beVietnamPro(color: AppTheme.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: AppTheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Salir',
                style: TextStyle(
                    color: AppTheme.errorRed, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await AuthService().logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  /// Deja elegir cuál de los 4 tipos de notificación disparar de inmediato,
  /// con contenido de ejemplo — solo para verlas en el celular sin esperar
  /// a que se cumpla la condición real de cada una.
  Future<void> _pickTestNotification(BuildContext context) async {
    final samples = <(IconData, String, String, String)>[
      (
        Icons.event_note_rounded,
        'Recordatorio diario',
        'No olvides tus movimientos de hoy',
        '¿Ya registraste tus gastos o ingresos de hoy en Monedo?',
      ),
      (
        Icons.autorenew_rounded,
        'Movimiento recurrente',
        'Gasto recurrente registrado',
        '"Renta" (\$500.00) se registró automáticamente hoy.',
      ),
      (
        Icons.pie_chart_rounded,
        'Alerta de presupuesto',
        'Vas al 80% de tu presupuesto de Alimentación',
        '\$400.00 de \$500.00 este mes.',
      ),
      (
        Icons.savings_rounded,
        'Meta de ahorro alcanzada',
        'Meta cumplida',
        'Completaste "Viaje a la playa": \$1,000.00.',
      ),
    ];

    final choice = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                'Elige qué notificación probar',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (var i = 0; i < samples.length; i++)
              ListTile(
                leading: Icon(samples[i].$1, color: AppTheme.secondary),
                title: Text(
                  samples[i].$2,
                  style: GoogleFonts.beVietnamPro(
                    color: AppTheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, i),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null) return;

    final sample = samples[choice];
    try {
      await NotificationService().showNow(
        key: 'test_notification_$choice',
        title: sample.$3,
        body: sample.$4,
      );
    } catch (e) {
      // TODO: diagnóstico temporal — quitar el detalle técnico una vez
      // identificada la causa real de por qué no llegan las notificaciones.
      if (context.mounted) {
        showAppToast(
          context,
          message: 'No se pudo mostrar la notificación:\n$e',
          icon: Icons.error_outline_rounded,
          accentColor: AppTheme.errorRed,
        );
      }
    }
  }

  Future<void> _reportProblem(String userId) async {
    final userData = await AuthService().getCurrentUserData();
    // Uri(queryParameters: ...) codifica espacios como "+" (form-encoding),
    // que Gmail muestra literal en vez de espacio. mailto (RFC 6068) espera
    // %20, así que se codifica a mano con Uri.encodeComponent.
    final subject = Uri.encodeComponent('Cuéntanos tu situación');
    final body = Uri.encodeComponent(
      'Usuario: ${userData?.username ?? ""}\n'
      'ID de usuario: $userId',
    );
    openExternalUrl('mailto:$_kSupportEmail?subject=$subject&body=$body');
  }

  Widget _buildUpdateBanner() {
    return FutureBuilder<UpdateInfo?>(
      future: UpdateService().checkForUpdate(),
      builder: (context, snap) {
        final update = snap.data;
        if (update == null) return const SizedBox.shrink();

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => openExternalUrl(update.downloadUrl),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.system_update_rounded,
                    color: AppTheme.secondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nueva versión disponible',
                        style: GoogleFonts.beVietnamPro(
                          color: AppTheme.primary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Monedo v${update.version} · toca para descargar',
                        style: GoogleFonts.beVietnamPro(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppTheme.secondary, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}
