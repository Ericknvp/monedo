// ============================================================
// recurring_transaction.dart
// Define una regla de movimiento recurrente (salario, renta,
// suscripciones, etc.) a partir de la cual se generan movimientos
// reales (TransactionModel) automáticamente.
// ============================================================

enum RecurrenceFrequency { daily, weekly, monthly, yearly }

RecurrenceFrequency _frequencyFromName(String? name) {
  return RecurrenceFrequency.values.firstWhere(
    (f) => f.name == name,
    orElse: () => RecurrenceFrequency.monthly,
  );
}

class RecurringTransactionModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String category;
  final bool isIncome;
  final String? accountId;
  final String? note;

  final RecurrenceFrequency frequency;
  final int interval; // "cada N" (días/semanas/meses/años según frequency)
  final int? dayOfWeek; // 1 (lunes) .. 7 (domingo), solo weekly
  final int? dayOfMonth; // 1..31, solo monthly/yearly
  final DateTime startDate;
  final DateTime? endDate; // null = sin fecha de fin
  final DateTime? lastGeneratedDate; // hasta qué fecha ya se generaron movimientos

  RecurringTransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.isIncome,
    required this.frequency,
    required this.interval,
    required this.startDate,
    this.accountId,
    this.note,
    this.dayOfWeek,
    this.dayOfMonth,
    this.endDate,
    this.lastGeneratedDate,
  });

  factory RecurringTransactionModel.fromMap(
      Map<String, dynamic> map, String id) {
    return RecurringTransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      isIncome: map['isIncome'] ?? false,
      accountId: map['accountId'],
      note: map['note'],
      frequency: _frequencyFromName(map['frequency']),
      interval: (map['interval'] ?? 1) is int
          ? (map['interval'] ?? 1) as int
          : (map['interval'] as num).toInt(),
      dayOfWeek: map['dayOfWeek'],
      dayOfMonth: map['dayOfMonth'],
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      lastGeneratedDate: map['lastGeneratedDate'] != null
          ? DateTime.parse(map['lastGeneratedDate'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'amount': amount,
      'category': category,
      'isIncome': isIncome,
      'accountId': accountId,
      'note': note,
      'frequency': frequency.name,
      'interval': interval,
      'dayOfWeek': dayOfWeek,
      'dayOfMonth': dayOfMonth,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'lastGeneratedDate': lastGeneratedDate?.toIso8601String(),
    };
  }

  RecurringTransactionModel copyWith({
    String? title,
    double? amount,
    String? category,
    bool? isIncome,
    String? accountId,
    String? note,
    RecurrenceFrequency? frequency,
    int? interval,
    int? dayOfWeek,
    int? dayOfMonth,
    DateTime? endDate,
    bool clearEndDate = false,
    DateTime? lastGeneratedDate,
  }) {
    return RecurringTransactionModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      isIncome: isIncome ?? this.isIncome,
      accountId: accountId ?? this.accountId,
      note: note ?? this.note,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      startDate: startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
    );
  }
}
