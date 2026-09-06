
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';
import 'account_service.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AccountService _accountService = AccountService();

  CollectionReference get _transactions =>
      _firestore.collection('transactions');
  CollectionReference get _goals => _firestore.collection('goals');

  // ---- Ajusta el monto ahorrado de una meta de forma atómica ----
  // (Se implementa aquí en vez de reutilizar GoalService para evitar una
  // dependencia circular: GoalService también depende de TransactionService.)
  Future<void> _adjustGoalSaved(String goalId, double delta) async {
    if (delta == 0) return;
    await _goals.doc(goalId).update({
      'savedAmount': FieldValue.increment(delta),
    });
  }

  double _signedAmount(TransactionModel t) => t.isIncome ? t.amount : -t.amount;

  // ---- Agrega una nueva transacción y ajusta el saldo de la cuenta ----
  Future<void> addTransaction(TransactionModel transaction) async {
    await _transactions.add(transaction.toMap());
    if (transaction.accountId != null) {
      await _accountService.adjustBalance(
          transaction.accountId!, _signedAmount(transaction));
    }
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

  // ---- Obtiene el historial de aportes de una meta de ahorro ----
  Stream<List<TransactionModel>> getGoalContributions(
      String userId, String goalId) {
    return getTransactions(userId)
        .map((transactions) => transactions.where((t) => t.goalId == goalId).toList());
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

  // ---- Edita una transacción existente y corrige el saldo de la(s) cuenta(s) ----
  Future<void> updateTransaction(
      TransactionModel oldTransaction, TransactionModel newTransaction) async {
    await _transactions.doc(newTransaction.id).update(newTransaction.toMap());

    if (oldTransaction.accountId == newTransaction.accountId) {
      final delta =
          _signedAmount(newTransaction) - _signedAmount(oldTransaction);
      if (oldTransaction.accountId != null) {
        await _accountService.adjustBalance(oldTransaction.accountId!, delta);
      }
    } else {
      if (oldTransaction.accountId != null) {
        await _accountService.adjustBalance(
            oldTransaction.accountId!, -_signedAmount(oldTransaction));
      }
      if (newTransaction.accountId != null) {
        await _accountService.adjustBalance(
            newTransaction.accountId!, _signedAmount(newTransaction));
      }
    }

    if (oldTransaction.goalId == newTransaction.goalId) {
      if (oldTransaction.goalId != null) {
        final delta = newTransaction.amount - oldTransaction.amount;
        await _adjustGoalSaved(oldTransaction.goalId!, delta);
      }
    } else {
      if (oldTransaction.goalId != null) {
        await _adjustGoalSaved(
            oldTransaction.goalId!, -oldTransaction.amount);
      }
      if (newTransaction.goalId != null) {
        await _adjustGoalSaved(
            newTransaction.goalId!, newTransaction.amount);
      }
    }
  }

  // ---- Elimina una transacción y revierte su efecto en la cuenta y la meta ----
  //
  // La UI no ofrece eliminar transferencias (se revierten haciendo otra en
  // sentido contrario), pero si algo llega a invocarlo igual se revierte el
  // saldo de ambas cuentas involucradas para no dejar la transferencia a medias.
  Future<void> deleteTransaction(TransactionModel transaction) async {
    await _transactions.doc(transaction.id).delete();
    if (transaction.accountId != null) {
      await _accountService.adjustBalance(
          transaction.accountId!, -_signedAmount(transaction));
    }
    if (transaction.isTransfer && transaction.transferAccountId != null) {
      await _accountService.adjustBalance(
          transaction.transferAccountId!, -transaction.amount);
    }
    if (transaction.goalId != null) {
      await _adjustGoalSaved(
          transaction.goalId!, -transaction.amount);
    }
  }

  // ---- Calcula el balance total ----
  double calculateBalance(List<TransactionModel> transactions) {
    double balance = 0;
    for (var t in transactions) {
      if (t.isIncome) {
        balance += t.amount;
      } else {
        balance -= t.amount; // Incluye ahorros (categoría 'Ahorro')
      }
    }
    return balance;
  }

  // ---- Calcula el total de ingresos (excluye transferencias entre cuentas propias) ----
  double calculateIncome(List<TransactionModel> transactions) {
    return transactions
        .where((t) => t.isIncome && !t.isTransfer)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // ---- Calcula el total de gastos (incluye ahorros, excluye transferencias) ----
  double calculateExpenses(List<TransactionModel> transactions) {
    return transactions
        .where((t) => !t.isIncome && !t.isTransfer)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // ---- Agrupa gastos por categoría para las gráficas (excluye transferencias) ----
  Map<String, double> getExpensesByCategory(
      List<TransactionModel> transactions) {
    final Map<String, double> categoryMap = {};
    for (var t in transactions.where((t) => !t.isIncome && !t.isTransfer)) {
      categoryMap[t.category] =
          (categoryMap[t.category] ?? 0) + t.amount;
    }
    return categoryMap;
  }
}
