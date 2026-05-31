import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/transaction_service.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _txService = TransactionService();
  String _filter = 'Todos';

  static const _filters = ['Todos', 'Ingresos', 'Gastos'];

  Future<void> _delete(TransactionModel t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('¿Eliminar movimiento?',
            style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary, fontWeight: FontWeight.w600)),
        content: Text(
          'Se eliminará "${t.title}" (${CurrencyFormatter.format(t.amount)}). Esta acción no se puede deshacer.',
          style:
              GoogleFonts.beVietnamPro(color: AppTheme.onSurfaceVariant),
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
    if (confirm == true) await _txService.deleteTransaction(t.id);
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<List<TransactionModel>>(
      stream: _txService.getTransactions(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.secondary),
          );
        }

        var transactions = snapshot.data ?? [];

        if (_filter == 'Ingresos') {
          transactions = transactions.where((t) => t.isIncome).toList();
        } else if (_filter == 'Gastos') {
          transactions = transactions.where((t) => !t.isIncome).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter pills
            Container(
              color: AppTheme.background,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: _filters.map((f) {
                  final isSelected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          f,
                          style: GoogleFonts.beVietnamPro(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Transaction list
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined,
                              size: 64, color: AppTheme.outlineVariant),
                          const SizedBox(height: 16),
                          Text(
                            'No hay movimientos',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Agrega tu primer movimiento',
                            style: GoogleFonts.beVietnamPro(
                                color: AppTheme.outlineVariant,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: transactions.length,
                      itemBuilder: (ctx, i) {
                        final t = transactions[i];
                        return TransactionTile(
                          transaction: t,
                          onEdit: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddTransactionScreen(transaction: t),
                            ),
                          ),
                          onDelete: () => _delete(t),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
