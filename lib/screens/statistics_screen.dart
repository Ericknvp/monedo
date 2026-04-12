
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/transaction_service.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _transactionService = TransactionService();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  final List<Color> _chartColors = [
    AppTheme.primaryPurple,
    AppTheme.accentPurple,
    AppTheme.income,
    AppTheme.expense,
    const Color(0xFF06B6D4),
    const Color(0xFFF59E0B),
    const Color(0xFFEC4899),
    const Color(0xFF8B5CF6),
    const Color(0xFF14B8A6),
    const Color(0xFFF97316),
  ];

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Selector de mes ----
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: AppTheme.textPrimary),
                  onPressed: () {
                    setState(() {
                      if (_selectedMonth == 1) {
                        _selectedMonth = 12;
                        _selectedYear--;
                      } else {
                        _selectedMonth--;
                      }
                    });
                  },
                ),
                Text(
                  '${_months[_selectedMonth - 1]} $_selectedYear',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right,
                      color: AppTheme.textPrimary),
                  onPressed: () {
                    setState(() {
                      if (_selectedMonth == 12) {
                        _selectedMonth = 1;
                        _selectedYear++;
                      } else {
                        _selectedMonth++;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          StreamBuilder<List<TransactionModel>>(
            stream: _transactionService.getTransactionsByMonth(
                userId, _selectedYear, _selectedMonth),
            builder: (context, snapshot) {
              final transactions = snapshot.data ?? [];
              final income =
              _transactionService.calculateIncome(transactions);
              final expenses =
              _transactionService.calculateExpenses(transactions);
              final balance = income - expenses;
              final categoryData =
              _transactionService.getExpensesByCategory(transactions);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard('Ingresos', income,
                            AppTheme.income, Icons.arrow_upward),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard('Gastos', expenses,
                            AppTheme.expense, Icons.arrow_downward),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                      'Balance',
                      balance,
                      balance >= 0 ? AppTheme.income : AppTheme.expense,
                      Icons.account_balance_wallet_outlined),
                  const SizedBox(height: 24),

                  if (categoryData.isNotEmpty) ...[
                    const Text(
                      'Gastos por categoría',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 220,
                            child: PieChart(
                              PieChartData(
                                sections: categoryData.entries
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final index = entry.key;
                                  final cat = entry.value;
                                  return PieChartSectionData(
                                    value: cat.value,
                                    title:
                                    '${(cat.value / expenses * 100).toStringAsFixed(0)}%',
                                    color: _chartColors[
                                    index % _chartColors.length],
                                    radius: 80,
                                    titleStyle: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  );
                                }).toList(),
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: categoryData.entries
                                .toList()
                                .asMap()
                                .entries
                                .map((entry) {
                              final index = entry.key;
                              final cat = entry.value;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _chartColors[
                                      index % _chartColors.length],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${cat.key}: ${CurrencyFormatter.format(cat.value)}',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          Icon(Icons.bar_chart_outlined,
                              size: 64, color: AppTheme.textSecondary),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay gastos este mes',
                            style: TextStyle(
                                color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          const Text(
            'Esta semana',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<TransactionModel>>(
            stream: _transactionService.getTransactionsByWeek(userId),
            builder: (context, snapshot) {
              final transactions = snapshot.data ?? [];
              final income =
              _transactionService.calculateIncome(transactions);
              final expenses =
              _transactionService.calculateExpenses(transactions);

              return Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard('Ingresos', income,
                        AppTheme.income, Icons.arrow_upward),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard('Gastos', expenses,
                        AppTheme.expense, Icons.arrow_downward),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
