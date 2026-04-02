// ============================================================
// main.dart
// Punto de entrada de la app Monedo.
// Inicializa Firebase y define la pantalla inicial.
// ============================================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  // Asegura que Flutter esté inicializado antes de Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase con la configuración generada
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
      debugShowCheckedModeBanner: false, // Quita el banner de debug
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}

// ---- Decide si mostrar login o dashboard según la sesión ----
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Mientras carga, muestra pantalla de splash
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.backgroundDark,
            body: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryPurple,
              ),
            ),
          );
        }

        // Si hay sesión activa, va al dashboard
        if (snapshot.hasData) {
          return const DashboardScreen();
        }

        // Si no hay sesión, va al login
        return const LoginScreen();
      },
    );
  }
}