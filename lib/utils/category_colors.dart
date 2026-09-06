import 'package:flutter/material.dart';

/// Asigna un color estable a cada categoría, para distinguirlas de un
/// vistazo (íconos de movimientos, chips de categoría y gráficas), siempre
/// acompañado del ícono y el nombre — nunca solo por color.
///
/// Las categorías predeterminadas tienen un color fijo elegido a mano, a
/// partir de una paleta validada para daltonismo (ver skill de dataviz:
/// `validate_palette.js`). Las categorías propias del usuario reciben un
/// color estable de una paleta extendida, calculado a partir de un hash
/// propio del nombre (no `String.hashCode`, que no está garantizado estable
/// entre plataformas).
class CategoryColors {
  CategoryColors._();

  /// "Otros" y "Transferencia" quedan neutros a propósito: no son un tema de
  /// gasto propiamente, así que no compiten por atención con las demás.
  static const Color neutral = Color(0xFF8B98A5);

  static const Map<String, Color> _fixed = {
    'Transporte': Color(0xFF2A78D6), // azul
    'Alimentación': Color(0xFFEB6834), // naranja
    'Inversión': Color(0xFF1BAF7A), // aqua
    'Educación': Color(0xFFEDA100), // amarillo
    'Ropa': Color(0xFFE87BA4), // magenta
    'Ahorro': Color(0xFF008300), // verde
    'Entretenimiento': Color(0xFF4A3AA7), // violeta
    'Salud': Color(0xFFE34948), // rojo
    'Hogar': Color(0xFF8B5E3C), // marrón
    'Trabajo': Color(0xFF34495E), // azul marino
    'Ocio': Color(0xFF8BC34A), // verde lima
    'Otros': neutral,
    'Transferencia': neutral,
  };

  /// Paleta extendida (mismos tonos que las categorías fijas, más algunos
  /// adicionales) para repartir entre categorías propias del usuario.
  static const List<Color> _extended = [
    Color(0xFF2A78D6),
    Color(0xFFEB6834),
    Color(0xFF1BAF7A),
    Color(0xFFEDA100),
    Color(0xFFE87BA4),
    Color(0xFF008300),
    Color(0xFF4A3AA7),
    Color(0xFFE34948),
    Color(0xFF8B5E3C),
    Color(0xFF34495E),
    Color(0xFF8BC34A),
    Color(0xFF6C7A89),
    Color(0xFFB05C3B),
    Color(0xFF5E60CE),
    Color(0xFFBF4E82),
    Color(0xFF4F8A6D),
  ];

  static Color forCategory(String category) {
    final fixed = _fixed[category];
    if (fixed != null) return fixed;

    var hash = 0;
    for (final unit in category.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return _extended[hash % _extended.length];
  }
}
