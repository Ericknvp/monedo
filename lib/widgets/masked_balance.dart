import 'package:flutter/material.dart';
import '../utils/balance_visibility.dart';
import '../utils/currency_formatter.dart';

/// Muestra un monto de dinero, reemplazándolo por puntos cuando el usuario
/// activó "ocultar saldo". [animate] usa el mismo conteo ascendente que
/// tenían las tarjetas de saldo (se salta al ocultar, no tiene sentido
/// animar puntos).
class MaskedAmount extends StatelessWidget {
  const MaskedAmount(
    this.amount, {
    super.key,
    this.style,
    this.animate = false,
    this.maxLines,
    this.overflow,
  });

  final double amount;
  final TextStyle? style;
  final bool animate;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: BalanceVisibility.hiddenNotifier,
      builder: (context, hidden, _) {
        if (hidden) {
          return Text(BalanceVisibility.mask,
              style: style, maxLines: maxLines, overflow: overflow);
        }
        if (!animate) {
          return Text(CurrencyFormatter.format(amount),
              style: style, maxLines: maxLines, overflow: overflow);
        }
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: amount),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Text(
            CurrencyFormatter.format(value),
            style: style,
            maxLines: maxLines,
            overflow: overflow,
          ),
        );
      },
    );
  }
}

/// Botón (ícono de ojo) que alterna mostrar/ocultar los saldos en toda la
/// app. Reactivo a [BalanceVisibility.hiddenNotifier] para reflejar el
/// estado actual sin importar desde qué tarjeta se togglee.
class BalanceVisibilityToggle extends StatelessWidget {
  const BalanceVisibilityToggle({super.key, required this.color, this.size = 18});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: BalanceVisibility.hiddenNotifier,
      builder: (context, hidden, _) => InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: BalanceVisibility.toggle,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: color,
            size: size,
          ),
        ),
      ),
    );
  }
}
