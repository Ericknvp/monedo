
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Alimentación':
        return Icons.restaurant_outlined;
      case 'Transporte':
        return Icons.directions_car_outlined;
      case 'Entretenimiento':
        return Icons.movie_outlined;
      case 'Salud':
        return Icons.health_and_safety_outlined;
      case 'Educación':
        return Icons.school_outlined;
      case 'Ropa':
        return Icons.checkroom_outlined;
      case 'Hogar':
        return Icons.home_outlined;
      case 'Trabajo':
        return Icons.work_outlined;
      case 'Inversión':
        return Icons.trending_up_outlined;
      case 'Ahorro':
        return Icons.savings_outlined;
      case 'Ocio':
        return Icons.celebration_outlined;
      default:
        return Icons.attach_money;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color =
    transaction.isIncome ? AppTheme.income : AppTheme.expense;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // ---- Icono de categoría ----
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(transaction.category),
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // ---- Título y fecha ----
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.date.day}/${transaction.date.month}/${transaction.date.year} · ${transaction.category}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (transaction.note != null &&
                    transaction.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    transaction.note!,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // ---- Monto ----
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatWithSign(
                    transaction.amount, transaction.isIncome),
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // ---- Botones editar y eliminar ----
              Row(
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppTheme.accentPurple,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(
                      Icons.delete_outline,
                      color: AppTheme.expense,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
