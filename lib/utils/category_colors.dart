import 'package:flutter/material.dart';

/// Colores elegidos a mano por el usuario para una categoría (por nombre),
/// sincronizados en vivo desde Firestore por [CategoryColorService]. Vive
/// aparte de [CategoryColors] para que cualquier pantalla que ya llama
/// `CategoryColors.forCategory` reciba el override sin cambios adicionales.
class CategoryColorRegistry {
  static final ValueNotifier<Map<String, Color>> customColors =
      ValueNotifier<Map<String, Color>>({});
}

/// Asigna un color estable a cada categoría, para distinguirlas de un
/// vistazo (íconos de movimientos, chips de categoría y gráficas), siempre
/// acompañado del ícono y el nombre — nunca solo por color.
///
/// Orden de resolución: color elegido por el usuario (si lo hay) > color fijo
/// de una categoría predeterminada > color estable por hash para categorías
/// propias sin color elegido. Los colores fijos y la paleta de swatches
/// vienen de una paleta validada para daltonismo (ver skill de dataviz:
/// `validate_palette.js`); un hash propio del nombre (no `String.hashCode`,
/// que no está garantizado estable entre plataformas) reparte la paleta
/// extendida entre categorías propias.
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
  /// adicionales): reparte de forma estable entre categorías propias sin
  /// color elegido, y es la lista de swatches que se ofrece al elegir color.
  static const List<Color> swatches = [
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
    neutral,
  ];

  static Color forCategory(String category) {
    final custom = CategoryColorRegistry.customColors.value[category];
    if (custom != null) return custom;

    final fixed = _fixed[category];
    if (fixed != null) return fixed;

    var hash = 0;
    for (final unit in category.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return swatches[hash % swatches.length];
  }
}
