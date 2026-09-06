import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/transaction_service.dart';
import '../services/account_service.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../theme/app_theme.dart';
import '../utils/amount_input_formatter.dart';
import '../utils/currency_formatter.dart';
import '../utils/category_icons.dart';
import '../utils/category_colors.dart';
import 'categories_screen.dart';
import 'accounts_screen.dart';
import '../widgets/app_toast.dart';

/// Abre el formulario de movimiento: como una ventana modal centrada (con
/// fondo oscurecido) en escritorio, o a pantalla completa en móvil.
Future<void> openAddTransaction(
  BuildContext context, {
  TransactionModel? transaction,
}) {
  final isDesktop = MediaQuery.of(context).size.width >= 900;

  if (isDesktop) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) =>
          AddTransactionScreen(transaction: transaction, isDialog: true),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
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
    MaterialPageRoute(
      builder: (_) => AddTransactionScreen(transaction: transaction),
    ),
  );
}

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;
  final bool isDialog;

  const AddTransactionScreen({
    super.key,
    this.transaction,
    this.isDialog = false,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _txService = TransactionService();
  final _accountService = AccountService();

  bool _isIncome = false;
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Otros';
  String? _selectedAccountId;

  static const _categories = [
    'Alimentación', 'Transporte', 'Entretenimiento', 'Salud',
    'Educación', 'Ropa', 'Hogar', 'Trabajo', 'Inversión',
    'Ahorro', 'Ocio', 'Otros',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _titleCtrl.text = t.title;
      _amountCtrl.text = CurrencyFormatter.formatNumber(t.amount);
      _noteCtrl.text = t.note ?? '';
      _isIncome = t.isIncome;
      _selectedDate = t.date;
      _selectedCategory = t.category;
      _selectedAccountId = t.accountId;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.secondary,
            surface: AppTheme.surfaceContainerLowest,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _showError(String message) {
    showAppToast(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      accentColor: AppTheme.errorRed,
    );
  }

  Future<bool> _confirmInsufficientFunds(String accountName, double balance) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Fondos insuficientes',
            style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary, fontWeight: FontWeight.w700)),
        content: Text(
          '"$accountName" tiene ${CurrencyFormatter.format(balance)}. Este gasto dejaría la cuenta en negativo. ¿Quieres continuar de todas formas?',
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
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    return confirm == true;
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _amountCtrl.text.trim().isEmpty) {
      _showError('Por favor completa todos los campos');
      return;
    }
    final amount = CurrencyFormatter.parse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      _showError('El monto debe ser un número válido mayor a 0');
      return;
    }
    if (_selectedAccountId == null) {
      _showError('Selecciona de qué cuenta sale o entra el dinero');
      return;
    }

    if (!_isIncome) {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final accounts = await _accountService.getAccounts(userId).first;
      AccountModel? account;
      for (final a in accounts) {
        if (a.id == _selectedAccountId) {
          account = a;
          break;
        }
      }
      if (account != null) {
        // Si se está editando el mismo movimiento sin cambiar de cuenta,
        // el monto anterior ya estaba descontado: se repone antes de comparar.
        final alreadyDeducted =
            (widget.transaction != null &&
                    !widget.transaction!.isIncome &&
                    widget.transaction!.accountId == _selectedAccountId)
                ? widget.transaction!.amount
                : 0.0;
        final availableBalance = account.balance + alreadyDeducted;
        if (amount > availableBalance) {
          final proceed =
              await _confirmInsufficientFunds(account.name, availableBalance);
          if (!proceed) return;
        }
      }
    }

    setState(() => _isLoading = true);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final tx = TransactionModel(
      id: widget.transaction?.id ?? '',
      userId: userId,
      title: _titleCtrl.text.trim(),
      amount: amount,
      category: _selectedCategory,
      isIncome: _isIncome,
      date: _selectedDate,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      accountId: _selectedAccountId,
      goalId: widget.transaction?.goalId,
    );
    if (widget.transaction != null) {
      await _txService.updateTransaction(widget.transaction!, tx);
    } else {
      await _txService.addTransaction(tx);
    }
    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;

    if (widget.isDialog) {
      return _buildDialog(isEditing);
    }

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
          isEditing ? 'Editar movimiento' : 'Nuevo movimiento',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.primary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildMobile(isEditing),
    );
  }

  /// Ventana modal centrada (escritorio): misma tarjeta de formulario que
  /// antes ocupaba toda la pantalla, ahora flotando sobre el fondo
  /// oscurecido, con un botón de cierre en vez de una AppBar completa.
  Widget _buildDialog(bool isEditing) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
          child: Material(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            elevation: 24,
            shadowColor: Colors.black.withOpacity(0.4),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(36, 32, 36, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isEditing
                              ? Icons.edit_note_rounded
                              : Icons.receipt_long_rounded,
                          color: AppTheme.secondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing
                                  ? 'Editar movimiento'
                                  : 'Registrar movimiento',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.primary,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Completa los datos del movimiento',
                              style: GoogleFonts.beVietnamPro(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppTheme.onSurfaceVariant),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildFormFields(isEditing),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields(bool isEditing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
              _buildTypeSelector(),
              const SizedBox(height: 28),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _textField(
                      _titleCtrl,
                      'Descripción',
                      icon: Icons.description_outlined,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: _textField(
                      _amountCtrl,
                      'Monto',
                      icon: Icons.attach_money_rounded,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [AmountInputFormatter()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildCategoryDropdown()),
                  const SizedBox(width: 20),
                  Expanded(child: _buildDatePicker()),
                ],
              ),
              const SizedBox(height: 20),

              _buildAccountDropdown(),
              const SizedBox(height: 20),

              _textField(_noteCtrl, 'Nota (opcional)',
                  icon: Icons.note_outlined, maxLines: 3),
              const SizedBox(height: 28),

              Divider(height: 1, color: AppTheme.surfaceVariant),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar',
                        style: TextStyle(color: AppTheme.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 220,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isEditing
                                  ? 'Guardar cambios'
                                  : 'Agregar movimiento',
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildMobile(bool isEditing) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTypeSelector(),
          const SizedBox(height: 24),
          _textField(_titleCtrl, 'Descripción',
              icon: Icons.description_outlined),
          const SizedBox(height: 16),
          _textField(_amountCtrl, 'Monto',
              icon: Icons.attach_money_rounded,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [AmountInputFormatter()]),
          const SizedBox(height: 16),
          _buildCategoryDropdown(),
          const SizedBox(height: 16),
          _buildDatePicker(),
          const SizedBox(height: 16),
          _buildAccountDropdown(),
          const SizedBox(height: 16),
          _textField(_noteCtrl, 'Nota (opcional)',
              icon: Icons.note_outlined, maxLines: 3),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      isEditing ? 'Guardar cambios' : 'Agregar movimiento',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    final selectedColor = _isIncome ? AppTheme.secondary : AppTheme.errorRed;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(100),
      ),
      padding: const EdgeInsets.all(4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedAlign(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment:
                    _isIncome ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: constraints.maxWidth / 2,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: selectedColor.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Row(
            children: [
              Expanded(child: _typeBtn('Gasto', false)),
              Expanded(child: _typeBtn('Ingreso', true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeBtn(String label, bool isIncome) {
    final isSelected = _isIncome == isIncome;
    final icon =
        isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    return GestureDetector(
      onTap: () => setState(() => _isIncome = isIncome),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              icon,
              key: ValueKey(isSelected),
              size: 16,
              color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.plusJakartaSans(
              color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String label, {
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.beVietnamPro(color: AppTheme.primary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.beVietnamPro(
            color: AppTheme.onSurfaceVariant, fontSize: 13),
        prefixIcon: icon != null
            ? Icon(icon, color: AppTheme.secondary, size: 20)
            : null,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return ValueListenableBuilder<Map<String, IconData>>(
      valueListenable: CategoryIconRegistry.customIcons,
      builder: (context, customIcons, _) {
        final customNames = customIcons.keys
            .where((n) => !_categories.contains(n))
            .toList()
          ..sort();
        final allNames = <String>{
          ..._categories,
          ...customNames,
          _selectedCategory,
        }.toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              dropdownColor: AppTheme.surfaceContainerLowest,
              style: GoogleFonts.beVietnamPro(
                  color: AppTheme.primary, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Categoría',
                labelStyle: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant, fontSize: 13),
                prefixIcon: Icon(CategoryIconRegistry.iconFor(_selectedCategory),
                    color: CategoryColors.forCategory(_selectedCategory), size: 20),
              ),
              items: allNames
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CategoryIconRegistry.iconFor(c),
                                size: 18, color: CategoryColors.forCategory(c)),
                            const SizedBox(width: 10),
                            Text(c),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                final created = await showAddCategorySheet(
                  context,
                  userId: userId,
                  existingNames: {..._categories, ...customNames},
                );
                if (created != null) {
                  setState(() => _selectedCategory = created);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline_rounded,
                        size: 15, color: AppTheme.secondary),
                    const SizedBox(width: 6),
                    Text(
                      'Agregar categoría',
                      style: GoogleFonts.beVietnamPro(
                        color: AppTheme.secondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountDropdown() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<List<AccountModel>>(
      stream: _accountService.getAccounts(userId),
      builder: (context, snap) {
        final accounts = snap.data ?? [];
        final hasSelection =
            accounts.any((a) => a.id == _selectedAccountId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: hasSelection ? _selectedAccountId : null,
              dropdownColor: AppTheme.surfaceContainerLowest,
              style: GoogleFonts.beVietnamPro(
                  color: AppTheme.primary, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Cuenta',
                labelStyle: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant, fontSize: 13),
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined,
                    color: AppTheme.secondary, size: 20),
              ),
              hint: Text('Selecciona una cuenta',
                  style: GoogleFonts.beVietnamPro(
                      color: AppTheme.outline, fontSize: 14)),
              items: accounts
                  .map((a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(a.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedAccountId = v),
            ),
            const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                final created =
                    await showAddAccountSheet(context, userId: userId);
                if (created != null) {
                  setState(() => _selectedAccountId = created);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline_rounded,
                        size: 15, color: AppTheme.secondary),
                    const SizedBox(width: 6),
                    Text(
                      'Agregar cuenta',
                      style: GoogleFonts.beVietnamPro(
                        color: AppTheme.secondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _fieldDecoration(String label, {IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          GoogleFonts.beVietnamPro(color: AppTheme.onSurfaceVariant, fontSize: 13),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppTheme.secondary, size: 20)
          : null,
    );
  }

  Widget _buildDatePicker() {
    // Se usa InputDecorator (con la misma _fieldDecoration de los demás
    // campos) para que la caja tenga exactamente el mismo alto y estilo
    // que el dropdown de categoría de al lado, y no se vean desalineados.
    return GestureDetector(
      onTap: _selectDate,
      child: InputDecorator(
        decoration:
            _fieldDecoration('Fecha', prefixIcon: Icons.calendar_today_outlined),
        child: Text(
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          style: GoogleFonts.beVietnamPro(color: AppTheme.primary, fontSize: 15),
        ),
      ),
    );
  }
}
