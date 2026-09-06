import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Muestra una notificación flotante en la parte superior de la pantalla:
/// arriba a la derecha en escritorio, arriba centrada en móvil.
void showAppToast(
  BuildContext context, {
  required String message,
  IconData icon = Icons.check_circle_rounded,
  Color accentColor = AppTheme.secondary,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.of(context);
  final isDesktop = MediaQuery.of(context).size.width >= 900;

  late OverlayEntry entry;
  entry = OverlayEntry(
    // Se toma el MediaQuery del propio contexto del overlay (por encima de
    // cualquier SafeArea de la pantalla que lo invoca), para que el padding
    // del status bar/notch sea el real y no uno ya consumido por un SafeArea.
    builder: (overlayContext) => _AppToast(
      message: message,
      icon: icon,
      accentColor: accentColor,
      isDesktop: isDesktop,
      topPadding: MediaQuery.of(overlayContext).padding.top,
      duration: duration,
      onDismissed: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}

class _AppToast extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color accentColor;
  final bool isDesktop;
  final double topPadding;
  final Duration duration;
  final VoidCallback onDismissed;

  const _AppToast({
    required this.message,
    required this.icon,
    required this.accentColor,
    required this.isDesktop,
    required this.topPadding,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<_AppToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: widget.isDesktop ? const Offset(0.25, 0) : const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    _timer?.cancel();
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _dismiss,
        child: Container(
          constraints: const BoxConstraints(minWidth: 260, maxWidth: 380),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.18),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.accentColor, size: 19),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  widget.message,
                  style: GoogleFonts.beVietnamPro(
                    color: AppTheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Positioned(
      top: widget.topPadding + 16,
      left: 16,
      right: 16,
      child: Align(
        alignment:
            widget.isDesktop ? Alignment.centerRight : Alignment.topCenter,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(position: _slide, child: card),
        ),
      ),
    );
  }
}
