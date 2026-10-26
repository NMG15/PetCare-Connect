import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';

void main() {
  final today = DateTime(2026, 10, 25, 7);
  final reminders = <Map<String, dynamic>>[
    <String, dynamic>{
      'pet': <String, dynamic>{'id': 'uno'},
      'hour': 8,
      'minute': 10,
      'days': <int>[],
      'enabled': true,
    },
    <String, dynamic>{
      'pet': <String, dynamic>{'id': 'uno'},
      'hour': 9,
      'minute': 20,
      'days': <int>[],
      'enabled': true,
    },
    <String, dynamic>{
      'pet': <String, dynamic>{'id': 'dos'},
      'hour': 10,
      'minute': 30,
      'days': <int>[],
      'enabled': true,
    },
    <String, dynamic>{
      'pet': <String, dynamic>{'id': 'uno'},
      'hour': 11,
      'minute': 40,
      'days': <int>[],
      'enabled': false,
    },
  ];

  test(
    'V45: tres horarios diarios solo marcan la siguiente fecha, no todo el mes',
    () {
      final counts = petCareAgendaNextMarkersInMonth(
        reminders,
        today,
        null,
        today,
      );
      expect(counts, <int, int>{25: 3});
      expect(counts.containsKey(26), isFalse);
      expect(counts.containsKey(27), isFalse);
    },
  );

  test('V45: dos horarios de una mascota son exactamente dos puntos', () {
    final counts = petCareAgendaNextMarkersInMonth(
      reminders,
      today,
      'uno',
      today,
    );
    expect(counts, <int, int>{25: 2});
  });

  test(
    'V45: horarios anteriores a la hora actual avanzan al dia siguiente',
    () {
      final counts = petCareAgendaNextMarkersInMonth(
        reminders,
        today,
        'uno',
        DateTime(2026, 10, 25, 8, 15),
      );
      expect(counts, <int, int>{25: 1, 26: 1});
    },
  );

  test('V45: meses pasados no contienen proximos avisos', () {
    final counts = petCareAgendaNextMarkersInMonth(
      reminders,
      DateTime(2026, 9, 25),
      null,
      today,
    );
    expect(counts, isEmpty);
  });

  test('V45: mes futuro marca una sola fecha por cada horario', () {
    final counts = petCareAgendaNextMarkersInMonth(
      reminders,
      DateTime(2026, 11, 25),
      'uno',
      today,
    );
    expect(counts, <int, int>{1: 2});
  });

  testWidgets(
    'V45: dos avisos dibujan dos puntos verdes sin pintar todos los dias',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PetCareAgendaMonthGrid(
                selectedDate: DateTime(2026, 10, 25),
                reminders: reminders,
                petFilter: 'uno',
                nowOverride: today,
                onDateChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('petcare-agenda-dot-2026-10-25-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('petcare-agenda-dot-2026-10-25-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('petcare-agenda-dot-2026-10-25-2')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('petcare-agenda-dot-2026-10-26-0')),
        findsNothing,
      );
    },
  );
}
