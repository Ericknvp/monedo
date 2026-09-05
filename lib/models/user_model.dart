// ============================================================
// user_model.dart
// Define el modelo de datos para cada usuario de Monedo.
// Si quieres agregar más info del usuario, hazlo aquí.
// ============================================================

class UserModel {
  final String id;           // ID único del usuario (viene de Firebase Auth)
  final String username;     // Nombre de usuario único
  final String email;        // Correo electrónico
  final DateTime createdAt;  // Fecha de registro
  final String? currency;    // Código de moneda preferida (USD, COP, etc.)

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
    this.currency,
  });

  // ---- Convierte un documento de Firestore a UserModel ----
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      currency: map['currency'] as String?,
    );
  }

  // ---- Convierte un UserModel a Map para guardar en Firestore ----
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      if (currency != null) 'currency': currency,
    };
  }
}