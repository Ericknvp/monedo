import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/transaction_service.dart';
import '../models/transaction.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'transactions_screen.dart';
import 'statistics_screen.dart';
import 'goals_screen.dart';
import 'about_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _transactionService = TransactionService();
  int _selectedIndex = 0;
  UserModel? _currentUser;

  static const _sectionTitles = [
    'Inicio',
    'Movimientos',
    'Estadísticas',
    'Metas de ahorro',
    'Acerca de',
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUserData();
    if (mounted) setState(() => _currentUser = user);
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

  Future<bool?> _confirmLogout() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Cerrar sesión?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('¿Seguro que quieres salir de tu cuenta?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Salir', style: TextStyle(color: AppTheme.expense)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = DateTime.now();
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      return _buildDesktopScaffold(userId, now);
    }

    // ── MOBILE (sin cambios) ──────────────────────────────────────
    final pages = [
      _buildHome(userId, now),
      const TransactionsScreen(),
      const StatisticsScreen(),
      const GoalsScreen(),
      const AboutScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/images/logomonedo.png', height: 32),
            const SizedBox(width: 8),
            const Text(
              'Monedo',
              style: TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              if (await _confirmLogout() == true) _logout();
            },
          ),
        ],
      ),
      body: pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: AppTheme.primaryPurple,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
              ),
              child: const Icon(Icons.add, color: AppTheme.textPrimary),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.cardDark,
        indicatorColor: AppTheme.primaryPurple,
        selectedIndex: _selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.home, color: AppTheme.textPrimary),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_outlined, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.list, color: AppTheme.textPrimary),
            label: 'Gastos',
          ),
          NavigationDestination(
            icon:
                Icon(Icons.bar_chart_outlined, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.bar_chart, color: AppTheme.textPrimary),
            label: 'Estadísticas',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.flag, color: AppTheme.textPrimary),
            label: 'Metas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.person, color: AppTheme.textPrimary),
            label: 'Info',
          ),
        ],
      ),
    );
  }

  // ── DESKTOP LAYOUT ────────────────────────────────────────────────
  Widget _buildDesktopScaffold(String userId, DateTime now) {
    final pages = [
      _buildDesktopHome(userId, now),
      const TransactionsScreen(),
      const StatisticsScreen(),
      const GoalsScreen(),
      const AboutScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildDesktopTopBar(),
                Expanded(child: pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(right: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Row(
              children: [
                Image.asset('assets/images/logomonedo.png', height: 36),
                const SizedBox(width: 10),
                const Text(
                  'Monedo',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Botón nuevo movimiento
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen()),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nuevo movimiento'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'MENÚ',
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.5),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 6),

          _buildSidebarItem(Icons.home_outlined, Icons.home, 'Inicio', 0),
          _buildSidebarItem(Icons.list_outlined, Icons.list, 'Movimientos', 1),
          _buildSidebarItem(Icons.bar_chart_outlined, Icons.bar_chart,
              'Estadísticas', 2),
          _buildSidebarItem(
              Icons.flag_outlined, Icons.flag, 'Metas de ahorro', 3),
          _buildSidebarItem(
              Icons.person_outline, Icons.person, 'Acerca de', 4),

          const Spacer(),

          // Usuario + logout
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (_currentUser?.username ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _currentUser?.username ?? 'Usuario',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    if (await _confirmLogout() == true) _logout();
                  },
                  icon: const Icon(Icons.logout,
                      color: AppTheme.textSecondary, size: 18),
                  tooltip: 'Cerrar sesión',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
      IconData icon, IconData selectedIcon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryPurple.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color:
                  isSelected ? AppTheme.primaryPurple : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTopBar() {
    final now = DateTime.now();
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final dateStr = '${now.day} de ${months[now.month - 1]} de ${now.year}';

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Text(
            _sectionTitles[_selectedIndex],
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            dateStr,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── DESKTOP HOME (2 columnas) ─────────────────────────────────────
  Widget _buildDesktopHome(String userId, DateTime now) {
    return StreamBuilder<List<TransactionModel>>(
      stream: _transactionService.getTransactions(userId),
      builder: (context, allSnapshot) {
        final allTransactions = allSnapshot.data ?? [];
        final totalBalance =
            _transactionService.calculateBalance(allTransactions);

        return StreamBuilder<List<TransactionModel>>(
          stream: _transactionService.getTransactionsByMonth(
              userId, now.year, now.month),
          builder: (context, monthSnapshot) {
            final monthTransactions = monthSnapshot.data ?? [];
            final monthIncome =
                _transactionService.calculateIncome(monthTransactions);
            final monthExpenses =
                _transactionService.calculateExpenses(monthTransactions);

            final expenses =
                monthTransactions.where((t) => !t.isIncome).toList();
            final incomes =
                monthTransactions.where((t) => t.isIncome).toList();
            final maxExpense = expenses.isEmpty
                ? 0.0
                : expenses
                    .map((t) => t.amount)
                    .reduce((a, b) => a > b ? a : b);
            final maxIncome = incomes.isEmpty
                ? 0.0
                : incomes
                    .map((t) => t.amount)
                    .reduce((a, b) => a > b ? a : b);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Columna izquierda ──────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${_currentUser?.username ?? 'Usuario'}! 👋',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tu resumen del mes',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        BalanceCard(
                          balance: totalBalance,
                          income: monthIncome,
                          expenses: monthExpenses,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Movimientos',
                                '${monthTransactions.length}',
                                Icons.receipt_long_outlined,
                                AppTheme.primaryPurple,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildStatCard(
                                'Mayor gasto',
                                CurrencyFormatter.format(maxExpense),
                                Icons.trending_down_outlined,
                                AppTheme.expense,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildStatCard(
                                'Mayor ingreso',
                                CurrencyFormatter.format(maxIncome),
                                Icons.trending_up_outlined,
                                AppTheme.income,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Columna derecha: últimos movimientos ───────────
                Container(
                  width: 360,
                  margin: const EdgeInsets.fromLTRB(0, 32, 32, 32),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
                        child: Row(
                          children: [
                            const Text(
                              'Últimos movimientos',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _selectedIndex = 1),
                              child: const Text(
                                'Ver todos',
                                style: TextStyle(
                                    color: AppTheme.accentPurple,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Colors.white10),
                      if (monthTransactions.isEmpty)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 48,
                                    color: AppTheme.textSecondary),
                                const SizedBox(height: 12),
                                const Text(
                                  'No hay movimientos este mes',
                                  style:
                                      TextStyle(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount:
                                monthTransactions.take(8).length,
                            itemBuilder: (context, index) {
                              final t =
                                  monthTransactions.take(8).toList()[index];
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
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: AppTheme.cardDark,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      title: const Text('¿Eliminar movimiento?',
                                          style: TextStyle(
                                              color: AppTheme.textPrimary)),
                                      content: Text(
                                        'Se eliminará "${t.title}" (${CurrencyFormatter.format(t.amount)}). Esta acción no se puede deshacer.',
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancelar',
                                              style: TextStyle(
                                                  color:
                                                      AppTheme.textSecondary)),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
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
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  // ── MOBILE HOME (sin cambios) ─────────────────────────────────────
  Widget _buildHome(String userId, DateTime now) {
    return StreamBuilder<List<TransactionModel>>(
      stream: _transactionService.getTransactions(userId),
      builder: (context, allSnapshot) {
        final allTransactions = allSnapshot.data ?? [];
        final totalBalance =
            _transactionService.calculateBalance(allTransactions);

        return StreamBuilder<List<TransactionModel>>(
          stream: _transactionService.getTransactionsByMonth(
              userId, now.year, now.month),
          builder: (context, monthSnapshot) {
            final monthTransactions = monthSnapshot.data ?? [];
            final monthIncome =
                _transactionService.calculateIncome(monthTransactions);
            final monthExpenses =
                _transactionService.calculateExpenses(monthTransactions);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${_currentUser?.username ?? 'Usuario'}! 👋',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tu resumen del mes',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  BalanceCard(
                    balance: totalBalance,
                    income: monthIncome,
                    expenses: monthExpenses,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Últimos movimientos',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (monthTransactions.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          Icon(Icons.receipt_long_outlined,
                              size: 64, color: AppTheme.textSecondary),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay movimientos este mes',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else
                    ...monthTransactions.take(5).map((t) => TransactionTile(
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
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppTheme.cardDark,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Text(
                                  '¿Eliminar movimiento?',
                                  style:
                                      TextStyle(color: AppTheme.textPrimary),
                                ),
                                content: Text(
                                  'Se eliminará "${t.title}" (${CurrencyFormatter.format(t.amount)}). Esta acción no se puede deshacer.',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('Cancelar',
                                        style: TextStyle(
                                            color: AppTheme.textSecondary)),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text('Eliminar',
                                        style:
                                            TextStyle(color: AppTheme.expense)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _transactionService.deleteTransaction(t.id);
                            }
                          },
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
