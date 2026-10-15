import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';

void main() {
  test('Eliminar mascota sin cuidados ni recordatorios', () async {
    final batches = <List<String>>[];

    await runPetDeletionBatches<String>(
      children: [],
      parent: 'mascota',
      commitBatch: (batch) async {
        batches.add(batch);
      },
    );

    expect(batches, [
      ['mascota']
    ]);
  });

  test('Organizar eliminaciones de diferentes tamaños', () async {
    for (final cantidad in [399, 400, 850]) {
      final batches = <List<String>>[];

      final children = List.generate(
        cantidad,
        (index) => 'registro_$index',
      );

      await runPetDeletionBatches<String>(
        children: children,
        parent: 'mascota',
        commitBatch: (batch) async {
          batches.add(batch);
        },
      );

      expect(
        batches.every((batch) => batch.length <= 400),
        isTrue,
      );

      expect(batches.last.last, 'mascota');

      expect(
        batches.expand((batch) => batch).toList(),
        [...children, 'mascota'],
      );
    }
  });

  test('Un error detiene los lotes siguientes', () async {
    final batches = <List<int>>[];

    await expectLater(
      runPetDeletionBatches<int>(
        children: List.generate(850, (index) => index),
        parent: -1,
        commitBatch: (batch) async {
          batches.add(batch);

          if (batches.length == 2) {
            throw StateError('Error simulado');
          }
        },
      ),
      throwsStateError,
    );

    expect(batches.length, 2);

    expect(
      batches.expand((batch) => batch),
      isNot(contains(-1)),
    );
  });
}