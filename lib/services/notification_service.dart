import 'dart:ui' show Color;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Envoltura sobre `flutter_local_notifications`: notificaciones que
/// programa/dispara el propio celular, sin servidor ni costo. Solo Android
/// por ahora — en web es un no-op (ver decisión en about_screen/preferences:
/// un push real en web necesitaría FCM + algo que lo dispare a horario, que
/// es la infraestructura extra que se descartó por el plan Blaze).
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'monedo_reminders';
  static const _channelName = 'Recordatorios de Monedo';
  static const _channelDescription =
      'Recordatorio diario, alertas de presupuesto, metas y movimientos recurrentes';

  /// Deja que cualquier excepción se propague — quien llama decide si debe
  /// bloquear algo o no (ver [initSafely] para el caso de arranque de la
  /// app, donde una falla aquí nunca debe impedir que abra).
  Future<void> init() async {
    if (kIsWeb || _initialized) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
    } catch (_) {
      // El nombre de zona del dispositivo no coincide con la base tz:
      // sigue en UTC. Solo afecta la hora exacta mostrada, no si dispara.
    }
    await _plugin.initialize(
      // 'ic_notification': silueta blanca del logo (billetera + moneda)
      // generada en drawable-*dpi — el ícono de app a color no sirve
      // aquí, Android lo aplana a un punto blanco genérico en la barra
      // de estado.
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
    );
    await _androidPlugin()?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
      ),
    );
    _initialized = true;
  }

  /// Para el arranque de la app (`main()`, antes de `runApp`): las
  /// notificaciones son un extra, nunca algo de lo que dependa el resto de
  /// la app, así que cualquier falla aquí se traga en vez de propagarse.
  Future<void> initSafely() async {
    try {
      await init();
    } catch (_) {
      // No se pudieron inicializar las notificaciones locales: el resto de
      // la app sigue funcionando igual, solo no habrá avisos.
    }
  }

  AndroidFlutterLocalNotificationsPlugin? _androidPlugin() =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Pide el permiso de notificaciones (obligatorio desde Android 13). Si el
  /// usuario lo niega, las llamadas de abajo simplemente no muestran nada —
  /// no se trata como error en ningún lugar que use este servicio.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final granted = await _androidPlugin()?.requestNotificationsPermission();
    return granted ?? false;
  }

  int _idFor(String key) => key.hashCode & 0x7FFFFFFF;

  // Verde de marca (AppTheme.secondary) para el círculo detrás del ícono en
  // la notificación expandida.
  static const _brandColor = Color(0xFF006C4B);

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          color: _brandColor,
        ),
      );

  /// Dispara una notificación de inmediato (alertas de presupuesto, metas,
  /// movimientos recurrentes recién generados, y el botón de prueba).
  Future<void> showNow({
    required String key,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    await init();
    await _plugin.show(
      id: _idFor(key),
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }

  /// Programa una notificación única para una fecha/hora futura (recordatorio
  /// diario de gastos). `key` identifica la notificación para poder
  /// cancelarla más tarde si ya no aplica (ver [cancel]).
  Future<void> scheduleAt({
    required String key,
    required DateTime dateTime,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    await init();
    final scheduled = tz.TZDateTime.from(dateTime, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id: _idFor(key),
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancel(String key) async {
    if (kIsWeb) return;
    await _plugin.cancel(id: _idFor(key));
  }
}
