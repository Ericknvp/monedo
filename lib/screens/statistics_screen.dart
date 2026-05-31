import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final _txService = TransactionService();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  static const _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];
  static const _monthsShort = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  final List<Color> _chartColors = [
    AppTheme.primary,
    AppTheme.secondary,
    const Color(0xFF3F6376),
    AppTheme.secondaryFixed,
    const Color(0xFF06B6D4),
    const Color(0xFFF59E0B),
    const Color(0xFFEC4899),
    const Color(0xFF8B5CF6),
  ];

  void _prevMonth() => setState(() {
        if (_selectedMonth == 1) {
          _selectedMonth = 12;
          _selectedYear--;
        } else {
          _selectedMonth--;
        }
      });

  void _nextMonth() => setState(() {
        if (_selectedMonth == 12) {
          _selectedMonth = 1;
          _selectedYear++;
        } else {
          _selectedMonth++;
        }
      });

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 40 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month selector (dial style)
          _buildMonthSelector(isDesktop),
          const SizedBox(height: 32),

          // Data
          StreamBuilder<List<TransactionModel>>(
            stream: _txService.getTransactionsByMonth(
                userId, _selectedYear, _selectedMonth),
            builder: (context, snap) {
              final tx = snap.data ?? [];
              final income = _txService.calculateIncome(tx);
              final expenses = _txService.calculateExpenses(tx);
              final balance = income - expenses;
              final categoryData = _txService.getExpensesByCategory(tx);

              if (isDesktop) {
                return _buildDesktopLayout(
                    userId, income, expenses, balance, categoryData);
              }
              return _buildMobileLayout(
                  userId, income, expenses, balance, categoryData);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(bool isDesktop) {
    final now = DateTime.now();
    final prev1 = DateTime(_selectedYear, _selectedMonth - 1, 1);
    final prev2 = DateTime(_selectedYear, _selectedMonth - 2, 1);
    final next1 = DateTime(_selectedYear, _selectedMonth + 1, 1);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _monthPill(_monthsShort[prev2.month - 1], false, _prevMonth),
            _monthPill(_monthsShort[prev1.month - 1], false, _prevMonth),
            _monthPill(
              '${_months[_selectedMonth - 1]} $_selectedYear',
              true,
              null,
            ),
            _monthPill(_monthsShort[next1.month - 1], false, _nextMonth),
            _monthPill(
              _monthsShort[(DateTime(_selectedYear, _selectedMonth + 2, 1).month) - 1],
              false,
              _nextMonth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthPill(String label, bool isActive, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
            horizontal: isActive ? 24 : 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            color: isActive ? Colors.white : AppTheme.onSurfaceVariant,
            fontSize: isActive ? 14 : 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    String userId,
    double income,
    double expenses,
    double balance,
    Map<String, double> categoryData,
  ) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Donut chart (left, 8/12)
            Expanded(
              flex: 8,
              child: _buildDonutCard(income, expenses, categoryData),
            ),
            const SizedBox(width: 24),
            // Stat cards (right, 4/12)
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _summaryCard('Ingresos', income, Icons.trending_up_rounded,
                      AppTheme.secondaryContainer.withOpacity(0.5),
                      AppTheme.onSecondaryContainer),
                  const SizedBox(height: 16),
                  _summaryCard('Gastos', expenses, Icons.trending_down_rounded,
                      AppTheme.errorContainer.withOpacity(0.3), AppTheme.errorRed),
                  const SizedBox(height: 16),
                  _summaryCard(
                    'Balance',
                    balance,
                    Icons.account_balance_wallet_rounded,
                    balance >= 0
                        ? AppTheme.secondaryContainer.withOpacity(0.4)
                        : AppTheme.errorContainer.withOpacity(0.3),
                    balance >= 0 ? AppTheme.secondary : AppTheme.errorRed,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildWeeklySection(userId),
      ],
    );
  }

  Widget _buildMobileLayout(
    String userId,
    double income,
    double expenses,
    double balance,
    Map<String, double> categoryData,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard('Ingresos', income, Icons.trending_up_rounded,
                  AppTheme.secondaryContainer.withOpacity(0.5),
                  AppTheme.onSecondaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard('Gastos', expenses, Icons.trending_down_rounded,
                  AppTheme.errorContainer.withOpacity(0.3), AppTheme.errorRed),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _summaryCard(
          'Balance',
          balance,
          Icons.account_balance_wallet_rounded,
          balance >= 0
              ? AppTheme.secondaryContainer.withOpacity(0.4)
              : AppTheme.errorContainer.withOpacity(0.3),
          balance >= 0 ? AppTheme.secondary : AppTheme.errorRed,
        ),
        const SizedBox(height: 24),
        _buildDonutCard(income, expenses, categoryData),
        const SizedBox(height: 24),
        _buildWeeklySection(userId),
      ],
    );
  }

  Widget _buildDonutCard(
      double income, double expenses, Map<String, double> categoryData) {
    if (categoryData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.surfaceVariant),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.bar_chart_outlined,
                  size: 56, color: AppTheme.outlineVariant),
              const SizedBox(height: 14),
              Text(
                'Sin gastos este mes',
                style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.onSurfaceVariant, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Distribución de gastos',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 260,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sections: categoryData.entries
                        .toList()
                        .asMap()
                        .entries
                        .map((e) {
                      final idx = e.key;
                      final cat = e.value;
                      return PieChartSectionData(
                        value: cat.value,
                        title: expenses > 0
                            ? '${(cat.value / expenses * 100).toStringAsFixed(0)}%'
                            : '',
                        color: _chartColors[idx % _chartColors.length],
                        radius: 90,
                        titleStyle: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                  ),
                ),
                // Center text
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total gastado',
                        style: GoogleFonts.beVietnamPro(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(expenses),
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: categoryData.entries.toList().asMap().entries.map((e) {
              final idx = e.key;
              final cat = e.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _chartColors[idx % _chartColors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${cat.key}: ${CurrencyFormatter.format(cat.value)}',
                    style: GoogleFonts.beVietnamPro(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
      String title, double amount, IconData icon, Color bg, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.beVietnamPro(
                      color: AppTheme.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                CurrencyFormatter.format(amount),
                style: GoogleFonts.plusJakartaSans(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySection(String userId) {
    return StreamBuilder<List<TransactionModel>>(
      stream: _txService.getTransactionsByWeek(userId),
      builder: (context, snap) {
        final tx = snap.data ?? [];
        final income = _txService.calculateIncome(tx);
        final expenses = _txService.calculateExpenses(tx);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta semana',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _summaryCard('Ingresos', income,
                      Icons.trending_up_rounded,
                      AppTheme.secondaryContainer.withOpacity(0.5),
                      AppTheme.onSecondaryContainer),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _summaryCard('Gastos', expenses,
                      Icons.trending_down_rounded,
                      AppTheme.errorContainer.withOpacity(0.3),
                      AppTheme.errorRed),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
