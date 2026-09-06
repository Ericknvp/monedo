import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/category_icons.dart';
import '../utils/category_colors.dart';

class TransactionTile extends StatefulWidget {
  final TransactionModel transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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

    final isDesktop = MediaQuery.of(context).size.width >= 900;

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
            // Tocar el movimiento completo abre editarlo, no solo el lápiz.
            // Las transferencias no se editan (ver nota más abajo).
            onTap: t.isTransfer ? null : widget.onEdit,
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
                  Text(
                    t.title,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
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
                              : AppTheme.primaryContainer.withOpacity(0.15)),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      t.isTransfer ? 'Transferencia' : (isIncome ? 'Ingreso' : 'Gasto'),
                      style: GoogleFonts.beVietnamPro(
                        color: t.isTransfer
                            ? AppTheme.onSurfaceVariant
                            : (isIncome
                                ? AppTheme.onSecondaryContainer
                                : AppTheme.onPrimaryFixedVariant),
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

            // Amount + hover actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                const SizedBox(height: 6),
                // Las transferencias entre cuentas propias no se editan ni
                // eliminan desde aquí (son dos movimientos espejo); para
                // revertirlas se hace otra transferencia en sentido inverso.
                if (!t.isTransfer)
                  AnimatedOpacity(
                    opacity: (!isDesktop || _hovered) ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      children: [
                        _actionBtn(Icons.edit_rounded,
                            AppTheme.onSurfaceVariant,
                            AppTheme.surfaceContainer, widget.onEdit),
                        const SizedBox(width: 6),
                        _actionBtn(Icons.delete_rounded,
                            AppTheme.errorRed,
                            AppTheme.errorContainer, widget.onDelete),
                      ],
                    ),
                  ),
              ],
            ),
          ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(
      IconData icon, Color color, Color bg, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}
