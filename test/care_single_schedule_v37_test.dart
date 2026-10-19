import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/petcare_care_features.dart';

void main() {
  final saved = <Map<String, dynamic>>[
    {'id': 'legacy1', 'careId': 'water', 'hour': 8, 'minute': 0},
    {'id': 'food1', 'careId': 'feeding', 'hour': 17, 'minute': 0},
  ];
  final catalog = <Map<String, dynamic>>[
    {'id': 'water', 'label': 'Agua'},
    {'id': 'feeding', 'label': 'Alimentación'},
    {'id': 'personal_3', 'label': 'Comida con medicina'},
  ];

  test('V37: no crear un segundo horario para un cuidado existente', () {
    expect(canAddReminderForCare(saved, 'water'), isFalse);
    expect(canAddReminderForCare(saved, 'feeding'), isFalse);
  });

  test('V37: un cuidado personal sin horario puede programarse', () {
    expect(canAddReminderForCare(saved, 'personal_3'), isTrue);
    expect(caresWithoutReminder(catalog, saved)
        .map((care) => care['id']), ['personal_3']);
  });

  test('V37: horario de otra mascota no se mezcla (lista individual)', () {
    expect(remindersForCare(saved, 'personal_3'), isEmpty);
    expect(careScheduleSummary(remindersForCare(saved, 'water')),
        'Aviso: 8:00 a. m.');
  });

  test('V37: no se pierden horarios antiguos duplicados', () {
    final old = [
      ...saved,
      {'id': 'legacy2', 'careId': 'water', 'hour': 19, 'minute': 0},
    ];
    expect(remindersForCare(old, 'water'), hasLength(2));
    expect(canAddReminderForCare(old, 'water'), isFalse);
    expect(careScheduleSummary(remindersForCare(old, 'water')),
        '2 horarios');
  });
}
