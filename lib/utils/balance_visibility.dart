import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencia local (no sincronizada con el perfil, igual que el modo
/// oscuro en AppTheme) para ocultar los saldos en pantalla cuando se abre
/// la app en público. Un solo notifier global para que todas las tarjetas
/// de saldo se oculten/muestren juntas al tocar el botón en cualquiera.
class BalanceVisibility {
  static const _prefsKey = 'balance_hidden';

  static final ValueNotifier<bool> hiddenNotifier = ValueNotifier<bool>(false);

  static bool get hidden => hiddenNotifier.value;

  static const String mask = '••••••';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    hiddenNotifier.value = prefs.getBool(_prefsKey) ?? false;
  }

  static Future<void> toggle() async {
    hiddenNotifier.value = !hiddenNotifier.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, hiddenNotifier.value);
  }
}
