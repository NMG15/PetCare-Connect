import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare_connect_mobile/petcare_care_features.dart';

const _careTypes = <Map<String, dynamic>>[
  {'id': 'feeding', 'label': 'Alimentación'},
];

Future<void> openWeekdays(WidgetTester tester) async {
  // V32 tiene mas espacio vertical en el formulario. Un ListView construye
  // sus hijos de manera diferida: el titulo puede estar visible mientras
  // ActionChip y FilterChip todavia no forman parte del arbol de widgets.
  // Avanzar hasta el primer dia hace que se construya toda la seccion.
  await tester.scrollUntilVisible(
    find.text('Lun'),
    160,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byType(ActionChip));
  await tester.pumpAndSettle();
  expect(find.byType(ActionChip), findsOneWidget);
  expect(find.byType(FilterChip), findsNWidgets(7));
}

void main() {
  testWidgets('Un horario nuevo comienza sin días seleccionados', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ReminderEditorPage(
        petId: 'pet-demo', petName: 'Flash', careTypes: _careTypes,
      ),
    ));
    await openWeekdays(tester);
    expect(find.text('Sin días seleccionados'), findsOneWidget);
    expect(tester.widgetList<FilterChip>(find.byType(FilterChip))
        .where((chip) => chip.selected), isEmpty);

    await tester.tap(find.byType(ActionChip));
    await tester.pumpAndSettle();
    expect(tester.widgetList<FilterChip>(find.byType(FilterChip))
        .where((chip) => chip.selected).length, 7);

    await tester.tap(find.byType(ActionChip));
    await tester.pumpAndSettle();
    expect(tester.widgetList<FilterChip>(find.byType(FilterChip))
        .where((chip) => chip.selected), isEmpty);
  });

  testWidgets('Horarios antiguos diarios mantienen sus siete días', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ReminderEditorPage(
        petId: 'pet-demo', petName: 'Flash', careTypes: _careTypes,
        existing: {'id': 'legacy', 'careId': 'feeding', 'days': <int>[]},
      ),
    ));
    await openWeekdays(tester);
    expect(tester.widgetList<FilterChip>(find.byType(FilterChip))
        .where((chip) => chip.selected).length, 7);
  });
}
