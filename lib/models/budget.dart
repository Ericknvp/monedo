class BudgetModel {
  final String id;
  final String userId;
  final String category;
  final double monthlyLimit;
  final DateTime createdAt;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.monthlyLimit,
    required this.createdAt,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> map, String id) {
    return BudgetModel(
      id: id,
      userId: map['userId'] ?? '',
      category: map['category'] ?? '',
      monthlyLimit: (map['monthlyLimit'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category,
      'monthlyLimit': monthlyLimit,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
