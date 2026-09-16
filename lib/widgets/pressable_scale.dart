import 'package:flutter/material.dart';

/// Envuelve [child] con feedback táctil inmediato: se encoge levemente al
/// presionar (desde el instante del toque, no al soltar) y vuelve a su
/// tamaño normal al soltar o cancelar. Pensado para selectores/píldoras
/// personalizados que solo cambian de color y no dan sensación de "presión".
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final HitTestBehavior behavior;

  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.96,
    this.behavior = HitTestBehavior.deferToChild,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: widget.behavior,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
