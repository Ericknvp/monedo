// ============================================================
// dashboard_screen.dart
// Pantalla principal de Monedo. Muestra el balance actual,
// ingresos, gastos del mes y los últimos movimientos.
// ============================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/transaction_service.dart';
import '../models/transaction.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'transactions_screen.dart';
import 'statistics_screen.dart';
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

  // ---- Carga los datos del usuario actual ----
  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUserData();
    if (mounted) {
      setState(() => _currentUser = user);
    }
  }

  // ---- Cierra la sesión del usuario ----
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
            onPressed: _logout,
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
            label: 'Movimientos',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined,
                color: AppTheme.textSecondary),
            selectedIcon:
            Icon(Icons.bar_chart, color: AppTheme.textPrimary),
            label: 'Estadísticas',
          ),
          NavigationDestination(
            icon:
            Icon(Icons.person_outlined, color: AppTheme.textSecondary),
            selectedIcon:
            Icon(Icons.person, color: AppTheme.textPrimary),
            label: 'Acerca de',
          ),
        ],
      ),
    );
  }

  // ---- Construye la pantalla de inicio ----
  Widget _buildHome(String userId, DateTime now) {
    return StreamBuilder<List<TransactionModel>>(
      stream: _transactionService.getTransactionsByMonth(
          userId, now.year, now.month),
      builder: (context, snapshot) {
        final transactions = snapshot.data ?? [];
        final balance = _transactionService.calculateBalance(transactions);
        final income = _transactionService.calculateIncome(transactions);
        final expenses =
        _transactionService.calculateExpenses(transactions);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${_currentUser?.username ?? 'Usuario'} 👋',
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
                balance: balance,
                income: income,
                expenses: expenses,
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
              if (transactions.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      Icon(Icons.receipt_long_outlined,
                          size: 64, color: AppTheme.textSecondary),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay movimientos este mes',
                        style:
                        TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                ...transactions.take(5).map((t) => TransactionTile(
                  transaction: t,
                  onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddTransactionScreen(transaction: t),
                    ),
                  ),
                  onDelete: () async {
                    await _transactionService
                        .deleteTransaction(t.id);
                  },
                )),
            ],
          ),
        );
      },
    );
  }
}