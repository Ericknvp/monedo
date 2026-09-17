import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/account_service.dart';
import '../services/recurring_transaction_service.dart';
import '../screens/onboarding_screen.dart';
import '../utils/currency_formatter.dart';
import 'branded_loading_screen.dart';

/// Verifica que el usuario tenga moneda y al menos un bolsillo configurados.
/// Cuentas creadas (o que iniciaron sesión) antes de estas funciones
/// completan solo lo que les falte, una única vez, antes de ver [child].
class SetupGate extends StatefulWidget {
  final Widget child;

  const SetupGate({super.key, required this.child});

  @override
  State<SetupGate> createState() => _SetupGateState();
}

class _SetupGateState extends State<SetupGate> {
  final _authService = AuthService();
  final _accountService = AccountService();
  bool? _needsCurrency;
  bool? _needsAccounts;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final userData = await _authService.getCurrentUserData();
    if (userData?.currency != null) {
      CurrencyFormatter.setCurrency(userData!.currency!);
    }
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final accounts = await _accountService.getAccounts(userId).first;
    final needsAccounts = accounts.isEmpty;
    if (!needsAccounts) {
      // Movimientos recurrentes vencidos (salario, renta, etc.): se generan
      // una vez por apertura de la app, antes de mostrar el dashboard, para
      // que los saldos ya estén al día. Se evita mientras el usuario sigue
      // en onboarding sin bolsillos configurados. Si falla (sin conexión,
      // reglas de Firestore aún no actualizadas, etc.) no debe bloquear el
      // resto de la app: se reintenta en la próxima apertura.
      try {
        await RecurringTransactionService().generateDueTransactions(userId);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _needsCurrency = userData?.currency == null;
      _needsAccounts = needsAccounts;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_needsCurrency == null || _needsAccounts == null) {
      return const BrandedLoadingScreen();
    }
    if (_needsCurrency == true || _needsAccounts == true) {
      return OnboardingScreen(
        showWelcome: false,
        showCurrency: _needsCurrency!,
        showAccounts: _needsAccounts!,
        showExplanatory: false,
        onFinish: () => setState(() {
          _needsCurrency = false;
          _needsAccounts = false;
        }),
      );
    }
    return widget.child;
  }
}
