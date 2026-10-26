import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';
import 'package:petcare_connect_mobile/petcare_history_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('V44: las 12 AM y 12 PM se muestran sin ambigüedad', () {
    expect(petTimeAmPm(0, 0), '12:00 AM');
    expect(petTimeAmPm(12, 0), '12:00 PM');
    expect(petTimeAmPm(21, 3), '9:03 PM');
    expect(petTimeAmPm(9, 3), '9:03 AM');
  });

  test('V44: las tortugas y peces no reciben colores de pelaje genéricos', () {
    expect(petColorsForSpecies('Tortuga'), contains('Verde oliva'));
    expect(petColorsForSpecies('Tortuga'), contains('Marrón'));
    expect(petColorsForSpecies('Pez'), contains('Iridescente'));
    expect(petCoatOptions('Tortuga'), contains('Caparazón abovedado'));
    expect(speciesCatalog['Perro'], contains('Mestizo / Sin raza definida'));
  });

  test(
    'V44: PDF con marca y nombre del responsable se genera sin cambiar registros',
    () async {
      final records = [
        PetCarePdfEntry(
          date: DateTime(2026, 10, 25),
          care: 'Alimentación',
          time: '09:03 PM',
          note: 'Tortuga con caparazón verde oliva',
        ),
      ];
      final bytes = await createPetCareHistoryPdf(
        petName: 'Orejitas',
        ownerName: 'Pável',
        period: 'Octubre de 2026',
        entries: records,
      );
      expect(ascii.decode(bytes.take(4).toList()), '%PDF');
      expect(bytes.length, greaterThan(1000));
      expect(records.single.care, 'Alimentación');
    },
  );

  test('V44: no se altera el acceso a Google ni la firma de compilación', () {
    final source = File('lib/main.dart').readAsStringSync();
    final auth = File('lib/screens/auth_pages.dart').readAsStringSync();
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(source.contains('serverClientId:'), isTrue);
    expect(auth.contains('GoogleSignIn.instance.authenticate()'), isTrue);
    expect(gradle.contains('com.petcareconnect.app'), isTrue);
    expect(File('android/app/src/main/res/raw/keep.xml').existsSync(), isTrue);
  });

  test('V44: permisos de avisos exactos tienen alternativa aproximada', () {
    final reminder = File('lib/petcare_care_features.dart').readAsStringSync();
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest.contains('SCHEDULE_EXACT_ALARM'), isTrue);
    expect(
      reminder.contains('AndroidScheduleMode.exactAllowWhileIdle'),
      isTrue,
    );
    expect(
      reminder.contains('AndroidScheduleMode.inexactAllowWhileIdle'),
      isTrue,
    );
    expect(reminder.contains('requestExactAlarmsPermission()'), isTrue);
  });
}
