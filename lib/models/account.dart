class AccountModel {
  final String id;
  final String userId;
  final String name;
  final double balance;
  final DateTime createdAt;

  AccountModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.balance,
    required this.createdAt,
  });

  factory AccountModel.fromMap(Map<String, dynamic> map, String id) {
    return AccountModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      balance: (map['balance'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'balance': balance,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
