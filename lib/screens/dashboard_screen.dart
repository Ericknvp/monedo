import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/transaction_service.dart';
import '../services/category_service.dart';
import '../services/category_color_service.dart';
import '../services/category_visibility_service.dart';
import '../services/account_service.dart';
import '../services/goal_service.dart';
import '../models/transaction.dart';
import '../models/user_model.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../models/goal.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/category_icons.dart';
import '../utils/category_colors.dart';
import '../utils/category_visibility.dart';
import '../widgets/balance_card.dart';
import '../widgets/accounts_summary.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'transactions_screen.dart';
import 'statistics_screen.dart';
import 'goals_screen.dart';
import 'about_screen.dart';
import 'preferences_screen.dart';
import 'login_screen.dart';
import 'accounts_screen.dart';
import 'categories_screen.dart';
import 'budgets_screen.dart';

class _MonthData {
  final DateTime month;
  final double income;
  final double expenses;
  const _MonthData(
      {required this.month, required this.income, required this.expenses});
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _txService = TransactionService();
  final _categoryService = CategoryService();
  final _categoryColorService = CategoryColorService();
  final _categoryVisibilityService = CategoryVisibilityService();
  final _accountService = AccountService();
  final _goalService = GoalService();
  StreamSubscription<List<CategoryModel>>? _categorySub;
  StreamSubscription<Map<String, Color>>? _categoryColorSub;
  StreamSubscription<Set<String>>? _categoryVisibilitySub;
  int _selectedIndex = 0;
  UserModel? _currentUser;
  late final Future<List<_MonthData>> _chartFuture;

  // Nota: estas listas solo se usan en el menú lateral de escritorio.
  // La barra de navegación de móvil tiene sus propios destinos fijos.
  static const _sectionTitles = [
    'Vista general',
    'Movimientos',
    'Estadísticas',
    'Metas de ahorro',
    'Mis cuentas',
    'Mis categorías',
    'Presupuestos',
    'Preferencias',
    'Acerca de',
  ];

  static const _navItems = [
    (Icons.dashboard_rounded, 'Vista general'),
    (Icons.receipt_long_rounded, 'Movimientos'),
    (Icons.analytics_rounded, 'Estadísticas'),
    (Icons.savings_rounded, 'Metas'),
    (Icons.account_balance_wallet_outlined, 'Mis cuentas'),
    (Icons.category_outlined, 'Mis categorías'),
    (Icons.pie_chart_outline_rounded, 'Presupuestos'),
    (Icons.tune_rounded, 'Preferencias'),
    (Icons.person_outline_rounded, 'Acerca de'),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _chartFuture = _loadChartData(uid);
    _categorySub = _categoryService.getCategories(uid).listen((categories) {
      CategoryIconRegistry.customIcons.value = {
        for (final c in categories) c.name: c.icon,
      };
    });
    _categoryColorSub = _categoryColorService.getColors(uid).listen((colors) {
      CategoryColorRegistry.customColors.value = colors;
    });
    _categoryVisibilitySub =
        _categoryVisibilityService.getDisabled(uid).listen((disabled) {
      CategoryVisibilityRegistry.disabled.value = disabled;
    });
  }

  @override
  void dispose() {
    _categorySub?.cancel();
    _categoryColorSub?.cancel();
    _categoryVisibilitySub?.cancel();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUserData();
    if (mounted) setState(() => _currentUser = user);
  }

  Future<List<_MonthData>> _loadChartData(String userId) async {
    final now = DateTime.now();
    final result = <_MonthData>[];
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final transactions =
          await _txService.getTransactionsByMonth(userId, d.year, d.month).first;
      result.add(_MonthData(
        month: d,
        income: _txService.calculateIncome(transactions),
        expenses: _txService.calculateExpenses(transactions),
      ));
    }
    return result;
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<bool?> _confirmLogout() => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLowest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('¿Cerrar sesión?',
              style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primary, fontWeight: FontWeight.w600)),
          content: Text('¿Seguro que quieres salir de tu cuenta?',
              style: GoogleFonts.beVietnamPro(color: AppTheme.onSurfaceVariant)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar',
                  style: TextStyle(color: AppTheme.onSurfaceVariant)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Salir',
                  style: TextStyle(
                      color: AppTheme.errorRed, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = DateTime.now();
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) return _buildDesktop(userId, now);
    return _buildMobile(userId, now);
  }

  // ── DESKTOP ───────────────────────────────────────────────────
  Widget _buildDesktop(String userId, DateTime now) {
    final pages = [
      _buildDesktopHome(userId, now),
      const TransactionsScreen(),
      const StatisticsScreen(),
      const GoalsScreen(),
      const AccountsScreen(embedded: true),
      const CategoriesScreen(embedded: true),
      const BudgetsScreen(embedded: true),
      const PreferencesScreen(),
      AboutScreen(showPreferences: false, memberSince: _currentUser?.createdAt),
    ];
    final safeIndex = _selectedIndex.clamp(0, pages.length - 1);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildDesktopHeader(userId),
                Expanded(child: pages[safeIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        border: Border(right: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logomonedo_new.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 4),
                Text(
                  'Monedo',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          // Nav
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: _navItems.asMap().entries.map((e) {
                return _sidebarItem(e.value.$1, e.value.$2, e.key);
              }).toList(),
            ),
          ),

          const Spacer(),

          // User footer
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppTheme.secondaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (_currentUser?.username ?? 'U')[0].toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.onSecondaryFixed,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _currentUser?.username ?? 'Usuario',
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      color: AppTheme.onPrimaryFixedVariant, size: 18),
                  tooltip: 'Cerrar sesión',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    if (await _confirmLogout() == true) _logout();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                color: isSelected ? AppTheme.primary : Colors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildDesktopHeader(String userId) {
    final now = DateTime.now();
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final dateStr = '${now.day} de ${months[now.month - 1]} de ${now.year}';

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(bottom: BorderSide(color: AppTheme.surfaceVariant)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _sectionTitles[_selectedIndex],
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                dateStr,
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => openAddTransaction(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Agregar movimiento'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
              textStyle: GoogleFonts.beVietnamPro(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── DESKTOP HOME ──────────────────────────────────────────────
  Widget _buildDesktopHome(String userId, DateTime now) {
    return StreamBuilder<List<AccountModel>>(
      stream: _accountService.getAccounts(userId),
      builder: (context, accSnap) {
        final totalBalance = _accountService.totalBalance(accSnap.data ?? []);

        return StreamBuilder<List<TransactionModel>>(
          stream: _txService.getTransactionsByMonth(userId, now.year, now.month),
          builder: (context, monthSnap) {
            final monthTx = monthSnap.data ?? [];
            final income = _txService.calculateIncome(monthTx);
            final expenses = _txService.calculateExpenses(monthTx);

            final expList =
                monthTx.where((t) => !t.isIncome && !t.isTransfer).toList();
            final incList =
                monthTx.where((t) => t.isIncome && !t.isTransfer).toList();
            TransactionModel? maxExpTx;
            for (final t in expList) {
              if (maxExpTx == null || t.amount > maxExpTx.amount) maxExpTx = t;
            }
            TransactionModel? maxIncTx;
            for (final t in incList) {
              if (maxIncTx == null || t.amount > maxIncTx.amount) maxIncTx = t;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero card
                  _buildHeroCard(totalBalance, income, expenses),
                  const SizedBox(height: 24),

                  AccountsSummaryCard(accounts: accSnap.data ?? []),
                  const SizedBox(height: 24),

                  // Stat cards row
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          '${monthTx.length} movimientos',
                          'Este mes',
                          Icons.receipt_long_rounded,
                          AppTheme.primaryContainer.withOpacity(0.15),
                          AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _statCard(
                          maxExpTx == null
                              ? CurrencyFormatter.format(0)
                              : '${CurrencyFormatter.format(maxExpTx.amount)} de ${maxExpTx.title}',
                          'Mayor gasto',
                          Icons.trending_down_rounded,
                          AppTheme.errorContainer.withOpacity(0.3),
                          AppTheme.errorRed,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _statCard(
                          maxIncTx == null
                              ? CurrencyFormatter.format(0)
                              : '${CurrencyFormatter.format(maxIncTx.amount)} de ${maxIncTx.title}',
                          'Mayor ingreso',
                          Icons.trending_up_rounded,
                          AppTheme.secondaryContainer.withOpacity(0.4),
                          AppTheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _buildGoalsStatCard(userId)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Chart + Recent transactions
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: _buildBarChartCard(userId),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 360,
                        child: _buildRecentPanel(monthTx, userId),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Menciona las metas de ahorro en la vista general de escritorio (en
  // móvil ya tienen su propia pestaña fija en la barra inferior, así que
  // no hace falta repetirlas aquí).
  // Misma forma que _statCard (movimientos / mayor gasto / mayor ingreso),
  // como una cuarta tarjeta al lado de ellas, tocable para ir a Metas.
  Widget _buildGoalsStatCard(String userId) {
    return StreamBuilder<List<GoalModel>>(
      stream: _goalService.getGoals(userId),
      builder: (context, snap) {
        final goals = snap.data ?? [];
        final avgProgress = goals.isEmpty
            ? 0.0
            : goals.map((g) => g.progressPercent).reduce((a, b) => a + b) /
                goals.length;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _selectedIndex = 3),
          child: _statCard(
            goals.isEmpty
                ? 'Crear meta'
                : '${goals.length} ${goals.length == 1 ? 'meta' : 'metas'} · ${(avgProgress * 100).toStringAsFixed(0)}%',
            'Metas de ahorro',
            Icons.savings_rounded,
            AppTheme.secondaryContainer.withOpacity(0.2),
            AppTheme.secondary,
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(double balance, double income, double expenses) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0C3547),
            Color(0xFF082D3C),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF96F6C8).withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BALANCE DISPONIBLE',
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.secondaryFixed,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Balance total: ${CurrencyFormatter.format(balance)}',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.72,
                      ),
                    ),
                    TextSpan(
                      text: ' ${CurrencyFormatter.current.code}',
                      style: GoogleFonts.beVietnamPro(
                        color: AppTheme.secondaryFixed,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _heroChip(
                    Icons.arrow_downward_rounded,
                    'Ingresos del mes: ${CurrencyFormatter.format(income)}',
                    AppTheme.secondaryFixed,
                    AppTheme.onSecondaryFixed,
                  ),
                  _heroChip(
                    Icons.arrow_upward_rounded,
                    'Gastos del mes: ${CurrencyFormatter.format(expenses)}',
                    Colors.white.withOpacity(0.12),
                    Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip(IconData icon, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.beVietnamPro(
                color: fg, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      String value, String label, IconData icon, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
                color: AppTheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartCard(String userId) {
    const monthNames = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

    return Container(
      padding: const EdgeInsets.all(28),
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
              Text(
                'Ingresos vs Gastos',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Últimos 6 meses',
                  style: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          FutureBuilder<List<_MonthData>>(
            future: _chartFuture,
            builder: (ctx, snap) {
              if (!snap.hasData) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.secondary),
                  ),
                );
              }
              final data = snap.data!;
              final maxY = data.fold<double>(
                0,
                (prev, d) => [prev, d.income, d.expenses].reduce((a, b) => a > b ? a : b),
              );

              return SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => AppTheme.primary,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final textColor = rodIndex == 0
                              ? AppTheme.secondaryFixed
                              : Colors.white;
                          return BarTooltipItem(
                            rod.toY.toStringAsFixed(0),
                            TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY == 0 ? 100 : maxY * 1.25,
                    barGroups: data.asMap().entries.map((e) {
                      return BarChartGroupData(
                        x: e.key,
                        groupVertically: false,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.income,
                            color: AppTheme.secondaryFixed,
                            width: 12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          BarChartRodData(
                            toY: e.value.expenses,
                            color: AppTheme.primary.withOpacity(0.15),
                            width: 12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= data.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                monthNames[data[idx].month.month - 1],
                                style: GoogleFonts.beVietnamPro(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _chartLegend(AppTheme.secondaryFixed, 'Ingresos'),
              const SizedBox(width: 20),
              _chartLegend(AppTheme.primary.withOpacity(0.2), 'Gastos'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
              color: AppTheme.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRecentPanel(List<TransactionModel> monthTx, String userId) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
            child: Row(
              children: [
                Text(
                  'Actividad reciente',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  child: Text(
                    'Ver todos',
                    style: GoogleFonts.beVietnamPro(
                      color: AppTheme.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.surfaceVariant),
          if (monthTx.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        size: 40, color: AppTheme.outlineVariant),
                    const SizedBox(height: 10),
                    Text(
                      'Sin movimientos este mes',
                      style: GoogleFonts.beVietnamPro(
                          color: AppTheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ...monthTx.take(7).map((t) => TransactionTile(
                  transaction: t,
                  onEdit: () => openAddTransaction(context, transaction: t),
                  onDelete: () => _deleteTransaction(t),
                )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(TransactionModel t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('¿Eliminar movimiento?',
            style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary, fontWeight: FontWeight.w600)),
        content: Text(
          'Se eliminará "${t.title}". Esta acción no se puede deshacer.',
          style: GoogleFonts.beVietnamPro(color: AppTheme.onSurfaceVariant),
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
    if (confirm == true) await _txService.deleteTransaction(t);
  }

  // ── MOBILE ───────────────────────────────────────────────────
  Widget _buildMobile(String userId, DateTime now) {
    final pages = [
      _buildMobileHome(userId, now),
      const TransactionsScreen(),
      const StatisticsScreen(),
      const GoalsScreen(),
      AboutScreen(memberSince: _currentUser?.createdAt),
    ];
    // El menú de escritorio tiene una pestaña más (Preferencias), así que
    // el índice guardado puede no existir aquí si se redimensiona la
    // ventana estando en una pestaña que solo vive en escritorio.
    final safeIndex = _selectedIndex.clamp(0, pages.length - 1);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        titleSpacing: 4,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logomonedo_new.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              'Monedo',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),
      body: pages[safeIndex],
      floatingActionButton: safeIndex == 0
          ? FloatingActionButton(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
              onPressed: () => openAddTransaction(context),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.surfaceContainer,
        indicatorColor: AppTheme.secondary,
        selectedIndex: safeIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Gastos',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings_rounded),
            label: 'Metas',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHome(String userId, DateTime now) {
    return StreamBuilder<List<AccountModel>>(
      stream: _accountService.getAccounts(userId),
      builder: (context, accSnap) {
        final totalBalance = _accountService.totalBalance(accSnap.data ?? []);

        return StreamBuilder<List<TransactionModel>>(
          stream: _txService.getTransactionsByMonth(userId, now.year, now.month),
          builder: (context, monthSnap) {
            final monthTx = monthSnap.data ?? [];
            final income = _txService.calculateIncome(monthTx);
            final expenses = _txService.calculateExpenses(monthTx);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${_currentUser?.username ?? 'Usuario'}',
                    style: GoogleFonts.beVietnamPro(
                        color: AppTheme.onSurfaceVariant, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tu resumen del mes',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  BalanceCard(
                      balance: totalBalance,
                      income: income,
                      expenses: expenses),
                  const SizedBox(height: 20),
                  AccountsSummaryCard(accounts: accSnap.data ?? []),
                  const SizedBox(height: 28),
                  Text(
                    'Últimos movimientos',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (monthTx.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(Icons.receipt_long_outlined,
                                size: 56, color: AppTheme.outlineVariant),
                            const SizedBox(height: 14),
                            Text(
                              'No hay movimientos este mes',
                              style: GoogleFonts.beVietnamPro(
                                  color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...monthTx.take(5).map((t) => TransactionTile(
                          transaction: t,
                          onEdit: () =>
                              openAddTransaction(context, transaction: t),
                          onDelete: () => _deleteTransaction(t),
                        )),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
