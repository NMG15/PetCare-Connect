import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';

void main() {
  test('Elimina mascota, cuidados y recordatorios', () async {
    final firestore = FakeFirebaseFirestore();
    final cloudDb = CloudDb.forTesting(firestore);

    final propietario = firestore.collection('users').doc('usuario_prueba');
    final mascota = propietario.collection('pets').doc('firulais');

    await propietario.set({'name': 'Usuario de prueba'});
    await mascota.set({'name': 'Firulais'});

    await mascota.collection('care').doc('bano').set({'name': 'Bano'});

    await mascota.collection('reminders').doc('vacuna').set({'name': 'Vacuna'});

    await cloudDb.adminDeletePet('usuario_prueba', 'firulais');

    expect((await propietario.get()).exists, isTrue);
    expect((await mascota.get()).exists, isFalse);

    final cuidados = await mascota.collection('care').get();
    final recordatorios = await mascota.collection('reminders').get();

    expect(cuidados.docs, isEmpty);
    expect(recordatorios.docs, isEmpty);
  });

  test('Elimina una mascota con mas de 400 registros', () async {
    final firestore = FakeFirebaseFirestore();
    final cloudDb = CloudDb.forTesting(firestore);

    final propietario = firestore.collection('users').doc('usuario_grande');
    final mascota = propietario.collection('pets').doc('mascota_grande');

    final lote = firestore.batch();

    lote.set(propietario, {'name': 'Usuario grande'});
    lote.set(mascota, {'name': 'Mascota grande'});

    for (var i = 0; i < 405; i++) {
      lote.set(mascota.collection('care').doc('cuidado_$i'), {
        'name': 'Cuidado $i',
      });
    }

    await lote.commit();

    await cloudDb.adminDeletePet('usuario_grande', 'mascota_grande');

    expect((await propietario.get()).exists, isTrue);
    expect((await mascota.get()).exists, isFalse);

    final cuidados = await mascota.collection('care').get();

    expect(cuidados.docs, isEmpty);
  });

  test('Reintento recupera una eliminacion parcial', () async {
    final firestore = FakeFirebaseFirestore();
    final cloudDb = CloudDb.forTesting(firestore);

    final usuario = firestore.collection('users').doc('usuario_reintento');
    final mascota = usuario.collection('pets').doc('firulais_reintento');

    await usuario.set({'name': 'Usuario de prueba'});
    await mascota.set({'name': 'Firulais'});

    for (var inicio = 0; inicio < 401; inicio += 200) {
      final lote = firestore.batch();
      final limite = inicio + 200 < 401 ? inicio + 200 : 401;

      for (var i = inicio; i < limite; i++) {
        lote.set(mascota.collection('care').doc('cuidado_$i'), {
          'name': 'Cuidado $i',
        });
      }

      await lote.commit();
    }

    await mascota.collection('reminders').doc('vacuna').set({'name': 'Vacuna'});

    final primerLote = firestore.batch();

    for (var i = 0; i < 400; i++) {
      primerLote.delete(mascota.collection('care').doc('cuidado_$i'));
    }

    await primerLote.commit();

    expect((await mascota.get()).exists, isTrue);

    await cloudDb.adminDeletePet('usuario_reintento', 'firulais_reintento');

    expect((await usuario.get()).exists, isTrue);
    expect((await mascota.get()).exists, isFalse);

    expect((await mascota.collection('care').get()).docs, isEmpty);

    expect((await mascota.collection('reminders').get()).docs, isEmpty);
  });
}
