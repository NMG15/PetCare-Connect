import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/petcare_history_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('V45 PDF: quita emojis simples, secuencias y banderas', () {
    expect(petCarePdfSafeText('🐢 Alimentación ✅'), 'Alimentación');
    expect(
      petCarePdfSafeText('Revisión 👩🏽‍⚕️ a las 9:20 p. m.'),
      'Revisión a las 9:20 p. m.',
    );
    expect(petCarePdfSafeText('Mascota 🇲🇽 🐾'), 'Mascota');
    expect(petCarePdfSafeText('🐾', fallback: 'Cuidado'), 'Cuidado');
  });

  test('V45 PDF: preserva español, signos, numeros y acentos', () {
    expect(
      petCarePdfSafeText('Señor Ñandú: café ☕; revisión a las 9:15.'),
      'Señor Ñandú: café; revisión a las 9:15.',
    );
    expect(petCarePdfSafeText('Baño y alimentación'), 'Baño y alimentación');
  });

  test(
    'V45 PDF: exporta con emojis sin modificar los datos de origen',
    () async {
      final records = [
        PetCarePdfEntry(
          date: DateTime(2026, 10, 25),
          care: '🐢 Alimentación ✅',
          time: '09:20 PM',
          note: 'Señor Ñandú 👩🏽‍⚕️ comió muy bien.',
        ),
      ];
      final result = await createPetCareHistoryPdf(
        petName: '🐶 Orejitas',
        ownerName: 'Pável 🐾',
        period: 'Octubre de 2026 📅',
        entries: records,
      );
      expect(ascii.decode(result.take(4).toList()), '%PDF');
      expect(result.length, greaterThan(1000));
      expect(records.single.care, '🐢 Alimentación ✅');
      expect(records.single.note, 'Señor Ñandú 👩🏽‍⚕️ comió muy bien.');
    },
  );
}
