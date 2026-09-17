import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/setup_gate.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_text_field.dart';
import '../widgets/google_logo.dart';
import '../widgets/forgot_password_dialog.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  bool _validate() {
    setState(() {
      _emailError =
          _emailController.text.trim().isEmpty ? 'Ingresa tu correo' : null;
      _passwordError = _passwordController.text.trim().isEmpty
          ? 'Ingresa tu contraseña'
          : null;
    });
    return _emailError == null && _passwordError == null;
  }

  Future<void> _login() async {
    if (!_validate()) return;
    setState(() => _isLoading = true);
    final error = await _authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    setState(() => _isLoading = false);
    if (error != null) {
      _showError(error);
    } else if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SetupGate(child: DashboardScreen()),
        ),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    final (error, isNewUser) = await _authService.signInWithGoogle();
    setState(() => _isLoading = false);
    if (error != null) {
      _showError(error);
    } else if (mounted && _authService.currentUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => isNewUser
              ? const PostAuthOnboarding()
              : const SetupGate(child: DashboardScreen()),
        ),
      );
    }
  }

  void _showError(String message) {
    showAppToast(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      accentColor: AppTheme.errorRed,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return isDesktop ? _buildDesktop() : _buildMobile();
  }

  // ── DESKTOP ───────────────────────────────────────────────────
  Widget _buildDesktop() {
    return Scaffold(
      body: Row(
        children: [
          Expanded(child: _buildBrandingPanel()),
          SizedBox(
            width: 520,
            child: _buildFormPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingPanel() {
    return Container(
      color: AppTheme.navyFixed,
      child: Stack(
        children: [
          Positioned(
            top: -100, left: -100,
            child: _blob(500, AppTheme.secondaryFixed, 0.25),
          ),
          Positioned(
            top: 200, right: -80,
            child: _blob(400, AppTheme.onSecondaryContainer, 0.15),
          ),
          Positioned(
            bottom: -160, left: 60,
            child: _blob(600, AppTheme.successFixed, 0.15),
          ),
          Padding(
            padding: const EdgeInsets.all(60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/logomonedo_new.png',
                  width: 64,
                  height: 64,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tu dinero,\npor fin tiene sentido.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: -0.84,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Registra, analiza y controla tus\nfinanzas personales en un solo lugar.',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    color: AppTheme.secondaryFixed.withOpacity(0.85),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),
                _buildGlassCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }

  Widget _buildGlassCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryFixed.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.insights_rounded,
                    color: AppTheme.secondaryFixed, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen personal',
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Actualizado ahora',
                    style: GoogleFonts.beVietnamPro(
                      color: AppTheme.onPrimaryContainer,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: 0.75,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.secondaryFixed),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '¡Ahorraste 15% más que el mes pasado!',
            style: GoogleFonts.beVietnamPro(
              color: AppTheme.onPrimaryContainer,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel() {
    return Container(
      color: AppTheme.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 64),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido de nuevo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                  letterSpacing: -0.76,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa tus datos para acceder a tu cuenta.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 16,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              _buildFormFields(),
            ],
          ),
        ),
      ),
    );
  }

  // ── MOBILE ───────────────────────────────────────────────────
  Widget _buildMobile() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            Positioned(
              top: -70, left: -60,
              child: _blob(220, AppTheme.secondaryFixed, 0.2),
            ),
            Positioned(
              top: 50, right: -70,
              child: _blob(180, AppTheme.onSecondaryContainer, 0.15),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/images/logomonedo_new.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Bienvenido de nuevo',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ingresa tus datos para acceder a tu cuenta.',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 15,
                            color: AppTheme.secondaryFixed.withOpacity(0.85),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                        child: _buildFormFields(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SHARED FORM FIELDS (desktop) ──────────────────────────────
  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _emailController,
          label: 'Correo electrónico',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          errorText: _emailError,
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
          onSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          label: 'Contraseña',
          icon: Icons.lock_outlined,
          obscureText: true,
          showObscureToggle: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          errorText: _passwordError,
          onChanged: (_) {
            if (_passwordError != null) setState(() => _passwordError = null);
          },
          onSubmitted: (_) => _login(),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const ForgotPasswordDialog(),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              '¿Olvidaste tu contraseña?',
              style: GoogleFonts.beVietnamPro(
                color: AppTheme.secondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successFixed,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 20),
              elevation: 0,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Iniciar sesión',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(child: Divider(color: AppTheme.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'o continúa con',
                style: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant, fontSize: 13),
              ),
            ),
            Expanded(child: Divider(color: AppTheme.outlineVariant)),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _signInWithGoogle,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              shape: const StadiumBorder(),
              side: BorderSide(color: AppTheme.outlineVariant),
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GoogleLogo(size: 20),
                const SizedBox(width: 12),
                Text(
                  'Continuar con Google',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            ),
            child: RichText(
              text: TextSpan(
                text: '¿No tienes cuenta? ',
                style: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant, fontSize: 14),
                children: [
                  TextSpan(
                    text: 'Regístrate',
                    style: GoogleFonts.beVietnamPro(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
