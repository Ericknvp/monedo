import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Diálogo para cambiar la contraseña del usuario ya autenticado, pidiendo
/// la contraseña actual como confirmación de identidad.
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _authService = AuthService();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _done = false;
  String? _errorText;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentController.text;
    final newPassword = _newController.text;
    final confirm = _confirmController.text;

    if (current.isEmpty || newPassword.isEmpty || confirm.isEmpty) {
      setState(() => _errorText = 'Completa todos los campos');
      return;
    }
    if (newPassword.length < 6) {
      setState(() => _errorText = 'La nueva contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (newPassword != confirm) {
      setState(() => _errorText = 'Las contraseñas nuevas no coinciden');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    final error = await _authService.changePassword(
      currentPassword: current,
      newPassword: newPassword,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorText = error);
    } else {
      setState(() => _done = true);
    }
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
            child: _done ? _buildSuccess() : _buildForm(),
          ),
        ),
      ),
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

  Widget _buildForm() {
    return Column(
      key: const ValueKey('form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconBadge(Icons.password_rounded, AppTheme.secondaryContainer,
            AppTheme.onSecondaryContainer),
        const SizedBox(height: 20),
        Text(
          'Cambiar contraseña',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.primary),
        ),
        const SizedBox(height: 8),
        Text(
          'Confirma tu contraseña actual y elige una nueva.',
          style: GoogleFonts.beVietnamPro(
              fontSize: 14, color: AppTheme.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 24),
        _passwordField(
          controller: _currentController,
          label: 'Contraseña actual',
          obscure: _obscureCurrent,
          onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
        ),
        const SizedBox(height: 16),
        _passwordField(
          controller: _newController,
          label: 'Nueva contraseña',
          obscure: _obscureNew,
          onToggle: () => setState(() => _obscureNew = !_obscureNew),
        ),
        const SizedBox(height: 16),
        _passwordField(
          controller: _confirmController,
          label: 'Confirmar nueva contraseña',
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 12),
          Text(_errorText!,
              style: GoogleFonts.beVietnamPro(color: AppTheme.errorRed, fontSize: 13)),
        ],
        const SizedBox(height: 26),
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
                      fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
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
                        'Guardar',
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
        _iconBadge(Icons.check_circle_rounded, AppTheme.secondaryContainer,
            AppTheme.secondary),
        const SizedBox(height: 20),
        Text(
          '¡Contraseña actualizada!',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.primary),
        ),
        const SizedBox(height: 8),
        Text(
          'Tu contraseña se cambió correctamente.',
          style: GoogleFonts.beVietnamPro(
              fontSize: 14, color: AppTheme.onSurfaceVariant, height: 1.4),
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
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
