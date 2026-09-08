import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../utils/web_redirect.dart' if (dart.library.io) '../utils/web_redirect_stub.dart';
import '../widgets/preferences_section.dart';
import '../widgets/app_toast.dart';
import 'login_screen.dart';

const _kSupportEmail = 'narvaezvegaerick@gmail.com';

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
                'v2.4.1',
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

              // "Sobre Monedo" solo en escritorio: en móvil sobra (la app ya
              // se explica sola navegándola) y deja la pantalla más corta.
              if (isDesktop) ...[
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
                        'Sobre Monedo',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Monedo es tu app de finanzas personales: organiza el dinero de todas tus cuentas, registra cada movimiento y sigue tus metas de ahorro.',
                        style: GoogleFonts.beVietnamPro(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _featureRow(Icons.account_balance_wallet_rounded,
                          'Cuentas separadas y transferencias entre ellas'),
                      const SizedBox(height: 10),
                      _featureRow(Icons.savings_rounded,
                          'Metas de ahorro con seguimiento de aportes'),
                      const SizedBox(height: 10),
                      _featureRow(Icons.analytics_rounded,
                          'Estadísticas visuales por mes'),
                      const SizedBox(height: 10),
                      _featureRow(Icons.ios_share_rounded,
                          'Exportación de datos a Excel y PDF'),
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
                            const Icon(Icons.badge_outlined,
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
                              icon: const Icon(Icons.copy_rounded,
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
                              const Icon(Icons.event_available_outlined,
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
                            backgroundColor: AppTheme.secondary,
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
                        side: const BorderSide(color: AppTheme.errorRed),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],

              // Footer
              const Divider(color: AppTheme.surfaceVariant),
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
                          const Icon(Icons.language_rounded,
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
                    onTap: () => openExternalUrl('https://github.com/Ericknvp/monedo'),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.code_rounded,
                              color: AppTheme.onSurfaceVariant, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Ver repositorio en GitHub',
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

  void _reportProblem(String userId) {
    final uri = Uri(
      scheme: 'mailto',
      path: _kSupportEmail,
      queryParameters: {
        'subject': 'Reporte de problema - Monedo',
        'body': 'Describe aquí el problema que tuviste:\n\n\n'
            '—\n'
            'ID de usuario: $userId',
      },
    );
    openExternalUrl(uri.toString());
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
                const Icon(Icons.system_update_rounded,
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
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.secondary, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.secondary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.beVietnamPro(
              color: AppTheme.onSurfaceVariant,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
