import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../services/account_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/currency_picker.dart';
import 'accounts_screen.dart';

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;
  final List<String> steps;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
    this.steps = const [],
  });
}

const _explanatorySlides = [
  _OnboardingSlide(
    icon: Icons.insights_rounded,
    title: 'Todo tu dinero,\nen un solo lugar',
    description:
        'Apenas abres Monedo ves el resumen completo de tus finanzas personales.',
    steps: [
      'Balance total, ingresos y gastos del mes',
      'Accede a transacciones, metas y estadísticas desde un solo menú',
    ],
  ),
  _OnboardingSlide(
    icon: Icons.receipt_long_rounded,
    title: 'Registra ingresos\ny gastos al instante',
    description: 'Cada movimiento queda registrado en segundos.',
    steps: [
      'Toca el botón + para agregar un movimiento',
      'Elige la cuenta, la categoría y el monto',
      'El saldo de tu cuenta se actualiza al instante',
    ],
  ),
  _OnboardingSlide(
    icon: Icons.bar_chart_rounded,
    title: 'Estadísticas claras\nde tus finanzas',
    description: 'Entiende en qué se va tu dinero cada mes.',
    steps: [
      'Filtra por mes para ver tu evolución',
      'Compara ingresos contra gastos por categoría',
    ],
  ),
  _OnboardingSlide(
    icon: Icons.savings_rounded,
    title: 'Cumple tus metas\nde ahorro',
    steps: [
      'Toca "Nueva meta" y ponle un nombre',
      'Define el monto objetivo que quieres ahorrar',
      'Agrega abonos cuando quieras y sigue tu progreso en tiempo real',
    ],
    description:
        'Define objetivos, sigue tu progreso y celebra cada avance en el camino.',
  ),
];

enum _StepKind { welcome, currency, accounts, explanatory }

class _Step {
  final _StepKind kind;
  final _OnboardingSlide? slide;
  const _Step(this.kind, [this.slide]);
}

/// Asistente de configuración inicial. Según los flags, muestra un
/// recorrido completo (cuenta nueva) o solo los pasos que falten
/// (cuenta existente sin moneda y/o sin cuentas configuradas).
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  final bool showWelcome;
  final bool showCurrency;
  final bool showAccounts;
  final bool showExplanatory;

  const OnboardingScreen({
    super.key,
    required this.onFinish,
    this.showWelcome = true,
    this.showCurrency = false,
    this.showAccounts = false,
    this.showExplanatory = true,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  final _accountService = AccountService();
  StreamSubscription<List<AccountModel>>? _accountsSub;

  late final List<_Step> _steps = [
    if (widget.showWelcome) const _Step(_StepKind.welcome),
    if (widget.showCurrency) const _Step(_StepKind.currency),
    if (widget.showAccounts) const _Step(_StepKind.accounts),
    if (widget.showExplanatory)
      ..._explanatorySlides.map((s) => _Step(_StepKind.explanatory, s)),
  ];

  int _page = 0;
  Currency? _selectedCurrency;
  List<AccountModel> _accounts = [];
  bool _saving = false;

  bool get _isLast => _page == _steps.length - 1;

  bool get _canProceed {
    switch (_steps[_page].kind) {
      case _StepKind.currency:
        return _selectedCurrency != null;
      case _StepKind.accounts:
        return _accounts.isNotEmpty;
      default:
        return true;
    }
  }

  bool get _showSkip =>
      _steps[_page].kind == _StepKind.explanatory && !_isLast;

  @override
  void initState() {
    super.initState();
    if (widget.showAccounts) {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      _accountsSub = _accountService.getAccounts(userId).listen((accounts) {
        if (mounted) setState(() => _accounts = accounts);
      });
    }
  }

  @override
  void dispose() {
    _accountsSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (widget.showExplanatory) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
    }
    widget.onFinish();
  }

  Future<void> _next() async {
    if (!_canProceed) return;

    if (_steps[_page].kind == _StepKind.currency) {
      setState(() => _saving = true);
      await AuthService().updateCurrency(_selectedCurrency!.code);
      CurrencyFormatter.setCurrency(_selectedCurrency!.code);
      if (mounted) setState(() => _saving = false);
    }

    if (_isLast) {
      await _complete();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
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
              top: -90, left: -70,
              child: _blob(240, AppTheme.secondaryFixed, 0.18),
            ),
            Positioned(
              bottom: -120, right: -80,
              child: _blob(280, AppTheme.secondary, 0.2),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                          child: TextButton(
                            onPressed: _showSkip ? _complete : null,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                            ),
                            child: Text(
                              _showSkip ? 'Saltar' : '',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: _controller,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _steps.length,
                          onPageChanged: (i) => setState(() => _page = i),
                          itemBuilder: (context, i) => SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(32, 12, 32, 12),
                            child: _buildStepContent(_steps[i]),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _steps.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  width: i == _page ? 22 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: i == _page
                                        ? AppTheme.secondaryFixed
                                        : Colors.white.withOpacity(0.24),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _canProceed && !_saving ? _next : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.secondary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      Colors.white.withOpacity(0.12),
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
                                        _isLast ? 'Comenzar' : 'Siguiente',
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(_Step step) {
    switch (step.kind) {
      case _StepKind.welcome:
        return _buildWelcomeStep();
      case _StepKind.currency:
        return _buildCurrencyStep();
      case _StepKind.accounts:
        return _buildAccountsStep();
      case _StepKind.explanatory:
        return _buildSlide(step.slide!);
    }
  }

  Widget _buildWelcomeStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/logomonedo_new.png',
          width: 92,
          height: 92,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 32),
        Text(
          'Bienvenido a Monedo',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 27,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tu dinero, por fin tiene sentido.\nConfiguremos todo en un par de pasos.',
          textAlign: TextAlign.center,
          style: GoogleFonts.beVietnamPro(
            fontSize: 14.5,
            color: AppTheme.onPrimaryContainer,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepIcon(Icons.payments_outlined),
        const SizedBox(height: 28),
        Text(
          '¿Qué moneda usas?',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Elige tu moneda para que Monedo muestre tus cifras correctamente.',
          textAlign: TextAlign.center,
          style: GoogleFonts.beVietnamPro(
            fontSize: 14.5,
            color: AppTheme.onPrimaryContainer,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        CurrencyPickerField(
          selected: _selectedCurrency,
          onChanged: (c) => setState(() => _selectedCurrency = c),
        ),
      ],
    );
  }

  Widget _buildAccountsStep() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepIcon(Icons.account_balance_wallet_outlined),
        const SizedBox(height: 28),
        Text(
          '¿Dónde tienes tu dinero?',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Agrega tu efectivo y tus cuentas bancarias o billeteras digitales para separar tus saldos.',
          textAlign: TextAlign.center,
          style: GoogleFonts.beVietnamPro(
            fontSize: 14.5,
            color: AppTheme.onPrimaryContainer,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        if (_accounts.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _accounts.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(
                          height: 1, color: Colors.white.withOpacity(0.1)),
                    ),
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded,
                          color: AppTheme.secondaryFixed, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _accounts[i].name,
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(_accounts[i].balance),
                        style: GoogleFonts.beVietnamPro(
                          color: Colors.white70,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => showAddAccountSheet(context, userId: userId),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(_accounts.isEmpty ? 'Agregar cuenta' : 'Agregar otra cuenta'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withOpacity(0.4)),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            textStyle: GoogleFonts.beVietnamPro(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _stepIcon(IconData icon) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: AppTheme.secondaryFixed.withOpacity(0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppTheme.secondaryFixed, size: 38),
    );
  }

  Widget _buildSlide(_OnboardingSlide slide) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _stepIcon(slide.icon),
          const SizedBox(height: 28),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.25,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 14.5,
              color: AppTheme.onPrimaryContainer,
              height: 1.6,
            ),
          ),
          if (slide.steps.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0],
                  colors: [
                    Colors.white.withOpacity(0),
                    Colors.white.withOpacity(0.07),
                    Colors.white.withOpacity(0),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < slide.steps.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryFixed.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondaryFixed,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            slide.steps[i],
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13.5,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
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
