import 'package:flutter/material.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: _focused
                ? AppTheme.surfaceContainerLowest
                : AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
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
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 18),
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
                  keyboardType: widget.keyboardType,
                  textCapitalization: widget.textCapitalization,
                  textInputAction: widget.textInputAction,
                  onSubmitted: widget.onSubmitted,
                  onChanged: widget.onChanged,
                  autofillHints: widget.autofillHints,
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
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
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
                      const Icon(Icons.error_outline_rounded,
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
