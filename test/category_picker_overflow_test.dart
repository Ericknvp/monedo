// Cubre el desbordamiento horizontal de los chips compactos de categoría.
//
// El tamaño de cada chip se calcula a mano (ver `_categoryTileSize` en
// lib/widgets/form_kit.dart) para poder animarlo con `AnimatedPositioned`.
// Si esa medida no coincide con lo que el chip realmente ocupa, el `Row`
// interno se desborda hacia la derecha.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:monedo/theme/app_theme.dart';
import 'package:monedo/widgets/form_kit.dart';

/// Categorías variadas: nombres cortos y largos (los largos son los que
/// antes empujaban el texto fuera del chip).
const _nombres = [
  'Ocio',
  'Transporte',
  'Alimentación',
  'Vivienda y servicios',
];

Widget _app({
  required bool compact,
  required String seleccionada,
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 360,
          child: CategoryPickerField(
            selectedCategory: seleccionada,
            onChanged: (_) {},
            compact: compact,
            showQuickLinks: false,
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    // Sin red en los tests: se usa la tipografía por defecto en vez de
    // descargar beVietnamPro.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('los chips compactos de categoría no desbordan a la derecha',
      (WidgetTester tester) async {
    await tester.pumpWidget(_app(compact: true, seleccionada: 'Alimentación'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('la grilla de categorías no desborda', (WidgetTester tester) async {
    await tester.pumpWidget(_app(compact: false, seleccionada: 'Alimentación'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('con el tema real de la app tampoco desborda',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(compact: true, seleccionada: 'Alimentación', theme: AppTheme.lightTheme),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('el nombre de la categoría cabe entero en el chip',
      (WidgetTester tester) async {
    await tester.pumpWidget(_app(compact: true, seleccionada: 'Alimentación'));
    await tester.pumpAndSettle();

    final textos = find.descendant(
      of: find.byType(CategoryPickerField),
      matching: find.byType(Text),
    );

    for (final finder in textos.evaluate()) {
      final element = finder;
      final text = element.widget as Text;
      final label = text.data;
      if (label == null || !_nombres.contains(label)) continue;

      // Ancho natural del texto con el estilo efectivo (el mismo que usa el
      // `Text` al pintarse: `DefaultTextStyle` ambiente + su propio estilo).
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: DefaultTextStyle.of(element).style.merge(text.style),
        ),
        maxLines: 1,
        textDirection: Directionality.of(element),
        textScaler: MediaQuery.textScalerOf(element),
      )..layout();

      final pintado = tester.getSize(find.byWidget(text)).width;

      // Si el texto se recortó (ellipsis), el ancho pintado es menor que el
      // natural; con un margen de 1 px por el redondeo del hinted text.
      expect(
        pintado,
        greaterThanOrEqualTo(painter.width - 1.0),
        reason: 'el nombre "$label" quedó recortado dentro del chip',
      );
    }
  });
}
