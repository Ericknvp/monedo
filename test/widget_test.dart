// Smoke test de la app.
//
// El archivo original venía con la plantilla de Flutter (un contador con
// `MyApp`, que este proyecto no tiene) y no compilaba. Este smoke test
// comprueba lo mismo sin depender de Firebase, para que `flutter test`
// pueda correr en verde.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monedo/theme/app_theme.dart';

void main() {
  testWidgets('la app arranca con el tema de la marca', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(child: Text('Monedo')),
        ),
      ),
    );

    expect(find.text('Monedo'), findsOneWidget);
    expect(AppTheme.primary, isNotNull);
  });
}
