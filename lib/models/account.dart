class AccountModel {
  final String id;
  final String userId;
  final String name;
  final double balance;
  final DateTime createdAt;
  final int? color; // Valor ARGB elegido por el usuario; null = color por defecto

  AccountModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.balance,
    required this.createdAt,
    this.color,
  });

  factory AccountModel.fromMap(Map<String, dynamic> map, String id) {
    return AccountModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      balance: (map['balance'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      color: map['color'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'balance': balance,
      'createdAt': createdAt.toIso8601String(),
      'color': color,
    };
  }
}
