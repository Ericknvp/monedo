import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/budget.dart';
import '../services/budget_service.dart';
import '../theme/app_theme.dart';
import '../utils/amount_input_formatter.dart';
import '../utils/currency_formatter.dart';

/// Hoja para fijar (o quitar) el presupuesto mensual de una categoría.
Future<void> showBudgetEditor(
  BuildContext context, {
  required String userId,
  required String category,
  BudgetModel? current,
}) {
  final ctrl = TextEditingController(
    text: current != null
        ? CurrencyFormatter.formatNumber(current.monthlyLimit)
        : '',
  );
  final service = BudgetService();

  return showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surfaceContainerLowest,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
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
            'Presupuesto de "$category"',
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
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [AmountInputFormatter()],
            style: GoogleFonts.beVietnamPro(color: AppTheme.primary, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Monto mensual',
              hintText: 'Ej: 400000',
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
          const SizedBox(height: 20),
          Row(
            children: [
              if (current != null)
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      await service.deleteBudget(current.id);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Quitar límite'),
                  ),
                ),
              if (current != null) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = CurrencyFormatter.parse(ctrl.text.trim());
                    if (amount == null || amount <= 0) return;
                    await service.setBudget(
                      userId: userId,
                      category: category,
                      monthlyLimit: amount,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
