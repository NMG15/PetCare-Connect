import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';

void main() {
  testWidgets('La contraseña se oculta y se muestra con el ojo', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AuthPage(login: true),
    ));
    expect(tester.widget<TextField>(find.byType(TextField).last).obscureText, isTrue);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField).last).obscureText, isFalse);
    await tester.tap(find.byTooltip('Ocultar contraseña'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField).last).obscureText, isTrue);
  });
}
