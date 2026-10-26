import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_connect_mobile/main.dart';

void main() {
  test('V45: primera entrada muestra carga mientras no existen datos', () {
    expect(
      petCareHomeNeedsBlockingLoad(
        hasSuccessfulLoad: false,
        loadedUid: null,
        currentUid: 'cuentaA',
      ),
      isTrue,
    );
  });

  test('V45: regresar con la misma cuenta conserva la pantalla', () {
    expect(
      petCareHomeNeedsBlockingLoad(
        hasSuccessfulLoad: true,
        loadedUid: 'cuentaA',
        currentUid: 'cuentaA',
      ),
      isFalse,
    );
  });

  test(
    'V45: cambiar de usuario impide mostrar datos de la cuenta anterior',
    () {
      expect(
        petCareHomeNeedsBlockingLoad(
          hasSuccessfulLoad: true,
          loadedUid: 'cuentaA',
          currentUid: 'cuentaB',
        ),
        isTrue,
      );
      expect(
        petCareHomeNeedsBlockingLoad(
          hasSuccessfulLoad: true,
          loadedUid: 'cuentaA',
          currentUid: null,
        ),
        isTrue,
      );
    },
  );
}
