import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';

void main() {
  final catalog = <Map<String, dynamic>>[
    {'id': 'water', 'label': 'Agua', 'icon': 'water'},
    {'id': 'feeding', 'label': 'Alimentación', 'icon': 'feeding'},
    {'id': 'walk', 'label': 'Paseo / actividad', 'icon': 'walk'},
  ];

  test('V35: renombrar Agua solo para Flash mantiene ID e icono de mascota', () {
    final flash = mergedCareCatalogForPet(catalog, {
      'careOverrides': {
        'water': {'label': 'Agua especial', 'icon': 'pets'},
      },
    });
    final max = mergedCareCatalogForPet(catalog, {});
    expect(flash.first['id'], 'water');
    expect(flash.first['label'], 'Agua especial');
    expect(flash.first['icon'], 'pets');
    expect(flash.first['originalLabel'], 'Agua');
    expect(flash.first['userEdited'], true);
    expect(max.first['label'], 'Agua');
    expect(catalog.first['label'], 'Agua');
  });

  test('V35: restaurar los valores originales no altera el catálogo', () {
    final customized = mergedCareCatalogForPet(catalog, {
      'careOverrides': {
        'water': {'label': 'Agua purificada', 'icon': 'pets'},
      },
    });
    final restored = mergedCareCatalogForPet(catalog, {
      'careOverrides': <String, dynamic>{},
    });
    expect(customized.first['label'], isNot(restored.first['label']));
    expect(restored.first['label'], 'Agua');
    expect(restored.first['icon'], 'water');
  });

  test('V35: no duplicar nombres de base por mayúsculas o espacios', () {
    final merged = mergedCareCatalogForPet(catalog, {});
    expect(careNameTaken(merged, '  AGUA  '), true);
    expect(careNameTaken(merged, 'Alimentación'), true);
    expect(careNameTaken(merged, 'Agua', exceptId: 'water'), false);
    expect(careNameTaken(merged, 'Cepillado'), false);
  });

  test('V35: los avisos muestran el nombre personalizado actual', () {
    final flash = {
      'careOverrides': {
        'water': {'label': 'Agua filtrada', 'icon': 'water'},
      },
      'personalCareTypes': [
        {'id': 'personal_1', 'label': 'Vitaminas'},
      ],
    };
    expect(effectiveReminderCareLabel(flash, 'water', 'Agua'), 'Agua filtrada');
    expect(effectiveReminderCareLabel(flash, 'personal_1', 'Otro'), 'Vitaminas');
    expect(effectiveReminderCareLabel(flash, 'feeding', 'Alimentación'),
        'Alimentación');
  });

  for (final brightness in [Brightness.dark, Brightness.light]) {
    testWidgets('V35: tarjetas iguales con etiquetas de distinta longitud en $brightness',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: buildPetCareTheme(brightness),
        home: Scaffold(
          body: Row(children: [
            Expanded(child: PetCareTodayTile(
              care: const {'id': 'water', 'label': 'Agua'},
              countToday: 1, saving: false, onTap: () {},
            )),
            const SizedBox(width: 12),
            Expanded(child: PetCareTodayTile(
              care: const {'id': 'play', 'label': 'Juego / enriquecimiento'},
              countToday: 0, saving: false, onTap: () {},
            )),
          ]),
        ),
      ));
      final tiles = find.byType(PetCareTodayTile);
      expect(tiles, findsNWidgets(2));
      final rect1 = tester.getRect(tiles.at(0));
      final rect2 = tester.getRect(tiles.at(1));
      expect(rect1.height, rect2.height);
      expect(rect1.width, rect2.width);
      expect(find.text('HECHO'), findsOneWidget);
      expect(find.text('Toca para registrar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
