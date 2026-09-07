import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/account.dart';

class AccountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _accounts => _firestore.collection('accounts');
  CollectionReference get _transactions => _firestore.collection('transactions');

  // ---- Obtiene las cuentas del usuario en tiempo real ----
  Stream<List<AccountModel>> getAccounts(String userId) {
    return _accounts
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) =>
              AccountModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  // ---- Crea una nueva cuenta con su saldo inicial; devuelve su id ----
  //
  // Si es la PRIMERA cuenta del usuario, migra automáticamente el saldo de
  // los movimientos que ya existían antes de esta función (sin cuenta
  // asignada) para que no "desaparezca" dinero, y les asigna esta cuenta.
  Future<String> addAccount({
    required String userId,
    required String name,
    required double initialBalance,
  }) async {
    final existing = await _accounts.where('userId', isEqualTo: userId).get();
    var startingBalance = initialBalance;
    List<QueryDocumentSnapshot>? orphanedTx;

    if (existing.docs.isEmpty) {
      final txSnap =
          await _transactions.where('userId', isEqualTo: userId).get();
      orphanedTx = txSnap.docs.where((d) {
        final data = d.data() as Map<String, dynamic>;
        return data['accountId'] == null;
      }).toList();

      var legacyBalance = 0.0;
      for (final d in orphanedTx) {
        final data = d.data() as Map<String, dynamic>;
        final amount = (data['amount'] ?? 0).toDouble();
        final isIncome = data['isIncome'] ?? false;
        legacyBalance += isIncome ? amount : -amount;
      }
      startingBalance += legacyBalance;
    }

    final doc = await _accounts.add(AccountModel(
      id: '',
      userId: userId,
      name: name,
      balance: startingBalance,
      createdAt: DateTime.now(),
    ).toMap());

    if (orphanedTx != null && orphanedTx.isNotEmpty) {
      final batch = _firestore.batch();
      for (final d in orphanedTx) {
        batch.update(d.reference, {'accountId': doc.id});
      }
      await batch.commit();
    }

    return doc.id;
  }

  // ---- Renombra una cuenta (no toca el saldo) ----
  Future<void> renameAccount(String id, String name) async {
    await _accounts.doc(id).update({'name': name});
  }

  // ---- Cambia el color elegido para una cuenta ----
  Future<void> setColor(String id, int colorValue) async {
    await _accounts.doc(id).update({'color': colorValue});
  }

  // ---- Aplica un cambio de saldo (positivo o negativo) de forma atómica ----
  Future<void> adjustBalance(String accountId, double delta) async {
    if (delta == 0) return;
    await _accounts.doc(accountId).update({
      'balance': FieldValue.increment(delta),
    });
  }

  // ---- Elimina una cuenta ----
  Future<void> deleteAccount(String id) async {
    await _accounts.doc(id).delete();
  }

  // ---- Transfiere dinero entre dos cuentas propias, de forma atómica ----
  //
  // Además de ajustar ambos saldos, deja registrado un único movimiento de
  // tipo transferencia (con la cuenta origen en `accountId` y la destino en
  // `transferAccountId`) para que quede visible en el historial, las
  // estadísticas y las exportaciones, en vez de desaparecer silenciosamente.
  Future<void> transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
  }) async {
    if (fromAccountId == toAccountId || amount <= 0) return;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final txRef = _transactions.doc();

    await _firestore.runTransaction((txn) async {
      final fromRef = _accounts.doc(fromAccountId);
      final toRef = _accounts.doc(toAccountId);
      final fromSnap = await txn.get(fromRef);
      final toSnap = await txn.get(toRef);
      final fromData = fromSnap.data() as Map<String, dynamic>?;
      final toData = toSnap.data() as Map<String, dynamic>?;
      final fromBalance = (fromData?['balance'] ?? 0).toDouble();
      final toBalance = (toData?['balance'] ?? 0).toDouble();
      final fromName = fromData?['name'] ?? '';
      final toName = toData?['name'] ?? '';

      txn.update(fromRef, {'balance': fromBalance - amount});
      txn.update(toRef, {'balance': toBalance + amount});

      txn.set(txRef, {
        'userId': userId,
        'title': 'Transferencia: $fromName → $toName',
        'amount': amount,
        'category': 'Transferencia',
        'isIncome': false,
        'date': DateTime.now().toIso8601String(),
        'note': null,
        'accountId': fromAccountId,
        'goalId': null,
        'isTransfer': true,
        'transferAccountId': toAccountId,
      });
    });
  }

  double totalBalance(List<AccountModel> accounts) {
    return accounts.fold(0.0, (sum, a) => sum + a.balance);
  }
}
