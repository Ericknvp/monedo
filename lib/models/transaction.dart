// ============================================================
// transaction.dart
// Define el modelo de datos para cada movimiento (ingreso o gasto).
// Se renombra como TransactionModel para evitar conflicto con Firestore.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;           // ID único del movimiento
  final String userId;       // ID del usuario dueño del movimiento
  final String title;        // Título o descripción del movimiento
  final double amount;       // Monto del movimiento
  final String category;     // Categoría (comida, transporte, etc.)
  final bool isIncome;       // true = ingreso, false = gasto
  final DateTime date;       // Fecha del movimiento
  final String? note;        // Nota opcional
  final String? accountId;   // Bolsillo del que sale/entra el dinero
  final String? goalId;      // Meta de ahorro a la que pertenece (si aplica)
  final bool isTransfer;         // true si es una transferencia entre bolsillos propios
  final String? transferAccountId; // Bolsillo destino de la transferencia (accountId es el de origen)
  final String? recurringId; // ID de la regla recurrente que generó este movimiento (si aplica)

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
    this.isTransfer = false,
    this.transferAccountId,
    this.recurringId,
  });

  /// Convierte el valor de `date` a una fecha local.
  ///
  /// No siempre llega igual: la app escribe la fecha como texto ISO en
  /// hora local, pero el bot de Telegram la escribe como timestamp de
  /// Firestore, que el SDK entrega como objeto `Timestamp`. Con
  /// `DateTime.parse` a secas, un movimiento del bot hacia el mismo
  /// error al parsear y tumbaba el listado entero.
  ///
  /// Todo se pasa a hora local para que los filtros por día y por mes
  /// (que comparan contra fechas locales) traten igual lo que escribe
  /// la app y lo que escribe el bot.
  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is DateTime) return value.toLocal();
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }

  // ---- Convierte un documento de Firestore a TransactionModel ----
  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      isIncome: map['isIncome'] ?? false,
      date: _parseDate(map['date']),
      note: map['note'],
      accountId: map['accountId'],
      goalId: map['goalId'],
      isTransfer: map['isTransfer'] ?? false,
      transferAccountId: map['transferAccountId'],
      recurringId: map['recurringId'],
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
      'isTransfer': isTransfer,
      'transferAccountId': transferAccountId,
      'recurringId': recurringId,
    };
  }
}