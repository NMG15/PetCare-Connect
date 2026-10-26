import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart' as petcare;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('REGRESION: OAuth web coincide con google-services.json', () {
    final source = File('lib/main.dart').readAsStringSync();
    final google =
        jsonDecode(File('android/app/google-services.json').readAsStringSync())
            as Map<String, dynamic>;
    final clients = (google['client'] as List).cast<Map<String, dynamic>>();
    final selected =
        clients.where((client) {
          final info = client['client_info'] as Map<String, dynamic>;
          final android = info['android_client_info'] as Map<String, dynamic>;
          return android['package_name'] == 'com.petcareconnect.app';
        }).toList();
    expect(selected.length, 1, reason: 'Paquete Android no coincide');
    final oauth =
        (selected.single['oauth_client'] as List).cast<Map<String, dynamic>>();
    final web = oauth.where((entry) => entry['client_type'] == 3).toList();
    expect(web.length, 1, reason: 'Se necesita un unico cliente OAuth Web');
    final configuredId = web.single['client_id'] as String;
    final matches =
        RegExp("serverClientId:\\s*'([^']+)'").allMatches(source).toList();
    expect(
      matches.length,
      1,
      reason: 'No cambiar inicializacion Google sin test',
    );
    expect(
      matches.single.group(1) == configuredId,
      isTrue,
      reason: 'El ID Web de Dart y el de Firebase no coinciden',
    );
  });

  test('REGRESION: Google sigue autenticando mediante Firebase', () {
    final auth = File('lib/screens/auth_pages.dart').readAsStringSync();
    expect(auth.contains('GoogleSignIn.instance.authenticate()'), isTrue);
    expect(auth.contains('GoogleAuthProvider.credential('), isTrue);
    expect(
      auth.contains('FirebaseAuth.instance.signInWithCredential('),
      isTrue,
    );
    expect(auth.contains('GOOGLE_SIGN_IN_ERROR:'), isTrue);
  });

  test('REGRESION: logo de Google y modos de apariencia conservados', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final auth = File('lib/screens/auth_pages.dart').readAsStringSync();
    expect(pubspec.contains('assets/icon/google_g_color.png'), isTrue);
    expect(auth.contains('google_g_color.png'), isTrue);
    final theme = File('lib/core/app_theme.dart').readAsStringSync();
    expect(theme.contains('ColorScheme.fromSeed('), isTrue);
    expect(theme.contains('Brightness.dark'), isTrue);
    expect(petcare.green, const Color(0xFF13694D));
    expect(
      petcare.buildPetCareTheme(Brightness.light).brightness,
      Brightness.light,
    );
    expect(
      petcare.buildPetCareTheme(Brightness.dark).brightness,
      Brightness.dark,
    );
  });

  test('REGRESION: controles basicos de reglas Firestore locales', () {
    final rules = File('firestore.rules').readAsStringSync();
    expect(rules.contains('request.auth.uid == userId'), isTrue);
    expect(rules.contains('allow write: if false;'), isTrue);
    expect(
      RegExp(
        r'allow\s+(read|write|create|update|delete)\s*:\s*if\s+true',
      ).hasMatch(rules),
      isFalse,
      reason: 'Se detecto una regla con acceso publico',
    );
  });

  test('REGRESION: version y paquete de actualizacion', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    final version = RegExp(
      r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(
      version,
      isNotNull,
      reason: 'El formato de version Flutter es incorrecto',
    );

    final buildNumber = int.parse(version!.group(4)!);

    expect(
      buildNumber,
      greaterThanOrEqualTo(43),
      reason: 'No regresar a una version anterior de PetCare',
    );

    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(
      RegExp(
        r'applicationId\s*=\s*"com\.petcareconnect\.app"',
      ).hasMatch(gradle),
      isTrue,
      reason: 'No cambiar el identificador Android de PetCare',
    );
  });
}
