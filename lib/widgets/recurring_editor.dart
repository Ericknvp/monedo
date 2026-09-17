import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/account.dart';
import '../models/recurring_transaction.dart';
import '../services/account_service.dart';
import '../services/recurring_transaction_service.dart';
import '../theme/app_theme.dart';
import '../utils/account_colors.dart';
import '../utils/amount_input_formatter.dart';
import '../utils/category_colors.dart';
import '../utils/category_icons.dart';
import '../utils/currency_formatter.dart';
import 'app_date_picker.dart';
import 'app_toast.dart';
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

/// Hoja para crear o editar una regla de movimiento recurrente. La fecha de
/// inicio (`startDate`) no es editable una vez creada la regla: cambiar el
/// ancla reabriría la pregunta de qué pasa con las ocurrencias ya
/// generadas, así que se mantiene fija.
Future<void> showRecurringEditor(
  BuildContext context, {
  required String userId,
  RecurringTransactionModel? current,
}) {
  final service = RecurringTransactionService();
  final titleCtrl = TextEditingController(text: current?.title ?? '');
  final amountCtrl = TextEditingController(
    text: current != null
        ? CurrencyFormatter.formatNumber(current.amount)
        : '',
  );

  return showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surfaceContainerLowest,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      var isIncome = current?.isIncome ?? false;
      var category = current?.category ?? 'Otros';
      var accountId = current?.accountId;
      var frequency = current?.frequency ?? RecurrenceFrequency.monthly;
      var interval = current?.interval ?? 1;
      var dayOfWeek = current?.dayOfWeek ?? current?.startDate.weekday ?? 1;
      var dayOfMonth = current?.dayOfMonth ?? current?.startDate.day ?? 1;
      var noEndDate = current?.endDate == null;
      var endDate = current?.endDate;

      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> pickEndDate() async {
            final base = current?.startDate ?? DateTime.now();
            final picked = await showAppDatePicker(
              ctx,
              initialDate: endDate ?? base,
              firstDate: base,
              lastDate: DateTime(base.year + 20),
            );
            if (picked != null) setSheetState(() => endDate = picked);
          }

          Future<void> save() async {
            final amount = CurrencyFormatter.parse(amountCtrl.text.trim());
            if (titleCtrl.text.trim().isEmpty || amount == null || amount <= 0) {
              return;
            }
            final base = RecurringTransactionModel(
              id: current?.id ?? '',
              userId: userId,
              title: titleCtrl.text.trim(),
              amount: amount,
              category: category,
              isIncome: isIncome,
              accountId: accountId,
              note: current?.note,
              frequency: frequency,
              interval: interval,
              dayOfWeek: frequency == RecurrenceFrequency.weekly ? dayOfWeek : null,
              dayOfMonth: (frequency == RecurrenceFrequency.monthly ||
                      frequency == RecurrenceFrequency.yearly)
                  ? dayOfMonth
                  : null,
              startDate: current?.startDate ?? DateTime.now(),
              endDate: noEndDate ? null : endDate,
              lastGeneratedDate: current?.lastGeneratedDate,
            );
            try {
              if (current != null) {
                await service.updateRule(base);
              } else {
                final saved = await service.addRule(base);
                await service.generateForRule(saved);
              }
            } catch (_) {
              if (ctx.mounted) {
                showAppToast(
                  ctx,
                  message: 'No se pudo guardar. Intenta de nuevo.',
                  icon: Icons.error_outline_rounded,
                  accentColor: AppTheme.errorRed,
                );
              }
              return;
            }
            if (ctx.mounted) Navigator.pop(ctx);
          }

          Widget frequencyPill(RecurrenceFrequency f) {
            final selected = frequency == f;
            return PressableScale(
              onTap: () => setSheetState(() => frequency = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.navyFixed
                      : AppTheme.surfaceContainerLow,
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

          Widget stepperButton(IconData icon, {VoidCallback? onTap}) {
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
                    size: 16,
                    color: enabled ? AppTheme.primary : AppTheme.outlineVariant),
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
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
                    current != null ? 'Editar recurrente' : 'Nuevo recurrente',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.beVietnamPro(
                        color: AppTheme.primary, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                      labelStyle: GoogleFonts.beVietnamPro(
                          color: AppTheme.onSurfaceVariant, fontSize: 13),
                      filled: true,
                      fillColor: AppTheme.surfaceContainerLow,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [AmountInputFormatter()],
                          style: GoogleFonts.beVietnamPro(
                              color: AppTheme.primary, fontSize: 15),
                          decoration: InputDecoration(
                            labelText: 'Monto',
                            labelStyle: GoogleFonts.beVietnamPro(
                                color: AppTheme.onSurfaceVariant, fontSize: 13),
                            filled: true,
                            fillColor: AppTheme.surfaceContainerLow,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      PressableScale(
                        onTap: () => setSheetState(() => isIncome = !isIncome),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isIncome
                                ? AppTheme.successFixed
                                : AppTheme.dangerFixed,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            isIncome ? 'Ingreso' : 'Gasto',
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
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: category,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(14),
                          decoration: InputDecoration(
                            labelText: 'Categoría',
                            labelStyle: GoogleFonts.beVietnamPro(
                                color: AppTheme.onSurfaceVariant, fontSize: 13),
                            filled: true,
                            fillColor: AppTheme.surfaceContainerLow,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: {
                            ...kDefaultCategoryIcons.keys,
                            ...CategoryIconRegistry.customIcons.value.keys,
                            category,
                          }.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CategoryIconRegistry.iconFor(c),
                                      size: 16,
                                      color: CategoryColors.forCategory(c)),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(c,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.beVietnamPro(
                                            color: AppTheme.primary,
                                            fontSize: 13.5)),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setSheetState(() => category = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  StreamBuilder<List<AccountModel>>(
                    stream: AccountService().getAccounts(userId),
                    builder: (context, snap) {
                      final accounts = snap.data ?? [];
                      final hasSelection = accounts.any((a) => a.id == accountId);
                      return DropdownButtonFormField<String>(
                        value: hasSelection ? accountId : null,
                        isExpanded: true,
                        dropdownColor: AppTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        decoration: InputDecoration(
                          labelText: 'Cuenta',
                          labelStyle: GoogleFonts.beVietnamPro(
                              color: AppTheme.onSurfaceVariant, fontSize: 13),
                          filled: true,
                          fillColor: AppTheme.surfaceContainerLow,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: accounts
                            .map((a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: AccountColors.forAccount(a),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(a.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.beVietnamPro(
                                                color: AppTheme.primary,
                                                fontSize: 13.5)),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setSheetState(() => accountId = v),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Text('Frecuencia',
                      style: GoogleFonts.beVietnamPro(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        RecurrenceFrequency.values.map(frequencyPill).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Cada cuánto',
                      style: GoogleFonts.beVietnamPro(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      stepperButton(Icons.remove_rounded,
                          onTap: interval > 1
                              ? () => setSheetState(() => interval--)
                              : null),
                      SizedBox(
                        width: 36,
                        child: Text(
                          '$interval',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.beVietnamPro(
                              color: AppTheme.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      stepperButton(Icons.add_rounded,
                          onTap: interval < 99
                              ? () => setSheetState(() => interval++)
                              : null),
                      const SizedBox(width: 8),
                      Text(_intervalUnitLabel(frequency, interval),
                          style: GoogleFonts.beVietnamPro(
                              color: AppTheme.onSurfaceVariant, fontSize: 13.5)),
                    ],
                  ),
                  if (frequency == RecurrenceFrequency.weekly) ...[
                    const SizedBox(height: 16),
                    Text('Día de la semana',
                        style: GoogleFonts.beVietnamPro(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(7, (i) {
                        final dow = i + 1;
                        final selected = dayOfWeek == dow;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(100),
                              onTap: () => setSheetState(() => dayOfWeek = dow),
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
                                    color: selected
                                        ? Colors.white
                                        : AppTheme.onSurfaceVariant,
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
                  if (frequency == RecurrenceFrequency.monthly ||
                      frequency == RecurrenceFrequency.yearly) ...[
                    const SizedBox(height: 16),
                    Text('Día del mes',
                        style: GoogleFonts.beVietnamPro(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: dayOfMonth,
                      isExpanded: true,
                      dropdownColor: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.surfaceContainerLow,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
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
                        if (v != null) setSheetState(() => dayOfMonth = v);
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
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
                        value: noEndDate,
                        activeThumbColor: AppTheme.successFixed,
                        onChanged: (v) => setSheetState(() => noEndDate = v),
                      ),
                    ],
                  ),
                  if (!noEndDate)
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: pickEndDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event_busy_outlined,
                                size: 18, color: AppTheme.onSurfaceVariant),
                            const SizedBox(width: 10),
                            Text(
                              endDate == null
                                  ? 'Selecciona una fecha'
                                  : '${endDate!.day}/${endDate!.month}/${endDate!.year}',
                              style: GoogleFonts.beVietnamPro(
                                  color: AppTheme.primary,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      if (current != null)
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              try {
                                await service.deleteRule(current.id);
                              } catch (_) {
                                if (ctx.mounted) {
                                  showAppToast(
                                    ctx,
                                    message: 'No se pudo eliminar. Intenta de nuevo.',
                                    icon: Icons.error_outline_rounded,
                                    accentColor: AppTheme.errorRed,
                                  );
                                }
                                return;
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.errorRed,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Eliminar'),
                          ),
                        ),
                      if (current != null) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successFixed,
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
        },
      );
    },
  );
}
