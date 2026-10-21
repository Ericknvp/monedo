import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/category_icons.dart';

/// Publica en el documento del usuario la lista de categorías que tiene
/// habilitadas.
///
/// El bot de Telegram necesita saber en qué categorías encajar un
/// movimiento, y esa lista depende de las 94 predeterminadas de la app
/// menos las que el usuario desactivó, más las suyas propias. Duplicar
/// esa lista dentro del bot se desincroniza en cuanto la app añade,
/// renombra o quita una categoría, así que la app la publica y el bot
/// se limita a leerla del documento del usuario.
///
/// El bot la lee en `users/{uid}.enabledCategories`.
class EnabledCategoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Categoría de sistema: la asigna la app al mover dinero entre
  /// bolsillos propios. Nunca se elige a mano, así que no se publica
  /// como categoría elegible.
  static const String systemCategory = 'Transferencia';

  /// Nombres de las categorías que el usuario puede elegir ahora mismo.
  ///
  /// Son las predeterminadas de la app que no ha desactivado, más sus
  /// categorías propias. 'Transferencia' se queda fuera porque la pone
  /// la app sola.
  Future<List<String>> compute(String userId) async {
    final disabled = await _firestore
        .collection('disabledCategories')
        .where('userId', isEqualTo: userId)
        .get();
    final disabledNames = disabled.docs
        .map((d) => d.get('category') as String?)
        .whereType<String>()
        .toSet();

    final custom = await _firestore
        .collection('categories')
        .where('userId', isEqualTo: userId)
        .get();
    final customNames = custom.docs
        .map((d) => d.get('name') as String?)
        .whereType<String>()
        .where((n) => n.isNotEmpty)
        .toList();

    final defaults = kDefaultCategoryIcons.keys.where(
      (n) => n != systemCategory && !disabledNames.contains(n),
    );

    final all = <String>{...defaults, ...customNames}.toList()..sort();
    return all;
  }

  /// Escribe la lista en `users/{uid}.enabledCategories`.
  ///
  /// Se llama cada vez que cambia algo: al activar o desactivar una
  /// categoría, al crear, renombrar o borrar una propia, y al terminar
  /// la configuración inicial.
  ///
  /// Un fallo aquí no debe romper la acción que lo disparó: la
  /// categoría se guardó igual, solo se queda desactualizada la copia
  /// que lee el bot, que se arregla en la siguiente publicación.
  Future<void> publish(String userId) async {
    try {
      final names = await compute(userId);
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'enabledCategories': names});
    } catch (_) {
      // La publicación es best-effort: no interrumpe lo que la app
      // estaba haciendo.
    }
  }
}
