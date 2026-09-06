// ============================================================
// transaction.dart
// Define el modelo de datos para cada movimiento (ingreso o gasto).
// Se renombra como TransactionModel para evitar conflicto con Firestore.
// ============================================================

class TransactionModel {
  final String id;           // ID único del movimiento
  final String userId;       // ID del usuario dueño del movimiento
  final String title;        // Título o descripción del movimiento
  final double amount;       // Monto del movimiento
  final String category;     // Categoría (comida, transporte, etc.)
  final bool isIncome;       // true = ingreso, false = gasto
  final DateTime date;       // Fecha del movimiento
  final String? note;        // Nota opcional
  final String? accountId;   // Cuenta de la que sale/entra el dinero
  final String? goalId;      // Meta de ahorro a la que pertenece (si aplica)

  TransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.isIncome,
    required this.date,
    this.note,
    this.accountId,
    this.goalId,
  });

  // ---- Convierte un documento de Firestore a TransactionModel ----
  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      isIncome: map['isIncome'] ?? false,
      date: DateTime.parse(map['date']),
      note: map['note'],
      accountId: map['accountId'],
      goalId: map['goalId'],
    );
  }

  // ---- Convierte un TransactionModel a Map para guardar en Firestore ----
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'amount': amount,
      'category': category,
      'isIncome': isIncome,
      'date': date.toIso8601String(),
      'note': note,
      'accountId': accountId,
      'goalId': goalId,
    };
  }
}