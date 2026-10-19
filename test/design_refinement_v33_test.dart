import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';

void main() {
  testWidgets('V33: selector muestra una lista acotada y permite elegir', (tester) async {
    String selected = 'a';
    await tester.pumpWidget(MaterialApp(
      theme: buildPetCareTheme(Brightness.dark),
      home: StatefulBuilder(builder: (context, repaint) => Scaffold(
        body: Center(child: PetCareCompactSelector(
          label: 'Tipo de cuidado',
          value: selected,
          options: const [
            PetCareSelectOption(value: 'a', label: 'Agua'),
            PetCareSelectOption(value: 'b', label: 'Alimentación'),
            PetCareSelectOption(value: 'c', label: 'Paseo'),
          ],
          onChanged: (value) => repaint(() => selected = value),
        )),
      )),
    ));
    await tester.tap(find.byKey(const ValueKey('petcare-selector-Tipo de cuidado')));
    await tester.pumpAndSettle();
    expect(find.text('Alimentación'), findsOneWidget);
    await tester.tap(find.text('Alimentación'));
    await tester.pumpAndSettle();
    expect(selected, 'b');
    expect(find.text('Alimentación'), findsOneWidget);
  });

  testWidgets('V33: selector largo no se expande a pantalla completa', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: PetCareCompactSelector(
        label: 'Especie', value: 'v0',
        options: List.generate(40, (i) =>
            PetCareSelectOption(value: 'v$i', label: 'Especie $i')),
        onChanged: (_) {},
      ),
    )));
    await tester.tap(find.byKey(const ValueKey('petcare-selector-Especie')));
    await tester.pumpAndSettle();
    final sheets = find.byType(BottomSheet);
    expect(sheets, findsOneWidget);
    final sheetSize = tester.getSize(sheets.first);
    expect(sheetSize.height, lessThan(tester.view.physicalSize.height / tester.view.devicePixelRatio));
  });

  test('V33: contraste de acciones delicadas depende del esquema de error', () {
    final scheme = buildPetCareTheme(Brightness.dark).colorScheme;
    expect(scheme.error, isNot(scheme.primary));
  });
}
