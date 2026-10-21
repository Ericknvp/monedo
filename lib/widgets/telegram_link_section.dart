import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/telegram_user_state.dart';
import '../services/telegram_link_service.dart';
import '../theme/app_theme.dart';
import 'app_toast.dart';
import 'telegram_link_dialog.dart';

/// Sección de ajustes para vincular (o desvincular) la cuenta de
/// Telegram con la de Monedo.
///
/// El estado se lee en tiempo real del documento del usuario
/// (`users/{uid}` → `telegramLinked`), así que la tarjeta cambia sola
/// en cuanto el bot confirma la vinculación, sin recargar.
///
/// Comparte el vocabulario visual del resto de "Preferencias": misma
/// fila, mismo ícono de 20px, mismo color de texto. El ícono de
/// Telegram es el único elemento con color propio, porque identifica
/// de un vistazo de qué integración se trata.
class TelegramLinkSection extends StatefulWidget {
  const TelegramLinkSection({super.key});

  @override
  State<TelegramLinkSection> createState() => _TelegramLinkSectionState();
}

class _TelegramLinkSectionState extends State<TelegramLinkSection> {
  final TelegramLinkService _service = TelegramLinkService();

  StreamSubscription<TelegramUserState>? _subscription;
  TelegramUserState? _state;
  bool _unlinking = false;

  @override
  void initState() {
    super.initState();

    final uid = _service.currentUid;
    if (uid == null) return;

    _subscription = _service.watchState(uid).listen((state) {
      if (!mounted) return;
      setState(() => _state = state);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _openLinkDialog() async {
    final linked = await showTelegramLinkDialog(
      context,
      username: _state?.monedoUsername,
    );
    if (linked == true && mounted) {
      showAppToast(
        context,
        message: 'Asistente de IA activado. Ya puedes enviar tus audios',
        icon: Icons.check_circle_rounded,
        accentColor: AppTheme.secondary,
      );
    }
  }

  Future<void> _confirmUnlink() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        // Sin un tope de ancho, el parrafo se estira a todo el ancho de
        // la pantalla en escritorio y deja de leerse como un dialogo.
        // Va aqui y no en el tema del dialogo porque hay varios
        // formularios (el de registrar movimiento, entre otros) que
        // necesitan el ancho que piden.
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 420),
        title: Text(
          'Desvincular Telegram',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        content: Text(
          '¿Seguro que deseas desvincular tu cuenta de Telegram? Dejarás de '
          'recibir avisos y tus audios ya no se registrarán. Tu cuenta de '
          'Monedo no se elimina y puedes volver a vincularla cuando quieras.',
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            height: 1.4,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Desvincular',
              style: TextStyle(color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final uid = _service.currentUid;
    if (uid == null) return;

    setState(() => _unlinking = true);
    try {
      await _service.unlink(uid, _state?.chatId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _unlinking = false);
      showAppToast(
        context,
        message: 'No se pudo desvincular. Inténtalo de nuevo',
        icon: Icons.error_outline_rounded,
        accentColor: AppTheme.errorRed,
      );
      return;
    }

    if (!mounted) return;
    setState(() => _unlinking = false);
    showAppToast(
      context,
      message: 'Telegram desvinculado con éxito',
      icon: Icons.check_circle_rounded,
      accentColor: AppTheme.secondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final linked = state?.linked ?? false;

    return TelegramLinkCard(
      linked: linked,
      connectedName: linked ? state?.connectedName : null,
      busy: _unlinking,
      onTap: _openLinkDialog,
      onUnlink: _confirmUnlink,
    );
  }
}

/// Tarjeta de Telegram dentro de los ajustes.
///
/// Recibe el estado ya resuelto y los callbacks, de modo que se puede
/// renderizar y revisar aislada sin depender de Firebase.
class TelegramLinkCard extends StatefulWidget {
  /// Si la cuenta ya está vinculada a un chat de Telegram.
  final bool linked;

  /// Nombre o ID de la cuenta conectada (`null` si no hay ninguno).
  final String? connectedName;

  /// Si hay una desvinculación en curso.
  final bool busy;

  /// Se llama al tocar la tarjeta cuando la cuenta no está vinculada.
  final VoidCallback onTap;

  /// Se llama al confirmar la desvinculación.
  final VoidCallback onUnlink;

  const TelegramLinkCard({
    super.key,
    required this.linked,
    this.connectedName,
    this.busy = false,
    required this.onTap,
    required this.onUnlink,
  });

  @override
  State<TelegramLinkCard> createState() => _TelegramLinkCardState();
}

class _TelegramLinkCardState extends State<TelegramLinkCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        // En reposo la tarjeta es plana; al pasar el raton sube de
        // superficie y gana borde y sombra, como los tiles de lista.
        color: _hovered && !widget.linked
            ? AppTheme.surfaceContainerLowest
            : AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hovered && !widget.linked
              ? AppTheme.outline
              : AppTheme.outlineVariant,
        ),
        boxShadow: _hovered && !widget.linked
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: widget.linked
          ? _connected(context)
          : _notConnected(context),
    );

    // Sin vinculo la tarjeta es una accion (abrir el generador de PIN);
    // con vinculo es un estado con una accion secundaria propia.
    if (widget.linked) return card;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: card,
      ),
    );
  }

  /// Estado sin vincular: la tarjeta es una acción.
  Widget _notConnected(BuildContext context) {
    return Row(
      // Alineado arriba: el ícono debe leerse en la misma línea que el
      // título, no flotar en el centro de la fila.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.send_rounded,
          color: AppTheme.telegramBlue,
          size: 20,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AiTitle(),
              const SizedBox(height: 2),
              Text(
                'Graba un audio y se anota solo',
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.onSurfaceVariant,
        ),
      ],
    );
  }

  /// Estado vinculado: indicador verde, cuenta conectada y la acción
  /// destructiva en su propia línea para que la etiqueta larga no
  /// compita con el estado por el espacio.
  Widget _connected(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.send_rounded,
              color: AppTheme.telegramBlue,
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: AppTheme.secondary,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Asistente de IA',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.beVietnamPro(
                            color: AppTheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.connectedName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${widget.connectedName} · Conectado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.beVietnamPro(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: widget.busy ? null : widget.onUnlink,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
              disabledForegroundColor: AppTheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: widget.busy
                ? SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.errorRed,
                    ),
                  )
                : const Text('Desvincular Telegram'),
          ),
        ),
      ],
    );
  }
}

/// Título "Asistente de IA" de la tarjeta.
///
/// El icono de destello va acompañado de las palabras: el color nunca
/// es el único portador de significado.
class _AiTitle extends StatelessWidget {
  const _AiTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.auto_awesome_rounded,
          size: 14,
          color: AppTheme.secondary,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Asistente de IA',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              color: AppTheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
