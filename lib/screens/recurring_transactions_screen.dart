import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/recurring_transaction.dart';
import '../services/recurring_transaction_service.dart';
import '../theme/app_theme.dart';
import '../utils/category_colors.dart';
import '../utils/category_icons.dart';
import '../utils/currency_formatter.dart';
import '../widgets/recurring_editor.dart';
import '../widgets/branded_loading_screen.dart';

const _weekdayNames = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

const _monthNames = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String _summary(RecurringTransactionModel r) {
  final n = r.interval;
  switch (r.frequency) {
    case RecurrenceFrequency.daily:
      return n == 1 ? 'Cada día' : 'Cada $n días';
    case RecurrenceFrequency.weekly:
      final day = _weekdayNames[(r.dayOfWeek ?? r.startDate.weekday) - 1];
      return n == 1 ? 'Cada $day' : 'Cada $n semanas · $day';
    case RecurrenceFrequency.monthly:
      final day = r.dayOfMonth ?? r.startDate.day;
      return n == 1 ? 'Cada mes · día $day' : 'Cada $n meses · día $day';
    case RecurrenceFrequency.yearly:
      final day = r.dayOfMonth ?? r.startDate.day;
      final month = _monthNames[r.startDate.month - 1];
      return n == 1
          ? 'Cada año · $day $month'
          : 'Cada $n años · $day $month';
  }
}

/// Abre "Movimientos recurrentes": como una ventana modal centrada (con
/// fondo oscurecido) en escritorio, o a pantalla completa en móvil — mismo
/// patrón que [openExportScreen] en export_screen.dart.
Future<void> openRecurringTransactionsScreen(BuildContext context) {
  final isDesktop = MediaQuery.of(context).size.width >= 900;

  if (isDesktop) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) =>
          const RecurringTransactionsScreen(isDialog: true),
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
    MaterialPageRoute(builder: (_) => const RecurringTransactionsScreen()),
  );
}

class RecurringTransactionsScreen extends StatelessWidget {
  final bool isDialog;

  const RecurringTransactionsScreen({super.key, this.isDialog = false});

  @override
  Widget build(BuildContext context) {
    if (isDialog) return _buildDialog(context);

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
          'Movimientos recurrentes',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.primary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildList(context),
    );
  }

  /// Ventana modal centrada (escritorio).
  Widget _buildDialog(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
          child: Material(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            elevation: 24,
            shadowColor: Colors.black.withOpacity(0.4),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.repeat_rounded,
                            color: AppTheme.secondary, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Movimientos recurrentes',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: AppTheme.onSurfaceVariant),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildList(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<List<RecurringTransactionModel>>(
      stream: RecurringTransactionService().getRules(userId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: BrandedInlineLoader());
        }
        final rules = snap.data!;
        if (rules.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.repeat_rounded,
                      size: 40, color: AppTheme.outlineVariant),
                  const SizedBox(height: 12),
                  Text(
                    'Sin movimientos recurrentes',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Activa "Repetir este movimiento" al agregar un gasto o ingreso.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.beVietnamPro(
                        color: AppTheme.onSurfaceVariant, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: rules.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final r = rules[i];
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () =>
                  showRecurringEditor(context, userId: userId, current: r),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: CategoryColors.forCategory(r.category)
                            .withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(CategoryIconRegistry.iconFor(r.category),
                          size: 20, color: CategoryColors.forCategory(r.category)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _summary(r),
                            style: GoogleFonts.beVietnamPro(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.formatWithSign(r.amount, r.isIncome),
                      style: GoogleFonts.beVietnamPro(
                        color: r.isIncome ? AppTheme.secondary : AppTheme.errorRed,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
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
}
