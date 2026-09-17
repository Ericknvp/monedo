import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Aviso compacto en la parte inferior (no una notificación arriba) para un
/// borrado ya confirmado: en vez de ejecutar la acción al toque, la deja
/// pendiente y muestra "DESHACER" con una barra que se va vaciando durante
/// [duration], para que quede claro que la eliminación está en curso (no ya
/// hecha) y cuánto tiempo queda para arrepentirse.
///
/// Si no se toca "DESHACER" antes de que la barra termine, se ejecuta
/// [onConfirmed]. Si se toca, se ejecuta [onUndo] en su lugar (para revertir
/// cualquier cambio ya hecho en la pantalla, si lo hay).
///
/// Se resuelve el overlay a partir de [context] antes de insertar la
/// entrada, así que es seguro llamarla justo antes de un `Navigator.pop`
/// (p. ej. cerrar la pantalla de edición tras eliminar): el toast queda
/// insertado en el overlay raíz de la app, no en el de la ruta que se cierra.
void showUndoToast(
  BuildContext context, {
  required String message,
  required Future<void> Function() onConfirmed,
  VoidCallback? onUndo,
  Duration duration = const Duration(seconds: 4),
}) {
  final overlay = Overlay.of(context);
  final isDesktop = MediaQuery.of(context).size.width >= 900;
  final bottomPadding = MediaQuery.of(context).padding.bottom;
  // En móvil la mayoría de estas pantallas tienen una barra de navegación
  // inferior; se despeja con un margen fijo en vez de intentar medirla.
  final bottomOffset = bottomPadding + (isDesktop ? 16.0 : 88.0);

  var undone = false;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _UndoToast(
      message: message,
      isDesktop: isDesktop,
      bottomOffset: bottomOffset,
      duration: duration,
      onUndo: () {
        undone = true;
        onUndo?.call();
      },
      onDismissed: () {
        entry.remove();
        if (!undone) onConfirmed();
      },
    ),
  );

  overlay.insert(entry);
}

class _UndoToast extends StatefulWidget {
  final String message;
  final bool isDesktop;
  final double bottomOffset;
  final Duration duration;
  final VoidCallback onUndo;
  final VoidCallback onDismissed;

  const _UndoToast({
    required this.message,
    required this.isDesktop,
    required this.bottomOffset,
    required this.duration,
    required this.onUndo,
    required this.onDismissed,
  });

  @override
  State<_UndoToast> createState() => _UndoToastState();
}

class _UndoToastState extends State<_UndoToast>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final AnimationController _progress;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();

    // Cuenta regresiva visual: arranca llena y se vacía en línea recta
    // durante `duration`; al llegar a 0 dispara el borrado real.
    _progress = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) _dismiss();
      })
      ..reverse(from: 1);
  }

  Future<void> _dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    _progress.stop();
    await _controller.reverse();
    widget.onDismissed();
  }

  void _handleUndo() {
    if (_dismissing) return;
    widget.onUndo();
    _dismiss();
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.fromLTRB(12, 8, 6, 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.16),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_outline_rounded,
                    color: AppTheme.errorRed, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.message,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.beVietnamPro(
                      color: AppTheme.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                TextButton(
                  onPressed: _handleUndo,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.successFixed,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  child: Text(
                    'DESHACER',
                    style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: AnimatedBuilder(
                animation: _progress,
                builder: (_, __) => LinearProgressIndicator(
                  value: _progress.value,
                  minHeight: 2.5,
                  backgroundColor: AppTheme.errorRed.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation(AppTheme.errorRed),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Positioned(
      bottom: widget.bottomOffset,
      left: 16,
      right: 16,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(position: _slide, child: card),
        ),
      ),
    );
  }
}
