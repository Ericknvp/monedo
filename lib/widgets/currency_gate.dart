import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/currency_selection_screen.dart';
import '../utils/currency_formatter.dart';

/// Verifica que el usuario tenga una moneda configurada (Firestore).
/// Cuentas creadas (o que iniciaron sesión) antes de esta función la
/// seleccionan una única vez antes de ver [child].
class CurrencyGate extends StatefulWidget {
  final Widget child;

  const CurrencyGate({super.key, required this.child});

  @override
  State<CurrencyGate> createState() => _CurrencyGateState();
}

class _CurrencyGateState extends State<CurrencyGate> {
  final _authService = AuthService();
  bool? _needsCurrency;

  @override
  void initState() {
    super.initState();
    _checkCurrency();
  }

  Future<void> _checkCurrency() async {
    final userData = await _authService.getCurrentUserData();
    if (userData?.currency != null) {
      CurrencyFormatter.setCurrency(userData!.currency!);
      setState(() => _needsCurrency = false);
    } else {
      setState(() => _needsCurrency = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_needsCurrency == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_needsCurrency == true) {
      return CurrencySelectionScreen(
        onFinish: (code) {
          CurrencyFormatter.setCurrency(code);
          setState(() => _needsCurrency = false);
        },
      );
    }
    return widget.child;
  }
}
