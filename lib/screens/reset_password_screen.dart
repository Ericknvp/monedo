import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/web_redirect.dart' if (dart.library.io) '../utils/web_redirect_stub.dart';
import 'login_screen.dart';

enum _ResetState { verifying, invalid, form, success }

/// Pantalla con la marca de Monedo a la que llega el usuario al hacer
/// clic en el link de "Olvidé mi contraseña" del correo. Reemplaza la
/// página genérica de Firebase.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _authService = AuthService();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _ResetState _state = _ResetState.verifying;
  String? _oobCode;
  String? _email;
  String? _errorMessage;
  String? _formError;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _verifyCode();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = getUrlParam('oobCode');
    if (code == null || code.isEmpty) {
      setState(() {
        _state = _ResetState.invalid;
        _errorMessage = 'Este link no es válido.';
      });
      return;
    }
    final (email, error) = await _authService.verifyPasswordResetCode(code);
    if (!mounted) return;
    setState(() {
      if (error != null) {
        _state = _ResetState.invalid;
        _errorMessage = error;
      } else {
        _state = _ResetState.form;
        _oobCode = code;
        _email = email;
      }
    });
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.isEmpty || confirm.isEmpty) {
      setState(() => _formError = 'Completa ambos campos');
      return;
    }
    if (password.length < 6) {
      setState(() => _formError = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (password != confirm) {
      setState(() => _formError = 'Las contraseñas no coinciden');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });
    final error = await _authService.confirmPasswordReset(_oobCode!, password);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error != null) {
      setState(() => _formError = error);
    } else {
      setState(() => _state = _ResetState.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            Positioned(
              top: -80, left: -70,
              child: _blob(240, AppTheme.secondaryFixed, 0.2),
            ),
            Positioned(
              bottom: -100, right: -80,
              child: _blob(260, AppTheme.onPrimaryContainer, 0.15),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logomonedo_new.png',
                          width: 56,
                          height: 56,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 28),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: _buildContent(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildContent() {
    switch (_state) {
      case _ResetState.verifying:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator(color: AppTheme.secondary)),
        );
      case _ResetState.invalid:
        return _buildInvalid();
      case _ResetState.form:
        return _buildForm();
      case _ResetState.success:
        return _buildSuccess();
    }
  }

  Widget _buildInvalid() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconBadge(Icons.error_outline_rounded, AppTheme.errorContainer, AppTheme.errorRed),
        const SizedBox(height: 20),
        Text('Link no válido',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.primary)),
        const SizedBox(height: 8),
        Text(_errorMessage ?? 'Este link no es válido.',
            style: GoogleFonts.beVietnamPro(
                fontSize: 14, color: AppTheme.onSurfaceVariant, height: 1.4)),
        const SizedBox(height: 28),
        _primaryButton('Volver al inicio de sesión', () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconBadge(Icons.lock_reset_rounded, AppTheme.secondaryContainer,
            AppTheme.onSecondaryContainer),
        const SizedBox(height: 20),
        Text('Crea tu nueva contraseña',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.primary)),
        const SizedBox(height: 8),
        Text(
          _email != null
              ? 'Para la cuenta $_email'
              : 'Elige una contraseña segura para tu cuenta.',
          style: GoogleFonts.beVietnamPro(
              fontSize: 14, color: AppTheme.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 24),
        _passwordField(
          controller: _passwordController,
          label: 'Nueva contraseña',
          obscure: _obscurePassword,
          onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 16),
        _passwordField(
          controller: _confirmController,
          label: 'Confirmar contraseña',
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        if (_formError != null) ...[
          const SizedBox(height: 12),
          Text(_formError!,
              style: GoogleFonts.beVietnamPro(color: AppTheme.errorRed, fontSize: 13)),
        ],
        const SizedBox(height: 26),
        _primaryButton(
          'Guardar contraseña',
          _isSubmitting ? null : _submit,
          loading: _isSubmitting,
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconBadge(Icons.check_circle_rounded, AppTheme.secondaryContainer, AppTheme.secondary),
        const SizedBox(height: 20),
        Text('¡Contraseña actualizada!',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.primary)),
        const SizedBox(height: 8),
        Text('Ya puedes iniciar sesión con tu nueva contraseña.',
            style: GoogleFonts.beVietnamPro(
                fontSize: 14, color: AppTheme.onSurfaceVariant, height: 1.4)),
        const SizedBox(height: 28),
        _primaryButton('Iniciar sesión', () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }),
      ],
    );
  }

  Widget _iconBadge(IconData icon, Color background, Color foreground) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: foreground, size: 28),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.beVietnamPro(color: AppTheme.primary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.beVietnamPro(color: AppTheme.onSurfaceVariant, fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outlined,
            color: AppTheme.onSurfaceVariant, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppTheme.onSurfaceVariant,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: AppTheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.secondary, width: 1.6),
        ),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onPressed, {bool loading = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
