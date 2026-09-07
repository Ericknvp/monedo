import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/web_redirect.dart' if (dart.library.io) '../utils/web_redirect_stub.dart';
import '../widgets/preferences_section.dart';
import '../widgets/app_toast.dart';

const _kSupportEmail = 'narvaezvegaerick@gmail.com';

class AboutScreen extends StatelessWidget {
  /// En escritorio, Preferencias vive en su propia sección del menú, así
  /// que aquí no se repite. En móvil sigue mostrándose dentro de Acerca de.
  final bool showPreferences;

  const AboutScreen({super.key, this.showPreferences = true});

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
                'v2.2.1',
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
                      const PreferencesSection(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

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
