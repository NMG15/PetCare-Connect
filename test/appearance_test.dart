import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';

void main() {
  test('El modo se interpreta correctamente sin preferencias guardadas', () {
    expect(PetCareAppearance.fromStoredValue(null), ThemeMode.system);
    expect(PetCareAppearance.fromStoredValue('otro'), ThemeMode.system);
  });
  test('Claro y oscuro se conservan al guardarlos', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark, ThemeMode.system]) {
      expect(PetCareAppearance.fromStoredValue(PetCareAppearance.toStoredValue(mode)), mode);
    }
  });
}
