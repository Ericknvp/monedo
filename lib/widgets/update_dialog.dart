import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../utils/web_redirect.dart' if (dart.library.io) '../utils/web_redirect_stub.dart';

/// Revisa si hay una versión más nueva de Monedo y, si el usuario no la
/// descartó ya, muestra un aviso con acceso directo a la landing para
/// descargarla. No hace nada si falla la consulta o no hay novedades.
Future<void> checkAndShowUpdateDialog(BuildContext context) async {
  final service = UpdateService();
  final update = await service.checkForUpdate();
  if (update == null) return;
  if (await service.wasDismissed(update.version)) return;
  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.secondary.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.system_update_rounded,
            color: AppTheme.secondary, size: 26),
      ),
      title: Text(
        'Nueva versión disponible',
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          color: AppTheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        'Monedo v${update.version} ya está disponible, con mejoras y correcciones. Descárgala desde la página de Monedo.',
        textAlign: TextAlign.center,
        style: GoogleFonts.beVietnamPro(
          color: AppTheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () async {
            await service.dismissVersion(update.version);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: Text('Más tarde',
              style: TextStyle(color: AppTheme.onSurfaceVariant)),
        ),
        ElevatedButton(
          onPressed: () {
            openExternalUrl(update.downloadUrl);
            Navigator.pop(ctx);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondary,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 0,
          ),
          child: const Text('Descargar'),
        ),
      ],
    ),
  );
}
