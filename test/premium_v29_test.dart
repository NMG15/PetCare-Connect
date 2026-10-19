import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';

void main() {
  testWidgets('Premium V29: bienvenida y rutas de acceso', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildPetCareTheme(Brightness.light),
      home: const WelcomePage(),
    ));
    expect(find.text('PetCare Connect'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('✦  TODO SU MUNDO, EN TUS MANOS'), findsOneWidget);
  });

  testWidgets('Premium V29: hero y navegación de usuario', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: const PetCareSignatureHero(
          eyebrow: 'PetCare', title: 'Cuidados', subtitle: 'Demo'),
        bottomNavigationBar: PetCareBottomNav(
          selected: 0, onSelected: (_) {}),
      ),
    ));
    expect(find.text('Cuidados'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Mascotas'), findsOneWidget);
    expect(find.text('Agenda'), findsOneWidget);
    expect(find.text('Cuenta'), findsOneWidget);
  });
}
