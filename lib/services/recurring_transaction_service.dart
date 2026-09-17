import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import 'transaction_service.dart';

/// Reglas de movimientos recurrentes (salario, renta, suscripciones) y la
/// lógica que genera los movimientos reales (TransactionModel) cuando les
/// toca. La generación se dispara una vez por apertura de la app desde
/// [SetupGate], nunca en segundo plano fuera de la app.
class RecurringTransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TransactionService _txService = TransactionService();

  // Tope de ocurrencias generadas por regla en una sola corrida: evita que
  // un bug de fechas (o una regla diaria olvidada durante años) cuelgue la
  // app generando miles de movimientos de golpe.
  static const int _maxOccurrencesPerRun = 366;

  CollectionReference get _rules =>
      _firestore.collection('recurringTransactions');

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Crea la regla y devuelve la misma regla con el `id` real asignado por
  /// Firestore (necesario para generar la primera ocurrencia de inmediato).
  Future<RecurringTransactionModel> addRule(
      RecurringTransactionModel rule) async {
    final doc = await _rules.add(rule.toMap());
    return RecurringTransactionModel.fromMap(rule.toMap(), doc.id);
  }

  Future<void> updateRule(RecurringTransactionModel rule) async {
    await _rules.doc(rule.id).update(rule.toMap());
  }

  Future<void> deleteRule(String id) async {
    await _rules.doc(id).delete();
  }

  Stream<List<RecurringTransactionModel>> getRules(String userId) {
    return _rules.where('userId', isEqualTo: userId).snapshots().map((snap) {
      final rules = snap.docs
          .map((d) => RecurringTransactionModel.fromMap(
              d.data() as Map<String, dynamic>, d.id))
          .toList();
      rules.sort((a, b) => b.startDate.compareTo(a.startDate));
      return rules;
    });
  }

  /// Último día real del mes `month` (1-12) de `year` — para recortar un
  /// `dayOfMonth` guardado (p.ej. 31) contra meses más cortos sin perder
  /// nunca el valor original guardado en la regla.
  int _lastDayOfMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  DateTime _monthlyOccurrence(int year, int month, int dayOfMonth) {
    final lastDay = _lastDayOfMonth(year, month);
    final day = dayOfMonth.clamp(1, lastDay);
    return DateTime(year, month, day);
  }

  /// Calcula la fecha de la ocurrencia número `k` (0 = la primera, en
  /// `startDate`) de una regla. Pura: no toca Firestore.
  DateTime occurrenceFor(RecurringTransactionModel rule, int k) {
    final anchor = _dateOnly(rule.startDate);
    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        return DateTime(
            anchor.year, anchor.month, anchor.day + rule.interval * k);

      case RecurrenceFrequency.weekly:
        final dow = rule.dayOfWeek ?? anchor.weekday; // 1=lunes..7=domingo
        final alignShift = ((dow - anchor.weekday) % 7 + 7) % 7;
        final firstAligned = DateTime(
            anchor.year, anchor.month, anchor.day + alignShift);
        return DateTime(firstAligned.year, firstAligned.month,
            firstAligned.day + 7 * rule.interval * k);

      case RecurrenceFrequency.monthly:
        final totalMonths = (anchor.month - 1) + rule.interval * k;
        final year = anchor.year + totalMonths ~/ 12;
        final month = totalMonths % 12 + 1;
        return _monthlyOccurrence(year, month, rule.dayOfMonth ?? anchor.day);

      case RecurrenceFrequency.yearly:
        final year = anchor.year + rule.interval * k;
        return _monthlyOccurrence(
            year, anchor.month, rule.dayOfMonth ?? anchor.day);
    }
  }

  /// Genera (si corresponde) los movimientos vencidos de una sola regla,
  /// desde donde se quedó `lastGeneratedDate` hasta `now`, y actualiza el
  /// cursor de la regla. Se usa tanto desde la generación masiva por
  /// usuario como justo al crear una regla nueva (para que la primera
  /// ocurrencia aparezca de inmediato).
  Future<void> generateForRule(RecurringTransactionModel rule,
      {DateTime? now}) async {
    final today = _dateOnly(now ?? DateTime.now());
    final endBound = rule.endDate == null ? null : _dateOnly(rule.endDate!);
    final cursor =
        rule.lastGeneratedDate == null ? null : _dateOnly(rule.lastGeneratedDate!);

    DateTime? lastGenerated;
    var cappedOut = false;

    for (var k = 0; k < _maxOccurrencesPerRun; k++) {
      final occ = occurrenceFor(rule, k);
      if (occ.isAfter(today)) break;
      if (endBound != null && occ.isAfter(endBound)) break;
      if (cursor != null && !occ.isAfter(cursor)) continue;

      await _txService.addTransaction(TransactionModel(
        id: '',
        userId: rule.userId,
        title: rule.title,
        amount: rule.amount,
        category: rule.category,
        isIncome: rule.isIncome,
        date: occ,
        note: rule.note,
        accountId: rule.accountId,
        recurringId: rule.id,
      ));
      lastGenerated = occ;

      if (k == _maxOccurrencesPerRun - 1) cappedOut = true;
    }

    DateTime? newCursor;
    if (lastGenerated != null) {
      newCursor = lastGenerated;
    } else if (!cappedOut) {
      // No había nada pendiente: adelanta el cursor a hoy para que la
      // próxima corrida no vuelva a recorrer todo el historial.
      newCursor = cursor ?? today;
    }

    if (newCursor != null && newCursor != rule.lastGeneratedDate) {
      await _rules.doc(rule.id).update({
        'lastGeneratedDate': newCursor.toIso8601String(),
      });
    }
  }

  /// Revisa todas las reglas del usuario y genera lo que esté vencido.
  /// Se llama una vez por apertura de la app (ver SetupGate).
  Future<void> generateDueTransactions(String userId, {DateTime? now}) async {
    final snap = await _rules.where('userId', isEqualTo: userId).get();
    final rules = snap.docs
        .map((d) =>
            RecurringTransactionModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();

    await Future.wait(rules.map((r) => generateForRule(r, now: now)));
  }
}
