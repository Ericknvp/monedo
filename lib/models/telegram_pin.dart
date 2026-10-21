// ============================================================
// telegram_pin.dart
// Modelo del PIN temporal que permite vincular una cuenta de
// Telegram con la de Monedo.
//
// El PIN lo genera el cliente (la app), lo guarda en Firestore y
// se lo muestra al usuario. El bot de Telegram es quien lo canjea:
// busca el documento por su ID (= el propio PIN), valida que no
// esté usado ni expirado, marca `used: true` y escribe el vínculo.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class TelegramPin {
  /// Código de 6 dígitos que el usuario escribe en el chat de Telegram.
  /// Es también el ID del documento en la colección `telegram_pins`.
  final String pin;

  /// UID de Firebase Auth del usuario que generó el PIN.
  final String uid;

  /// Momento en que se generó el PIN.
  final DateTime createdAt;

  /// Momento en que el PIN deja de ser válido (5 minutos por defecto).
  final DateTime expiresAt;

  /// Si el PIN ya fue canjeado por el bot.
  final bool used;

  TelegramPin({
    required this.pin,
    required this.uid,
    required this.createdAt,
    required this.expiresAt,
    required this.used,
  });

  /// Tiempo que falta para que el PIN expire. Nunca es negativo: si ya
  /// expiró devuelve [Duration.zero].
  Duration remainingAt(DateTime now) {
    final left = expiresAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  /// Si el PIN ya no es válido a la hora [now].
  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  /// Construye el modelo desde un documento de Firestore.
  ///
  /// [pin] se pasa aparte porque el ID del documento es el PIN y puede
  /// no estar repetido dentro del propio mapa.
  factory TelegramPin.fromMap(Map<String, dynamic> map, {String? pin}) {
    return TelegramPin(
      pin: pin ?? map['pin'] as String? ?? '',
      uid: map['uid'] as String? ?? '',
      createdAt: _toDateTime(map['createdAt']) ?? DateTime.now(),
      expiresAt: _toDateTime(map['expiresAt']) ?? DateTime.now(),
      used: map['used'] as bool? ?? false,
    );
  }

  /// Mapa del PIN tal como se escribe en Firestore.
  ///
  /// Nota: al crear el PIN el servicio escribe `createdAt` con
  /// [FieldValue.serverTimestamp] (la hora del servidor, no la del
  /// dispositivo). Aquí se deja la fecha local para cuando el modelo
  /// se serializa fuera de ese flujo.
  Map<String, dynamic> toMap() {
    return {
      'pin': pin,
      'uid': uid,
      'createdAt': createdAt,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'used': used,
    };
  }

  /// Convierte los distintos formatos de fecha que puede devolver
  /// Firestore a [DateTime].
  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
