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

  // ---- Elimina una categoría personalizada ----
  Future<void> deleteCategory(String id) async {
    await _categories.doc(id).delete();
  }
}
