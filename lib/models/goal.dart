
class GoalModel {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;   // Precio total de la meta
  final double savedAmount;    // Cuánto se ha ahorrado hasta ahora
  final String? imageUrl;      // URL de imagen de la meta (opcional)
  final String? note;
  final DateTime createdAt;

  GoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    this.imageUrl,
    this.note,
    required this.createdAt,
  });

  double get progressPercent =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => savedAmount >= targetAmount;

  double get remaining => (targetAmount - savedAmount).clamp(0.0, double.infinity);

  factory GoalModel.fromMap(Map<String, dynamic> map, String id) {
    return GoalModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      targetAmount: (map['targetAmount'] ?? 0).toDouble(),
      savedAmount: (map['savedAmount'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'],
      note: map['note'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'imageUrl': imageUrl,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  GoalModel copyWith({
    String? id,
    String? userId,
    String? title,
    double? targetAmount,
    double? savedAmount,
    String? imageUrl,
    String? note,
    DateTime? createdAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      imageUrl: imageUrl ?? this.imageUrl,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
