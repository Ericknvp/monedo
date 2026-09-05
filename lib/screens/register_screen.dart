import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/currency_picker.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  Currency? _selectedCurrency;

  Future<void> _register() async {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      _showError('Por favor completa todos los campos');
      return;
    }
    if (_selectedCurrency == null) {
      _showError('Selecciona tu moneda');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Las contraseñas no coinciden');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showError('La contraseña debe tener al menos 6 caracteres');
      return;
    }
    setState(() => _isLoading = true);
    final error = await _authService.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      currency: _selectedCurrency!.code,
    );
    setState(() => _isLoading = false);
    if (error != null) {
      _showError(error);
    } else if (mounted) {
      CurrencyFormatter.setCurrency(_selectedCurrency!.code);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const _PostRegisterOnboarding()),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorRed),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
            width: 540,
            child: _buildFormPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingPanel() {
    return Container(
      color: AppTheme.primary,
      child: Stack(
        children: [
          Positioned(
            top: -100, right: -60,
            child: _blob(500, AppTheme.secondaryFixed, 0.2),
          ),
          Positioned(
            bottom: -80, left: -80,
            child: _blob(450, AppTheme.secondary, 0.15),
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
                const SizedBox(height: 32),
                Text(
                  'Tu dinero,\nbajo control.',
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
                  'Únete a miles de personas que ya\ntienen el control de sus finanzas.',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    color: AppTheme.secondaryFixed.withOpacity(0.85),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),
                _buildFeatureItem(Icons.receipt_long_rounded,
                    'Registra ingresos y gastos'),
                const SizedBox(height: 16),
                _buildFeatureItem(Icons.bar_chart_rounded,
                    'Visualiza estadísticas por mes'),
                const SizedBox(height: 16),
                _buildFeatureItem(Icons.savings_rounded,
                    'Crea y sigue tus metas de ahorro'),
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

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.secondaryFixed.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.secondaryFixed, size: 20),
        ),
        const SizedBox(width: 14),
        Text(
          text,
          style: GoogleFonts.beVietnamPro(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildFormPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 56),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crear cuenta',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                  letterSpacing: -0.76,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Comienza tu camino hacia la claridad financiera.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 16,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
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
              top: -80, right: -60,
              child: _blob(220, AppTheme.secondaryFixed, 0.2),
            ),
            Positioned(
              top: 60, left: -70,
              child: _blob(180, AppTheme.secondary, 0.18),
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
                          'Crear cuenta',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Comienza tu camino hacia la claridad financiera.',
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
                      decoration: const BoxDecoration(
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

  InputDecoration _fieldDecoration(
    String label, {
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          GoogleFonts.beVietnamPro(color: AppTheme.onSurfaceVariant, fontSize: 14),
      filled: true,
      fillColor: AppTheme.surfaceContainerLow,
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: AppTheme.onSurfaceVariant, size: 20),
      suffixIcon: suffixIcon,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.outlineVariant, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.secondary, width: 1.6),
      ),
    );
  }

  // ── SHARED FORM (desktop) ─────────────────────────────────────
  Widget _buildFormFields() {
    Widget field(TextEditingController ctrl, String label, IconData icon,
        {bool obscure = false,
        bool isConfirm = false,
        TextInputType? keyboardType}) {
      return TextField(
        controller: ctrl,
        obscureText:
            obscure ? (isConfirm ? _obscureConfirm : _obscurePassword) : false,
        keyboardType: keyboardType,
        style: GoogleFonts.beVietnamPro(color: AppTheme.primary, fontSize: 16),
        decoration: _fieldDecoration(
          label,
          prefixIcon: icon,
          suffixIcon: obscure
              ? IconButton(
                  icon: Icon(
                    (isConfirm ? _obscureConfirm : _obscurePassword)
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () => setState(() => isConfirm
                      ? _obscureConfirm = !_obscureConfirm
                      : _obscurePassword = !_obscurePassword),
                )
              : null,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field(_usernameController, 'Nombre de usuario', Icons.person_outline),
        const SizedBox(height: 20),
        CurrencyPickerField(
          selected: _selectedCurrency,
          onChanged: (c) => setState(() => _selectedCurrency = c),
        ),
        const SizedBox(height: 20),
        field(_emailController, 'Correo electrónico', Icons.email_outlined,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 20),
        field(_passwordController, 'Contraseña', Icons.lock_outlined,
            obscure: true),
        const SizedBox(height: 20),
        field(_confirmPasswordController, 'Confirmar contraseña',
            Icons.lock_outlined,
            obscure: true, isConfirm: true),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
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
                        'Crear cuenta',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            child: RichText(
              text: TextSpan(
                text: '¿Ya tienes cuenta? ',
                style: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant, fontSize: 14),
                children: [
                  TextSpan(
                    text: 'Inicia sesión',
                    style: GoogleFonts.beVietnamPro(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w700,
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

/// Muestra el onboarding siempre después de un registro nuevo (sin
/// importar si ya se vio antes en este dispositivo) y luego el Dashboard.
class _PostRegisterOnboarding extends StatefulWidget {
  const _PostRegisterOnboarding();

  @override
  State<_PostRegisterOnboarding> createState() =>
      _PostRegisterOnboardingState();
}

class _PostRegisterOnboardingState extends State<_PostRegisterOnboarding> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    if (_done) return const DashboardScreen();
    return OnboardingScreen(onFinish: () => setState(() => _done = true));
  }
}
