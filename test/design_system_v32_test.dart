import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';

void main() {
  test('Premium V3: negro real, verde esmeralda, grafito y foco accesible', () {
    final dark = buildPetCareTheme(Brightness.dark);
    final scheme = dark.colorScheme;
    expect(dark.scaffoldBackgroundColor, Colors.black);
    expect(scheme.primary, const Color(0xFF47E6A1));
    expect(scheme.surfaceContainerLow, const Color(0xFF17191D));
    expect(scheme.onSurface, const Color(0xFFF5F7F6));
    expect(dark.bottomSheetTheme.backgroundColor, const Color(0xFF1C1E22));
    expect(dark.dialogTheme.backgroundColor, const Color(0xFF1C1E22));
    expect(dark.inputDecorationTheme.focusedBorder, isA<OutlineInputBorder>());
    expect(dark.inputDecorationTheme.errorBorder, isA<OutlineInputBorder>());
  });

  test('Premium V3: modo claro mantiene fondos claros y verde legible', () {
    final light = buildPetCareTheme(Brightness.light);
    expect(light.scaffoldBackgroundColor, isNot(Colors.black));
    expect(light.colorScheme.primary, const Color(0xFF13694D));
    expect(light.colorScheme.onPrimary, Colors.white);
  });

  testWidgets('Premium V3: los botones mantienen etiquetas legibles', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildPetCareTheme(Brightness.dark),
      home: Scaffold(body: Center(
        child: FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.check),
          label: const Text('Guardar horario'),
        ),
      )),
    ));
    expect(find.text('Guardar horario'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
