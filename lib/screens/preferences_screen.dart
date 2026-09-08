import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/preferences_section.dart';

/// Sección "Preferencias" como su propio destino del menú (escritorio).
class PreferencesScreen extends StatelessWidget {
  /// Se llama tras guardar un nombre de usuario nuevo, para que el dashboard
  /// refresque el usuario que tiene en caché (saludo, avatar, etc.).
  final VoidCallback? onUsernameChanged;

  const PreferencesScreen({super.key, this.onUsernameChanged});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 40 : 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preferencias',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.56,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Personaliza cómo Monedo se ve y se comporta para ti.',
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceVariant),
                ),
                child: PreferencesSection(
                  showQuickLinks: false,
                  onUsernameChanged: onUsernameChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
