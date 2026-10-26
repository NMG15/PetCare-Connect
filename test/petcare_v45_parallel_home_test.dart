import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';

void main() {
  test('V45: las dos consultas se inician sin esperar entre ellas', () async {
    final pendingPets = Completer<List<Map<String, dynamic>>>();
    final pendingAdmin = Completer<bool>();
    var petsStarted = 0;
    var adminStarted = 0;
    final future = petCareLoadHomeSummary(
      loadPets: () {
        petsStarted++;
        return pendingPets.future;
      },
      loadAdmin: () {
        adminStarted++;
        return pendingAdmin.future;
      },
    );
    await Future<void>.delayed(Duration.zero);
    expect(petsStarted, 1);
    expect(adminStarted, 1);
    pendingAdmin.complete(true);
    pendingPets.complete([
      {'id': 'pet1'},
    ]);
    final result = await future;
    expect(result.pets.single['id'], 'pet1');
    expect(result.isAdmin, isTrue);
  });

  test('V45: un usuario no administrador conserva su valor false', () async {
    final result = await petCareLoadHomeSummary(
      loadPets: () async => <Map<String, dynamic>>[],
      loadAdmin: () async => false,
    );
    expect(result.pets, isEmpty);
    expect(result.isAdmin, isFalse);
  });

  test('V45: error de Firestore no se convierte en datos vacios', () async {
    await expectLater(
      petCareLoadHomeSummary(
        loadPets: () async => throw StateError('sin conexion'),
        loadAdmin: () async => false,
      ),
      throwsStateError,
    );
  });

  test('V45: no cachea permisos ni mascotas entre consultas', () async {
    var callsPets = 0;
    var callsAdmin = 0;
    Future<List<Map<String, dynamic>>> pets() async {
      callsPets++;
      return <Map<String, dynamic>>[];
    }

    Future<bool> admin() async {
      callsAdmin++;
      return callsAdmin == 1;
    }

    final first = await petCareLoadHomeSummary(
      loadPets: pets,
      loadAdmin: admin,
    );
    final second = await petCareLoadHomeSummary(
      loadPets: pets,
      loadAdmin: admin,
    );
    expect(first.isAdmin, isTrue);
    expect(second.isAdmin, isFalse);
    expect(callsPets, 2);
    expect(callsAdmin, 2);
  });
}
