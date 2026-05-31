// ============================================================
// main.dart
// Punto de entrada de la app Monedo.
// Inicializa Firebase y define la pantalla inicial.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'utils/web_redirect.dart' if (dart.library.io) 'utils/web_redirect_stub.dart';

void main() async {
  // Este método segura que Flutter esté inicializado antes de Firebase
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      home: const AuthWrapper(),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const DashboardScreen();
        }

        // No autenticado: en web redirige a la landing o muestra la pantalla según ?view=
        if (kIsWeb) {
          final view = getViewParam();
          if (view == 'register') return const RegisterScreen();
          if (view == 'login') return const LoginScreen();
          // Sin parámetro → redirige a la landing page
          redirectToLanding();
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Mobile: muestra login directamente
        return const LoginScreen();
      },
    );
  }
}