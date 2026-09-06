import 'package:flutter/foundation.dart';

/// Nombres de categorías predeterminadas que el usuario deshabilitó, para
/// que no aparezcan al elegir categoría en un movimiento nuevo. Se
/// sincroniza en vivo desde Firestore por [CategoryVisibilityService].
class CategoryVisibilityRegistry {
  static final ValueNotifier<Set<String>> disabled =
      ValueNotifier<Set<String>>({});
}
