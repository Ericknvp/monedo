import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget.dart';

/// Presupuesto mensual por categoría: un límite fijo que se aplica cada mes
/// (no varía de un mes a otro), comparado contra el gasto real en
/// Estadísticas.
class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _budgets => _firestore.collection('budgets');

  // ---- Presupuestos del usuario en tiempo real ----
  Stream<List<BudgetModel>> getBudgets(String userId) {
    return _budgets.where('userId', isEqualTo: userId).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => BudgetModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
      list.sort((a, b) => a.category.toLowerCase().compareTo(b.category.toLowerCase()));
      return list;
    });
  }

  // ---- Fija (o reemplaza) el límite mensual de una categoría ----
  Future<void> setBudget({
    required String userId,
    required String category,
    required double monthlyLimit,
  }) async {
    final existing = await _budgets
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .limit(1)
        .get();
    if (existing.docs.isEmpty) {
      await _budgets.add(BudgetModel(
        id: '',
        userId: userId,
        category: category,
        monthlyLimit: monthlyLimit,
        createdAt: DateTime.now(),
      ).toMap());
    } else {
      await existing.docs.first.reference.update({'monthlyLimit': monthlyLimit});
    }
  }

  // ---- Quita el límite de una categoría ----
  Future<void> deleteBudget(String id) async {
    await _budgets.doc(id).delete();
  }
}
