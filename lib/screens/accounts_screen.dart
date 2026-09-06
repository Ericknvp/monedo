import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/account.dart';
import '../services/account_service.dart';
import '../theme/app_theme.dart';
import '../utils/amount_input_formatter.dart';
import '../utils/currency_formatter.dart';
import '../widgets/app_toast.dart';

/// Abre la hoja para crear una cuenta nueva (ej. Efectivo, Nu, Nequi).
/// Devuelve el id de la cuenta creada, o null si se canceló.
Future<String?> showAddAccountSheet(
  BuildContext context, {
  required String userId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppTheme.surfaceContainerLowest,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _AddAccountSheet(userId: userId),
  );
}

/// Abre la hoja para transferir dinero entre dos cuentas propias.
Future<void> showTransferSheet(
  BuildContext context, {
  required List<AccountModel> accounts,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surfaceContainerLowest,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _TransferSheet(accounts: accounts),
  );
}

/// Abre "Mis cuentas": como una ventana modal centrada (con fondo
/// oscurecido) en escritorio, o a pantalla completa en móvil.
Future<void> openAccountsScreen(BuildContext context) {
  final isDesktop = MediaQuery.of(context).size.width >= 900;

  if (isDesktop) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const AccountsScreen(isDialog: true),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  return Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AccountsScreen()),
  );
}

class AccountsScreen extends StatefulWidget {
  final bool isDialog;
  // Incrustada como sección propia del menú lateral de escritorio: sin
  // AppBar ni botón de volver (el encabezado ya lo pone el panel principal).
  final bool embedded;

  const AccountsScreen({
    super.key,
    this.isDialog = false,
    this.embedded = false,
  });

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final _accountService = AccountService();

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _confirmDelete(AccountModel account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Eliminar cuenta?',
            style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary, fontWeight: FontWeight.w700)),
        content: Text(
          'Se eliminará "${account.name}". Los movimientos que ya la usan conservarán su historial, pero no se podrá volver a elegir esta cuenta.',
          style: GoogleFonts.beVietnamPro(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: AppTheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              shape: const StadiumBorder(),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _accountService.deleteAccount(account.id);
    }
  }

  Future<void> _rename(AccountModel account) async {
    final ctrl = TextEditingController(text: account.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Renombrar cuenta',
            style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          style: GoogleFonts.beVietnamPro(color: AppTheme.primary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(color: AppTheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              shape: const StadiumBorder(),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      await _accountService.renameAccount(account.id, newName);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDialog) return _buildDialog();
    if (widget.embedded) return _buildBody();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mis cuentas',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.primary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  /// Ventana modal centrada (escritorio).
  Widget _buildDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
          child: Material(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            elevation: 24,
            shadowColor: Colors.black.withOpacity(0.4),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 20, 4),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.account_balance_wallet_outlined,
                            color: AppTheme.secondary, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Mis cuentas',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.primary,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppTheme.onSurfaceVariant),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildBody(isDialog: true)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody({bool isDialog = false}) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return StreamBuilder<List<AccountModel>>(
        stream: _accountService.getAccounts(_userId),
        builder: (context, snap) {
          final accounts = snap.data ?? [];
          final total = _accountService.totalBalance(accounts);

          final content = SingleChildScrollView(
                padding: EdgeInsets.all(isDialog ? 24 : (isDesktop ? 32 : 20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0C3547),
                            Color(0xFF082D3C),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BALANCE TOTAL',
                            style: GoogleFonts.beVietnamPro(
                              color: AppTheme.secondaryFixed,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            CurrencyFormatter.format(total),
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${accounts.length} ${accounts.length == 1 ? 'cuenta' : 'cuentas'}',
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => showAddAccountSheet(context,
                                userId: _userId),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text('Nueva cuenta'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondary,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                            ),
                          ),
                        ),
                        if (accounts.length >= 2) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => showTransferSheet(
                                  context, accounts: accounts),
                              icon: const Icon(
                                  Icons.swap_horiz_rounded, size: 20),
                              label: const Text('Transferir'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                side: const BorderSide(
                                    color: AppTheme.outlineVariant),
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 28),
                    if (accounts.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.surfaceVariant),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined,
                                size: 40, color: AppTheme.outlineVariant),
                            const SizedBox(height: 10),
                            Text(
                              'Todavía no tienes cuentas registradas',
                              style: GoogleFonts.beVietnamPro(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    else
                      ...accounts.map((a) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: AppTheme.surfaceVariant),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: AppTheme.secondary,
                                      size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.name,
                                        style: GoogleFonts.beVietnamPro(
                                          color: AppTheme.primary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        CurrencyFormatter.format(a.balance),
                                        style: GoogleFonts.beVietnamPro(
                                          color: AppTheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      color: AppTheme.onSurfaceVariant,
                                      size: 18),
                                  onPressed: () => _rename(a),
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppTheme.errorRed,
                                      size: 18),
                                  onPressed: () => _confirmDelete(a),
                                ),
                              ],
                            ),
                          )),
                  ],
                ),
              );

          if (isDialog) return content;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 640 : 700),
              child: content,
            ),
          );
        },
      );
  }
}

class _AddAccountSheet extends StatefulWidget {
  final String userId;

  const _AddAccountSheet({required this.userId});

  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}

enum _AccountKind { cash, bank }

class _AddAccountSheetState extends State<_AddAccountSheet> {
  final _accountService = AccountService();
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  bool _saving = false;
  String? _error;
  _AccountKind? _kind;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _pickCash() {
    setState(() {
      _kind = _AccountKind.cash;
      _nameCtrl.text = 'Efectivo';
      _error = null;
    });
  }

  void _pickBank() {
    setState(() {
      _kind = _AccountKind.bank;
      _nameCtrl.clear();
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nameFocus.requestFocus();
    });
  }

  Future<void> _save() async {
    if (_kind == null) {
      setState(() => _error = 'Elige una opción para continuar');
      return;
    }
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = _kind == _AccountKind.cash
          ? 'Ponle un nombre a la cuenta'
          : 'Escribe el nombre de tu banco o billetera');
      return;
    }
    final balance = _balanceCtrl.text.trim().isEmpty
        ? 0.0
        : CurrencyFormatter.parse(_balanceCtrl.text.trim());
    if (balance == null) {
      setState(() => _error = 'El saldo inicial no es válido');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final id = await _accountService.addAccount(
      userId: widget.userId,
      name: name,
      initialBalance: balance,
    );
    if (mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 28,
        right: 28,
        top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Nueva cuenta',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.primary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '¿Dónde tienes tu dinero?',
            style: GoogleFonts.beVietnamPro(
                color: AppTheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _kindCard(
                  label: 'Efectivo',
                  description: 'El dinero que tienes a la mano',
                  icon: Icons.payments_rounded,
                  selected: _kind == _AccountKind.cash,
                  onTap: _pickCash,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _kindCard(
                  label: 'Banco o billetera',
                  description: 'Ej: PayPal, tu banco...',
                  icon: Icons.account_balance_rounded,
                  selected: _kind == _AccountKind.bank,
                  onTap: _pickBank,
                ),
              ),
            ],
          ),
          if (_kind == _AccountKind.bank) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              focusNode: _nameFocus,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              style:
                  GoogleFonts.beVietnamPro(color: AppTheme.primary, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Nombre del banco o billetera',
                hintText: 'Ej: PayPal, mi banco...',
                labelStyle: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant, fontSize: 13),
                filled: true,
                fillColor: AppTheme.surfaceContainerLow,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _balanceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [AmountInputFormatter()],
            style: GoogleFonts.beVietnamPro(color: AppTheme.primary, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Saldo inicial (opcional)',
              hintText: 'Ej: 50000',
              labelStyle: GoogleFonts.beVietnamPro(
                  color: AppTheme.onSurfaceVariant, fontSize: 13),
              filled: true,
              fillColor: AppTheme.surfaceContainerLow,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: GoogleFonts.beVietnamPro(
                    color: AppTheme.errorRed, fontSize: 13)),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.4),
                    )
                  : Text('Crear cuenta',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kindCard({
    required String label,
    required String description,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.secondary.withOpacity(0.08)
              : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.secondary : AppTheme.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: selected ? AppTheme.secondary : AppTheme.onSurfaceVariant,
                size: 24),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                color: selected ? AppTheme.secondary : AppTheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: GoogleFonts.beVietnamPro(
                color: AppTheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferSheet extends StatefulWidget {
  final List<AccountModel> accounts;

  const _TransferSheet({required this.accounts});

  @override
  State<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<_TransferSheet> {
  final _accountService = AccountService();
  final _amountCtrl = TextEditingController();
  String? _fromId;
  String? _toId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.accounts.isNotEmpty) _fromId = widget.accounts.first.id;
    if (widget.accounts.length > 1) _toId = widget.accounts[1].id;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _transfer() async {
    final amount = CurrencyFormatter.parse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Ingresa un monto válido');
      return;
    }
    if (_fromId == null || _toId == null || _fromId == _toId) {
      setState(() => _error = 'Elige dos cuentas distintas');
      return;
    }
    final from = widget.accounts.firstWhere((a) => a.id == _fromId);
    if (amount > from.balance) {
      setState(() => _error = 'Saldo insuficiente en ${from.name}');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await _accountService.transferBetweenAccounts(
      fromAccountId: _fromId!,
      toAccountId: _toId!,
      amount: amount,
    );
    if (!mounted) return;
    final to = widget.accounts.firstWhere((a) => a.id == _toId);
    showAppToast(
      context,
      message:
          'Transferiste ${CurrencyFormatter.format(amount)} de ${from.name} a ${to.name}',
      icon: Icons.swap_horiz_rounded,
      accentColor: AppTheme.secondary,
    );
    Navigator.pop(context);
  }

  Widget _accountDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: AppTheme.surfaceContainerLowest,
      style: GoogleFonts.beVietnamPro(color: AppTheme.primary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.beVietnamPro(
            color: AppTheme.onSurfaceVariant, fontSize: 13),
        filled: true,
        fillColor: AppTheme.surfaceContainerLow,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      items: widget.accounts
          .map((a) => DropdownMenuItem(
                value: a.id,
                child: Text('${a.name} · ${CurrencyFormatter.format(a.balance)}'),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 28,
        right: 28,
        top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Transferir entre cuentas',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.primary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          _accountDropdown(
            label: 'Desde',
            value: _fromId,
            onChanged: (v) => setState(() => _fromId = v),
          ),
          const SizedBox(height: 12),
          const Icon(Icons.arrow_downward_rounded,
              color: AppTheme.onSurfaceVariant, size: 20),
          const SizedBox(height: 12),
          _accountDropdown(
            label: 'Hacia',
            value: _toId,
            onChanged: (v) => setState(() => _toId = v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [AmountInputFormatter()],
            style: GoogleFonts.beVietnamPro(color: AppTheme.primary, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Monto a transferir',
              labelStyle: GoogleFonts.beVietnamPro(
                  color: AppTheme.onSurfaceVariant, fontSize: 13),
              filled: true,
              fillColor: AppTheme.surfaceContainerLow,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: GoogleFonts.beVietnamPro(
                    color: AppTheme.errorRed, fontSize: 13)),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _transfer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.4),
                    )
                  : Text('Transferir',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
