import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/category_icons.dart';
import '../utils/category_colors.dart';
import 'transaction_detail_sheet.dart';

class TransactionTile extends StatefulWidget {
  final TransactionModel transaction;
  final VoidCallback onEdit;
  // Devuelve si realmente se eliminó (false si se canceló la confirmación),
  // para que la vista de detalle sepa si debe cerrarse o quedarse abierta.
  final Future<bool> Function() onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final isIncome = t.isIncome;
    final amountColor = t.isTransfer
        ? AppTheme.onSurfaceVariant
        : (isIncome ? AppTheme.onSecondaryContainer : AppTheme.primary);
    // El ícono se colorea por categoría (para distinguirlas de un vistazo);
    // "Transferencia" ya cae en el tono neutro de CategoryColors.
    final categoryColor = CategoryColors.forCategory(t.category);
    final iconBg = categoryColor.withOpacity(0.14);
    final iconColor = categoryColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _hovered ? AppTheme.surfaceContainerLowest : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? AppTheme.outlineVariant : Colors.transparent,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            // Tocar el movimiento completo abre el detalle; "Editar"/"Eliminar"
            // viven dentro de esa hoja, no en la fila.
            onTap: () => showTransactionDetail(
              context,
              transaction: t,
              onEdit: widget.onEdit,
              onDelete: widget.onDelete,
            ),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ValueListenableBuilder<Map<String, IconData>>(
                valueListenable: CategoryIconRegistry.customIcons,
                builder: (context, _, __) => Icon(
                  CategoryIconRegistry.iconFor(t.category),
                  color: iconColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Title + note
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (t.recurringId != null) ...[
                        Icon(Icons.repeat_rounded,
                            size: 12, color: AppTheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (t.note != null && t.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      t.note!,
                      style: GoogleFonts.beVietnamPro(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Category pill + date
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: t.isTransfer
                          ? AppTheme.surfaceContainerHighest
                          : (isIncome
                              ? AppTheme.secondaryContainer.withOpacity(0.5)
                              : AppTheme.expenseContainer),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      t.isTransfer ? 'Transferencia' : (isIncome ? 'Ingreso' : 'Gasto'),
                      style: GoogleFonts.beVietnamPro(
                        color: t.isTransfer
                            ? AppTheme.onSurfaceVariant
                            : (isIncome
                                ? AppTheme.onSecondaryContainer
                                : AppTheme.onExpenseContainer),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${t.date.day}/${t.date.month}/${t.date.year}',
                    style: GoogleFonts.beVietnamPro(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              t.isTransfer
                  ? CurrencyFormatter.format(t.amount)
                  : CurrencyFormatter.formatWithSign(t.amount, t.isIncome),
              style: GoogleFonts.plusJakartaSans(
                color: amountColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
