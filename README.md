# PetCare Connect · Proyecto reorganizado · 0.20.1 (21)

Esta entrega reorganiza la app Flutter y renueva por completo el micrositio público. **Contiene código fuente, no incluye una APK nueva compilada ni se ha publicado automáticamente.**

## Qué cambió

- `lib/main.dart`: punto de entrada, tema y banderas de compilación.
- `lib/core/pet_shared.dart`: herramientas compartidas de interfaz/perfiles.
- `lib/data/cloud_db.dart`: acceso a Firestore.
- `lib/data/pet_catalog.dart`: catálogos y valores predeterminados.
- `lib/screens/auth_pages.dart`: pantallas de bienvenida, autenticación y diagnóstico de Facebook.
- `lib/screens/pet_pages.dart`: inicio, edición de mascotas y detalles.
- `lib/screens/admin_pages.dart`: administración.
- `lib/petcare_care_features.dart`: avisos locales y cuidados (lógica conservada).
- `lib/petcare_cloud_messaging.dart`: avisos push de Firebase (lógica conservada).
- `meta-site/`: micrositio público adaptable a móvil, aviso de privacidad, términos, eliminación de datos, error 404 y controlador de recuperación de contraseña.
- `pubspec.yaml`: versión `0.20.1+21` para actualizar la versión 20 ya enviada a Amazon.
- `android/app/src/main/AndroidManifest.xml`: tráfico HTTP no cifrado deshabilitado; conserva metadata y actividades de Facebook.

### Correcciones de autenticación

1. Inicio con correo ya no rechaza contraseñas antiguas de menos de 8 caracteres. El registro nuevo sí exige 8.
2. Facebook ya no oculta los errores del SDK/Firebase: muestra un diálogo con diagnóstico copiable, **sin mostrar el token de acceso**.
3. Errores de red se presentan con mensajes más claros.
4. Un fallo al sincronizar el perfil no impide entrar si Firebase Authentication completó el inicio de sesión.
5. Firebase envía correos de recuperación/verificación en español.
6. La versión Amazon no ejecuta el inicio de Google ni FCM, dependientes de servicios de Google. No elimina esas funciones de la versión Android normal.
7. Si no se pueden cargar mascotas por problemas de red, se muestra un botón para reintentar en lugar de un spinner sin fin.

**Importante:** esta corrección proporciona *diagnóstico* y un escenario seguro para probar; la autenticación de Facebook requiere también configuración válida en Meta Developers y Firebase. Sin un error de runtime real no es posible garantizar que ya se haya solucionado toda la integración.

## NO borrar el proyecto anterior

Este ZIP es una **copia limpia del código fuente**. Por seguridad, se omitieron `.git`, `build`, `.dart_tool`, `android/key.properties`, `android/app/upload-keystore.jks`, `android/local.properties` y certificados. **No compartas tu keystore ni contraseñas**. Conserva la carpeta original `PetCareApp` que ya tiene esos archivos.

Recomendado: descomprime esta carpeta **separada** y copia de la carpeta original solo los archivos privados que necesitas para firmar (en tu computadora, jamás en este chat ni en GitHub):

- `android/key.properties` (mantén su contenido secreto).
- `android/app/upload-keystore.jks` (firma original, necesaria para actualizar la app existente).
- `android/local.properties` si Flutter/Android Studio no lo generan de nuevo.

El archivo `android/app/google-services.json` se incluye porque configura Firebase para Android, pero se conserva ignorado por Git. `android/key.properties.example` explica los nombres necesarios, sin contraseñas.

## Compilación para celular Android

En PowerShell, dentro de la carpeta **nueva corregida**:

```powershell
flutter doctor
flutter pub get
flutter analyze
flutter test
powershell -ExecutionPolicy Bypass -File .\scripts\build_android.ps1
```

Salida en `dist/PetCare_Android_v21.apk`. Este APK **conserva** los botones Google y Facebook. Antes de distribuirlo, prueba registro, inicio con correo, Google y Facebook. Si Facebook falla, toca «Copiar diagnóstico» y comparte el texto sin tokens ni contraseñas.

## Compilación para Amazon Fire Tablet

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_amazon.ps1
```

Salida en `dist/PetCare_Amazon_Fire_v21.apk`. **No** usa el inicio nativo con Google ni las notificaciones push FCM (las alertas locales siguen funcionando). Por defecto también oculta el botón de Facebook en Fire **hasta confirmar que allí funciona**. No se recomienda mostrar botones que sabemos que pueden fallar en la revisión.

Cuando pruebes Facebook satisfactoriamente en un Fire Tablet, puedes activarlo al compilar usando:

```powershell
flutter build apk --release --dart-define=AMAZON_BUILD=true --dart-define=AMAZON_FACEBOOK_ENABLED=true
```

Esta variante no es la predeterminada para Amazon, precisamente porque la versión 20 fue rechazada por un botón de autenticación en Fire OS. **La APK 21 necesita revisión nueva de Amazon; no reutilices la 20.**

### Meta / Facebook: pasos que faltan comprobar

- Firebase Console → Authentication → Método de acceso → Facebook: habilitado, App ID y App Secret correctos. No pegues el *App Secret* en Flutter ni en páginas HTML.
- Meta Developers → Facebook Login → Android: paquete **`com.petcareconnect.app`**, clase **`com.petcareconnect.app.MainActivity`**, Key Hash de la firma con que instalas el APK.
- La firma de `upload-keystore.jks` usada en tu APK y la firma aplicada por **Amazon Appstore** no tienen por qué ser iguales. Registra ambas firmas pertinentes en Meta si necesitas Facebook en ambas variantes.
- Mientras la app Meta esté en desarrollo, usa para pruebas una cuenta con rol autorizado en Meta. Para permitir personas externas puede ser necesario completar la publicación/revisión de Meta.
- Verifica y utiliza el token cliente de Meta y el App ID correctos. El token cliente puede estar en `strings.xml`, pero **nunca** pongas ahí tu contraseña de keystore ni el App Secret.
- No se necesita publicar en Amazon para activar Facebook Login en un Android normal.

Comprobar la huella de la firma de la APK Android (ejemplo con herramientas de Android SDK) no equivale al hash Base64 que pide Meta: genera el Key Hash de Facebook a partir del certificado real correspondiente.

### Importante sobre seguridad de firma

Si alguna vez compartiste la contraseña de `upload-keystore.jks`, trátala como expuesta. Si la app aún no se ha publicado, considera preparar una clave nueva y actualizar las huellas configuradas antes de lanzar. Si ya hay usuarios instalados, **no cambies la firma sin planificar la actualización**, pues deben mantenerse certificados compatibles.

## Micrositio gratis (Firebase Hosting)

Todo está en `meta-site/`. URLs tras el despliegue:

- `https://petcare-connect-67787.web.app/`
- `https://petcare-connect-67787.web.app/privacy.html`
- `https://petcare-connect-67787.web.app/terms.html`
- `https://petcare-connect-67787.web.app/delete-data.html`
- `https://petcare-connect-67787.web.app/auth-action.html` (enlace usado por Firebase Authentication).

Para desplegar **solo después de revisar**:

```powershell
firebase login
firebase use petcare-connect-67787
firebase deploy --only hosting
```

O usa `powershell -ExecutionPolicy Bypass -File .\scripts\deploy_site.ps1`.

**La subida no ocurre automáticamente al editar el ZIP.** Al abrir `auth-action.html` sin un código válido debe decir que falta un enlace válido; eso es normal.

### Activar la recuperación diseñada

1. Despliega el micrositio.
2. Prueba que la página `auth-action.html` carga con HTTPS.
3. Firebase Console → Authentication → Plantillas → Restablecimiento de contraseña → Editar → **Personalizar URL de acción**.
4. URL exacta: `https://petcare-connect-67787.web.app/auth-action.html`.
5. Esta configuración de Firebase puede utilizarse para **todas** las plantillas de correo. El controlador también procesa verificación de correo y recuperación de correo.
6. Solicita un **nuevo** restablecimiento desde la app, abre el correo de prueba y confirma el cambio.

Los correos de Firebase siguen teniendo el diseño básico de Firebase. La página de restablecimiento sí es completamente personalizada; para correos HTML de marca necesitas un sistema de envío adicional.

## Privacidad y operación

- Datos de mascotas, notas y recordatorios se guardan en Firestore bajo cada usuario; las fotos que el usuario elige se guardan localmente en su dispositivo y por eso no se sincronizan entre dispositivos en esta versión.
- `firestore.rules` conserva las reglas de acceso por usuario y administrador; no modificar sin revisarlas con pruebas de seguridad.
- Para una solicitud de eliminación de datos usa `petcareconnect.soporte@gmail.com` y confirma la identidad de quien la solicita.
- El sitio **no** muestra secretos de Firebase Admin, contraseñas, ni códigos de recuperación.

## Verificaciones

Se comprobó el formato/estructura del código fuente, los enlaces internos del sitio, el XML Android y la sintaxis JavaScript. **En este entorno no está instalado Flutter/Dart**, por lo cual no se ejecutaron aquí `flutter analyze`, `flutter test` ni `flutter build apk`. Ejecútalos en tu laptop antes de instalar o subir una APK nueva.
