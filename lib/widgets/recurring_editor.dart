import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/recurring_transaction.dart';
import '../services/recurring_transaction_service.dart';
import '../theme/app_theme.dart';
import '../utils/amount_input_formatter.dart';
import '../utils/currency_formatter.dart';
import 'app_date_picker.dart';
import 'app_text_field.dart';
import 'app_toast.dart';
import 'form_kit.dart';
import 'pressable_scale.dart';

const _weekdayLetters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

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

/// Abre el formulario para crear o editar una regla de movimiento
/// recurrente: ventana modal centrada en escritorio (mismo patrón que
/// [openAddTransaction]), hoja inferior en móvil. La fecha de inicio
/// (`startDate`) no es editable una vez creada la regla: cambiar el ancla
/// reabriría la pregunta de qué pasa con las ocurrencias ya generadas, así
/// que se mantiene fija.
Future<void> showRecurringEditor(
  BuildContext context, {
  required String userId,
  RecurringTransactionModel? current,
}) {
  final isDesktop = MediaQuery.of(context).size.width >= 900;

  if (isDesktop) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => _RecurringEditorBody(
        userId: userId,
        current: current,
        isDialog: true,
      ),
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

  return showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surfaceContainerLowest,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _RecurringEditorBody(
      userId: userId,
      current: current,
      isDialog: false,
    ),
  );
}

class _RecurringEditorBody extends StatefulWidget {
  const _RecurringEditorBody({
    required this.userId,
    required this.current,
    required this.isDialog,
  });

  final String userId;
  final RecurringTransactionModel? current;
  final bool isDialog;

  @override
  State<_RecurringEditorBody> createState() => _RecurringEditorBodyState();
}

class _RecurringEditorBodyState extends State<_RecurringEditorBody> {
  final _service = RecurringTransactionService();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;

  late bool _isIncome;
  late String _category;
  String? _accountId;
  late RecurrenceFrequency _frequency;
  late int _interval;
  late int _dayOfWeek;
  late int _dayOfMonth;
  late bool _noEndDate;
  DateTime? _endDate;
  bool _isLoading = false;

  bool get _isEditing => widget.current != null;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    _titleCtrl = TextEditingController(text: current?.title ?? '');
    _amountCtrl = TextEditingController(
      text: current != null
          ? CurrencyFormatter.formatNumber(current.amount)
          : '',
    );
    _isIncome = current?.isIncome ?? false;
    _category = current?.category ?? 'Otros';
    _accountId = current?.accountId;
    _frequency = current?.frequency ?? RecurrenceFrequency.monthly;
    _interval = current?.interval ?? 1;
    _dayOfWeek = current?.dayOfWeek ?? current?.startDate.weekday ?? 1;
    _dayOfMonth = current?.dayOfMonth ?? current?.startDate.day ?? 1;
    _noEndDate = current?.endDate == null;
    _endDate = current?.endDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickEndDate() async {
    final base = widget.current?.startDate ?? DateTime.now();
    final picked = await showAppDatePicker(
      context,
      initialDate: _endDate ?? base,
      firstDate: base,
      lastDate: DateTime(base.year + 20),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _save() async {
    final amount = CurrencyFormatter.parse(_amountCtrl.text.trim());
    if (_titleCtrl.text.trim().isEmpty || amount == null || amount <= 0) {
      return;
    }
    setState(() => _isLoading = true);
    final current = widget.current;
    // No se crea además una transacción suelta para hoy: generateForRule ya
    // genera la primera ocurrencia (startDate siempre está vencida, porque
    // el date picker no permite fechas futuras).
    final base = RecurringTransactionModel(
      id: current?.id ?? '',
      userId: widget.userId,
      title: _titleCtrl.text.trim(),
      amount: amount,
      category: _category,
      isIncome: _isIncome,
      accountId: _accountId,
      note: current?.note,
      frequency: _frequency,
      interval: _interval,
      dayOfWeek: _frequency == RecurrenceFrequency.weekly ? _dayOfWeek : null,
      dayOfMonth: (_frequency == RecurrenceFrequency.monthly ||
              _frequency == RecurrenceFrequency.yearly)
          ? _dayOfMonth
          : null,
      startDate: current?.startDate ?? DateTime.now(),
      endDate: _noEndDate ? null : _endDate,
      lastGeneratedDate: current?.lastGeneratedDate,
    );
    try {
      if (current != null) {
        await _service.updateRule(base);
      } else {
        final saved = await _service.addRule(base);
        await _service.generateForRule(saved);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        showAppToast(
          context,
          message: 'No se pudo guardar. Intenta de nuevo.',
          icon: Icons.error_outline_rounded,
          accentColor: AppTheme.errorRed,
        );
      }
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final current = widget.current;
    if (current == null || _isLoading) return;
    final confirm = await confirmDestructiveAction(
      context,
      title: '¿Eliminar recurrente?',
      message:
          '"${current.title}" (${CurrencyFormatter.format(current.amount)}) dejará de generarse. Los movimientos ya creados no se eliminan.',
    );
    if (!confirm || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await _service.deleteRule(current.id);
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        showAppToast(
          context,
          message: 'No se pudo eliminar. Intenta de nuevo.',
          icon: Icons.error_outline_rounded,
          accentColor: AppTheme.errorRed,
        );
      }
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  Widget _frequencyPill(RecurrenceFrequency f) {
    final selected = _frequency == f;
    return PressableScale(
      onTap: () => setState(() => _frequency = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppTheme.navyFixed : AppTheme.surfaceContainerLow,
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
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 16, color: enabled ? AppTheme.primary : AppTheme.outlineVariant),
      ),
    );
  }

  Widget _buildFields({required bool compact}) {
    final gap = compact ? 12.0 : 14.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _titleCtrl,
          label: 'Descripción',
          icon: Icons.edit_note_rounded,
          textCapitalization: TextCapitalization.sentences,
          dense: compact,
        ),
        SizedBox(height: gap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: AppTextField(
                controller: _amountCtrl,
                label: 'Monto',
                icon: Icons.payments_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [AmountInputFormatter()],
                dense: compact,
              ),
            ),
            const SizedBox(width: 10),
            PressableScale(
              onTap: () => setState(() => _isIncome = !_isIncome),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: compact ? 46 : 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isIncome ? AppTheme.successFixed : AppTheme.dangerFixed,
                  borderRadius: BorderRadius.circular(compact ? 10 : 14),
                ),
                child: Text(
                  _isIncome ? 'Ingreso' : 'Gasto',
                  style: GoogleFonts.beVietnamPro(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        CategoryPickerField(
          selectedCategory: _category,
          onChanged: (v) => setState(() => _category = v),
          compact: compact,
          showQuickLinks: true,
        ),
        SizedBox(height: gap),
        AccountPickerField(
          selectedAccountId: _accountId,
          onChanged: (v) => setState(() => _accountId = v),
          dense: compact,
        ),
        SizedBox(height: compact ? 14 : 18),
        FormFieldLabel('Frecuencia', dense: compact),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: RecurrenceFrequency.values.map(_frequencyPill).toList(),
        ),
        SizedBox(height: gap + 2),
        FormFieldLabel('Cada cuánto', dense: compact),
        Row(
          children: [
            _stepperButton(Icons.remove_rounded,
                onTap: _interval > 1
                    ? () => setState(() => _interval--)
                    : null),
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
                onTap: _interval < 99
                    ? () => setState(() => _interval++)
                    : null),
            const SizedBox(width: 8),
            Text(_intervalUnitLabel(_frequency, _interval),
                style: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant, fontSize: 13.5)),
          ],
        ),
        if (_frequency == RecurrenceFrequency.weekly) ...[
          SizedBox(height: gap + 2),
          FormFieldLabel('Día de la semana', dense: compact),
          Row(
            children: List.generate(7, (i) {
              final dow = i + 1;
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
                            : AppTheme.surfaceContainerLow,
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
          ),
        ],
        if (_frequency == RecurrenceFrequency.monthly ||
            _frequency == RecurrenceFrequency.yearly) ...[
          SizedBox(height: gap + 2),
          FormFieldLabel('Día del mes', dense: compact),
          DropdownButtonFormField<int>(
            value: _dayOfMonth,
            isExpanded: true,
            dropdownColor: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.surfaceContainerLow,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: compact ? 9 : 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            items: List.generate(31, (i) => i + 1)
                .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text('Día $d',
                          style: GoogleFonts.beVietnamPro(
                              color: AppTheme.primary, fontSize: 14)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _dayOfMonth = v);
            },
          ),
        ],
        SizedBox(height: compact ? 14 : 16),
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
              onChanged: (v) => setState(() => _noEndDate = v),
            ),
          ],
        ),
        if (!_noEndDate) ...[
          const SizedBox(height: 4),
          AppFieldShell(
            icon: Icons.event_busy_outlined,
            onTap: _pickEndDate,
            dense: compact,
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.isDialog ? _buildDialog() : _buildSheet();
  }

  /// Ventana modal centrada (escritorio) — mismo patrón visual que
  /// [openAddTransaction]: tarjeta flotante con encabezado (ícono + título +
  /// subtítulo + cierre), cuerpo scrolleable y acciones flotantes fuera del
  /// scroll.
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
                              child: Icon(Icons.repeat_rounded,
                                  color: AppTheme.secondary, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isEditing
                                        ? 'Editar recurrente'
                                        : 'Nuevo recurrente',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.primary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Se repite automáticamente según la frecuencia',
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
                        _buildFields(compact: true),
                      ],
                    ),
                  ),
                ),
                _buildDialogFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 0, 36, 22),
      child: Row(
        children: [
          if (_isEditing)
            DangerTextAction(
              label: 'Eliminar recurrente',
              dense: true,
              onTap: _isLoading ? null : _delete,
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
                    _isEditing ? 'Guardar cambios' : 'Crear recurrente',
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

  /// Hoja inferior (móvil): mismo contenido que el diálogo, sin densidad
  /// reducida (hay más alto disponible que ancho para respetar).
  Widget _buildSheet() {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
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
              _isEditing ? 'Editar recurrente' : 'Nuevo recurrente',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _buildFields(compact: false),
            const SizedBox(height: 24),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FullWidthPrimaryButton(
                  label: _isEditing ? 'Guardar cambios' : 'Crear recurrente',
                  isLoading: _isLoading,
                  onTap: _save,
                ),
                if (_isEditing)
                  DangerTextAction(
                    label: 'Eliminar recurrente',
                    onTap: _isLoading ? null : _delete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
