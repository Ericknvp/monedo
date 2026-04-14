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

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUserData();
    if (mounted) {
      setState(() => _currentUser = user);
    }
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

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = DateTime.now();

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
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.cardDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    '¿Cerrar sesión?',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  content: const Text(
                    '¿Seguro que quieres salir de tu cuenta?',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Salir',
                        style: TextStyle(color: AppTheme.expense),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                _logout();
              }
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
        backgroundColor: AppTheme.primaryPurple,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AddTransactionScreen()),
          );
        },
        child: const Icon(Icons.add, color: AppTheme.textPrimary),
      )
          : null,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.cardDark,
        indicatorColor: AppTheme.primaryPurple,
        selectedIndex: _selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
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
            icon: Icon(Icons.bar_chart_outlined, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.bar_chart, color: AppTheme.textPrimary),
            label: 'Estadísticas',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.flag, color: AppTheme.textPrimary),
            label: 'Metas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.person, color: AppTheme.textPrimary),
            label: 'Info',
          ),
        ],
      ),
    );
  }

  Widget _buildHome(String userId, DateTime now) {
    return StreamBuilder<List<TransactionModel>>(
      // Stream 1: TODAS las transacciones históricas (para el balance total)
      stream: _transactionService.getTransactions(userId),
      builder: (context, allSnapshot) {
        final allTransactions = allSnapshot.data ?? [];
        final totalBalance = _transactionService.calculateBalance(allTransactions);

        // Stream 2: Solo las del mes actual (para ingresos/gastos del mes)
        return StreamBuilder<List<TransactionModel>>(
          stream: _transactionService.getTransactionsByMonth(
              userId, now.year, now.month),
          builder: (context, monthSnapshot) {
            final monthTransactions = monthSnapshot.data ?? [];
            final monthIncome = _transactionService.calculateIncome(monthTransactions);
            final monthExpenses = _transactionService.calculateExpenses(monthTransactions);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${_currentUser?.username ?? 'Usuario'}! 👋',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
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
                    balance: totalBalance,    // balance acumulado total
                    income: monthIncome,      // ingresos del mes
                    expenses: monthExpenses,  // gastos del mes
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
                              style: TextStyle(color: AppTheme.textPrimary),
                            ),
                            content: Text(
                              'Se eliminará "${t.title}" (${CurrencyFormatter.format(t.amount)}). Esta acción no se puede deshacer.',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
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