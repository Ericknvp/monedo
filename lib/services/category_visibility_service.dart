import 'package:cloud_firestore/cloud_firestore.dart';

/// Guarda qué categorías predeterminadas el usuario decidió ocultar (para
/// que no le estorben en el formulario de movimientos), sin eliminarlas de
/// verdad — a diferencia de las categorías propias, que sí se eliminan.
class CategoryVisibilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _disabled =>
      _firestore.collection('disabledCategories');

  // ---- Nombres de categorías predeterminadas deshabilitadas por el usuario ----
  Stream<Set<String>> getDisabled(String userId) {
    return _disabled.where('userId', isEqualTo: userId).snapshots().map(
        (snap) => snap.docs
            .map((d) => (d.data() as Map<String, dynamic>)['category'] as String?)
            .whereType<String>()
            .toSet());
  }

  // ---- Deshabilita o vuelve a habilitar una categoría predeterminada ----
  Future<void> setDisabled({
    required String userId,
    required String category,
    required bool disabled,
  }) async {
    final existing = await _disabled
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .get();

    if (disabled) {
      if (existing.docs.isEmpty) {
        await _disabled.add({'userId': userId, 'category': category});
      }
    } else {
      for (final doc in existing.docs) {
        await doc.reference.delete();
      }
    }
  }
}
