import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';

void main() {
  test('Premium V29: modo oscuro negro con tarjetas grises', () {
    final theme = buildPetCareTheme(Brightness.dark);
    expect(theme.scaffoldBackgroundColor, Colors.black);
    expect(theme.colorScheme.surface, Colors.black);
    expect(theme.colorScheme.surfaceContainerLow, const Color(0xFF17191D));
    expect(theme.colorScheme.primaryContainer, const Color(0xFF24262A));
    expect(theme.colorScheme.primary, const Color(0xFF47E6A1));
  });

  test('Premium V31: acentos y botones coherentes en modo oscuro', () {
    final theme = buildPetCareTheme(Brightness.dark);
    expect(theme.colorScheme.primary, const Color(0xFF47E6A1));
    expect(theme.colorScheme.onPrimary, const Color(0xFF052819));
    expect(theme.filledButtonTheme.style!.backgroundColor!
      .resolve(<WidgetState>{}), theme.colorScheme.primary);
    expect(theme.floatingActionButtonTheme.backgroundColor,
      theme.colorScheme.primary);
    expect(theme.colorScheme.surfaceContainerHigh, const Color(0xFF292B30));
    expect(theme.bottomSheetTheme.modalBackgroundColor,
      const Color(0xFF1C1E22));
  });

  test('Premium V29: modo claro permanece sin cambios de fondo', () {
    final theme = buildPetCareTheme(Brightness.light);
    expect(theme.colorScheme.surface, const Color(0xFFF9FAF6));
    expect(theme.colorScheme.primary, const Color(0xFF13694D));
  });
}
