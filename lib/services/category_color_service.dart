import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Guarda colores de categoría elegidos por el usuario, sean para una
/// categoría propia o para sobreescribir el color por defecto de una
/// categoría predeterminada (ambas se identifican solo por su nombre).
class CategoryColorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _colors => _firestore.collection('categoryColors');

  // ---- Colores personalizados del usuario, por nombre de categoría ----
  Stream<Map<String, Color>> getColors(String userId) {
    return _colors.where('userId', isEqualTo: userId).snapshots().map((snap) {
      final map = <String, Color>{};
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final category = data['category'] as String?;
        final colorValue = data['colorValue'] as int?;
        if (category != null && colorValue != null) {
          map[category] = Color(colorValue);
        }
      }
      return map;
    });
  }

  // ---- Fija (o reemplaza) el color elegido para una categoría ----
  Future<void> setColor({
    required String userId,
    required String category,
    required Color color,
  }) async {
    final existing = await _colors
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .limit(1)
        .get();
    if (existing.docs.isEmpty) {
      await _colors.add({
        'userId': userId,
        'category': category,
        'colorValue': color.value,
      });
    } else {
      await existing.docs.first.reference.update({'colorValue': color.value});
    }
  }

  // ---- Quita el color elegido, volviendo al color por defecto de la categoría ----
  Future<void> resetColor({
    required String userId,
    required String category,
  }) async {
    final existing = await _colors
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .get();
    for (final doc in existing.docs) {
      await doc.reference.delete();
    }
  }
}
