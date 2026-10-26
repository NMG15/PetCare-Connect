import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';

void main() {
  test('V45 admin: recuento concurrente con limite y suma precisa', () async {
    var active = 0;
    var peak = 0;
    final summary = await petCareCountAdminPets(
      userIds: ['a', 'b', 'c', 'd', 'e'],
      maxConcurrent: 2,
      countForUser: (id) async {
        active++;
        if (active > peak) peak = active;
        await Future<void>.delayed(const Duration(milliseconds: 4));
        active--;
        return id == 'e' ? 3 : 1;
      },
    );
    expect(peak, 2);
    expect(active, 0);
    expect(summary.total, 7);
    expect(summary.failedUsers, 0);
    expect(summary.isComplete, isTrue);
  });

  test(
    'V45 admin: error individual produce total parcial identificable',
    () async {
      final summary = await petCareCountAdminPets(
        userIds: ['a', 'b', 'c'],
        countForUser: (uid) async {
          if (uid == 'b') throw StateError('permiso denegado');
          return 2;
        },
      );
      expect(summary.total, 4);
      expect(summary.failedUsers, 1);
      expect(summary.isComplete, isFalse);
    },
  );

  test('V45 admin: usuarios repetidos no se cuentan dos veces', () async {
    var calls = 0;
    final summary = await petCareCountAdminPets(
      userIds: ['a', 'a', '', 'b'],
      countForUser: (_) async {
        calls++;
        return 1;
      },
    );
    expect(calls, 2);
    expect(summary.total, 2);
    expect(summary.isComplete, isTrue);
  });

  test('V45 admin: lista sin usuarios no realiza consultas', () async {
    final summary = await petCareCountAdminPets(
      userIds: [],
      countForUser: (_) async => throw StateError('no deberia ejecutarse'),
    );
    expect(summary.total, 0);
    expect(summary.failedUsers, 0);
  });

  test('V45 admin: un conteo negativo se marca como lectura fallida', () async {
    final summary = await petCareCountAdminPets(
      userIds: ['a'],
      countForUser: (_) async => -1,
    );
    expect(summary.total, 0);
    expect(summary.failedUsers, 1);
  });

  test('V45 admin: rechaza limites de concurrencia invalidos', () async {
    await expectLater(
      petCareCountAdminPets(
        userIds: ['a'],
        countForUser: (_) async => 1,
        maxConcurrent: 0,
      ),
      throwsArgumentError,
    );
    await expectLater(
      petCareCountAdminPets(
        userIds: ['a'],
        countForUser: (_) async => 1,
        maxConcurrent: 9,
      ),
      throwsArgumentError,
    );
  });
}
