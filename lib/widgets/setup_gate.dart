import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/account_service.dart';
import '../services/recurring_transaction_service.dart';
import '../screens/onboarding_screen.dart';
import '../utils/currency_formatter.dart';
import '../utils/onboarding_tour.dart';
import 'branded_loading_screen.dart';

/// Verifica que el usuario tenga moneda y al menos un bolsillo configurados.
/// Cuentas creadas (o que iniciaron sesión) antes de estas funciones
/// completan solo lo que les falte, una única vez, antes de ver [child].
///
/// También es la puerta por la que pasa toda cuenta recién registrada: tras
/// crearla, Firebase dispara `authStateChanges` casi de inmediato y
/// [AuthWrapper] (en main.dart) reconstruye hacia aquí antes de que la
/// pantalla de registro alcance a navegar por su cuenta a
/// `PostAuthOnboarding` (esa navegación manual queda descartada porque el
/// widget ya fue reemplazado). Por eso, en vez de depender de esa
/// navegación, aquí se detecta una cuenta nueva de forma confiable: si no
/// tiene moneda NI bolsillos ([_needsCurrency] y [_needsAccounts] ambos
/// true en el primer chequeo), solo pudo ser recién creada (una cuenta que
/// ya completó el onboarding siempre tiene ambos), así que se le muestra
/// también el paso de categorías y se activa el recorrido guiado
/// ([OnboardingTour]).
///
/// Esa marca se guarda en [_confirmedNewAccounts] (estático: sobrevive a
/// que este State se recree) porque, al elegir la moneda dentro del propio
/// onboarding, [CurrencyFormatter.setCurrency] notifica al
/// `ValueListenableBuilder` que envuelve toda la app en main.dart. Eso
/// reconstruye [AuthWrapper] entero: su `StreamBuilder` pasa un instante por
/// `ConnectionState.waiting` (nueva suscripción a `authStateChanges`) antes
/// de volver a emitir el usuario ya autenticado, y en ese instante
/// `AuthWrapper` muestra `BrandedLoadingScreen`, destruyendo este `SetupGate`
/// a mitad del onboarding. Cuando se vuelve a crear, la moneda ya quedó
/// guardada (`_needsCurrency` da `false`), así que sin esta marca se perdía
/// la detección de cuenta nueva justo después del primer paso.
class SetupGate extends StatefulWidget {
  final Widget child;

  const SetupGate({super.key, required this.child});

  @override
  State<SetupGate> createState() => _SetupGateState();
}

class _SetupGateState extends State<SetupGate> {
  static final Set<String> _confirmedNewAccounts = {};

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
    final needsCurrency = userData?.currency == null;
    final needsAccounts = accounts.isEmpty;
    if (needsCurrency && needsAccounts && userId.isNotEmpty) {
      _confirmedNewAccounts.add(userId);
    }
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
      _needsCurrency = needsCurrency;
      _needsAccounts = needsAccounts;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_needsCurrency == null || _needsAccounts == null) {
      return const BrandedLoadingScreen();
    }
    if (_needsCurrency == true || _needsAccounts == true) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final isNewAccount = _confirmedNewAccounts.contains(uid);
      return OnboardingScreen(
        showWelcome: false,
        showCurrency: _needsCurrency!,
        showAccounts: _needsAccounts!,
        showCategories: isNewAccount,
        onFinish: () async {
          if (isNewAccount) {
            _confirmedNewAccounts.remove(uid);
            await OnboardingTour.markNewAccount(uid);
          }
          if (mounted) {
            setState(() {
              _needsCurrency = false;
              _needsAccounts = false;
            });
          }
        },
      );
    }
    return widget.child;
  }
}
