import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/budget.dart';
import '../services/budget_service.dart';
import '../theme/app_theme.dart';
import '../utils/amount_input_formatter.dart';
import '../utils/currency_formatter.dart';
import 'app_text_field.dart';
import 'form_kit.dart';

/// Abre el editor de presupuesto: ventana modal centrada (con fondo
/// oscurecido) en escritorio, hoja inferior en móvil — mismo patrón que
/// `openAddTransaction` en add_transaction_screen.dart.
Future<void> showBudgetEditor(
  BuildContext context, {
  required String userId,
  required String category,
  BudgetModel? current,
}) {
  final isDesktop = MediaQuery.of(context).size.width >= 900;

  if (isDesktop) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => _BudgetEditor(
        userId: userId,
        category: category,
        current: current,
        isDesktop: true,
      ),
    );
  }

  return showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surfaceContainerLowest,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _BudgetEditor(
      userId: userId,
      category: category,
      current: current,
      isDesktop: false,
    ),
  );
}

class _BudgetEditor extends StatefulWidget {
  const _BudgetEditor({
    required this.userId,
    required this.category,
    required this.current,
    required this.isDesktop,
  });

  final String userId;
  final String category;
  final BudgetModel? current;
  final bool isDesktop;

  @override
  State<_BudgetEditor> createState() => _BudgetEditorState();
}

class _BudgetEditorState extends State<_BudgetEditor> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.current != null
        ? CurrencyFormatter.formatNumber(widget.current!.monthlyLimit)
        : '',
  );
  final _service = BudgetService();
  bool _isLoading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = CurrencyFormatter.parse(_ctrl.text.trim());
    if (amount == null || amount <= 0) return;
    setState(() => _isLoading = true);
    try {
      await _service.setBudget(
        userId: widget.userId,
        category: widget.category,
        monthlyLimit: amount,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final current = widget.current;
    if (current == null || _isLoading) return;
    final confirm = await confirmDestructiveAction(
      context,
      title: '¿Quitar límite?',
      message:
          'Se quitará el límite mensual de "${widget.category}". Podrás fijar uno nuevo cuando quieras.',
      confirmLabel: 'Quitar',
    );
    if (!confirm || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await _service.deleteBudget(current.id);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (mounted) Navigator.pop(context);
  }

  Widget _amountField({bool dense = false}) {
    return AppTextField(
      controller: _ctrl,
      label: 'Monto mensual',
      icon: Icons.payments_outlined,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [AmountInputFormatter()],
      autofocus: !widget.isDesktop,
      dense: dense,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDesktop) return _buildDialog();
    return _buildSheet();
  }

  Widget _buildDialog() {
    final isEditing = widget.current != null;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 16),
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
                            child: Icon(Icons.pie_chart_rounded,
                                color: AppTheme.secondary, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Presupuesto de "${widget.category}"',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.primary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Cada mes se compara contra lo gastado en esta categoría.',
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
                      const SizedBox(height: 18),
                      _amountField(dense: true),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 22),
                  child: Row(
                    children: [
                      if (isEditing)
                        DangerTextAction(
                          label: 'Quitar límite',
                          dense: true,
                          onTap: _isLoading ? null : _delete,
                        ),
                      const Spacer(),
                      FloatingPillButton(
                        color: AppTheme.secondary,
                        width: 160,
                        onTap: _isLoading ? null : _save,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.4),
                              )
                            : Text(
                                'Guardar',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheet() {
    final isEditing = widget.current != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
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
            'Presupuesto de "${widget.category}"',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Límite mensual: cada mes se compara contra lo gastado en esta categoría.',
            style: GoogleFonts.beVietnamPro(
              color: AppTheme.onSurfaceVariant,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _amountField(),
          const SizedBox(height: 24),
          FullWidthPrimaryButton(
            label: 'Guardar',
            isLoading: _isLoading,
            onTap: _save,
          ),
          if (isEditing)
            Center(
              child: DangerTextAction(
                label: 'Quitar límite',
                onTap: _isLoading ? null : _delete,
              ),
            ),
        ],
      ),
    );
  }
}
