import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

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

  Future<void> _register() async {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      _showError('Por favor completa todos los campos');
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
    );
    setState(() => _isLoading = false);
    if (error != null) {
      _showError(error);
    } else if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logomonedo_new.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crear cuenta',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Únete a Monedo',
                    style: GoogleFonts.beVietnamPro(
                      color: AppTheme.secondaryFixed,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildMobileFormFields(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFormFields() {
    inputField(TextEditingController ctrl, String label, IconData icon,
        {bool obscure = false, bool isConfirm = false, TextInputType? keyboardType}) {
      return TextField(
        controller: ctrl,
        obscureText: obscure
            ? (isConfirm ? _obscureConfirm : _obscurePassword)
            : false,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              GoogleFonts.beVietnamPro(color: Colors.white60, fontSize: 14),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24, width: 2),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide:
                BorderSide(color: AppTheme.secondaryFixed, width: 2),
          ),
          prefixIcon: Icon(icon, color: AppTheme.secondaryFixed),
          suffixIcon: obscure
              ? IconButton(
                  icon: Icon(
                    (isConfirm ? _obscureConfirm : _obscurePassword)
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white54,
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
      children: [
        inputField(_usernameController, 'Nombre de usuario', Icons.person_outline),
        const SizedBox(height: 20),
        inputField(_emailController, 'Correo electrónico', Icons.email_outlined,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 20),
        inputField(_passwordController, 'Contraseña', Icons.lock_outlined,
            obscure: true),
        const SizedBox(height: 20),
        inputField(_confirmPasswordController, 'Confirmar contraseña',
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
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('Crear cuenta',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: RichText(
            text: TextSpan(
              text: '¿Ya tienes cuenta? ',
              style: GoogleFonts.beVietnamPro(
                  color: Colors.white70, fontSize: 14),
              children: [
                TextSpan(
                  text: 'Inicia sesión',
                  style: GoogleFonts.beVietnamPro(
                    color: AppTheme.secondaryFixed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── SHARED FORM (desktop) ─────────────────────────────────────
  Widget _buildFormFields() {
    Widget field(TextEditingController ctrl, String label,
        {bool obscure = false,
        bool isConfirm = false,
        TextInputType? keyboardType}) {
      return TextField(
        controller: ctrl,
        obscureText:
            obscure ? (isConfirm ? _obscureConfirm : _obscurePassword) : false,
        keyboardType: keyboardType,
        style: GoogleFonts.beVietnamPro(color: AppTheme.primary, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.beVietnamPro(
              color: AppTheme.onSurfaceVariant, fontSize: 14),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.surfaceVariant, width: 2),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.secondary, width: 2),
          ),
          suffixIcon: obscure
              ? IconButton(
                  icon: Icon(
                    (isConfirm ? _obscureConfirm : _obscurePassword)
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTheme.onSurfaceVariant,
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
        field(_usernameController, 'Nombre de usuario'),
        const SizedBox(height: 28),
        field(_emailController, 'Correo electrónico',
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 28),
        field(_passwordController, 'Contraseña', obscure: true),
        const SizedBox(height: 28),
        field(_confirmPasswordController, 'Confirmar contraseña',
            obscure: true, isConfirm: true),
        const SizedBox(height: 40),
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
