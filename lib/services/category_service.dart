import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _categories => _firestore.collection('categories');

  // ---- Obtiene las categorías personalizadas del usuario en tiempo real ----
  Stream<List<CategoryModel>> getCategories(String userId) {
    return _categories
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) =>
              CategoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  // ---- Crea una nueva categoría personalizada ----
  Future<void> addCategory({
    required String userId,
    required String name,
    required int iconCodePoint,
  }) async {
    await _categories.add(CategoryModel(
      id: '',
      userId: userId,
      name: name,
      iconCodePoint: iconCodePoint,
      createdAt: DateTime.now(),
    ).toMap());
  }

  // ---- Edita una categoría personalizada existente ----
  //
  // Si cambia el nombre, migra los movimientos que ya usaban el nombre
  // anterior (y su color elegido, si tenía uno) para no dejarlos huérfanos.
  Future<void> updateCategory({
    required String id,
    required String userId,
    required String oldName,
    required String newName,
    required int iconCodePoint,
  }) async {
    await _categories.doc(id).update({
      'name': newName,
      'iconCodePoint': iconCodePoint,
    });
    if (oldName == newName) return;

    final txSnap = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: oldName)
        .get();
    if (txSnap.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in txSnap.docs) {
        batch.update(doc.reference, {'category': newName});
      }
      await batch.commit();
    }

    final colorSnap = await _firestore
        .collection('categoryColors')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: oldName)
        .get();
    for (final doc in colorSnap.docs) {
      await doc.reference.update({'category': newName});
    }
  }

  // ---- Elimina una categoría personalizada ----
  Future<void> deleteCategory(String id) async {
    await _categories.doc(id).delete();
  }
}
