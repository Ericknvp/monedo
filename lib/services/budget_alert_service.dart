import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget.dart';
import '../utils/currency_formatter.dart';
import 'budget_service.dart';
import 'notification_service.dart';
import 'transaction_service.dart';

/// Revisa, después de guardar un gasto, si su categoría cruzó el 80% o el
/// 100% de su presupuesto mensual — y si es así, avisa una sola vez por
/// umbral y por mes (no cada vez que se agrega un gasto de más), usando el
/// mismo cálculo de "gastado" que ya se ve en Estadísticas.
class BudgetAlertService {
  final _budgetService = BudgetService();
  final _txService = TransactionService();
  final _notifications = NotificationService();

  // Corre siempre después de un guardado real (gasto ya registrado); si
  // algo aquí falla (permiso, plugin), no debe hacer parecer que el gasto
  // no se guardó — se traga el error en vez de propagarlo.
  Future<void> checkAfterExpense({
    required String userId,
    required String category,
    required DateTime date,
  }) async {
    try {
      final budgets = await _budgetService.getBudgets(userId).first;
      BudgetModel? budget;
      for (final b in budgets) {
        if (b.category == category) {
          budget = b;
          break;
        }
      }
      if (budget == null || budget.monthlyLimit <= 0) return;

      final monthTx = await _txService
          .getTransactionsByMonth(userId, date.year, date.month)
          .first;
      final spent = _txService.getExpensesByCategory(monthTx)[category] ?? 0;
      final ratio = spent / budget.monthlyLimit;
      final monthKey = '${date.year}-${date.month}';

      if (ratio >= 1.0) {
        await _notifyOnce(
          markerKey: 'budget_100_${category}_$monthKey',
          title: 'Superaste tu presupuesto de $category',
          body: 'Ya llevas ${CurrencyFormatter.format(spent)} de '
              '${CurrencyFormatter.format(budget.monthlyLimit)} este mes.',
        );
      } else if (ratio >= 0.8) {
        await _notifyOnce(
          markerKey: 'budget_80_${category}_$monthKey',
          title: 'Vas al 80% de tu presupuesto de $category',
          body: '${CurrencyFormatter.format(spent)} de '
              '${CurrencyFormatter.format(budget.monthlyLimit)} este mes.',
        );
      }
    } catch (_) {
      // No se pudo mostrar la alerta de presupuesto: no crítico.
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
