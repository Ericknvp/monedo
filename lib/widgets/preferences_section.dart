import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/expense_reminder_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../screens/categories_screen.dart';
import '../screens/accounts_screen.dart';
import '../screens/budgets_screen.dart';
import '../screens/export_screen.dart';
import 'currency_picker.dart';
import 'app_text_field.dart';
import 'app_toast.dart';
import 'change_password_dialog.dart';

/// Contenido de preferencias del usuario: moneda activa y acceso a sus
/// categorías personalizadas. Se reutiliza tanto dentro de "Ajustes"
/// (móvil) como en su propia sección del menú (escritorio).
class PreferencesSection extends StatefulWidget {
  /// En escritorio, "Mis bolsillos", "Mis categorías" y "Presupuestos" ya
  /// tienen su propio ítem en el menú lateral, así que aquí no se repiten.
  /// En móvil (sin esos ítems en la barra inferior) siguen apareciendo.
  final bool showQuickLinks;

  /// Se llama tras guardar un nombre de usuario nuevo, para que la pantalla
  /// que la contiene pueda refrescar el usuario que tiene en caché (por
  /// ejemplo el saludo o el avatar del dashboard).
  final VoidCallback? onUsernameChanged;

  const PreferencesSection({
    super.key,
    this.showQuickLinks = true,
    this.onUsernameChanged,
  });

  @override
  State<PreferencesSection> createState() => _PreferencesSectionState();
}

class _PreferencesSectionState extends State<PreferencesSection> {
  final _authService = AuthService();
  late Currency _currency = CurrencyFormatter.current;
  bool _savingCurrency = false;
  String? _username;
  bool _loadingUsername = true;

  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = ExpenseReminderService.defaultTime;
  bool _loadingReminder = true;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    if (!kIsWeb) _loadReminderPreference();
  }

  Future<void> _loadReminderPreference() async {
    final service = ExpenseReminderService();
    final enabled = await service.isEnabled();
    final time = await service.getTime();
    if (!mounted) return;
    setState(() {
      _reminderEnabled = enabled;
      _reminderTime = time;
      _loadingReminder = false;
    });
  }

  Future<void> _toggleReminder(bool value) async {
    if (value) await NotificationService().requestPermission();
    setState(() => _reminderEnabled = value);
    await ExpenseReminderService()
        .setPreference(enabled: value, time: _reminderTime);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    await ExpenseReminderService().evaluate(userId);
  }

  Future<void> _pickReminderTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked == null || !mounted) return;
    setState(() => _reminderTime = picked);
    await ExpenseReminderService()
        .setPreference(enabled: _reminderEnabled, time: picked);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    await ExpenseReminderService().evaluate(userId);
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
    String? error;
    bool saving = false;

    final newUsername = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLowest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Cambiar nombre de usuario',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, color: AppTheme.primary),
          ),
          content: AppTextField(
            controller: controller,
            label: 'Nombre de usuario',
            icon: Icons.alternate_email_rounded,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            errorText: error,
            onChanged: (_) {
              if (error != null) setDialogState(() => error = null);
            },
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(color: AppTheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final trimmed = controller.text.trim();
                      if (trimmed.isEmpty) {
                        setDialogState(
                            () => error = 'Ingresa un nombre de usuario');
                        return;
                      }
                      if (trimmed == _username) {
                        Navigator.pop(ctx);
                        return;
                      }
                      setDialogState(() => saving = true);
                      final result = await _authService.updateUsername(trimmed);
                      if (result != null) {
                        setDialogState(() {
                          saving = false;
                          error = result;
                        });
                        return;
                      }
                      if (ctx.mounted) Navigator.pop(ctx, trimmed);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successFixed,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();

    if (newUsername == null || !mounted) return;
    setState(() => _username = newUsername);
    widget.onUsernameChanged?.call();
    showAppToast(
      context,
      message: 'Nombre de usuario actualizado',
      icon: Icons.check_circle_rounded,
      accentColor: AppTheme.secondary,
    );
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
              Icon(Icons.alternate_email_rounded,
                  color: AppTheme.onSurfaceVariant, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: _loadingUsername
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Text(
                        _username != null ? '@$_username' : 'Sin nombre de usuario',
                        style: GoogleFonts.beVietnamPro(
                          color: AppTheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined,
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
        _appearanceSection(),
        if (!kIsWeb) ...[
          const SizedBox(height: 20),
          _reminderSection(),
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
            label: 'Mis bolsillos',
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

  Widget _appearanceSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dark_mode_outlined,
                  color: AppTheme.onSurfaceVariant, size: 20),
              const SizedBox(width: 14),
              Text(
                'Apariencia',
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppTheme.themeModeNotifier,
            builder: (context, mode, _) {
              return Row(
                children: [
                  _appearanceOption(
                      'Sistema', Icons.brightness_auto_rounded, ThemeMode.system, mode),
                  const SizedBox(width: 8),
                  _appearanceOption(
                      'Claro', Icons.light_mode_rounded, ThemeMode.light, mode),
                  const SizedBox(width: 8),
                  _appearanceOption(
                      'Oscuro', Icons.dark_mode_rounded, ThemeMode.dark, mode),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _appearanceOption(
      String label, IconData icon, ThemeMode value, ThemeMode current) {
    final selected = value == current;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => AppTheme.setThemeMode(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.successFixed : AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.successFixed : AppTheme.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? AppTheme.onSecondary : AppTheme.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppTheme.onSecondary : AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reminderSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_outlined,
                  color: AppTheme.onSurfaceVariant, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Recordarme registrar mis gastos',
                  style: GoogleFonts.beVietnamPro(
                    color: AppTheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: _reminderEnabled,
                onChanged: _loadingReminder ? null : _toggleReminder,
                activeThumbColor: AppTheme.secondary,
              ),
            ],
          ),
          if (_reminderEnabled) ...[
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickReminderTime,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 16, color: AppTheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Todos los días a las ${_reminderTime.format(context)}',
                      style: GoogleFonts.beVietnamPro(
                        color: AppTheme.secondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
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
            Icon(Icons.chevron_right_rounded,
                color: AppTheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
