import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Image.asset(
                  'assets/newmonedodesign/newlogo.png',
                  height: 44,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Monedo',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'v1.2.1',
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
              const SizedBox(height: 24),

              // Creator card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceVariant),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'E',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Creado por',
                      style: GoogleFonts.beVietnamPro(
                          color: AppTheme.onSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Erick Narváez Vega',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _linkRow(
                      Icons.language_rounded,
                      'Portafolio',
                      'ericknvp-dev.vercel.app',
                      () => _launch('https://ericknvp-dev.vercel.app'),
                    ),
                    const SizedBox(height: 14),
                    _linkRow(
                      Icons.code_rounded,
                      'Repositorio',
                      'github.com/Ericknvp/monedo',
                      () => _launch('https://github.com/Ericknvp/monedo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
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

  Widget _linkRow(IconData icon, String label, String display, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.secondaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.secondary, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.beVietnamPro(
                      color: AppTheme.onSurfaceVariant, fontSize: 12)),
              Text(
                display,
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.secondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: AppTheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
