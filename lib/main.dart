import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'petcare_care_features.dart';
import 'petcare_cloud_messaging.dart';

part 'core/app_appearance.dart';
part 'core/app_theme.dart';
part 'core/premium_components.dart';
part 'core/pet_shared.dart';
part 'data/cloud_db.dart';
part 'data/pet_catalog.dart';
part 'screens/auth_pages.dart';
part 'screens/pet_pages.dart';
part 'screens/admin_pages.dart';
part 'screens/settings_page.dart';

const green = Color(0xFF13694D);
const cream = Color(0xFFF9FAF6);
const orange = Color(0xFFF2A65A);
const ink = Color(0xFF173A2D);
const pale = Color(0xFFE8F3EB);


const bool amazonBuild = bool.fromEnvironment('AMAZON_BUILD', defaultValue: false);


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
  }
  if (!amazonBuild) {
    try {
      await PetCareCloudMessaging.instance.init();
    } catch (e) {
      debugPrint('FCM_INIT: $e');
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
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: isDark ? Colors.black : cream,
            systemNavigationBarDividerColor: isDark ? Colors.black : cream,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AuthGate(),
    ),
  );
}
