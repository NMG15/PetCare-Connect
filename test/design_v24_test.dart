import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';

void main() {
  test('Los colores del tema oscuro distinguen texto y fondo', () {
    final colors = buildPetCareTheme(Brightness.dark).colorScheme;
    expect(colors.onSurface.computeLuminance(),
        greaterThan(colors.surface.computeLuminance()));
    expect(colors.onPrimaryContainer.computeLuminance(),
        greaterThan(colors.primaryContainer.computeLuminance()));
    expect(colors.onSecondaryContainer.computeLuminance(),
        greaterThan(colors.secondaryContainer.computeLuminance()));
  });

  test('El modo claro conserva texto oscuro sobre superficies claras', () {
    final colors = buildPetCareTheme(Brightness.light).colorScheme;
    expect(colors.onSurface.computeLuminance(),
        lessThan(colors.surface.computeLuminance()));
  });
}
