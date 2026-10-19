import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petcare_connect_mobile/main.dart';
import 'package:petcare_connect_mobile/petcare_care_features.dart';

void main() {
  testWidgets(
    'Pantalla inicial: iniciar sesión y crear cuenta',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomePage(),
        ),
      );

      expect(find.text('PetCare Connect'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Crear cuenta'), findsOneWidget);
    },
  );

  test('Edad del perfil: singular y plural', () {
    expect(petAgeLabel('1'), '1 año');
    expect(petAgeLabel('12'), '12 años');
    expect(petAgeLabel('23'), '23 años');
    expect(petAgeLabel(''), '');
  });

  test('Edad de mascota de dos años', () {
    expect(petAgeLabel('2'), '2 años');
  });

  test('Pelaje: opciones normales y casos sin pelo', () {
    expect(petCoatOptions('Perro'), contains('Corto'));
    expect(petCoatOptions('Gato'), contains('Medio'));
    expect(petCoatOptions('Perro'), contains('Largo'));
    expect(petCoatOptions('Ave'), contains('Abundante'));
  });

  testWidgets(
    'Editor de horario: cuidado, hora y días',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReminderEditorPage(
            petId: 'demo-pet',
            petName: 'Kira',
            careTypes: [
              {
                'id': 'feeding',
                'label': 'Alimentación',
              },
            ],
          ),
        ),
      );

      // V37 simplifica el encabezado: ya no muestra una tarjeta
      // redundante con 'Recordatorio · mascota'. El editor debe seguir
      // mostrando el cuidado, la hora y la seleccion de dias.
      expect(find.text('Crear horario'), findsOneWidget);
      expect(find.text('Alimentación'), findsOneWidget);
      expect(find.text('5:00 p. m.'), findsOneWidget);

      // El ListView crea contenido conforme se desplaza.
      await tester.scrollUntilVisible(
        find.text('Repetir'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Repetir'), findsOneWidget);
      expect(find.text('Sin días seleccionados'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.widgetWithText(ActionChip, 'Todos los días'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(ActionChip, 'Todos los días'));
      await tester.pumpAndSettle();
      expect(find.text('Sin días seleccionados'), findsNothing);
      expect(find.text('Todos los días'), findsWidgets);
      expect(find.text('Guardar horario'), findsOneWidget);
      expect(find.text('Probar notificación ahora'), findsNothing);
    },
  );
}