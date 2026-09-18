import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controla cuándo mostrar los recorridos guiados (coach marks) que
/// explican botones clave la primera vez que alguien crea una cuenta.
///
/// Solo se muestran a cuentas marcadas como nuevas con [markNewAccount]
/// (llamado justo al terminar el setup inicial tras registrarse): una
/// cuenta existente que actualiza la app nunca tuvo esa marca, así que
/// [shouldShow] siempre da `false` para ella y el recorrido no aparece de
/// la nada para usuarios que ya conocen la app.
class OnboardingTour {
  OnboardingTour._();

  static const dashboard = 'dashboard';
  static const movements = 'movements';
  static const statistics = 'statistics';
  static const goals = 'goals';

  static String _newAccountKey(String uid) => 'onboarding_tour_new_$uid';
  static String _seenKey(String uid, String section) =>
      'onboarding_tour_seen_${section}_$uid';

  static Future<void> markNewAccount(String uid) async {
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_newAccountKey(uid), true);
  }

  static Future<bool> shouldShow(String uid, String section) async {
    if (uid.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_newAccountKey(uid)) ?? false)) return false;
    return !(prefs.getBool(_seenKey(uid, section)) ?? false);
  }

  static Future<void> markSeen(String uid, String section) async {
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey(uid, section), true);
  }

  /// Vuelve a armar el recorrido completo para [uid], como si la cuenta
  /// acabara de crearse: permite revisar cambios al tour sin tener que
  /// registrar una cuenta nueva cada vez (botón de prueba en Acerca de,
  /// visible solo para la cuenta de pruebas del equipo).
  static Future<void> resetAll(String uid) async {
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_newAccountKey(uid), true);
    for (final section in [dashboard, movements, statistics, goals]) {
      await prefs.remove(_seenKey(uid, section));
    }
  }
}

/// Llaves globales de los widgets señalados por los recorridos guiados.
/// Viven aparte de cada pantalla porque [DashboardScreen] es quien decide
/// cuándo lanzar el recorrido de Movimientos/Estadísticas/Metas (al
/// cambiar de pestaña), pero los widgets que hay que señalar están
/// definidos dentro de esas pantallas.
class OnboardingTargets {
  OnboardingTargets._();

  // Movimientos
  static final searchBar = GlobalKey(debugLabel: 'onboarding_search_bar');
  static final filters = GlobalKey(debugLabel: 'onboarding_filters');
  static final exportButton =
      GlobalKey(debugLabel: 'onboarding_export_button');

  // Estadísticas
  static final monthSelector =
      GlobalKey(debugLabel: 'onboarding_month_selector');
  static final categoryBreakdown =
      GlobalKey(debugLabel: 'onboarding_category_breakdown');

  // Metas
  static final createGoal = GlobalKey(debugLabel: 'onboarding_create_goal');
}
