import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/onboarding_tour.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_text_field.dart';
import '../widgets/google_logo.dart';
import '../widgets/setup_gate.dart';
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
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  bool _validate() {
    setState(() {
      _usernameError = _usernameController.text.trim().isEmpty
          ? 'Ingresa un nombre de usuario'
          : null;
      _emailError =
          _emailController.text.trim().isEmpty ? 'Ingresa tu correo' : null;
      _passwordError = _passwordController.text.trim().isEmpty
          ? 'Ingresa una contraseña'
          : _passwordController.text.length < 6
              ? 'Debe tener al menos 6 caracteres'
              : null;
      _confirmError = _confirmPasswordController.text.trim().isEmpty
          ? 'Confirma tu contraseña'
          : _passwordController.text != _confirmPasswordController.text
              ? 'Las contraseñas no coinciden'
              : null;
    });
    return _usernameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmError == null;
  }

  Future<void> _register() async {
    if (!_validate()) return;
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
        MaterialPageRoute(builder: (_) => const PostAuthOnboarding()),
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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
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
      color: AppTheme.navyFixed,
      child: Stack(
        children: [
          Positioned(
            top: -100, right: -60,
            child: _blob(500, AppTheme.secondaryFixed, 0.2),
          ),
          Positioned(
            bottom: -80, left: -80,
            child: _blob(450, AppTheme.successFixed, 0.15),
          ),
          // Marca real (la misma silueta del logo), grande y tenue, en vez
          // de una cifra de usuarios inventada: llena el espacio sin
          // afirmar algo que no es cierto.
          Positioned(
            bottom: -70, right: -70,
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/images/logomonedo_new.png',
                width: 420,
                height: 420,
                fit: BoxFit.contain,
              ),
            ),
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
                const SizedBox(height: 24),
                _buildFreeBadge(),
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

  // Mismo dato real que ya usa la landing ("100% gratuito · Sin tarjeta ·
  // Sin sorpresas"), no una cifra de usuarios inventada.
  Widget _buildFreeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: AppTheme.secondaryFixed, size: 16),
          const SizedBox(width: 8),
          Text(
            '100% gratuito · Sin tarjeta · Sin sorpresas',
            style: GoogleFonts.beVietnamPro(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel() {
    return Container(
      color: AppTheme.surfaceContainerLowest,
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
              const SizedBox(height: 32),
              _buildFormFields(),
            ],
          ),
        ),
      ),
    );
  }

  // ── MOBILE ───────────────────────────────────────────────────
  // Cabecera reducida a una sola fila (logo + título) y campos en
  // versión "dense" para que el formulario completo, botón de Google
  // incluido, entre en pantalla sin necesitar scroll en la mayoría de
  // equipos; el SingleChildScrollView solo actúa como red de seguridad
  // en pantallas muy chicas o con texto grande.
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
              child: _blob(180, AppTheme.successFixed, 0.18),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 14),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/logomonedo_new.png',
                          width: 61,
                          height: 61,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Crear cuenta',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.4,
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
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
                        physics: const ClampingScrollPhysics(),
                        child: _buildMobileFormFields(),
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

  Widget _buildMobileFormFields() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _usernameController,
          label: 'Nombre de usuario',
          icon: Icons.alternate_email_rounded,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
          errorText: _usernameError,
          dense: true,
          onChanged: (_) {
            if (_usernameError != null) setState(() => _usernameError = null);
          },
          onSubmitted: (_) => _emailFocus.requestFocus(),
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _emailController,
          focusNode: _emailFocus,
          label: 'Correo electrónico',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          errorText: _emailError,
          dense: true,
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
          onSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          label: 'Contraseña',
          icon: Icons.lock_outlined,
          obscureText: true,
          showObscureToggle: true,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          errorText: _passwordError,
          dense: true,
          onChanged: (_) {
            if (_passwordError != null) setState(() => _passwordError = null);
          },
          onSubmitted: (_) => _confirmFocus.requestFocus(),
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _confirmPasswordController,
          focusNode: _confirmFocus,
          label: 'Confirmar contraseña',
          icon: Icons.lock_outlined,
          obscureText: true,
          showObscureToggle: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          errorText: _confirmError,
          dense: true,
          onChanged: (_) {
            if (_confirmError != null) setState(() => _confirmError = null);
          },
          onSubmitted: (_) => _register(),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successFixed,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.4),
                  )
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
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Divider(color: AppTheme.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'o continúa con',
                style: GoogleFonts.beVietnamPro(
                    color: AppTheme.onSurfaceVariant, fontSize: 12),
              ),
            ),
            Expanded(child: Divider(color: AppTheme.outlineVariant)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _signInWithGoogle,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              shape: const StadiumBorder(),
              side: BorderSide(color: AppTheme.outlineVariant),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GoogleLogo(size: 18),
                const SizedBox(width: 10),
                Text(
                  'Continuar con Google',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
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

  // ── SHARED FORM (desktop) ─────────────────────────────────────
  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _usernameController,
          label: 'Nombre de usuario',
          icon: Icons.alternate_email_rounded,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
          errorText: _usernameError,
          onChanged: (_) {
            if (_usernameError != null) setState(() => _usernameError = null);
          },
          onSubmitted: (_) => _emailFocus.requestFocus(),
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: _emailController,
          focusNode: _emailFocus,
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
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          errorText: _passwordError,
          onChanged: (_) {
            if (_passwordError != null) setState(() => _passwordError = null);
          },
          onSubmitted: (_) => _confirmFocus.requestFocus(),
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: _confirmPasswordController,
          focusNode: _confirmFocus,
          label: 'Confirmar contraseña',
          icon: Icons.lock_outlined,
          obscureText: true,
          showObscureToggle: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          errorText: _confirmError,
          onChanged: (_) {
            if (_confirmError != null) setState(() => _confirmError = null);
          },
          onSubmitted: (_) => _register(),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successFixed,
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
/// También se usa tras un primer inicio de sesión con Google.
class PostAuthOnboarding extends StatefulWidget {
  const PostAuthOnboarding({super.key});

  @override
  State<PostAuthOnboarding> createState() => _PostAuthOnboardingState();
}

class _PostAuthOnboardingState extends State<PostAuthOnboarding> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    if (_done) return const DashboardScreen();
    // La bienvenida ya se muestra antes de registrarse (OnboardingGate
    // delante de RegisterScreen). Aquí, con la cuenta recién creada, solo
    // falta moneda y bolsillos.
    return OnboardingScreen(
      showWelcome: false,
      showCurrency: true,
      showAccounts: true,
      showCategories: true,
      onFinish: () async {
        final uid = AuthService().currentUser?.uid;
        if (uid != null) await OnboardingTour.markNewAccount(uid);
        if (mounted) setState(() => _done = true);
      },
    );
  }
}
