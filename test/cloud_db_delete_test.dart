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
}
