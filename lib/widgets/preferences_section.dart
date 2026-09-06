import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../screens/categories_screen.dart';
import '../screens/export_screen.dart';
import 'currency_picker.dart';
import 'app_toast.dart';

/// Contenido de preferencias del usuario: moneda activa y acceso a sus
/// categorías personalizadas. Se reutiliza tanto dentro de "Acerca de"
/// (móvil) como en su propia sección del menú (escritorio).
class PreferencesSection extends StatefulWidget {
  const PreferencesSection({super.key});

  @override
  State<PreferencesSection> createState() => _PreferencesSectionState();
}

class _PreferencesSectionState extends State<PreferencesSection> {
  final _authService = AuthService();
  late Currency _currency = CurrencyFormatter.current;
  bool _savingCurrency = false;

  Future<void> _changeCurrency(Currency currency) async {
    setState(() => _savingCurrency = true);
    await _authService.updateCurrency(currency.code);
    CurrencyFormatter.setCurrency(currency.code);
    setState(() {
      _currency = currency;
      _savingCurrency = false;
    });
    if (mounted) {
      showAppToast(
        context,
        message: 'Moneda actualizada a ${currency.code}',
        icon: Icons.check_circle_rounded,
        accentColor: AppTheme.secondary,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IgnorePointer(
          ignoring: _savingCurrency,
          child: Opacity(
            opacity: _savingCurrency ? 0.6 : 1,
            child: CurrencyPickerField(
              selected: _currency,
              onChanged: _changeCurrency,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Cambiar la moneda solo actualiza el formato de tus cifras; no convierte los montos ya registrados.',
          style: GoogleFonts.beVietnamPro(
            color: AppTheme.onSurfaceVariant,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        _navRow(
          context,
          icon: Icons.category_outlined,
          label: 'Mis categorías',
          builder: (_) => const CategoriesScreen(),
        ),
        const SizedBox(height: 10),
        _navRow(
          context,
          icon: Icons.ios_share_rounded,
          label: 'Exportar datos',
          builder: (_) => const ExportScreen(),
          onTap: () => openExportScreen(context),
        ),
      ],
    );
  }

  Widget _navRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required WidgetBuilder builder,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap ??
          () => Navigator.push(context, MaterialPageRoute(builder: builder)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
