import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

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

  IconData _icon(String cat) {
    switch (cat) {
      case 'Alimentación': return Icons.restaurant_rounded;
      case 'Transporte': return Icons.directions_car_rounded;
      case 'Entretenimiento': return Icons.movie_rounded;
      case 'Salud': return Icons.health_and_safety_rounded;
      case 'Educación': return Icons.school_rounded;
      case 'Ropa': return Icons.checkroom_rounded;
      case 'Hogar': return Icons.home_rounded;
      case 'Trabajo': return Icons.work_rounded;
      case 'Inversión': return Icons.trending_up_rounded;
      case 'Ahorro': return Icons.savings_rounded;
      case 'Ocio': return Icons.celebration_rounded;
      default: return Icons.attach_money_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final isIncome = t.isIncome;
    final amountColor =
        isIncome ? AppTheme.onSecondaryContainer : AppTheme.primary;
    final iconBg = isIncome
        ? AppTheme.secondaryContainer.withOpacity(0.4)
        : AppTheme.surfaceContainerHighest;
    final iconColor =
        isIncome ? AppTheme.onSecondaryContainer : AppTheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _hovered ? AppTheme.surfaceContainerLowest : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? AppTheme.outlineVariant : Colors.transparent,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
        ),
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
              child: Icon(_icon(t.category), color: iconColor, size: 22),
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
                      color: isIncome
                          ? AppTheme.secondaryContainer.withOpacity(0.5)
                          : AppTheme.primaryContainer.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      isIncome ? 'Ingreso' : 'Gasto',
                      style: GoogleFonts.beVietnamPro(
                        color: isIncome
                            ? AppTheme.onSecondaryContainer
                            : AppTheme.onPrimaryFixedVariant,
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
                  CurrencyFormatter.formatWithSign(t.amount, t.isIncome),
                  style: GoogleFonts.plusJakartaSans(
                    color: amountColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedOpacity(
                  opacity: _hovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 180),
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
    );
  }

  Widget _actionBtn(
      IconData icon, Color color, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
