import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/currency_picker.dart';

/// Pantalla obligatoria (una sola vez) para que cuentas creadas antes de
/// tener soporte de moneda elijan su preferencia.
class CurrencySelectionScreen extends StatefulWidget {
  final ValueChanged<String> onFinish;

  const CurrencySelectionScreen({super.key, required this.onFinish});

  @override
  State<CurrencySelectionScreen> createState() =>
      _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState extends State<CurrencySelectionScreen> {
  final _authService = AuthService();
  Currency? _selected;
  bool _saving = false;

  Future<void> _continue() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    await _authService.updateCurrency(_selected!.code);
    if (mounted) widget.onFinish(_selected!.code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            Positioned(
              top: -80, left: -60,
              child: _blob(220, AppTheme.secondaryFixed, 0.2),
            ),
            Positioned(
              bottom: -100, right: -70,
              child: _blob(220, AppTheme.secondary, 0.18),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryFixed.withOpacity(0.16),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.payments_outlined,
                              color: AppTheme.secondaryFixed, size: 28),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '¿Qué moneda usas?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Elige tu moneda para que Monedo muestre tus cifras correctamente.',
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
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CurrencyPickerField(
                              selected: _selected,
                              onChanged: (c) => setState(() => _selected = c),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    (_selected == null || _saving) ? null : _continue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.secondary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      AppTheme.outlineVariant,
                                  shape: const StadiumBorder(),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  elevation: 0,
                                ),
                                child: _saving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.4),
                                      )
                                    : Text(
                                        'Continuar',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
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
}
