# 🐾 PetCare Connect V37 · Evaluación con compañeros

**Versión:** `0.21.8 (37)` · **Plataforma:** Android · **Entrega hasta:** **22/10/2026 a las 23:59** (México centro).

**Descarga:** [APK oficial V37](https://github.com/NMG15/PetCare-Connect/releases/download/v0.21.8/PetCare_Android_v37.apk) · [Detalles de la versión](https://github.com/NMG15/PetCare-Connect/releases/tag/v0.21.8).

> **Objetivo:** que compañeros reales comprueben las funciones principales, la facilidad de uso y cualquier error, dejando un informe verificable en GitHub. No es necesario encontrar fallos: también cuenta explicar qué funcionó bien.

## Evaluadores

| Colaborador | Informe individual | Estado |
|---|---|---|
| @CarlosWrld | [Abrir informe](evaluadores/CarlosWrld.md) | Pendiente |
| @Julio10Mon | [Abrir informe](evaluadores/Julio10Mon.md) | Pendiente |
| Tercera persona por confirmar | [Formato reservado](evaluadores/Evaluador_3_PENDIENTE.md) | Por asignar |

## ¿Qué deben probar?

Solo son **6 pruebas obligatorias** y **1 opcional**; ver los pasos de cada una en [PLAN_7_CASOS.md](PLAN_7_CASOS.md). Cubre instalación/acceso, mascotas, cuidados, horarios, historial, diseño claro/oscuro y, opcionalmente, permisos de administración. 

**Tiempo estimado:** 15-25 minutos para las obligatorias. Si una prueba requiere esperar un aviso, pueden anotar que aún no se completó y añadir el resultado posteriormente.

## ¿Cómo se entrega? (muy importante)

1. Descarga e instala **PetCare Connect V37**. No desinstales una versión anterior con datos importantes sin respaldo.
2. Entra con **una cuenta propia autorizada para pruebas**. No uses credenciales que te compartió otra persona. Si no tienes cuenta autorizada, solicita permiso antes de crear registros en Firebase real.
3. Abre el archivo de tu nombre en la carpeta [`evaluadores`](evaluadores/). **Solo edita tu archivo**; no modifiques código ni configuración.
4. En GitHub pulsa **Edit (lápiz)** y completa las filas con `Correcto`, `Error` o `No probado` y una observación breve. Si hay un error, anota cómo reproducirlo. No es obligatorio adjuntar capturas, pero ayuda si no muestran datos privados.
5. Al guardar, elige **crear una rama nueva** para el cambio y abrir un **Pull Request**. En el PR: **base = `testing/petcare-v37`**, no `main`.
6. Titula tu PR `test: evaluación V37 @TU_USUARIO` y comparte el enlace. La hora de creación del PR será la evidencia de entrega.

**No pongas resultados inventados.** Si no puedes ejecutar un caso, marca `No probado` y explica por qué.

## Límites para proteger los datos

- La APK usa **Firebase real**. Solo prueba creación o edición sobre **tu propia mascota ficticia de pruebas** y si el propietario del proyecto autorizó usar la base de datos para ello; usa nombres como `PRUEBA_Carlos`.
- **No elimines información existente**, no hagas pruebas de estrés ni accedas a mascotas de otras cuentas.
- No compartas contraseñas, enlaces de recuperación, correos privados ni datos personales en capturas.
- La función de recuperar contraseña se prueba exclusivamente con **tu propio correo de prueba**, sin publicar el enlace.
- El panel administrativo es **opcional** y solo para quien tenga autorización y permisos adecuados. No se presta la cuenta de administrador.

## Cierre de la ronda

**Fecha límite:** 22 de octubre de 2026, 23:59 (hora del centro de México). GitHub permite verificar autor y hora del PR, pero **no bloqueará entregas automáticamente**. El propietario anotará resultados en [Resumen de entregas](RESUMEN_ENTREGAS.md). Una entrega posterior puede quedar marcada fuera de plazo.
