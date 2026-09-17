import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Campo de texto de autenticación (login/registro): fondo plano en reposo,
/// borde y halo de acento que aparecen solo al enfocar, error inline debajo.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.showObscureToggle = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.focusNode,
    this.onSubmitted,
    this.errorText,
    this.onChanged,
    this.autofillHints,
    this.maxLines = 1,
    this.dense = false,
    this.inputFormatters,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final bool showObscureToggle;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  /// Versión más compacta (menos padding vertical) para contextos con poco
  /// espacio vertical, como el diálogo de escritorio.
  final bool dense;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  late bool _obscured = widget.obscureText;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  bool get _hasError => widget.errorText != null;

  Color get _accentColor {
    if (_hasError) return AppTheme.errorRed;
    if (_focused) return AppTheme.secondary;
    return AppTheme.outlineVariant;
  }

  @override
  Widget build(BuildContext context) {
    // Radio más chico en escritorio (dense): las píldoras muy redondeadas
    // leen como un control táctil; un radio más cerrado se siente hecho
    // para mouse, no una versión encogida de móvil.
    final radius = widget.dense ? 10.0 : 14.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: _focused
                ? AppTheme.surfaceContainerLowest
                : AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: (_focused || _hasError)
                  ? _accentColor
                  : Colors.transparent,
              width: 1.6,
            ),
            boxShadow: (_focused || _hasError)
                ? [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: widget.maxLines > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(
                    left: 18, top: widget.maxLines > 1 ? 16 : 0),
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: _accentColor),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  builder: (context, color, _) =>
                      Icon(widget.icon, color: color, size: 20),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: _obscured,
                  maxLines: widget.obscureText ? 1 : widget.maxLines,
                  keyboardType: widget.keyboardType,
                  textCapitalization: widget.textCapitalization,
                  textInputAction: widget.textInputAction,
                  onSubmitted: widget.onSubmitted,
                  onChanged: widget.onChanged,
                  autofillHints: widget.autofillHints,
                  inputFormatters: widget.inputFormatters,
                  autofocus: widget.autofocus,
                  style: GoogleFonts.beVietnamPro(
                    color: AppTheme.primary,
                    fontSize: 16,
                  ),
                  cursorColor: AppTheme.secondary,
                  decoration: InputDecoration(
                    labelText: widget.label,
                    labelStyle: GoogleFonts.beVietnamPro(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    floatingLabelStyle: GoogleFonts.beVietnamPro(
                      color: _hasError ? AppTheme.errorRed : AppTheme.secondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                        vertical: widget.dense ? 11 : 16, horizontal: 14),
                  ),
                ),
              ),
              if (widget.showObscureToggle)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: IconButton(
                    onPressed: () => setState(() => _obscured = !_obscured),
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween(begin: 0.9, end: 1.0).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Icon(
                        _obscured
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        key: ValueKey(_obscured),
                        color: AppTheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 18),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topLeft,
          child: _hasError
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: AppTheme.errorRed, size: 14),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.errorText!,
                          style: GoogleFonts.beVietnamPro(
                            color: AppTheme.errorRed,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Caja plana (mismo radio y fondo que [AppTextField] en reposo) para
/// campos que no se escriben, sino que abren un selector al tocarlos
/// (fecha, cuenta): sin estado de foco propio, solo feedback de toque.
class AppFieldShell extends StatelessWidget {
  const AppFieldShell({
    super.key,
    required this.icon,
    required this.child,
    this.trailing,
    this.onTap,
    this.dense = false,
  });

  final IconData icon;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;
  /// Versión más compacta (menos padding vertical), para el diálogo de
  /// escritorio donde hay que aprovechar mejor el alto disponible.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final radius = dense ? 10.0 : 14.0;
    final content = Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radius),
      ),
      padding:
          EdgeInsets.symmetric(horizontal: 14, vertical: dense ? 9.5 : 13),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppTheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: child),
          if (trailing != null) ...[const SizedBox(width: 6), trailing!],
        ],
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        hoverColor: AppTheme.surfaceContainerHigh,
        child: content,
      ),
    );
  }
}

/// Detecta hover de mouse (no-op en táctil) para widgets que necesitan un
/// estado visual propio al pasar el cursor encima, más allá de lo que ya
/// da `InkWell` — usado por controles compactos de escritorio.
class HoverBuilder extends StatefulWidget {
  const HoverBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, bool hovered) builder;

  @override
  State<HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: widget.builder(context, _hovered),
    );
  }
}
