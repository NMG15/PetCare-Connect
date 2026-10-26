import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/petcare_care_features.dart';

void main() {
  test('V45: conserva avisos activos y otras notificaciones', () {
    final pending = <({int id, String? payload})>[
      (id: 11, payload: 'pet:mascota-a'),
      (id: 12, payload: 'pet:mascota-b'),
      (id: 2147000000, payload: null),
      (id: 13, payload: 'otra-funcion'),
    ];
    expect(stalePetCareReminderIds(pending, {11}), {12});
  });

  test('V45: borra solo avisos de mascota al quitar horarios', () {
    final pending = <({int id, String? payload})>[
      (id: 21, payload: 'pet:mascota-a'),
      (id: 22, payload: 'pet:mascota-a'),
      (id: 23, payload: 'pet:mascota-b'),
      (id: 24, payload: null),
    ];
    expect(stalePetCareReminderIds(pending, {}), {21, 22, 23});
  });

  test('V45: sincronizacion no cancela todas las notificaciones', () {
    final source = File('lib/petcare_care_features.dart').readAsStringSync();
    final start = source.indexOf(
      'Future<void> syncForUser(String userId) async {',
    );
    final end = source.indexOf('Set<int> stalePetCareReminderIds(', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final syncCode = source.substring(start, end);
    expect(syncCode.contains('_plugin.cancelAll()'), isFalse);
    expect(syncCode.contains('pendingNotificationRequests()'), isTrue);
    expect(syncCode.contains('_plugin.cancel(id)'), isTrue);

    expect(source.contains('Future<void> cancelAll() async {'), isTrue);
  });
}
