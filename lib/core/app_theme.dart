// Paleta adaptable; sin invertir colores de fotografías ni del logotipo.
part of '../main.dart';

Color adaptiveInk(BuildContext context) => Theme.of(context).colorScheme.onSurface;
Color adaptiveMuted(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;
Color adaptivePale(BuildContext context) => Theme.of(context).colorScheme.primaryContainer;
Color adaptiveSurface(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerLow;

ThemeData buildPetCareTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: green,
    brightness: brightness,
    surface: dark ? const Color(0xFF121B17) : cream,
  ).copyWith(
    primary: dark ? const Color(0xFF74DEAB) : green,
    onPrimary: dark ? const Color(0xFF06281A) : Colors.white,
    primaryContainer: dark ? const Color(0xFF214435) : const Color(0xFFE3F4E9),
    onPrimaryContainer: dark ? const Color(0xFFD7FFE8) : const Color(0xFF173A2B),
    secondaryContainer: dark ? const Color(0xFF2A4437) : const Color(0xFFE5F2E9),
    onSecondaryContainer: dark ? const Color(0xFFE2FFF0) : const Color(0xFF173C2D),
  );
  final surface = dark ? const Color(0xFF202C27) : Colors.white;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? const Color(0xFF34453D) : ink,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: dark ? const Color(0xFF6DD8A1) : green,
        foregroundColor: dark ? const Color(0xFF09251A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      floatingLabelStyle: TextStyle(color: scheme.primary),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: surface,
      textStyle: TextStyle(color: scheme.onSurface, fontSize: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    listTileTheme: ListTileThemeData(
      textColor: scheme.onSurface,
      iconColor: scheme.onSurfaceVariant,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
  );
}


/// Barra de acción consistente: mantiene el botón fuera de la navegación Android.
/// Algunos fabricantes informan un inset de 0 incluso en edge-to-edge.
Widget petCareActionFooter(BuildContext context, Widget button,
    {double horizontal = 20}) {
  final bottomInset = MediaQuery.of(context).viewPadding.bottom;
  final bottomSpace = bottomInset < 48 ? 72.0 : bottomInset + 16.0;
  return ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: Padding(
      padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, bottomSpace),
      child: SizedBox(height: 54, width: double.infinity, child: button),
    ),
  );
}
