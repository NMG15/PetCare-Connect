import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';

void main() {
  testWidgets('Editor administrativo muestra sus opciones en español',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildPetCareTheme(Brightness.light),
      home: const AdminCareTypeEditorPage(),
    ));
    expect(find.text('Nuevo cuidado'), findsOneWidget);
    expect(find.text('1. Información del cuidado'), findsOneWidget);
  });

  test('La vista administrativa mantiene todas las acciones de gestión', () {
    final source = File('lib/screens/admin_pages.dart').readAsStringSync();
    for (final label in [
      'Crear nuevo cuidado',
      'Seleccionar todas',
      'Limpiar selección',
      'Mostrar a los usuarios',
      'Ocultar',
      'Duplicar',
      'Eliminar',
      'Vista previa',
    ]) {
      expect(source, contains(label));
    }
  });
}
