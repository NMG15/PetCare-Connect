import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';

void main() {
  test('V45: carga inicial ejecuta una vez por cuenta', () async {
    final gate = PetCareHomeOncePerAccount();
    var calls = 0;
    await gate.run('A', () async {
      calls++;
    });
    await gate.run('A', () async {
      calls++;
    });
    expect(calls, 1);
  });

  test('V45: cambiar de usuario exige una nueva sincronizacion', () async {
    final gate = PetCareHomeOncePerAccount();
    var calls = 0;
    await gate.run('A', () async {
      calls++;
    });
    await gate.run('B', () async {
      calls++;
    });
    expect(calls, 2);
  });

  test('V45: un error no bloquea el reintento posterior', () async {
    final gate = PetCareHomeOncePerAccount();
    var calls = 0;
    await expectLater(
      gate.run('A', () async {
        calls++;
        throw StateError('sin red');
      }),
      throwsStateError,
    );
    await gate.run('A', () async {
      calls++;
    });
    expect(calls, 2);
  });

  test('V45: dos cargas simultaneas comparten una sola operacion', () async {
    final gate = PetCareHomeOncePerAccount();
    final pending = Completer<void>();
    var calls = 0;
    final first = gate.run('A', () async {
      calls++;
      await pending.future;
    });
    final second = gate.run('A', () async {
      calls++;
    });
    expect(calls, 1);
    pending.complete();
    await Future.wait([first, second]);
    expect(calls, 1);
  });

  test('V45: logout invalida tareas completadas de la misma cuenta', () async {
    final gate = PetCareHomeOncePerAccount();
    var calls = 0;
    await gate.run('A', () async {
      calls++;
    });
    gate.reset();
    await gate.run('A', () async {
      calls++;
    });
    expect(calls, 2);
  });

  test('V45: resultado anterior no marca como completa otra sesion', () async {
    final gate = PetCareHomeOncePerAccount();
    final oldTask = Completer<void>();
    var callsA = 0;
    var callsB = 0;
    final first = gate.run('A', () async {
      callsA++;
      await oldTask.future;
    });
    await gate.run('B', () async {
      callsB++;
    });
    oldTask.complete();
    await first;
    await gate.run('B', () async {
      callsB++;
    });
    expect(callsA, 1);
    expect(callsB, 1);
  });
}
