import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/telegram_pin.dart';
import '../models/telegram_user_state.dart';
import '../services/telegram_link_service.dart';
import '../theme/app_theme.dart';
import '../utils/web_redirect.dart'
    if (dart.library.io) '../utils/web_redirect_stub.dart';
import 'app_toast.dart';

/// Abre el diálogo de vinculación con Telegram.
///
/// [username] es el nombre de usuario de Monedo; forma parte del
/// comando `/vincular <usuario> <PIN>` que el bot necesita para saber a
/// qué cuenta enlazar el chat. Si no se pasa, se resuelve leyendo el
/// documento del usuario.
///
/// Devuelve `true` si el usuario terminó vinculado (el bot confirmó el
/// PIN mientras el diálogo estaba abierto) y `null` si se cerró sin
/// vincular.
Future<bool?> showTelegramLinkDialog(
  BuildContext context, {
  String? username,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => TelegramLinkDialog(username: username),
  );
}

/// Diálogo de vinculación con Telegram.
///
/// Muestra un PIN de 6 dígitos con una cuenta atrás de 5 minutos, el
/// comando exacto que hay que enviar al bot y un enlace directo al chat
/// de Telegram. El diálogo se cierra solo en cuanto el bot confirma la
/// vinculación (se escucha el documento `telegram_links/{uid}`).
///
/// La lógica (generar el PIN, la cuenta atrás, la suscripción al
/// vínculo) vive en el estado; [TelegramLinkDialogContent] es la parte
/// puramente visual y puede renderizarse aislada.
class TelegramLinkDialog extends StatefulWidget {
  /// Nombre de usuario de Monedo para el comando `/vincular`.
  final String? username;

  const TelegramLinkDialog({super.key, this.username});

  @override
  State<TelegramLinkDialog> createState() => _TelegramLinkDialogState();
}

class _TelegramLinkDialogState extends State<TelegramLinkDialog> {
  final TelegramLinkService _service = TelegramLinkService();

  TelegramPin? _pin;
  bool _loading = true;
  String? _error;
  Duration _remaining = TelegramLinkService.pinLifetime;
  bool _expired = false;

  String? _username;
  bool? _previousLinked;

  Timer? _ticker;
  StreamSubscription<TelegramUserState>? _stateSubscription;
  bool _popping = false;

  @override
  void initState() {
    super.initState();

    final provided = widget.username?.trim();
    if (provided != null && provided.isNotEmpty) {
      _username = provided;
    }

    // Escucha el documento del usuario en tiempo real: cuando el bot
    // canjea el PIN, `telegramLinked` pasa a true, el diálogo se cierra
    // solo y la tarjeta de ajustes ya muestra el estado "conectado"
    // sin que el usuario tenga que recargar.
    final uid = _service.currentUid;
    if (uid != null) {
      _stateSubscription = _service.watchState(uid).listen(_onStateChanged);
    }

    _generatePin();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }

  void _onStateChanged(TelegramUserState state) {
    if (!mounted) return;

    // Si no nos pasaron el nombre de usuario, lo tomamos del documento.
    if (_username == null &&
        state.monedoUsername != null &&
        state.monedoUsername!.isNotEmpty) {
      setState(() => _username = state.monedoUsername);
    }

    final was = _previousLinked;
    _previousLinked = state.linked;

    // Solo nos interesa la transición false → true: si el usuario ya
    // estaba vinculado, el diálogo no se cierra solo.
    if (state.linked && was == false && !_popping) {
      _popping = true;
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _generatePin() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _expired = false;
      });
    }

    try {
      final pin = await _service.createPin();
      if (!mounted) return;
      _startTicker(pin);
      setState(() {
        _pin = pin;
        _remaining = pin.remainingAt(DateTime.now());
        _loading = false;
      });
    } on TelegramLinkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        // Último recurso: el servicio ya traduce los errores de
        // Firestore, así que llegar aquí es algo inesperado.
        _error = 'No se pudo generar el PIN. Inténtalo de nuevo';
        _loading = false;
      });
    }
  }

  void _startTicker(TelegramPin pin) {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final left = pin.remainingAt(DateTime.now());
      if (left <= Duration.zero) {
        timer.cancel();
        _onExpired();
        return;
      }
      setState(() => _remaining = left);
    });
  }

  void _onExpired() {
    final pin = _pin;
    if (pin != null) unawaited(_discardPin(pin));
    if (!mounted) return;
    setState(() {
      _remaining = Duration.zero;
      _expired = true;
    });
  }

  /// Borra el PIN caducado. Es limpieza best-effort: el bot también lo
  /// descartaría por expiration, así que un fallo aquí no es crítico.
  Future<void> _discardPin(TelegramPin pin) async {
    try {
      await _service.deletePin(pin.pin);
    } catch (_) {
      // Silenciado a propósito.
    }
  }

  void _openTelegram() {
    openExternalUrl(TelegramLinkService.botUrl);
  }

  @override
  Widget build(BuildContext context) {
    return TelegramLinkDialogContent(
      pin: _pin?.pin,
      username: _username,
      remaining: _remaining,
      expired: _expired,
      loading: _loading,
      error: _error,
      onRegenerate: _generatePin,
      onOpenTelegram: _openTelegram,
      onClose: () => Navigator.pop(context),
    );
  }
}

/// Parte visual del diálogo de vinculación.
///
/// Recibe el estado ya resuelto y los callbacks, de modo que se puede
/// renderizar y revisar aislada (por ejemplo, en una pantalla de
/// previsualización) sin depender de Firebase.
class TelegramLinkDialogContent extends StatelessWidget {
  /// PIN mostrado al usuario. `null` mientras se genera.
  final String? pin;

  /// Nombre de usuario de Monedo. Va en el comando para que el bot sepa
  /// a qué cuenta enlazar el chat.
  final String? username;

  /// Tiempo restante para que el PIN expire.
  final Duration remaining;

  /// Si el PIN ya caducó.
  final bool expired;

  /// Si el PIN se está generando.
  final bool loading;

  /// Mensaje de error, si la generación falló.
  final String? error;

  /// Genera un PIN nuevo.
  final VoidCallback onRegenerate;

  /// Abre el chat del bot de Telegram.
  final VoidCallback onOpenTelegram;

  /// Cierra el diálogo.
  final VoidCallback onClose;

  const TelegramLinkDialogContent({
    super.key,
    this.pin,
    this.username,
    this.remaining = TelegramLinkService.pinLifetime,
    this.expired = false,
    this.loading = false,
    this.error,
    required this.onRegenerate,
    required this.onOpenTelegram,
    required this.onClose,
  });

  /// Comando que el usuario tiene que enviarle al bot.
  ///
  /// El formato es `/vincular <usuario> <PIN>`. Si el usuario no tiene
  /// nombre de usuario (caso excepcional) se envía solo el PIN.
  String get command {
    final user = username?.trim();
    final code = pin ?? '';
    if (user == null || user.isEmpty) return '/vincular $code';
    return '/vincular $user $code';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _spaced(String value) => value.split('').join(' ');

  Future<void> _copyCommand(BuildContext context, String command) async {
    await Clipboard.setData(ClipboardData(text: command));
    if (!context.mounted) return;
    showAppToast(
      context,
      message: 'Comando copiado',
      icon: Icons.check_rounded,
      accentColor: AppTheme.secondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 20),
              _pinPanel(),
              const SizedBox(height: 20),
              if (error == null) ...[
                _instructions(context),
                const SizedBox(height: 24),
              ],
              _actions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.telegramBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.send_rounded,
            color: AppTheme.telegramBlue,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Vincular Telegram',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Distintivo de la función: pill menta con las
                  // iniciales, como los chips de estado del resto de la app.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'IA',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppTheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // La explicación de la función va ARRIBA, antes del PIN:
              // el usuario tiene que entender qué gana por vincular la
              // cuenta antes de ver un código. Una línea, sin rodeos.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.mic_none_rounded,
                    size: 16,
                    color: AppTheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Graba un audio y se anota solo.',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        height: 1.4,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Text(
                  'Ejemplo: «gasté 17.000 en aseo»',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    height: 1.4,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pinPanel() {
    if (loading) return _skeletonPanel();
    if (error != null) return _errorPanel(error!);
    return _activePanel();
  }

  Widget _activePanel() {
    final value = pin ?? '';
    final progress = remaining.inMilliseconds /
        TelegramLinkService.pinLifetime.inMilliseconds;
    final low = remaining.inSeconds <= 60;
    final accent = expired
        ? AppTheme.errorRed
        : (low ? AppTheme.warningAmberText : AppTheme.secondary);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        children: [
          // El PIN: dato que el usuario debe leer y transcribir, así que
          // va en Jakarta (cifras reconocibles) con cifras tabulares para
          // que no se bailen al digitar.
          Semantics(
            label: 'Código de vinculación: ${_spaced(value)}',
            child: ExcludeSemantics(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
                ),
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 10,
                    color:
                        expired ? AppTheme.onSurfaceVariant : AppTheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _countdownRow(accent),
          const SizedBox(height: 10),
          _progressBar(progress, accent),
        ],
      ),
    );
  }

  Widget _countdownRow(Color accent) {
    final label =
        expired ? 'El PIN expiró' : 'Expira en ${_formatDuration(remaining)}';
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            expired ? Icons.timer_off_outlined : Icons.schedule_rounded,
            size: 15,
            color: expired ? AppTheme.onSurfaceVariant : accent,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: expired ? AppTheme.onSurfaceVariant : accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar(double progress, Color accent) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.linear,
      builder: (context, value, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: double.infinity,
            height: 4,
            child: Stack(
              children: [
                // Carril: hijo NO posicionado, así que se pinta primero y
                // ocupa todo el ancho. Un `Positioned.fill` se pintaría
                // encima del relleno y lo taparía.
                Container(color: AppTheme.surfaceVariant),
                // `heightFactor: 1` es imprescindible: sin él el
                // `ColoredBox` no tiene hijo y colapsa a altura cero,
                // dejando la barra invisible.
                FractionallySizedBox(
                  widthFactor: value,
                  heightFactor: 1,
                  child: ColoredBox(color: accent),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _skeletonPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: const _PinSkeleton(),
    );
  }

  Widget _errorPanel(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: AppTheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                height: 1.4,
                color: AppTheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructions(BuildContext context) {
    final command = this.command;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Abre el bot y envía el comando:',
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            height: 1.4,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  command,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copiar comando',
                onPressed: () => _copyCommand(context, command),
                icon: const Icon(Icons.copy_rounded, size: 17),
                color: AppTheme.onSurfaceVariant,
                visualDensity: VisualDensity.compact,
                splashRadius: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actions() {
    // Jerarquía según el estado: la acción principal siempre es la que
    // desbloquea el flujo. Con el PIN caducado, lo importante es
    // regenerarlo; abrir Telegram pasa a ser la acción secundaria.
    if (error != null) {
      return Column(
        children: [
          _primaryButton(
            label: 'Reintentar',
            icon: Icons.refresh_rounded,
            onPressed: onRegenerate,
          ),
          const SizedBox(height: 4),
          _textButton('Cancelar', onPressed: onClose),
        ],
      );
    }

    if (expired) {
      return Column(
        children: [
          _primaryButton(
            label: 'Generar otro PIN',
            icon: Icons.refresh_rounded,
            onPressed: onRegenerate,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _textButton('Abrir Telegram', onPressed: onOpenTelegram),
              ),
              Expanded(
                child: _textButton('Cancelar', onPressed: onClose),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        _primaryButton(
          label: 'Abrir Telegram',
          icon: Icons.send_rounded,
          onPressed: loading ? null : onOpenTelegram,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _textButton(
                'Generar otro PIN',
                onPressed: loading ? null : onRegenerate,
              ),
            ),
            Expanded(
              child: _textButton('Cancelar', onPressed: onClose),
            ),
          ],
        ),
      ],
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.successFixed,
          foregroundColor: AppTheme.onSecondary,
          disabledBackgroundColor: AppTheme.surfaceContainerHigh,
          disabledForegroundColor: AppTheme.onSurfaceVariant,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textButton(String label, {VoidCallback? onPressed}) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: GoogleFonts.beVietnamPro(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Esqueleto de carga del PIN.
///
/// Se usan bloques con pulso en lugar de un spinner: el panel mantiene
/// su forma al cargar y el salto de tamaño al aparecer el código es
/// imperceptible.
class _PinSkeleton extends StatefulWidget {
  const _PinSkeleton();

  @override
  State<_PinSkeleton> createState() => _PinSkeletonState();
}

class _PinSkeletonState extends State<_PinSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.35 + (_controller.value * 0.45);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _bar(190, 34, opacity),
            const SizedBox(height: 14),
            _bar(120, 12, opacity),
          ],
        );
      },
    );
  }

  Widget _bar(double width, double height, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
