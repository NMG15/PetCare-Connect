part of '../main.dart';

class PetCareAppearance {
  PetCareAppearance._();

  static const storageKey = 'petcare_theme_mode_v1';
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  static ThemeMode fromStoredValue(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String toStoredValue(ThemeMode value) => value.name;

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      mode.value = fromStoredValue(prefs.getString(storageKey));
    } catch (error) {
      debugPrint('THEME_LOAD: ${error.runtimeType}');
    }
  }

  static Future<void> update(ThemeMode value) async {
    mode.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, toStoredValue(value));
    } catch (error) {
      debugPrint('THEME_SAVE: ${error.runtimeType}');
    }
  }
}
