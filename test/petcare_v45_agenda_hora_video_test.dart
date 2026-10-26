import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';
import 'package:petcare_connect_mobile/petcare_care_features.dart';

void main() {
  test('V45 video: al cambiar de octubre a noviembre cambia la fecha', () {
    expect(
      petCareAgendaDateForMonth(DateTime(2026, 10, 25), DateTime(2026, 11, 1)),
      DateTime(2026, 11, 25),
    );
  });
  test('V45 video: febrero limita el dia 31 a 28', () {
    expect(
      petCareAgendaDateForMonth(DateTime(2027, 1, 31), DateTime(2027, 2, 1)),
      DateTime(2027, 2, 28),
    );
  });
  test('V45 video: febrero bisiesto admite 29', () {
    expect(
      petCareAgendaDateForMonth(DateTime(2028, 1, 31), DateTime(2028, 2, 1)),
      DateTime(2028, 2, 29),
    );
  });
  test('V45 video: cambio de diciembre a enero conserva dia', () {
    expect(
      petCareAgendaDateForMonth(DateTime(2026, 12, 25), DateTime(2027, 1, 1)),
      DateTime(2027, 1, 25),
    );
  });
  test('V45 video: 12 AM y 12 PM no se confunden', () {
    const noon = TimeOfDay(hour: 12, minute: 37);
    expect(
      petCareTimeWithPeriod(noon, 0),
      const TimeOfDay(hour: 0, minute: 37),
    );
    expect(
      petCareTimeWithPeriod(noon, 1),
      const TimeOfDay(hour: 12, minute: 37),
    );
  });
  test('V45 video: cambiar de 7:37 AM a PM conserva minutos', () {
    const morning = TimeOfDay(hour: 7, minute: 37);
    expect(
      petCareTimeWithPeriod(morning, 1),
      const TimeOfDay(hour: 19, minute: 37),
    );
    expect(
      petCareTimeWithPeriod(const TimeOfDay(hour: 19, minute: 37), 0),
      morning,
    );
  });
}
