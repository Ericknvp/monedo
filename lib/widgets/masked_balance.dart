import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/balance_visibility.dart';
import '../utils/currency_formatter.dart';

/// Último valor mostrado por cada [MaskedAmount] animado, por [trackingId].
/// Vive fuera del árbol de widgets (sobrevive a que la pantalla se destruya
/// y reconstruya al cambiar de pestaña) para que el conteo ascendente solo
/// se dispare la primera vez que arranca la app o cuando el monto realmente
/// cambia — no cada vez que se vuelve a montar el widget con el mismo valor.
class _BalanceTracker {
  static final Map<String, double> _lastValues = {};

  static double? consume(String id, double amount) {
    final last = _lastValues[id];
    _lastValues[id] = amount;
    return last;
  }
}

/// Muestra un monto de dinero, reemplazándolo por puntos cuando el usuario
/// activó "ocultar saldo".
///
/// Con [animate] activado, el número cuenta ascendiendo solo la primera vez
/// que se muestra en la sesión o cuando [amount] cambia de verdad respecto
/// al último valor visto para [trackingId] (por defecto compartido entre
/// todas las vistas del balance total); si se vuelve a montar con el mismo
/// valor (p.ej. al volver de otra pestaña) se muestra estático, sin repetir
/// la animación. Cuando el monto sube se tiñe de un leve verde y cuando baja
/// de un leve rojo mientras se asienta en el nuevo valor.
class MaskedAmount extends StatefulWidget {
  const MaskedAmount(
    this.amount, {
    super.key,
    this.style,
    this.animate = false,
    this.trackingId,
    this.maxLines,
    this.overflow,
  });

  final double amount;
  final TextStyle? style;
  final bool animate;
  final String? trackingId;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  State<MaskedAmount> createState() => _MaskedAmountState();
}

class _MaskedAmountState extends State<MaskedAmount>
    with SingleTickerProviderStateMixin {
  static const _flashDuration = Duration(milliseconds: 1800);

  late final AnimationController _flashController;
  double _from = 0;
  double _to = 0;
  Color? _flashColor;

  String get _id => widget.trackingId ?? 'balance';

  @override
  void initState() {
    super.initState();
    _flashController =
        AnimationController(vsync: this, duration: _flashDuration);
    _consume(widget.amount);
  }

  void _consume(double amount) {
    final last = _BalanceTracker.consume(_id, amount);
    if (last == null || last == amount) {
      _from = last ?? 0;
      _to = amount;
      return;
    }
    _from = last;
    _to = amount;
    _flashColor = amount > last ? AppTheme.income : AppTheme.expense;
    _flashController
      ..reset()
      ..forward();
  }

  @override
  void didUpdateWidget(covariant MaskedAmount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && widget.amount != oldWidget.amount) {
      setState(() => _consume(widget.amount));
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: BalanceVisibility.hiddenNotifier,
      builder: (context, hidden, _) {
        if (hidden) {
          return Text(BalanceVisibility.mask,
              style: widget.style,
              maxLines: widget.maxLines,
              overflow: widget.overflow);
        }
        if (!widget.animate) {
          return Text(CurrencyFormatter.format(widget.amount),
              style: widget.style,
              maxLines: widget.maxLines,
              overflow: widget.overflow);
        }
        final baseColor = widget.style?.color ?? DefaultTextStyle.of(context).style.color;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: _from, end: _to),
          duration: const Duration(milliseconds: 1300),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return AnimatedBuilder(
              animation: _flashController,
              builder: (context, _) {
                var color = baseColor;
                if (_flashColor != null) {
                  final intensity =
                      (1 - Curves.easeOut.transform(_flashController.value)) *
                          0.55;
                  color = Color.lerp(baseColor, _flashColor, intensity);
                }
                return Text(
                  CurrencyFormatter.format(value),
                  style: (widget.style ?? const TextStyle()).copyWith(color: color),
                  maxLines: widget.maxLines,
                  overflow: widget.overflow,
                );
              },
            );
          },
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
