// ============================================================
// main.dart
// Punto de entrada de la app Monedo.
// Inicializa Firebase y define la pantalla inicial.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/setup_gate.dart';
import 'widgets/branded_loading_screen.dart';
import 'utils/currency_formatter.dart';
import 'utils/web_redirect.dart' if (dart.library.io) 'utils/web_redirect_stub.dart';

void main() async {
  // Este método segura que Flutter esté inicializado antes de Firebase
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Correos de Firebase Auth (verificación, restablecer contraseña, etc.)
  // en español en vez de inglés.
  await FirebaseAuth.instance.setLanguageCode('es');

  runApp(const MonedoApp());
}

class MonedoApp extends StatelessWidget {
  const MonedoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monedo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: ValueListenableBuilder<Currency>(
        valueListenable: CurrencyFormatter.notifier,
        // No usar `const` aquí: se necesita una instancia nueva en cada
        // notificación para que Flutter reconstruya todo el subárbol
        // (si no, al ser idéntica al widget anterior, se omite el rebuild).
        builder: (context, _, __) => AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // El link de "olvidé mi contraseña" debe funcionar sin importar
        // si ya hay una sesión activa en este navegador. Se detecta tanto
        // por nuestro propio parámetro (?view=reset-password) como por el
        // que agrega Firebase si el link viene de una "Action URL"
        // configurada en la consola (?mode=resetPassword).
        if (kIsWeb &&
            (getViewParam() == 'reset-password' ||
                getUrlParam('mode') == 'resetPassword')) {
          return const ResetPasswordScreen();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BrandedLoadingScreen();
        }

        if (snapshot.hasData) {
          return const SetupGate(child: DashboardScreen());
        }

        // No autenticado: en web redirige a la landing o muestra la pantalla según ?view=
        if (kIsWeb) {
          final view = getViewParam();
          if (view == 'register') {
            return const OnboardingGate(child: RegisterScreen());
          }
          if (view == 'login') {
            return const OnboardingGate(child: LoginScreen());
          }
          // Sin parámetro → redirige a la landing page
          redirectToLanding();
          return const BrandedLoadingScreen();
        }

        // Mobile: muestra onboarding (solo la primera vez) y luego login
        return const OnboardingGate(child: LoginScreen());
      },
    );
  }
}

/// Muestra el onboarding una única vez (persistido en SharedPreferences)
/// antes de dar paso a [child].
class OnboardingGate extends StatefulWidget {
  final Widget child;

  const OnboardingGate({super.key, required this.child});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool? _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSeenOnboarding == null) {
      return const BrandedLoadingScreen();
    }
    if (_hasSeenOnboarding == false) {
      return OnboardingScreen(
        onFinish: () => setState(() => _hasSeenOnboarding = true),
      );
    }
    return widget.child;
  }
}