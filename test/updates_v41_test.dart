import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/petcare_care_features.dart';
import 'package:petcare_connect_mobile/petcare_history_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('V41: los sonidos previos se mantienen sin modificar el canal', () {
    expect(normalizeReminderSound(null), 'default');
    expect(normalizeReminderSound('desconocido'), 'default');
    expect(normalizeReminderSound('default'), 'default');
    expect(normalizeReminderSound('soft'), 'soft');
    expect(normalizeReminderSound('chime'), 'chime');
    expect(petCareReminderSoundNames.length, 3);
  });

  test(
    'V41: el PDF se genera para el periodo elegido sin modificar datos',
    () async {
      final records = [
        PetCarePdfEntry(
          date: DateTime(2026, 10, 23),
          care: 'Agua',
          time: '08:30',
          note: 'Se cambió el agua',
        ),
      ];
      final result = await createPetCareHistoryPdf(
        petName: 'Mascota',
        period: 'octubre de 2026',
        entries: records,
      );
      expect(result.length, greaterThan(100));
      expect(ascii.decode(result.take(4).toList()), '%PDF');
      expect(records.length, 1);
    },
  );

  test('V41: se genera informe PDF incluso cuando no hay registros', () async {
    final result = await createPetCareHistoryPdf(
      petName: 'Mascota',
      period: 'Semana',
      entries: [],
    );
    expect(ascii.decode(result.take(4).toList()), '%PDF');
  });
}
