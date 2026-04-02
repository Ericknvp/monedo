// ============================================================
// transactions_screen.dart
// Pantalla que muestra todos los movimientos del usuario.
// Permite editar y eliminar cada movimiento.
// ============================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/transaction_service.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _transactionService = TransactionService();
  String _filter = 'Todos';

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Column(
      children: [
        // ---- Filtros ----
        Container(
          color: AppTheme.cardDark,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: ['Todos', 'Ingresos', 'Gastos'].map((filter) {
              final isSelected = _filter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _filter = filter),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryPurple
                          : AppTheme.cardMedium,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // ---- Lista de movimientos ----
        Expanded(
          child: StreamBuilder<List<TransactionModel>>(
            stream: _transactionService.getTransactions(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primaryPurple),
                );
              }

              var transactions = snapshot.data ?? [];

              if (_filter == 'Ingresos') {
                transactions =
                    transactions.where((t) => t.isIncome).toList();
              } else if (_filter == 'Gastos') {
                transactions =
                    transactions.where((t) => !t.isIncome).toList();
              }

              if (transactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 64, color: AppTheme.textSecondary),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay movimientos',
                        style:
                        TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final t = transactions[index];
                  return TransactionTile(
                    transaction: t,
                    onEdit: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddTransactionScreen(transaction: t),
                      ),
                    ),
                    onDelete: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppTheme.cardDark,
                          title: const Text(
                            '¿Eliminar movimiento?',
                            style: TextStyle(
                                color: AppTheme.textPrimary),
                          ),
                          content: const Text(
                            'Esta acción no se puede deshacer.',
                            style: TextStyle(
                                color: AppTheme.textSecondary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('Cancelar',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary)),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text('Eliminar',
                                  style: TextStyle(
                                      color: AppTheme.expense)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _transactionService
                            .deleteTransaction(t.id);
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}