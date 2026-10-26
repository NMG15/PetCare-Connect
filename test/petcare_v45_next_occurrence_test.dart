import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/petcare_care_features.dart';

void main() {
  test('V45: sin dias no hay fecha de aviso', () {
    final next = petCareNextOccurrencePreview(
      now: DateTime(2026, 10, 26, 9, 0),
      hour: 9,
      minute: 2,
      days: {},
    );
    expect(next, isNull);
  });

  test('V45: un aviso futuro del mismo dia se muestra como hoy', () {
    final next = petCareNextOccurrencePreview(
      now: DateTime(2026, 10, 26, 9, 20),
      hour: 9,
      minute: 22,
      days: {DateTime.monday},
    );
    expect(next, DateTime(2026, 10, 26, 9, 22));
  });

  test('V45: un aviso del mismo minuto pasa al siguiente dia valido', () {
    final next = petCareNextOccurrencePreview(
      now: DateTime(2026, 10, 26, 9, 20, 15),
      hour: 9,
      minute: 20,
      days: {DateTime.monday, DateTime.tuesday},
    );
    expect(next, DateTime(2026, 10, 27, 9, 20));
  });

  test('V45: un dia semanal vencido se programa la siguiente semana', () {
    final next = petCareNextOccurrencePreview(
      now: DateTime(2026, 10, 26, 20, 0),
      hour: 8,
      minute: 0,
      days: {DateTime.monday},
    );
    expect(next, DateTime(2026, 11, 2, 8, 0));
  });

  test('V45: respeta el cambio de anio y descarta horas invalidas', () {
    expect(
      petCareNextOccurrencePreview(
        now: DateTime(2026, 12, 31, 23, 59),
        hour: 0,
        minute: 1,
        days: {DateTime.friday},
      ),
      DateTime(2027, 1, 1, 0, 1),
    );
    expect(
      petCareNextOccurrencePreview(
        now: DateTime(2026, 10, 26, 9),
        hour: 25,
        minute: 61,
        days: {DateTime.monday},
      ),
      isNull,
    );
  });

  testWidgets('V45: el editor presenta una pista del proximo aviso', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PetCareNextOccurrenceHint(
            time: const TimeOfDay(hour: 9, minute: 20),
            selectedDays: {
              DateTime.monday,
              DateTime.tuesday,
              DateTime.wednesday,
              DateTime.thursday,
              DateTime.friday,
              DateTime.saturday,
              DateTime.sunday,
            },
          ),
        ),
      ),
    );
    expect(find.textContaining('Pr\u00F3ximo aviso:'), findsOneWidget);
    expect(find.textContaining('Android puede demorar'), findsOneWidget);
  });
}
