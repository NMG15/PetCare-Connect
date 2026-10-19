import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';
import 'package:petcare_connect_mobile/petcare_care_features.dart';

void main() {
  test('V31: tema oscuro con acento esmeralda y fondo negro', () {
    final theme = buildPetCareTheme(Brightness.dark);
    expect(theme.scaffoldBackgroundColor, Colors.black);
    expect(theme.colorScheme.primary, const Color(0xFF47E6A1));
    expect(theme.colorScheme.onSurfaceVariant, const Color(0xFFB7BEC2));
    expect(theme.bottomSheetTheme.backgroundColor, const Color(0xFF1C1E22));
  });

  testWidgets('V31: elegir cuidado usa panel compacto y actualiza la seleccion',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildPetCareTheme(Brightness.dark),
      home: const ReminderEditorPage(
        petId: 'solo-vista',
        petName: 'Flash',
        careTypes: [
          {'id': 'feeding', 'label': 'Alimentación'},
          {'id': 'hygiene', 'label': 'Higiene'},
          {'id': 'vet', 'label': 'Veterinario'},
        ],
      ),
    ));
    expect(find.text('Alimentación'), findsOneWidget);
    await tester.tap(find.text('Alimentación'));
    await tester.pumpAndSettle();
    expect(find.text('Selecciona el cuidado'), findsOneWidget);
    await tester.tap(find.text('Higiene'));
    await tester.pumpAndSettle();
    expect(find.text('Higiene'), findsOneWidget);
    expect(find.text('Selecciona el cuidado'), findsNothing);
  });
}
