import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/transaction_service.dart';
import '../services/account_service.dart';
import '../services/budget_alert_service.dart';
import '../services/expense_reminder_service.dart';
import '../services/recurring_transaction_service.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/recurring_transaction.dart';
import '../theme/app_theme.dart';
import '../utils/amount_input_formatter.dart';
import '../utils/currency_formatter.dart';
import '../widgets/app_toast.dart';
import '../widgets/undo_toast.dart';
import '../widgets/app_date_picker.dart';
import '../widgets/app_text_field.dart';
import '../widgets/form_kit.dart';
import '../widgets/pressable_scale.dart';

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
  final _amountFocus = FocusNode();
  final _txService = TransactionService();
  final _accountService = AccountService();
  final _recurringService = RecurringTransactionService();

  bool _isIncome = false;
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Otros';
  String? _selectedAccountId;
  bool _showNoteField = false;

  // Movimiento recurrente (solo aplica al crear uno nuevo, no al editar).
  bool _showRecurring = false;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  int _interval = 1;
  int? _dayOfWeek;
  int? _dayOfMonth;
  bool _noEndDate = true;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _amountFocus.addListener(() => setState(() {}));
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _titleCtrl.text = t.title;
      _amountCtrl.text = CurrencyFormatter.formatNumber(t.amount);
      _noteCtrl.text = t.note ?? '';
      _isIncome = t.isIncome;
      _selectedDate = t.date;
      _selectedCategory = t.category;
      _selectedAccountId = t.accountId;
      _showNoteField = _noteCtrl.text.isNotEmpty;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showAppDatePicker(
      context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectEndDate() async {
    final picked = await showAppDatePicker(
      context,
      initialDate: _endDate ?? _selectedDate,
      firstDate: _selectedDate,
      lastDate: DateTime(_selectedDate.year + 20),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  void _showError(String message) {
    showAppToast(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      accentColor: AppTheme.errorRed,
    );
  }

  Future<bool> _confirmInsufficientFunds(
      String accountName, double balance) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Fondos insuficientes',
            style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary, fontWeight: FontWeight.w700)),
        content: Text(
          '"$accountName" tiene ${CurrencyFormatter.format(balance)}. Este gasto dejaría el bolsillo en negativo. ¿Quieres continuar de todas formas?',
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
              backgroundColor: AppTheme.dangerFixed,
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
      _showError('Selecciona de qué bolsillo sale o entra el dinero');
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
        // Si se está editando el mismo movimiento sin cambiar de bolsillo,
        // el monto anterior ya estaba descontado: se repone antes de comparar.
        final alreadyDeducted = (widget.transaction != null &&
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
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    try {
      await _saveTransaction(userId: userId, amount: amount, note: note);
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('No se pudo guardar el movimiento. Intenta de nuevo.');
      }
      return;
    }
    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _saveTransaction({
    required String userId,
    required double amount,
    required String? note,
  }) async {
    if (widget.transaction == null && _showRecurring) {
      // No se crea además una transacción suelta para hoy: generateForRule
      // ya genera la primera ocurrencia (startDate siempre está vencida,
      // porque el date picker no permite fechas futuras).
      final rule = RecurringTransactionModel(
        id: '',
        userId: userId,
        title: _titleCtrl.text.trim(),
        amount: amount,
        category: _selectedCategory,
        isIncome: _isIncome,
        accountId: _selectedAccountId,
        note: note,
        frequency: _frequency,
        interval: _interval,
        dayOfWeek: _frequency == RecurrenceFrequency.weekly
            ? (_dayOfWeek ?? _selectedDate.weekday)
            : null,
        dayOfMonth: (_frequency == RecurrenceFrequency.monthly ||
                _frequency == RecurrenceFrequency.yearly)
            ? (_dayOfMonth ?? _selectedDate.day)
            : null,
        startDate: _selectedDate,
        endDate: _noEndDate ? null : _endDate,
      );
      final savedRule = await _recurringService.addRule(rule);
      // generateForRule ya dispara el aviso de presupuesto y la
      // notificación de "movimiento recurrente registrado" internamente.
      await _recurringService.generateForRule(savedRule);
      if (!kIsWeb) {
        await ExpenseReminderService().onTransactionSaved(_selectedDate);
      }
    } else {
      final tx = TransactionModel(
        id: widget.transaction?.id ?? '',
        userId: userId,
        title: _titleCtrl.text.trim(),
        amount: amount,
        category: _selectedCategory,
        isIncome: _isIncome,
        date: _selectedDate,
        note: note,
        accountId: _selectedAccountId,
        goalId: widget.transaction?.goalId,
        recurringId: widget.transaction?.recurringId,
      );
      if (widget.transaction != null) {
        await _txService.updateTransaction(widget.transaction!, tx);
      } else {
        await _txService.addTransaction(tx);
      }
      if (!kIsWeb) {
        await ExpenseReminderService().onTransactionSaved(tx.date);
        if (!_isIncome) {
          await BudgetAlertService().checkAfterExpense(
            userId: userId,
            category: tx.category,
            date: tx.date,
          );
        }
      }
    }
  }

  Future<void> _confirmDelete() async {
    final t = widget.transaction;
    if (t == null || _isLoading) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('¿Eliminar movimiento?',
            style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary, fontWeight: FontWeight.w600)),
        content: Text(
          'Se eliminará "${t.title}" (${CurrencyFormatter.format(t.amount)}).',
          style: GoogleFonts.beVietnamPro(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: AppTheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Eliminar',
                style: TextStyle(
                    color: AppTheme.errorRed, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    // El toast se inserta en el overlay raíz antes de cerrar esta pantalla,
    // así que sigue visible (y el borrado real sigue pendiente) aunque la
    // pantalla de edición ya se haya cerrado.
    showUndoToast(
      context,
      message: 'Eliminando "${t.title}"',
      onConfirmed: () => _txService.deleteTransaction(t),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _amountFocus.dispose();
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
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.primary),
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: _buildMobileFields(),
            ),
          ),
          _buildMobileFooter(isEditing),
        ],
      ),
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
            // Column con altura mínima: el cuerpo scrollea internamente al
            // llegar al maxHeight de arriba, mientras el footer de botones
            // queda fijo fuera del scroll (no se pierde al hacer scroll).
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(36, 26, 36, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.secondary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isEditing
                                    ? Icons.edit_note_rounded
                                    : Icons.receipt_long_rounded,
                                color: AppTheme.secondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Completa los datos del movimiento',
                                    style: GoogleFonts.beVietnamPro(
                                        color: AppTheme.onSurfaceVariant,
                                        fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded,
                                  color: AppTheme.onSurfaceVariant),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildFormFields(isEditing),
                      ],
                    ),
                  ),
                ),
                _buildDialogFooter(isEditing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Acciones flotantes del diálogo de escritorio: sin barra ni fondo
  /// detrás, solo los botones con su propia sombra (como el FAB de "+" en
  /// móvil), quedando fijos fuera del área scrolleable.
  /// Un solo botón manda: el primario flota a la derecha, y "Eliminar"
  /// (si se está editando) queda como texto discreto a la izquierda — sin
  /// "Cancelar", ya que la "X" del encabezado cierra el diálogo.
  Widget _buildDialogFooter(bool isEditing) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 0, 36, 22),
      child: Row(
        children: [
          if (isEditing)
            DangerTextAction(
              label: 'Eliminar movimiento',
              dense: true,
              onTap: _isLoading ? null : _confirmDelete,
            ),
          const Spacer(),
          FloatingPillButton(
            color: AppTheme.secondary,
            width: 220,
            onTap: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.4),
                  )
                : Text(
                    isEditing ? 'Guardar cambios' : 'Agregar movimiento',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Versión de escritorio: más densa que móvil (héroe más chico, menos
  /// aire entre secciones) para que todo el formulario quepa en el diálogo
  /// sin scroll — hay ancho de sobra, pero el alto es limitado.
  Widget _buildFormFields(bool isEditing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _buildDesktopAmountField()),
            const SizedBox(width: 14),
            _buildTypeToggle(compact: true),
          ],
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _titleCtrl,
          label: 'Descripción',
          icon: Icons.edit_note_rounded,
          textCapitalization: TextCapitalization.sentences,
          dense: true,
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildDatePicker(dense: true)),
            const SizedBox(width: 16),
            Expanded(child: _buildAccountDropdown(dense: true)),
          ],
        ),
        const SizedBox(height: 14),
        _buildCategoryDropdown(compact: true),
        const SizedBox(height: 8),
        _buildNoteField(dense: true, compact: true),
        if (!isEditing) ...[
          const SizedBox(height: 8),
          _buildRecurringSection(compact: true),
        ],
      ],
    );
  }

  /// Campos de la pantalla completa de móvil, sin los botones (esos van en
  /// [_buildMobileFooter], fijos abajo fuera del scroll).
  Widget _buildMobileFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAmountHero(),
        const SizedBox(height: 20),
        AppTextField(
          controller: _titleCtrl,
          label: 'Descripción',
          icon: Icons.edit_note_rounded,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildDatePicker()),
            const SizedBox(width: 16),
            Expanded(child: _buildAccountDropdown()),
          ],
        ),
        const SizedBox(height: 16),
        _buildCategoryDropdown(),
        const SizedBox(height: 16),
        _buildNoteField(),
        if (widget.transaction == null) ...[
          const SizedBox(height: 16),
          _buildRecurringSection(),
        ],
      ],
    );
  }

  /// Botones fijos abajo, fuera del área que scrollea: un solo botón
  /// primario a todo el ancho, y (solo al editar) "Eliminar" como texto
  /// discreto debajo — sin "Cancelar", ya está la flecha de la AppBar.
  Widget _buildMobileFooter(bool isEditing) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 14, 24, MediaQuery.of(context).padding.bottom + 18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border(
            top: BorderSide(color: AppTheme.surfaceContainerHigh)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FullWidthPrimaryButton(
            label: isEditing ? 'Guardar cambios' : 'Agregar movimiento',
            isLoading: _isLoading,
            onTap: _save,
          ),
          if (isEditing)
            DangerTextAction(
              label: 'Eliminar movimiento',
              onTap: _isLoading ? null : _confirmDelete,
            ),
        ],
      ),
    );
  }

  /// Monto primero (solo móvil): número gigante que lleva el color/signo
  /// del tipo (Gasto/Ingreso), con el selector de tipo como píldora
  /// compacta encima — mismo campo de texto y `AmountInputFormatter` de
  /// siempre, solo que se ve como un display en vez de una caja de
  /// formulario. En escritorio se usa [_buildDesktopAmountField] en su
  /// lugar: un "hero" táctil de pantalla completa no encaja en un diálogo
  /// pensado para mouse y teclado.
  Widget _buildAmountHero() {
    final color = _isIncome ? AppTheme.secondary : AppTheme.errorRed;
    const amountSize = 52.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildTypeToggle(),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    _isIncome ? '+' : '−',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, right: 2),
                  child: Text(
                    CurrencyFormatter.current.symbol,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IntrinsicWidth(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [AmountInputFormatter()],
                    textAlign: TextAlign.center,
                    cursorColor: color,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: amountSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -amountSize * 0.023,
                      color: color,
                      height: 1,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      isCollapsed: true,
                      hintText: '0',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: amountSize,
                        fontWeight: FontWeight.w800,
                        color: color.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.current.code,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  /// Monto para escritorio: campo normal (no "hero"), del mismo tamaño que
  /// los demás controles del diálogo, con anillo de foco del color del tipo
  /// — va en la misma fila que el selector Gasto/Ingreso compacto.
  Widget _buildDesktopAmountField() {
    final color = _isIncome ? AppTheme.secondary : AppTheme.errorRed;
    final focused = _amountFocus.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel('Monto', dense: true),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: focused
                ? AppTheme.surfaceContainerLowest
                : AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: focused ? color : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.14),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _isIncome ? '+' : '−',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 17, fontWeight: FontWeight.w700, color: color),
              ),
              const SizedBox(width: 2),
              Text(
                CurrencyFormatter.current.symbol,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(width: 4),
              IntrinsicWidth(
                child: TextField(
                  controller: _amountCtrl,
                  focusNode: _amountFocus,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [AmountInputFormatter()],
                  cursorColor: color,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: color,
                    height: 1,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    isCollapsed: true,
                    hintText: '0',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Píldora Gasto/Ingreso con un thumb que se desliza de un segmento al
  /// otro (en vez de solo cambiar de color): los dos segmentos miden lo
  /// mismo para que el thumb pueda animarse con un simple `AnimatedAlign`.
  /// `compact` es la variante de escritorio: más chica y con radio cerrado
  /// (9px) en vez de píldora completa — al lado del monto, no como una
  /// barra propia encima.
  Widget _buildTypeToggle({bool compact = false}) {
    final segmentWidth = compact ? 70.0 : 98.0;
    final segmentHeight = compact ? 26.0 : 30.0;
    final outerRadius = compact ? 9.0 : 100.0;
    final innerRadius = compact ? 7.0 : 100.0;
    final fontSize = compact ? 11.0 : 12.5;
    final iconSize = compact ? 13.0 : 15.0;
    final color = _isIncome ? AppTheme.successFixed : AppTheme.dangerFixed;

    Widget seg(String label, bool isIncome, IconData icon) {
      final selected = _isIncome == isIncome;
      return PressableScale(
        onTap: () => setState(() => _isIncome = isIncome),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: segmentWidth,
          height: segmentHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(
                    end: selected
                        ? Colors.white
                        : AppTheme.onSurfaceVariant),
                duration: const Duration(milliseconds: 180),
                builder: (context, iconColor, _) =>
                    Icon(icon, size: iconSize, color: iconColor),
              ),
              const SizedBox(width: 5),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: GoogleFonts.beVietnamPro(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppTheme.onSurfaceVariant,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(outerRadius),
      ),
      // Tamaño fijo explícito: sin esto, el Stack hereda el ancho suelto de
      // todo el héroe (mucho más ancho que los dos segmentos) y el thumb,
      // al centrarse dentro de ese espacio de sobra, se desborda del pill.
      child: SizedBox(
        width: segmentWidth * 2,
        height: segmentHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment:
                _isIncome ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: segmentWidth,
              height: segmentHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(innerRadius),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              seg('Gasto', false, Icons.trending_down_rounded),
              seg('Ingreso', true, Icons.trending_up_rounded),
            ],
          ),
          ],
        ),
      ),
    );
  }

  static const _weekdayLetters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  String _frequencyLabel(RecurrenceFrequency f) {
    switch (f) {
      case RecurrenceFrequency.daily:
        return 'Diario';
      case RecurrenceFrequency.weekly:
        return 'Semanal';
      case RecurrenceFrequency.monthly:
        return 'Mensual';
      case RecurrenceFrequency.yearly:
        return 'Anual';
    }
  }

  String _intervalUnitLabel(RecurrenceFrequency f, int n) {
    final plural = n != 1;
    switch (f) {
      case RecurrenceFrequency.daily:
        return plural ? 'días' : 'día';
      case RecurrenceFrequency.weekly:
        return plural ? 'semanas' : 'semana';
      case RecurrenceFrequency.monthly:
        return plural ? 'meses' : 'mes';
      case RecurrenceFrequency.yearly:
        return plural ? 'años' : 'año';
    }
  }

  /// Sección "Hacer movimiento recurrente" (escritorio) / "Hacer recurrente"
  /// (móvil), colapsada por defecto igual que
  /// [_buildNoteField]: solo se muestra al crear un movimiento nuevo (no
  /// al editar uno ya existente, que edita esa transacción puntual y no la
  /// regla recurrente que la generó).
  Widget _buildRecurringSection({bool compact = false}) {
    void expand() => setState(() {
          _showRecurring = true;
          _dayOfWeek ??= _selectedDate.weekday;
          _dayOfMonth ??= _selectedDate.day;
        });

    if (!_showRecurring) {
      if (compact) {
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: expand,
          hoverColor: AppTheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.repeat_rounded,
                    size: 15, color: AppTheme.onSurfaceVariant),
                const SizedBox(width: 7),
                Text(
                  'Hacer movimiento recurrente',
                  style: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: expand,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            children: [
              Icon(Icons.repeat_rounded,
                  size: 18, color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hacer recurrente',
                  style: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.repeat_rounded, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  compact ? 'Hacer movimiento recurrente' : 'Hacer recurrente',
                  style: GoogleFonts.beVietnamPro(
                    color: AppTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Activado',
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.successFixed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Switch(
                value: _showRecurring,
                activeThumbColor: AppTheme.successFixed,
                onChanged: (v) => setState(() => _showRecurring = v),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FormFieldLabel('Frecuencia'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RecurrenceFrequency.values
                .map((f) => _frequencyPill(f))
                .toList(),
          ),
          const SizedBox(height: 14),
          FormFieldLabel('Cada cuánto'),
          _intervalStepper(),
          if (_frequency == RecurrenceFrequency.weekly) ...[
            const SizedBox(height: 14),
            FormFieldLabel('Día de la semana'),
            _dayOfWeekPicker(),
          ],
          if (_frequency == RecurrenceFrequency.monthly ||
              _frequency == RecurrenceFrequency.yearly) ...[
            const SizedBox(height: 14),
            FormFieldLabel('Día del mes'),
            _dayOfMonthField(),
          ],
          const SizedBox(height: 14),
          _endDateControl(),
        ],
      ),
    );
  }

  Widget _frequencyPill(RecurrenceFrequency f) {
    final selected = _frequency == f;
    return PressableScale(
      onTap: () => setState(() => _frequency = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color:
              selected ? AppTheme.navyFixed : AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          _frequencyLabel(f),
          style: GoogleFonts.beVietnamPro(
            color: selected ? Colors.white : AppTheme.onSurfaceVariant,
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _stepperButton(IconData icon, {VoidCallback? onTap}) {
    final enabled = onTap != null;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 16, color: enabled ? AppTheme.primary : AppTheme.outlineVariant),
      ),
    );
  }

  Widget _intervalStepper() {
    return Row(
      children: [
        Text('Cada',
            style: GoogleFonts.beVietnamPro(
                color: AppTheme.onSurfaceVariant, fontSize: 13.5)),
        const SizedBox(width: 10),
        _stepperButton(Icons.remove_rounded,
            onTap: _interval > 1 ? () => setState(() => _interval--) : null),
        SizedBox(
          width: 36,
          child: Text(
            '$_interval',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
                color: AppTheme.primary,
                fontSize: 15,
                fontWeight: FontWeight.w700),
          ),
        ),
        _stepperButton(Icons.add_rounded,
            onTap: _interval < 99 ? () => setState(() => _interval++) : null),
        const SizedBox(width: 8),
        Text(_intervalUnitLabel(_frequency, _interval),
            style: GoogleFonts.beVietnamPro(
                color: AppTheme.onSurfaceVariant, fontSize: 13.5)),
      ],
    );
  }

  Widget _dayOfWeekPicker() {
    return Row(
      children: List.generate(7, (i) {
        final dow = i + 1; // 1=lunes .. 7=domingo (DateTime.weekday)
        final selected = _dayOfWeek == dow;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
            child: InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: () => setState(() => _dayOfWeek = dow),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.navyFixed
                      : AppTheme.surfaceContainerLowest,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _weekdayLetters[i],
                  style: GoogleFonts.beVietnamPro(
                    color: selected ? Colors.white : AppTheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _dayOfMonthField() {
    return AppFieldShell(
      icon: Icons.event_note_outlined,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _dayOfMonth,
          isExpanded: true,
          isDense: true,
          icon: Icon(Icons.expand_more_rounded,
              color: AppTheme.onSurfaceVariant, size: 18),
          dropdownColor: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          items: List.generate(31, (i) => i + 1)
              .map((d) => DropdownMenuItem(
                    value: d,
                    child: Text('Día $d',
                        style: GoogleFonts.beVietnamPro(
                            color: AppTheme.primary, fontSize: 14)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _dayOfMonth = v),
        ),
      ),
    );
  }

  Widget _endDateControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Sin fecha de fin',
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.primary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch(
              value: _noEndDate,
              activeThumbColor: AppTheme.successFixed,
              onChanged: (v) => setState(() {
                _noEndDate = v;
                _endDate ??= DateTime(
                    _selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
              }),
            ),
          ],
        ),
        if (!_noEndDate)
          AppFieldShell(
            icon: Icons.event_busy_outlined,
            onTap: _selectEndDate,
            child: Text(
              _endDate == null
                  ? 'Selecciona una fecha'
                  : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
              style: GoogleFonts.beVietnamPro(
                  color: AppTheme.primary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  /// Campo de nota colapsado por defecto: muestra un botón compacto que,
  /// al tocarlo, revela el campo de texto (evita ocupar espacio fijo
  /// cuando la mayoría de movimientos no llevan nota).
  Widget _buildNoteField({bool dense = false, bool compact = false}) {
    if (!_showNoteField) {
      // En escritorio: link de texto plano con hover, no la píldora táctil
      // de móvil — coherente con el resto de controles densos del diálogo.
      if (compact) {
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _showNoteField = true),
          hoverColor: AppTheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.note_add_outlined,
                    size: 15, color: AppTheme.onSurfaceVariant),
                const SizedBox(width: 7),
                Text(
                  _noteCtrl.text.isEmpty
                      ? 'Agregar nota (opcional)'
                      : _noteCtrl.text,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: () => setState(() => _showNoteField = true),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
              horizontal: 16, vertical: dense ? 9 : 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            children: [
              Icon(Icons.note_add_outlined,
                  size: 18, color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _noteCtrl.text.isEmpty
                      ? 'Agregar nota (opcional)'
                      : _noteCtrl.text,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AppTextField(
          controller: _noteCtrl,
          label: 'Nota (opcional)',
          icon: Icons.note_outlined,
          maxLines: 3,
          dense: dense,
        ),
        TextButton.icon(
          onPressed: () => setState(() => _showNoteField = false),
          icon: const Icon(Icons.expand_less_rounded, size: 18),
          label: Text('Ocultar',
              style: GoogleFonts.beVietnamPro(fontSize: 12)),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.onSurfaceVariant,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 28),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown({bool compact = false}) {
    return CategoryPickerField(
      selectedCategory: _selectedCategory,
      onChanged: (v) => setState(() => _selectedCategory = v),
      compact: compact,
    );
  }

  Widget _buildAccountDropdown({bool dense = false}) {
    return AccountPickerField(
      selectedAccountId: _selectedAccountId,
      onChanged: (v) => setState(() => _selectedAccountId = v),
      label: _isIncome ? 'Recibido en' : 'Pagado con',
      dense: dense,
    );
  }

  Widget _buildDatePicker({bool dense = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel('Fecha', dense: dense),
        AppFieldShell(
          icon: Icons.calendar_today_outlined,
          onTap: _selectDate,
          dense: dense,
          child: Text(
            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            style:
                GoogleFonts.beVietnamPro(color: AppTheme.primary, fontSize: 14.5, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
