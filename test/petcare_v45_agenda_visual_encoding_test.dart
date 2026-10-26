import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';
import 'package:petcare_connect_mobile/petcare_care_features.dart';

void main() {
  final rows = <Map<String, dynamic>>[
    <String, dynamic>{
      'pet': <String, dynamic>{'id': 'gato', 'name': 'Gato'},
      'hour': 8,
      'minute': 45,
      'days': <int>[1, 3, 5],
      'enabled': true,
    },
    <String, dynamic>{
      'pet': <String, dynamic>{'id': 'perro', 'name': 'Perro'},
      'hour': 19,
      'minute': 30,
      'days': <int>[],
      'enabled': true,
    },
  ];

  test('V45: agenda marca correctamente dias y filtros de mascota', () {
    expect(petCareAgendaCountForDate(rows, DateTime(2026, 10, 26), null), 2);
    expect(petCareAgendaCountForDate(rows, DateTime(2026, 10, 27), null), 1);
    expect(petCareAgendaCountForDate(rows, DateTime(2026, 10, 27), 'gato'), 0);
    expect(petCareAgendaCountForDate(rows, DateTime(2026, 10, 26), 'gato'), 1);
  });
  testWidgets('V45: vista previa con acentos correctos en pantalla', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PetCareNextOccurrenceHint(
            time: TimeOfDay(hour: 8, minute: 45),
            selectedDays: <int>{1, 2, 3, 4, 5, 6, 7},
          ),
        ),
      ),
    );
    expect(find.textContaining('Pr\u00F3ximo aviso:'), findsOneWidget);
  });
  test('V45: textos fuente sin codificacion rota del editor', () {
    final src = File('lib/petcare_care_features.dart').readAsStringSync();
    expect(src.contains(String.fromCharCodes(<int>[0x00C3, 0x00B3])), isFalse);
    expect(src.contains(String.fromCharCodes(<int>[0x00C3, 0x00B1])), isFalse);
  });
  testWidgets('V45: el calendario visual navega y senala avisos', (
    tester,
  ) async {
    var chosen = DateTime(2026, 10, 26);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder:
                  (context, refresh) => PetCareAgendaMonthGrid(
                    selectedDate: chosen,
                    reminders: rows,
                    petFilter: 'gato',
                    onDateChanged: (date) => refresh(() => chosen = date),
                  ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Octubre 2026'), findsOneWidget);
    expect(find.textContaining('1 aviso el 26/10'), findsOneWidget);
    await tester.tap(find.byTooltip('Mes siguiente'));
    await tester.pumpAndSettle();
    expect(chosen, DateTime(2026, 11, 26));
    expect(find.text('Noviembre 2026'), findsOneWidget);
  });
}
