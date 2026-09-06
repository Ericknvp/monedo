import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/account_service.dart';
import '../screens/onboarding_screen.dart';
import '../utils/currency_formatter.dart';

/// Verifica que el usuario tenga moneda y al menos una cuenta configuradas.
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
    if (!mounted) return;
    setState(() {
      _needsCurrency = userData?.currency == null;
      _needsAccounts = accounts.isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_needsCurrency == null || _needsAccounts == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
