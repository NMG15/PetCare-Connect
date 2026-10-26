import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';

void main() {
  test('V40: registro de otras especies y controles de validación', () {
    expect(speciesCatalog.containsKey('Otra especie'), isTrue);
    expect(allPetSpecies, contains('Otra especie'));
    expect(speciesCatalog['Otra especie'], contains('Raza sin especificar'));
    expect(defaultCareForSpecies('Otra especie'), isNotEmpty);
    expect(
      defaultCareForSpecies('Otra especie').map((e) => e['id']),
      isNot(contains('walk')),
    );
    expect(validateCustomSpecies('Otra especie', ''), isNotNull);
    expect(validateCustomSpecies('Otra especie', 'Mono'), isNull);
    expect(
      validateCustomSpecies('Otra especie', 'x'.padRight(51, 'x')),
      isNotNull,
    );
    expect(validateCustomSpecies('Gato', ''), isNull);
  });

  test('V40: especies personalizadas se presentan sin cambiar las previas', () {
    expect(
      petSpeciesName({'species': 'Otra especie', 'customSpecies': 'Mono'}),
      'Mono',
    );
    expect(
      petSpeciesDescription({
        'species': 'Otra especie',
        'customSpecies': 'Mono',
        'breed': 'Raza sin especificar',
      }),
      'Mono',
    );
    expect(
      petSpeciesDescription({'species': 'Gato', 'breed': 'Siamés'}),
      'Gato · Siamés',
    );
  });

  test('V40: saludo visible del usuario o alternativa', () {
    expect(homeGreeting('Carlos Pérez'), 'Hola, Carlos');
    expect(homeGreeting(' '), 'Bienvenido a tu familia');
  });

  test(
    'V40: agenda unificada filtra por fecha y respeta horarios deshabilitados',
    () {
      final data = {
        'enabled': true,
        'hour': 8,
        'minute': 30,
        'days': [1, 3],
      };
      expect(reminderAppliesOnDate(data, DateTime(2026, 10, 19)), isTrue);
      expect(reminderAppliesOnDate(data, DateTime(2026, 10, 20)), isFalse);
      expect(
        reminderAppliesOnDate({
          ...data,
          'enabled': false,
        }, DateTime(2026, 10, 19)),
        isFalse,
      );
      expect(
        reminderAppliesOnDate({
          'hour': 8,
          'minute': 15,
          'days': [],
        }, DateTime(2026, 10, 20)),
        isTrue,
      );
    },
  );

  testWidgets('V40: Google conserva solamente la G sin fondo blanco', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuthPage(login: true)));
    await tester.scrollUntilVisible(
      find.text('Continuar con Google'),
      140,
      scrollable: find.byType(Scrollable).first,
    );
    final google = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName ==
              'assets/icon/google_g_color.png',
    );
    expect(google, findsOneWidget);
    expect(tester.widget<Image>(google).color, isNull);
    final size =
        tester.element(google).findAncestorWidgetOfExactType<SizedBox>();
    expect(size?.width, 24);
    expect(size?.height, 24);
  });
}
