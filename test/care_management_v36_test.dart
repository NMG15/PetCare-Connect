import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/petcare_care_features.dart';

void main() {
  final records = <Map<String, dynamic>>[
    {'id': 'r1', 'careId': 'water', 'hour': 8, 'minute': 5},
    {'id': 'r2', 'careId': 'water', 'hour': 19, 'minute': 0},
    {'id': 'r3', 'careId': 'feeding', 'hour': 17, 'minute': 15,
      'note': 'Alimento con medicamento'},
  ];

  test('V36: los avisos de Agua no se mezclan con Alimentacion', () {
    final water = remindersForCare(records, 'water');
    expect(water, hasLength(2));
    expect(water.every((r) => r['careId'] == 'water'), isTrue);
    expect(careScheduleSummary(water), '2 horarios');
  });

  test('V36: un recordatorio conserva cuidado y nota sin crear otro cuidado', () {
    final feeding = remindersForCare(records, 'feeding');
    expect(feeding.single['note'], 'Alimento con medicamento');
    expect(careScheduleSummary(feeding), 'Aviso: 5:15 p. m.');
  });

  test('V36: sin avisos, el cuidado existe pero no tiene horario', () {
    expect(remindersForCare(records, 'hygiene'), isEmpty);
    expect(careScheduleSummary(const []), 'Sin horario');
  });

  test('V36: un horario antiguo sin datos validos no rompe la pantalla', () {
    expect(careScheduleSummary(<Map<String, dynamic>>[
      {'careId': 'water', 'hour': -1, 'minute': 5}
    ]), '1 horario');
  });
}
