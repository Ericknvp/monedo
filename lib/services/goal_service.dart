
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/goal.dart';
import '../models/transaction.dart';
import 'transaction_service.dart';

class GoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TransactionService _transactionService = TransactionService();

  CollectionReference get _goals => _firestore.collection('goals');

  // ---- Crea una nueva meta ----
  Future<void> addGoal(GoalModel goal) async {
    await _goals.add(goal.toMap());
  }

  // ---- Obtiene todas las metas del usuario en tiempo real ----
  Stream<List<GoalModel>> getGoals(String userId) {
    return _goals
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return GoalModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ---- Agrega dinero a una meta y descuenta del balance (registra como gasto) ----
  Future<void> addSavingsToGoal({
    required GoalModel goal,
    required double amount,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Actualiza el monto ahorrado en la meta
    final newSaved = goal.savedAmount + amount;
    await _goals.doc(goal.id).update({'savedAmount': newSaved});

    final transaction = TransactionModel(
      id: '',
      userId: userId,
      title: 'Ahorro: ${goal.title}',
      amount: amount,
      category: 'Ahorro',
      isIncome: false,
      date: DateTime.now(),
      note: 'Aporte a meta de ahorro',
    );
    await _transactionService.addTransaction(transaction);
  }

  // ---- Elimina una meta (no devuelve el dinero al balance) ----
  Future<void> deleteGoal(String goalId) async {
    await _goals.doc(goalId).delete();
  }

  // ---- Actualiza los datos de una meta ----
  Future<void> updateGoal(GoalModel goal) async {
    await _goals.doc(goal.id).update(goal.toMap());
  }
}
