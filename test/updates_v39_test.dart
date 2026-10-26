import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';

void main() {
  test('V39: las nuevas especies tienen catálogo y sin raza definida', () {
    for (final species in ['Iguana', 'Erizo']) {
      expect(allPetSpecies, contains(species));
      expect(speciesCatalog[species], contains('Raza sin especificar'));
      expect(defaultCareForSpecies(species), isNotEmpty);
      expect(
        defaultCareForSpecies(species).map((care) => care['id']),
        isNot(contains('walk')),
      );
    }
    expect(
      defaultCareForSpecies('Iguana').map((care) => care['id']),
      contains('terrarium'),
    );
    expect(petCoatOptions('Iguana'), contains('Escamas verdes'));
    expect(petCoatOptions('Erizo'), contains('Púas cortas'));
  });

  test(
    'V39: validación de datos evita nombres vacíos y valores imposibles',
    () {
      expect(validatePetData(name: ' ', age: '', weight: ''), isNotNull);
      expect(validatePetData(name: 'Firu', age: '151', weight: '4'), isNotNull);
      expect(validatePetData(name: 'Firu', age: '4', weight: '0'), isNotNull);
      expect(validatePetData(name: 'Firu', age: '4', weight: '3.2'), isNull);
      expect(validatePetData(name: 'Firu', age: '', weight: ''), isNull);
    },
  );

  test('V39: próximo recordatorio de hoy', () {
    final now = DateTime(2026, 10, 19, 16, 30);
    final next = nextPetReminder({
      'enabled': true,
      'hour': 17,
      'minute': 0,
      'days': [1],
    }, now);
    expect(next, DateTime(2026, 10, 19, 17));
  });

  test('V39: recordatorio pasado salta al próximo lunes', () {
    final now = DateTime(2026, 10, 19, 18);
    final next = nextPetReminder({
      'enabled': true,
      'hour': 17,
      'minute': 0,
      'days': [1],
    }, now);
    expect(next, DateTime(2026, 10, 26, 17));
  });

  test('V39: recordatorios deshabilitados y horarios inválidos se omiten', () {
    final now = DateTime(2026, 10, 19, 12);
    expect(
      nextPetReminder({'enabled': false, 'hour': 18, 'minute': 0}, now),
      isNull,
    );
    expect(nextPetReminder({'hour': 25, 'minute': 0}, now), isNull);
  });

  test('V39: un aviso sin días repetidos se considera diario', () {
    final now = DateTime(2026, 10, 19, 18);
    expect(
      nextPetReminder({'hour': 17, 'minute': 0, 'days': []}, now),
      DateTime(2026, 10, 20, 17),
    );
  });

  testWidgets('V39: botón Google tiene imagen de marca y texto en español', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuthPage(login: true)));
    await tester.scrollUntilVisible(
      find.text('Continuar con Google'),
      140,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/icon/google_g_color.png',
      ),
      findsOneWidget,
    );
  });
}
