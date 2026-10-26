import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';

void main() {
  test('V45: solo consultar horarios no requiere actualizar Inicio', () {
    final flag = PetCareAgendaChangeFlag();
    expect(flag.changed, isFalse);
  });

  test('V45: guardar un horario obliga a actualizar Inicio al volver', () {
    final flag = PetCareAgendaChangeFlag();
    flag.markChanged();
    expect(flag.changed, isTrue);
  });

  test('V45: eliminar y restaurar conservan la marca de cambio', () {
    final flag = PetCareAgendaChangeFlag();
    flag.markChanged();
    flag.markChanged();
    expect(flag.changed, isTrue);
  });

  test('V45: el estado no se comparte entre entradas a Horarios', () {
    final anterior = PetCareAgendaChangeFlag()..markChanged();
    final nuevaRuta = PetCareAgendaChangeFlag();
    expect(anterior.changed, isTrue);
    expect(nuevaRuta.changed, isFalse);
  });
}
