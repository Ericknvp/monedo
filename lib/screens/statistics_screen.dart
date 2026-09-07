import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/transaction_service.dart';
import '../services/budget_service.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/category_colors.dart';
import '../utils/category_icons.dart';
import 'budgets_screen.dart';
import '../widgets/budget_editor.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _txService = TransactionService();
  final _budgetService = BudgetService();
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
  static const _weekdaysShort = ['L', 'M', 'Mi', 'J', 'V', 'S', 'D'];

  DateTime _startOfWeek(DateTime d) {
    final date = DateTime(d.year, d.month, d.day);
    return date.subtract(Duration(days: date.weekday - 1));
  }

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
                        balanceChange, tx);
                  }
                  return _buildMobileLayout(userId, income, expenses, balance,
                      categoryData, incomeChange, expensesChange,
                      balanceChange, tx);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(bool isDesktop) {
    // En móvil no hay espacio para las 5 píldoras del selector de
    // escritorio (la última se sale del contenedor); se usa un selector
    // compacto de flechas en su lugar.
    if (!isDesktop) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left_rounded),
                color: AppTheme.onSurfaceVariant,
                visualDensity: VisualDensity.compact,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '${_months[_selectedMonth - 1]} $_selectedYear',
                  style: GoogleFonts.beVietnamPro(
                    color: AppTheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
                color: AppTheme.onSurfaceVariant,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      );
    }

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
    List<TransactionModel> monthTx,
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
        _buildBudgetsCard(userId, categoryData),
        const SizedBox(height: 24),
        _buildWeeklySection(userId),
        const SizedBox(height: 24),
        _buildMonthTrendCard(monthTx, _selectedYear, _selectedMonth),
        const SizedBox(height: 24),
        _buildSixMonthTrendCard(userId),
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
    List<TransactionModel> monthTx,
  ) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _summaryCard('Ingresos', income, Icons.trending_up_rounded,
                  AppTheme.secondaryContainer.withOpacity(0.7),
                  AppTheme.onSecondaryContainer,
                  changePercent: incomeChange, compact: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard('Gastos', expenses, Icons.trending_down_rounded,
                  AppTheme.errorContainer.withOpacity(0.45), AppTheme.errorRed,
                  changePercent: expensesChange, higherIsBetter: false,
                  compact: true),
            ),
          ],
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
          compact: true,
        ),
        const SizedBox(height: 24),
        _buildDonutCard(income, expenses, categoryData),
        const SizedBox(height: 24),
        _buildBudgetsCard(userId, categoryData),
        const SizedBox(height: 24),
        _buildWeeklySection(userId),
        const SizedBox(height: 24),
        _buildMonthTrendCard(monthTx, _selectedYear, _selectedMonth),
        const SizedBox(height: 24),
        _buildSixMonthTrendCard(userId),
      ],
    );
  }

  // Nadie tiene presupuestos configurados todavía: en vez de ocultar la
  // sección, recomienda la función para que la gente sepa que existe.
  Widget _buildBudgetsPromoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.secondaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.pie_chart_outline_rounded,
                color: AppTheme.secondary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prueba los presupuestos por categoría',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fija un límite mensual a las categorías que quieras y aquí verás tu progreso, con aviso cuando te acerques o lo superes.',
                  style: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => openBudgetsScreen(context),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 17),
                  label: const Text('Configurar presupuestos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 0,
                    textStyle: GoogleFonts.beVietnamPro(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetsCard(String userId, Map<String, double> categoryData) {
    return StreamBuilder<List<BudgetModel>>(
      stream: _budgetService.getBudgets(userId),
      builder: (context, snap) {
        final budgets = snap.data ?? [];
        if (budgets.isEmpty) return _buildBudgetsPromoCard();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.surfaceVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Presupuestos del mes',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => openBudgetsScreen(context),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                    label: const Text('Agregar límite'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.secondary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      textStyle: GoogleFonts.beVietnamPro(
                          fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...budgets.map((b) {
                final spent = categoryData[b.category] ?? 0;
                final ratio = b.monthlyLimit > 0 ? spent / b.monthlyLimit : 0.0;
                final isOver = ratio > 1;
                final isWarning = ratio >= 0.8 && ratio <= 1;
                final barColor = isOver
                    ? AppTheme.errorRed
                    : (isWarning
                        ? const Color(0xFFC98500)
                        : CategoryColors.forCategory(b.category));

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => showBudgetEditor(
                    context,
                    userId: userId,
                    category: b.category,
                    current: b,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(CategoryIconRegistry.iconFor(b.category),
                                size: 16, color: barColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                b.category,
                                style: GoogleFonts.beVietnamPro(
                                  color: AppTheme.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${CurrencyFormatter.format(spent)} / ${CurrencyFormatter.format(b.monthlyLimit)}',
                              style: GoogleFonts.beVietnamPro(
                                color: barColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppTheme.onSurfaceVariant, size: 16),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: LinearProgressIndicator(
                            value: ratio.clamp(0, 1),
                            minHeight: 8,
                            backgroundColor: barColor.withOpacity(0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          ),
                        ),
                        if (isOver) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Superado por ${CurrencyFormatter.format(spent - b.monthlyLimit)}',
                            style: GoogleFonts.beVietnamPro(
                              color: AppTheme.errorRed,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
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
              final topColor = CategoryColors.forCategory(top.key);
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: topColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        color: topColor, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              style: GoogleFonts.beVietnamPro(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                              children: [
                                TextSpan(
                                  text: top.key,
                                  style:
                                      const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const TextSpan(text: ' es tu mayor gasto'),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              CurrencyFormatter.format(top.value),
                              style: GoogleFonts.plusJakartaSans(
                                color: topColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
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
            final touchedColor =
                hasTouch ? CategoryColors.forCategory(touchedEntry!.key) : null;

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
                              color: CategoryColors.forCategory(cat.key),
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
                                color: CategoryColors.forCategory(cat.key),
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
    bool compact = false,
  }) {
    final hasChange = changePercent != null && changePercent.isFinite;
    final isGood = hasChange &&
        (higherIsBetter ? changePercent >= 0 : changePercent <= 0);

    final trendRow = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            (changePercent ?? 0) >= 0
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 13,
            color: isGood ? AppTheme.secondary : AppTheme.errorRed,
          ),
          const SizedBox(width: 2),
          Text(
            compact
                ? '${(changePercent ?? 0).abs().toStringAsFixed(0)}%'
                : '${(changePercent ?? 0).abs().toStringAsFixed(0)}% vs mes anterior',
            style: GoogleFonts.beVietnamPro(
              color: isGood ? AppTheme.secondary : AppTheme.errorRed,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
            height: 36,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.format(amount),
                    style: GoogleFonts.plusJakartaSans(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                // Alto siempre reservado para esta línea (haya o no dato del
                // mes anterior) para que las cajas de Ingresos y Gastos, una
                // al lado de la otra, siempre queden con la misma altura.
                const SizedBox(height: 4),
                SizedBox(
                  height: 15,
                  child: hasChange ? trendRow : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySection(String userId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = _startOfWeek(now);
    final weekEnd = weekStart.add(const Duration(days: 7));
    final prevWeekStart = weekStart.subtract(const Duration(days: 7));
    final weekEndDisplay = weekStart.add(const Duration(days: 6));

    String fmtShort(DateTime d) => '${d.day} ${_monthsShort[d.month - 1]}';

    return StreamBuilder<List<TransactionModel>>(
      // Se pide un solo rango de 14 días (semana pasada + esta semana) y se
      // parte en memoria, en vez de dos streams anidados como en el mes.
      stream:
          _txService.getTransactionsByDateRange(userId, prevWeekStart, weekEnd),
      builder: (context, snap) {
        final all = snap.data ?? [];
        final currentTx =
            all.where((t) => !t.date.isBefore(weekStart)).toList();
        final prevTx = all.where((t) => t.date.isBefore(weekStart)).toList();

        final income = _txService.calculateIncome(currentTx);
        final expenses = _txService.calculateExpenses(currentTx);
        final prevIncome = _txService.calculateIncome(prevTx);
        final prevExpenses = _txService.calculateExpenses(prevTx);
        final incomeChange = _pctChange(income, prevIncome);
        final expensesChange = _pctChange(expenses, prevExpenses);

        final daily = _txService.getDailyTotals(currentTx, weekStart, 7);
        final dayKeys = daily.keys.toList()..sort();
        final maxDaily = daily.values
            .map((v) => v['expenses'] ?? 0)
            .fold<double>(0, (m, v) => v > m ? v : m);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.surfaceVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Esta semana',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.primary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${fmtShort(weekStart)} - ${fmtShort(weekEndDisplay)}',
                    style: GoogleFonts.beVietnamPro(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _summaryCard('Ingresos', income,
                        Icons.trending_up_rounded,
                        AppTheme.secondaryContainer.withOpacity(0.5),
                        AppTheme.onSecondaryContainer,
                        changePercent: incomeChange, compact: true),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _summaryCard('Gastos', expenses,
                        Icons.trending_down_rounded,
                        AppTheme.errorContainer.withOpacity(0.3),
                        AppTheme.errorRed,
                        changePercent: expensesChange,
                        higherIsBetter: false, compact: true),
                  ),
                ],
              ),
              _weekInsightBanner(expenses, prevExpenses),
              const SizedBox(height: 24),
              Text(
                'Gastos por día',
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 150,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxDaily == 0 ? 10 : maxDaily * 1.3,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final day = dayKeys[group.x.toInt()];
                          return BarTooltipItem(
                            '${_weekdaysShort[group.x.toInt()]} ${day.day}\n',
                            GoogleFonts.beVietnamPro(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: CurrencyFormatter.format(rod.toY),
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 26,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= dayKeys.length) {
                              return const SizedBox.shrink();
                            }
                            final isToday = dayKeys[idx] == today;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _weekdaysShort[idx],
                                style: GoogleFonts.beVietnamPro(
                                  color: isToday
                                      ? AppTheme.primary
                                      : AppTheme.onSurfaceVariant,
                                  fontSize: 11,
                                  fontWeight:
                                      isToday ? FontWeight.w800 : FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: dayKeys.asMap().entries.map((e) {
                      final idx = e.key;
                      final day = e.value;
                      final val = daily[day]?['expenses'] ?? 0;
                      final isToday = day == today;
                      final isFuture = day.isAfter(today);
                      return BarChartGroupData(
                        x: idx,
                        barRods: [
                          BarChartRodData(
                            toY: val,
                            width: 22,
                            borderRadius: BorderRadius.circular(6),
                            color: isFuture
                                ? AppTheme.outlineVariant.withOpacity(0.25)
                                : (isToday
                                    ? AppTheme.errorRed
                                    : AppTheme.errorRed.withOpacity(0.55)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Frase corta que resume, en lenguaje simple, cómo va la semana frente a
  // la anterior. Null cuando no hay ninguna base útil para comparar.
  Widget _weekInsightBanner(double expenses, double prevExpenses) {
    if (expenses == 0 && prevExpenses == 0) return const SizedBox.shrink();

    IconData icon;
    Color color;
    String message;

    if (prevExpenses == 0) {
      icon = Icons.info_outline_rounded;
      color = AppTheme.onSurfaceVariant;
      message =
          'La semana pasada no registraste gastos, así que no hay con qué comparar todavía.';
    } else {
      final change = ((expenses - prevExpenses) / prevExpenses) * 100;
      if (change > 5) {
        icon = Icons.trending_up_rounded;
        color = AppTheme.errorRed;
        message =
            'Gastaste ${change.toStringAsFixed(0)}% más que la semana pasada.';
      } else if (change < -5) {
        icon = Icons.trending_down_rounded;
        color = AppTheme.secondary;
        message =
            'Gastaste ${change.abs().toStringAsFixed(0)}% menos que la semana pasada. ¡Bien!';
      } else {
        icon = Icons.trending_flat_rounded;
        color = AppTheme.onSurfaceVariant;
        message = 'Vas gastando casi igual que la semana pasada.';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.primary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Líneas de evolución del mes: ingresos vs gastos acumulados, día a día.
  // Muy fácil de leer de un vistazo (¿qué línea va más arriba, y qué tan rápido sube?).
  Widget _buildMonthTrendCard(
      List<TransactionModel> monthTx, int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final now = DateTime.now();
    final isCurrentMonth = now.year == year && now.month == month;
    final lastDay = isCurrentMonth ? now.day : daysInMonth;

    final dailyExpense = List<double>.filled(daysInMonth, 0);
    final dailyIncome = List<double>.filled(daysInMonth, 0);
    for (var t in monthTx.where((t) => !t.isTransfer)) {
      if (t.isIncome) {
        dailyIncome[t.date.day - 1] += t.amount;
      } else {
        dailyExpense[t.date.day - 1] += t.amount;
      }
    }

    final cumulativeExpense = <double>[];
    final cumulativeIncome = <double>[];
    double runningExpense = 0;
    double runningIncome = 0;
    for (var i = 0; i < daysInMonth; i++) {
      runningExpense += dailyExpense[i];
      runningIncome += dailyIncome[i];
      cumulativeExpense.add(runningExpense);
      cumulativeIncome.add(runningIncome);
    }

    final visibleDays = isCurrentMonth ? lastDay : daysInMonth;
    final expenseSpots = List.generate(
        visibleDays, (i) => FlSpot(i.toDouble(), cumulativeExpense[i]));
    final incomeSpots = List.generate(
        visibleDays, (i) => FlSpot(i.toDouble(), cumulativeIncome[i]));

    final totalSpent =
        cumulativeExpense.isEmpty ? 0.0 : cumulativeExpense[visibleDays - 1];
    final totalIncome =
        cumulativeIncome.isEmpty ? 0.0 : cumulativeIncome[visibleDays - 1];
    final maxVal = totalSpent > totalIncome ? totalSpent : totalIncome;
    final maxY = maxVal <= 0 ? 10.0 : maxVal * 1.2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evolución del mes',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.primary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ingresos vs. gastos acumulados, día a día',
                      style: GoogleFonts.beVietnamPro(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              _legendDot('Ingresos', AppTheme.secondary),
              const SizedBox(width: 14),
              _legendDot('Gastos', AppTheme.errorRed),
            ],
          ),
          const SizedBox(height: 20),
          if (totalSpent <= 0 && totalIncome <= 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  'Aún no hay movimientos este mes',
                  style: GoogleFonts.beVietnamPro(
                      color: AppTheme.onSurfaceVariant, fontSize: 13),
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (daysInMonth - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: AppTheme.outlineVariant.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval:
                            (daysInMonth / 4).clamp(1, daysInMonth).roundToDouble(),
                        getTitlesWidget: (value, meta) {
                          final day = value.toInt() + 1;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '$day',
                              style: GoogleFonts.beVietnamPro(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                        final isIncome = s.barIndex == 0;
                        return LineTooltipItem(
                          '${isIncome ? 'Ingresos' : 'Gastos'} · día ${s.x.toInt() + 1}\n${CurrencyFormatter.format(s.y)}',
                          GoogleFonts.beVietnamPro(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: incomeSpots,
                      isCurved: true,
                      color: AppTheme.secondary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: expenseSpots,
                      isCurved: true,
                      color: AppTheme.errorRed,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.errorRed.withOpacity(0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Barras agrupadas ingresos/gastos de los últimos 6 meses: la vista más
  // simple para notar si el patrón mensual mejora o empeora con el tiempo.
  Widget _buildSixMonthTrendCard(String userId) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 5, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    final months = List.generate(6, (i) => DateTime(start.year, start.month + i, 1));

    return StreamBuilder<List<TransactionModel>>(
      stream: _txService.getTransactionsByDateRange(userId, start, end),
      builder: (context, snap) {
        final tx = snap.data ?? [];
        final incomeByMonth = <double>[];
        final expensesByMonth = <double>[];
        for (var m in months) {
          final monthTx = tx
              .where((t) => t.date.year == m.year && t.date.month == m.month)
              .toList();
          incomeByMonth.add(_txService.calculateIncome(monthTx));
          expensesByMonth.add(_txService.calculateExpenses(monthTx));
        }
        final maxVal = [...incomeByMonth, ...expensesByMonth]
            .fold<double>(0, (m, v) => v > m ? v : m);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.surfaceVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Últimos 6 meses',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.primary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ingresos y gastos, mes a mes',
                          style: GoogleFonts.beVietnamPro(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _legendDot('Ingresos', AppTheme.secondary),
                  const SizedBox(width: 14),
                  _legendDot('Gastos', AppTheme.errorRed),
                ],
              ),
              const SizedBox(height: 24),
              if (maxVal == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      'Aún no hay movimientos en este período',
                      style: GoogleFonts.beVietnamPro(
                          color: AppTheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxVal * 1.25,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final m = months[group.x.toInt()];
                            final label = rodIndex == 0 ? 'Ingresos' : 'Gastos';
                            return BarTooltipItem(
                              '${_monthsShort[m.month - 1]}\n$label: ',
                              GoogleFonts.beVietnamPro(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                              children: [
                                TextSpan(
                                  text: CurrencyFormatter.format(rod.toY),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= months.length) {
                                return const SizedBox.shrink();
                              }
                              final isCurrent = months[idx].year == now.year &&
                                  months[idx].month == now.month;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _monthsShort[months[idx].month - 1],
                                  style: GoogleFonts.beVietnamPro(
                                    color: isCurrent
                                        ? AppTheme.primary
                                        : AppTheme.onSurfaceVariant,
                                    fontSize: 11,
                                    fontWeight: isCurrent
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: months.asMap().entries.map((e) {
                        final idx = e.key;
                        return BarChartGroupData(
                          x: idx,
                          barRods: [
                            BarChartRodData(
                              toY: incomeByMonth[idx],
                              width: 9,
                              borderRadius: BorderRadius.circular(4),
                              color: AppTheme.secondary,
                            ),
                            BarChartRodData(
                              toY: expensesByMonth[idx],
                              width: 9,
                              borderRadius: BorderRadius.circular(4),
                              color: AppTheme.errorRed,
                            ),
                          ],
                          barsSpace: 4,
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            color: AppTheme.onSurfaceVariant,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
