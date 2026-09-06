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
  int? _touchedIndex;

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
    const Color(0xFF0EA5E9),
    const Color(0xFF14B8A6),
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

  /// Cambio porcentual de [current] respecto a [previous]. Null si no hay
  /// una base válida para comparar (mes anterior en cero).
  double? _pctChange(double current, double previous) {
    if (previous == 0) return null;
    return ((current - previous) / previous) * 100;
  }

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

              final prevMonthDate =
                  DateTime(_selectedYear, _selectedMonth - 1, 1);

              return StreamBuilder<List<TransactionModel>>(
                stream: _txService.getTransactionsByMonth(
                    userId, prevMonthDate.year, prevMonthDate.month),
                builder: (context, prevSnap) {
                  final prevTx = prevSnap.data ?? [];
                  final prevIncome = _txService.calculateIncome(prevTx);
                  final prevExpenses = _txService.calculateExpenses(prevTx);
                  final prevBalance = prevIncome - prevExpenses;

                  final incomeChange = _pctChange(income, prevIncome);
                  final expensesChange = _pctChange(expenses, prevExpenses);
                  final balanceChange = _pctChange(balance, prevBalance);

                  if (isDesktop) {
                    return _buildDesktopLayout(userId, income, expenses,
                        balance, categoryData, incomeChange, expensesChange,
                        balanceChange);
                  }
                  return _buildMobileLayout(userId, income, expenses, balance,
                      categoryData, incomeChange, expensesChange,
                      balanceChange);
                },
              );
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
    double? incomeChange,
    double? expensesChange,
    double? balanceChange,
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
                      AppTheme.secondaryContainer.withOpacity(0.7),
                      AppTheme.onSecondaryContainer,
                      changePercent: incomeChange),
                  const SizedBox(height: 16),
                  _summaryCard('Gastos', expenses, Icons.trending_down_rounded,
                      AppTheme.errorContainer.withOpacity(0.45), AppTheme.errorRed,
                      changePercent: expensesChange, higherIsBetter: false),
                  const SizedBox(height: 16),
                  _summaryCard(
                    'Balance',
                    balance,
                    Icons.account_balance_wallet_rounded,
                    balance >= 0
                        ? AppTheme.secondaryContainer.withOpacity(0.6)
                        : AppTheme.errorContainer.withOpacity(0.45),
                    balance >= 0 ? AppTheme.secondary : AppTheme.errorRed,
                    changePercent: balanceChange,
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
    double? incomeChange,
    double? expensesChange,
    double? balanceChange,
  ) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _summaryCard('Ingresos', income, Icons.trending_up_rounded,
                    AppTheme.secondaryContainer.withOpacity(0.7),
                    AppTheme.onSecondaryContainer,
                    changePercent: incomeChange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard('Gastos', expenses, Icons.trending_down_rounded,
                    AppTheme.errorContainer.withOpacity(0.45), AppTheme.errorRed,
                    changePercent: expensesChange, higherIsBetter: false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _summaryCard(
          'Balance',
          balance,
          Icons.account_balance_wallet_rounded,
          balance >= 0
              ? AppTheme.secondaryContainer.withOpacity(0.6)
              : AppTheme.errorContainer.withOpacity(0.45),
          balance >= 0 ? AppTheme.secondary : AppTheme.errorRed,
          changePercent: balanceChange,
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
          if (categoryData.isNotEmpty) ...[
            const SizedBox(height: 14),
            Builder(builder: (context) {
              final top = categoryData.entries
                  .reduce((a, b) => a.value >= b.value ? a : b);
              final topColor = _chartColors[
                  categoryData.keys.toList().indexOf(top.key) %
                      _chartColors.length];
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: topColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        color: topColor, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: GoogleFonts.beVietnamPro(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: top.key,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const TextSpan(text: ' es tu mayor gasto: '),
                            TextSpan(
                              text: CurrencyFormatter.format(top.value),
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, color: topColor),
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 28),
          Builder(builder: (context) {
            final entries = categoryData.entries.toList();
            final hasTouch =
                _touchedIndex != null && _touchedIndex! < entries.length;
            final touchedEntry = hasTouch ? entries[_touchedIndex!] : null;
            final touchedColor = hasTouch
                ? _chartColors[_touchedIndex! % _chartColors.length]
                : null;

            return Column(
              children: [
                SizedBox(
                  height: 260,
                  child: Stack(
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              final idx =
                                  response?.touchedSection?.touchedSectionIndex;
                              setState(() {
                                _touchedIndex = (event.isInterestedForInteractions &&
                                        idx != null &&
                                        idx >= 0)
                                    ? idx
                                    : null;
                              });
                            },
                          ),
                          sections: entries.asMap().entries.map((e) {
                            final idx = e.key;
                            final cat = e.value;
                            final isTouched = idx == _touchedIndex;
                            return PieChartSectionData(
                              value: cat.value,
                              title: expenses > 0
                                  ? '${(cat.value / expenses * 100).toStringAsFixed(0)}%'
                                  : '',
                              color: _chartColors[idx % _chartColors.length],
                              radius: isTouched ? 98 : 90,
                              titleStyle: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: isTouched ? 13 : 12,
                              ),
                            );
                          }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 60,
                        ),
                      ),
                      // Center text: detalle de la categoría en hover/tap,
                      // o el total gastado por defecto.
                      Center(
                        child: touchedEntry != null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: touchedColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    touchedEntry.key,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.beVietnamPro(
                                      color: AppTheme.onSurfaceVariant,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    CurrencyFormatter.format(touchedEntry.value),
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.primary,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    expenses > 0
                                        ? '${(touchedEntry.value / expenses * 100).toStringAsFixed(0)}% del total'
                                        : '',
                                    style: GoogleFonts.beVietnamPro(
                                      color: AppTheme.outline,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
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
                  children: entries.asMap().entries.map((e) {
                    final idx = e.key;
                    final cat = e.value;
                    final isTouched = idx == _touchedIndex;
                    return GestureDetector(
                      onTap: () => setState(
                          () => _touchedIndex = isTouched ? null : idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isTouched
                              ? AppTheme.surfaceContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
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
                                color: isTouched
                                    ? AppTheme.primary
                                    : AppTheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: isTouched
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _summaryCard(
    String title,
    double amount,
    IconData icon,
    Color bg,
    Color color, {
    double? changePercent,
    bool higherIsBetter = true,
  }) {
    final hasChange = changePercent != null && changePercent.isFinite;
    final isGood = hasChange &&
        (higherIsBetter ? changePercent >= 0 : changePercent <= 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 44,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.beVietnamPro(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  CurrencyFormatter.format(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (hasChange) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        changePercent >= 0
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 13,
                        color: isGood ? AppTheme.secondary : AppTheme.errorRed,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          '${changePercent.abs().toStringAsFixed(0)}% vs mes ant.',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.beVietnamPro(
                            color: isGood ? AppTheme.secondary : AppTheme.errorRed,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
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
