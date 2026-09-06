import 'package:flutter/material.dart';
import '../utils/category_icons.dart';

class CategoryModel {
  final String id;
  final String userId;
  final String name;
  final int iconCodePoint;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.iconCodePoint,
    required this.createdAt,
  });

  /// Devuelve un IconData ya existente del catálogo fijo de íconos
  /// (nunca reconstruido dinámicamente), para que el tree-shaking de
  /// íconos en el build de release funcione correctamente.
  IconData get icon {
    for (final entry in kCategoryIconChoices) {
      if (entry.value.codePoint == iconCodePoint) return entry.value;
    }
    return Icons.category_rounded;
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      iconCodePoint: map['iconCodePoint'] ?? Icons.category_rounded.codePoint,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
