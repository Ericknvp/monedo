import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal.dart';
import '../utils/currency_formatter.dart';
import 'notification_service.dart';

/// Avisa cuando un aporte hace que una meta cruce el 50% o el 100% de su
/// monto objetivo — una sola vez por hito y por meta (si luego se retira
/// dinero y se vuelve a cruzar, no se repite).
class GoalMilestoneService {
  static const _milestones = [0.5, 1.0];

  final _notifications = NotificationService();

  // Corre después de guardar un aporte real; una falla aquí (permiso,
  // plugin) no debe hacer parecer que el aporte no se guardó.
  Future<void> checkMilestone({
    required GoalModel goal,
    required double newSaved,
  }) async {
    if (goal.targetAmount <= 0) return;
    try {
      final before = goal.savedAmount / goal.targetAmount;
      final after = newSaved / goal.targetAmount;

      for (final milestone in _milestones) {
        if (before >= milestone || after < milestone) continue;
        final isComplete = milestone >= 1.0;
        await _notifyOnce(
          markerKey: 'goal_milestone_${goal.id}_${(milestone * 100).round()}',
          title: isComplete ? 'Meta cumplida' : 'Vas a la mitad de tu meta',
          body: isComplete
              ? 'Completaste "${goal.title}": ${CurrencyFormatter.format(goal.targetAmount)}.'
              : 'Ya llevas el 50% de "${goal.title}".',
        );
      }
    } catch (_) {
      // No se pudo mostrar el aviso de meta: no crítico.
    }
  }

  Future<void> _notifyOnce({
    required String markerKey,
    required String title,
    required String body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(markerKey) ?? false) return;
    await prefs.setBool(markerKey, true);
    await _notifications.showNow(key: markerKey, title: title, body: body);
  }
}
