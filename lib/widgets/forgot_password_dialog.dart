import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Diálogo de "¿Olvidaste tu contraseña?": pide el correo, envía el link
/// de restablecimiento vía Firebase y muestra una confirmación, sin
/// revelar si el correo está registrado o no.
class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _sent = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorText = 'Ingresa tu correo electrónico');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    final error = await _authService.sendPasswordReset(email);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (error != null) {
        _errorText = error;
      } else {
        _sent = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _sent ? _buildSuccess() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBadge(IconData icon, Color background, Color foreground) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: foreground, size: 28),
    );
  }

  Widget _buildForm() {
    return Column(
      key: const ValueKey('form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconBadge(
          Icons.lock_reset_rounded,
          AppTheme.secondaryContainer,
          AppTheme.onSecondaryContainer,
        ),
        const SizedBox(height: 20),
        Text(
          '¿Olvidaste tu contraseña?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa tu correo y te enviaremos un link para crear una nueva contraseña.',
          style: GoogleFonts.beVietnamPro(
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          onSubmitted: (_) => _submit(),
          style: GoogleFonts.beVietnamPro(color: AppTheme.primary, fontSize: 15),
          decoration: InputDecoration(
            labelText: 'Correo electrónico',
            errorText: _errorText,
            labelStyle: GoogleFonts.beVietnamPro(
                color: AppTheme.onSurfaceVariant, fontSize: 14),
            prefixIcon: const Icon(Icons.email_outlined,
                color: AppTheme.onSurfaceVariant, size: 20),
            filled: true,
            fillColor: AppTheme.surfaceContainerLow,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.errorRed),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.beVietnamPro(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Enviar link',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconBadge(
          Icons.mark_email_read_rounded,
          AppTheme.secondaryContainer,
          AppTheme.secondary,
        ),
        const SizedBox(height: 20),
        Text(
          'Revisa tu correo',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Si tu correo está registrado, te enviamos el link. Revisa la sección de spam.',
          style: GoogleFonts.beVietnamPro(
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
            child: Text(
              'Entendido',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
