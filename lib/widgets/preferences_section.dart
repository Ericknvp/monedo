import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../screens/categories_screen.dart';
import '../screens/accounts_screen.dart';
import '../screens/budgets_screen.dart';
import '../screens/export_screen.dart';
import 'currency_picker.dart';
import 'app_toast.dart';
import 'change_password_dialog.dart';

/// Contenido de preferencias del usuario: moneda activa y acceso a sus
/// categorías personalizadas. Se reutiliza tanto dentro de "Ajustes"
/// (móvil) como en su propia sección del menú (escritorio).
class PreferencesSection extends StatefulWidget {
  /// En escritorio, "Mis cuentas", "Mis categorías" y "Presupuestos" ya
  /// tienen su propio ítem en el menú lateral, así que aquí no se repiten.
  /// En móvil (sin esos ítems en la barra inferior) siguen apareciendo.
  final bool showQuickLinks;

  const PreferencesSection({super.key, this.showQuickLinks = true});

  @override
  State<PreferencesSection> createState() => _PreferencesSectionState();
}

class _PreferencesSectionState extends State<PreferencesSection> {
  final _authService = AuthService();
  late Currency _currency = CurrencyFormatter.current;
  bool _savingCurrency = false;
  String? _username;
  bool _loadingUsername = true;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final data = await _authService.getCurrentUserData();
    if (!mounted) return;
    setState(() {
      _username = data?.username;
      _loadingUsername = false;
    });
  }

  Future<void> _editUsername() async {
    final controller = TextEditingController(text: _username ?? '');
    final newUsername = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cambiar nombre de usuario',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700, color: AppTheme.primary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre de usuario'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newUsername == null || newUsername.isEmpty || newUsername == _username) {
      return;
    }

    final error = await _authService.updateUsername(newUsername);
    if (!mounted) return;
    if (error != null) {
      showAppToast(
        context,
        message: error,
        icon: Icons.error_outline_rounded,
        accentColor: AppTheme.errorRed,
      );
    } else {
      setState(() => _username = newUsername);
      showAppToast(
        context,
        message: 'Nombre de usuario actualizado',
        icon: Icons.check_circle_rounded,
        accentColor: AppTheme.secondary,
      );
    }
  }

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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outlineVariant),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_outline,
                  color: AppTheme.onSurfaceVariant, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: _loadingUsername
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _username ?? 'Sin nombre de usuario',
                        style: GoogleFonts.beVietnamPro(
                          color: AppTheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppTheme.onSurfaceVariant),
                onPressed: _loadingUsername ? null : _editUsername,
              ),
            ],
          ),
        ),
        if (_authService.hasPasswordProvider) ...[
          const SizedBox(height: 10),
          _navRow(
            context,
            icon: Icons.password_rounded,
            label: 'Cambiar contraseña',
            builder: (_) => const SizedBox.shrink(),
            onTap: () => showDialog(
              context: context,
              builder: (_) => const ChangePasswordDialog(),
            ),
          ),
        ],
        const SizedBox(height: 20),
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
        if (widget.showQuickLinks) ...[
          _navRow(
            context,
            icon: Icons.account_balance_wallet_outlined,
            label: 'Mis cuentas',
            builder: (_) => const AccountsScreen(),
            onTap: () => openAccountsScreen(context),
          ),
          const SizedBox(height: 10),
          _navRow(
            context,
            icon: Icons.category_outlined,
            label: 'Mis categorías',
            builder: (_) => const CategoriesScreen(),
            onTap: () => openCategoriesScreen(context),
          ),
          const SizedBox(height: 10),
          _navRow(
            context,
            icon: Icons.pie_chart_outline_rounded,
            label: 'Presupuestos',
            builder: (_) => const BudgetsScreen(),
            onTap: () => openBudgetsScreen(context),
          ),
          const SizedBox(height: 10),
        ],
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
