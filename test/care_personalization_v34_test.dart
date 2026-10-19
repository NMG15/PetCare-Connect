import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';

void main() {
  test('V34: categoria personal aparece solo en la mascota correspondiente', () {
    final common = <Map<String, dynamic>>[
      {'id': 'water', 'label': 'Agua', 'icon': 'water'},
      {'id': 'feeding', 'label': 'Alimentación', 'icon': 'feeding'},
    ];
    final flash = mergedCareCatalogForPet(common, {
      'personalCareTypes': [
        {'id': 'personal_123', 'label': 'Cepillado'},
      ],
    });
    final orejitas = mergedCareCatalogForPet(common, {});
    expect(flash.map((e) => e['label']), contains('Cepillado'));
    expect(orejitas.map((e) => e['label']), isNot(contains('Cepillado')));
    expect(common, hasLength(2));
  });

  test('V34: no permite IDs personales duplicados ni sustituir los globales', () {
    final result = mergedCareCatalogForPet([
      {'id': 'water', 'label': 'Agua'},
    ], {
      'personalCareTypes': [
        {'id': 'water', 'label': 'Nombre falso'},
        {'id': 'personal_1', 'label': 'Vitaminas'},
        {'id': 'personal_1', 'label': 'Duplicado'},
        {'id': 'personal_2', 'label': ''},
      ],
    });
    expect(result, hasLength(2));
    expect(result.first['label'], 'Agua');
    expect(result.last['label'], 'Vitaminas');
  });

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('V34: cuidado registrado destaca en $brightness', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: buildPetCareTheme(brightness),
        home: Scaffold(body: Center(child: SizedBox(width: 180,
          child: PetCareTodayTile(
            care: const {'id': 'water', 'label': 'Agua'},
            countToday: 2,
            saving: false,
            onTap: () {},
          ),
        ))),
      ));
      expect(find.text('HECHO'), findsOneWidget);
      expect(find.text('2 veces hoy · repetir'), findsOneWidget);
      final icon = find.byIcon(Icons.check_rounded);
      expect(icon, findsOneWidget);
    });
  }

  testWidgets('V34: sin registros indica que puedes tocar para registrar', (tester) async {
    var marks = 0;
    await tester.pumpWidget(MaterialApp(
      theme: buildPetCareTheme(Brightness.dark),
      home: Scaffold(body: PetCareTodayTile(
        care: const {'id': 'feeding', 'label': 'Alimentación'},
        countToday: 0,
        saving: false,
        onTap: () => marks++,
      )),
    ));
    expect(find.text('Toca para registrar'), findsOneWidget);
    expect(find.text('HECHO'), findsNothing);
    await tester.tap(find.text('Alimentación'));
    expect(marks, 1);
  });
}
