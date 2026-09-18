import 'package:flutter/material.dart' show TimeOfDay;
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'transaction_service.dart';

/// Recordatorio diario "¿ya registraste tus gastos de hoy?": se programa
/// (o cancela) cada vez que la app abre y cada vez que se guarda un
/// movimiento, comparando contra si ya hay algo registrado hoy — así nunca
/// llega si el usuario ya cumplió, y no hace falta backend para saberlo.
class ExpenseReminderService {
  static const _kEnabledKey = 'reminder_enabled';
  static const _kHourKey = 'reminder_hour';
  static const _kMinuteKey = 'reminder_minute';
  static const _notifKey = 'daily_expense_reminder';

  static const defaultTime = TimeOfDay(hour: 20, minute: 0);

  final _txService = TransactionService();
  final _notifications = NotificationService();

  // Encendido por defecto (a las 8pm, ver [defaultTime]) — el usuario lo
  // apaga o edita la hora desde Ajustes si no lo quiere.
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabledKey) ?? true;
  }

  Future<TimeOfDay> getTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_kHourKey);
    final minute = prefs.getInt(_kMinuteKey);
    if (hour == null || minute == null) return defaultTime;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setPreference({required bool enabled, TimeOfDay? time}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, enabled);
    if (time != null) {
      await prefs.setInt(_kHourKey, time.hour);
      await prefs.setInt(_kMinuteKey, time.minute);
    }
  }

  /// Revisa si hay que armar o cancelar el aviso de hoy. Se llama al abrir
  /// la app (sin esperar el resultado) y justo después de cambiar la
  /// preferencia en Ajustes — cualquier falla aquí (plugin, permisos) no
  /// debe romper nada más, así que se traga en vez de propagarse.
  Future<void> evaluate(String userId) async {
    if (userId.isEmpty) return;
    try {
      final enabled = await isEnabled();
      if (!enabled) {
        await _notifications.cancel(_notifKey);
        return;
      }

      // Como el recordatorio viene encendido por defecto, el permiso puede
      // no haberse pedido todavía (eso solo pasaba al tocar el switch en
      // Ajustes) — se pide aquí también; en Android, si ya se decidió
      // antes, esto no vuelve a mostrar diálogo alguno.
      await _notifications.requestPermission();

      final now = DateTime.now();
      if (await _hasTransactionToday(userId, now)) {
        await _notifications.cancel(_notifKey);
        return;
      }

      final time = await getTime();
      final target =
          DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (!target.isAfter(now)) {
        // Ya pasó la hora de hoy: no se dispara tarde, se reintenta mañana.
        await _notifications.cancel(_notifKey);
        return;
      }

      await _notifications.scheduleAt(
        key: _notifKey,
        dateTime: target,
        title: 'No olvides tus movimientos de hoy',
        body: '¿Ya registraste tus gastos o ingresos de hoy en Monedo?',
      );
    } catch (_) {
      // No se pudo programar el recordatorio: el resto de la app sigue
      // funcionando igual.
    }
  }

  Future<bool> _hasTransactionToday(String userId, DateTime now) async {
    final monthTx = await _txService
        .getTransactionsByMonth(userId, now.year, now.month)
        .first;
    return monthTx.any((t) => _isSameDay(t.date, now));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Se llama justo después de guardar un movimiento: si es de hoy, ya no
  /// hace falta esperar a la próxima apertura de la app para cancelar el
  /// aviso ya armado.
  Future<void> onTransactionSaved(DateTime transactionDate) async {
    if (!_isSameDay(transactionDate, DateTime.now())) return;
    try {
      await _notifications.cancel(_notifKey);
    } catch (_) {
      // No es crítico: en el peor caso el aviso de hoy suena de más.
    }
  }
}
