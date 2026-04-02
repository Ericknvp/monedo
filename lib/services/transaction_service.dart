// ============================================================
// transaction_service.dart
// Maneja todas las operaciones de movimientos en Firestore:
// agregar, obtener, editar y eliminar transacciones.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _transactions =>
      _firestore.collection('transactions');

  // ---- Agrega una nueva transacción ----
  Future<void> addTransaction(TransactionModel transaction) async {
    await _transactions.add(transaction.toMap());
  }

  // ---- Obtiene todas las transacciones de un usuario ----
  Stream<List<TransactionModel>> getTransactions(String userId) {
    return _transactions
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return TransactionModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
      // Ordenar en memoria por fecha descendente
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  // ---- Obtiene transacciones de un mes específico ----
  Stream<List<TransactionModel>> getTransactionsByMonth(
      String userId, int year, int month) {
    return getTransactions(userId).map((transactions) {
      return transactions.where((t) {
        return t.date.year == year && t.date.month == month;
      }).toList();
    });
  }

  // ---- Obtiene transacciones de la semana actual ----
  Stream<List<TransactionModel>> getTransactionsByWeek(String userId) {
    return getTransactions(userId).map((transactions) {
      final now = DateTime.now();
      final startOfWeek =
      now.subtract(Duration(days: now.weekday - 1));
      final start = DateTime(
          startOfWeek.year, startOfWeek.month, startOfWeek.day);
      return transactions.where((t) => t.date.isAfter(start)).toList();
    });
  }

  // ---- Edita una transacción existente ----
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _transactions.doc(transaction.id).update(transaction.toMap());
  }

  // ---- Elimina una transacción ----
  Future<void> deleteTransaction(String transactionId) async {
    await _transactions.doc(transactionId).delete();
  }

  // ---- Calcula el balance total ----
  double calculateBalance(List<TransactionModel> transactions) {
    double balance = 0;
    for (var t in transactions) {
      if (t.isIncome) {
        balance += t.amount;
      } else {
        balance -= t.amount;
      }
    }
    return balance;
  }

  // ---- Calcula el total de ingresos ----
  double calculateIncome(List<TransactionModel> transactions) {
    return transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // ---- Calcula el total de gastos ----
  double calculateExpenses(List<TransactionModel> transactions) {
    return transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // ---- Agrupa gastos por categoría para las gráficas ----
  Map<String, double> getExpensesByCategory(
      List<TransactionModel> transactions) {
    final Map<String, double> categoryMap = {};
    for (var t in transactions.where((t) => !t.isIncome)) {
      categoryMap[t.category] =
          (categoryMap[t.category] ?? 0) + t.amount;
    }
    return categoryMap;
  }
}