import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'petcare_care_features.dart';
import 'petcare_cloud_messaging.dart';

// Los módulos `part` preservan el acceso a las clases internas y evitan un archivo de 4,400 líneas.
part 'core/app_appearance.dart';
part 'core/app_theme.dart';
part 'core/pet_shared.dart';
part 'data/cloud_db.dart';
part 'data/pet_catalog.dart';
part 'screens/auth_pages.dart';
part 'screens/pet_pages.dart';
part 'screens/admin_pages.dart';
part 'screens/settings_page.dart';

const green = Color(0xFF257B54);
const cream = Color(0xFFF8F6F1);
const orange = Color(0xFFF2A65A);
const ink = Color(0xFF193B32);
const pale = Color(0xFFEAF5EF);


/// Compilación especial para Fire Tablet, sin servicios de Google Play.
/// La compilación Android habitual conserva Google y Facebook.
const bool amazonBuild = bool.fromEnvironment('AMAZON_BUILD', defaultValue: false);

/// Facebook se activa en Amazon SOLO después de probar su login en Fire OS.
const bool amazonFacebookEnabled = bool.fromEnvironment(
  'AMAZON_FACEBOOK_ENABLED', defaultValue: false,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await PetCareAppearance.initialize();
  if (!amazonBuild) registerPetCareCloudBackgroundHandler();
  if (!amazonBuild) {
    await GoogleSignIn.instance.initialize();
  }
  await FirebaseAuth.instance.setLanguageCode('es');
  try {
    await PetCareAlerts.instance.init();
  } catch (_) {
    // Si el teléfono no expone su zona horaria, la app puede abrirse.
    // La pantalla de recordatorios mostrará el error al programar.
  }
  if (!amazonBuild) {
    try {
      await PetCareCloudMessaging.instance.init();
    } catch (e) {
      debugPrint('FCM_INIT: $e');
      // FCM se volverá a intentar cuando el usuario inicie sesión.
    }
  }
  runApp(const PetCareApp());
}

class PetCareApp extends StatelessWidget {
  const PetCareApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: PetCareAppearance.mode,
    builder: (context, selectedMode, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PetCare Connect',
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: selectedMode,
      theme: buildPetCareTheme(Brightness.light),
      darkTheme: buildPetCareTheme(Brightness.dark),
      home: const AuthGate(),
    ),
  );
}
