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
    surface: dark ? Colors.black : cream,
  ).copyWith(
    primary: dark ? const Color(0xFF47E6A1) : green,
    onPrimary: dark ? const Color(0xFF052819) : Colors.white,
    primaryContainer: dark ? const Color(0xFF24262A) : const Color(0xFFE4F3E7),
    onPrimaryContainer: dark ? const Color(0xFFF2F4F4) : const Color(0xFF173A2B),
    secondaryContainer: dark ? const Color(0xFF292B30) : const Color(0xFFEFF6EF),
    onSecondaryContainer: dark ? const Color(0xFFF2F4F4) : const Color(0xFF173C2D),
    surface: dark ? Colors.black : cream,
    onSurface: dark ? const Color(0xFFF5F7F6) : null,
    onSurfaceVariant: dark ? const Color(0xFFB7BEC2) : null,
    surfaceContainerLowest: dark ? Colors.black : null,
    surfaceContainerLow: dark ? const Color(0xFF17191D) : null,
    surfaceContainer: dark ? const Color(0xFF202226) : null,
    surfaceContainerHigh: dark ? const Color(0xFF292B30) : null,
    surfaceContainerHighest: dark ? const Color(0xFF35383D) : null,
    outline: dark ? const Color(0xFF8C9599) : null,
    outlineVariant: dark ? const Color(0xFF41464B) : null,
  );
  final surface = dark ? const Color(0xFF1C1E22) : Colors.white;
  final selectedChip = dark ? const Color(0xFF183D30) : const Color(0xFFD2F1DD);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    splashFactory: InkRipple.splashFactory,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 31, fontWeight: FontWeight.w800,
          letterSpacing: -0.9, height: 1.15),
      headlineMedium: TextStyle(fontSize: 25, fontWeight: FontWeight.w800,
          letterSpacing: -0.6),
      titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w800,
          letterSpacing: -0.4),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      bodyMedium: TextStyle(fontSize: 14.5, height: 1.43),
      bodySmall: TextStyle(fontSize: 12.5, height: 1.38),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: surface,
      indicatorColor: selectedChip,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
        fontSize: 12,
        fontWeight: states.contains(WidgetState.selected)
            ? FontWeight.w800 : FontWeight.w600,
        color: states.contains(WidgetState.selected)
            ? scheme.primary : scheme.onSurfaceVariant,
      )),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
        size: 24,
        color: states.contains(WidgetState.selected)
            ? scheme.primary : scheme.onSurfaceVariant,
      )),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: scheme.primary),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(color: scheme.onSurface,
          fontSize: 20, fontWeight: FontWeight.w800),
      iconTheme: IconThemeData(color: scheme.onSurface),
      centerTitle: false,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? const Color(0xFF292C30) : ink,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        minimumSize: const Size(0, 54),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF202226) : const Color(0xFFF0F5F0),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      floatingLabelStyle: TextStyle(color: scheme.primary),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.error, width: 1.3),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.error, width: 1.7),
      ),
      prefixIconColor: scheme.onSurfaceVariant,
      suffixIconColor: scheme.onSurfaceVariant,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: selectedChip,
      checkmarkColor: dark ? const Color(0xFF47E6A1) : const Color(0xFF174730),
      elevation: 0,
      labelStyle: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: scheme.outlineVariant, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) =>
          states.contains(WidgetState.selected) ? selectedChip : surface),
        foregroundColor: WidgetStateProperty.all(scheme.onSurface),
        side: WidgetStateProperty.all(
          BorderSide(color: scheme.outlineVariant, width: 1)),
      ),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      dialBackgroundColor: scheme.surfaceContainerHighest,
      dialHandColor: scheme.primary,
      dialTextColor: WidgetStateColor.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? scheme.onPrimary : scheme.onSurface),
      hourMinuteColor: scheme.primaryContainer,
      hourMinuteTextColor: scheme.onPrimaryContainer,
      entryModeIconColor: scheme.primary,
      helpTextStyle: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.65)),
        borderRadius: BorderRadius.circular(22),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      modalBackgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: scheme.onSurfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: scheme.primary,
      selectionColor: scheme.primary.withValues(alpha: 0.25),
      selectionHandleColor: scheme.primary,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? scheme.primary : Colors.transparent),
      checkColor: WidgetStateProperty.all(scheme.onPrimary),
      side: BorderSide(color: scheme.outline, width: 1.5),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? scheme.onPrimary : scheme.onSurfaceVariant),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? scheme.primary : scheme.surfaceContainerHighest),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
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
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        minimumSize: const Size(0, 52),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
      ),
    ),
  );
}


const petCareDarkBackground = Color(0xFF000000);
const petCareDarkCard = Color(0xFF1C1E22);
const petCareEmerald = Color(0xFF47E6A1);

Widget petCareActionFooter(BuildContext context, Widget button,
    {double horizontal = 20}) {
  final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
  final bottomSpace = bottomInset < 20 ? 24.0 : bottomInset + 14.0;
  return ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: Padding(
      padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, bottomSpace),
      child: SizedBox(height: 54, width: double.infinity, child: button),
    ),
  );
}
