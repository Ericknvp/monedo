import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launch(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

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
                'v2.0',
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
                      'Monedo es una app de finanzas personales diseñada para ayudarte a tomar control de tu dinero. Registra tus ingresos y gastos, visualiza estadísticas mensuales, establece metas de ahorro y toma mejores decisiones financieras, todo desde un solo lugar.',
                      style: GoogleFonts.beVietnamPro(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _featureRow(Icons.receipt_long_rounded, 'Registro de ingresos y gastos'),
                    const SizedBox(height: 10),
                    _featureRow(Icons.analytics_rounded, 'Estadísticas visuales por mes'),
                    const SizedBox(height: 10),
                    _featureRow(Icons.savings_rounded, 'Metas de ahorro con seguimiento'),
                    const SizedBox(height: 10),
                    _featureRow(Icons.devices_rounded, 'Diseño responsive: web y móvil'),
                  ],
                ),
              ),
              const SizedBox(height: 40),

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
                    onTap: () => _launch('https://ericknvp-dev.vercel.app'),
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
                    onTap: () => _launch('https://github.com/Ericknvp/monedo'),
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

  Widget _featureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.secondary, size: 18),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.beVietnamPro(
            color: AppTheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
