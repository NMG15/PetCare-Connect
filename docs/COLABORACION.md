# PetCare Connect - Guia de colaboracion

## Proyecto
PetCare Connect es una aplicacion desarrollada con Flutter
para registrar mascotas y administrar sus cuidados.

## Organizacion del repositorio
- main: version estable.
- feature/*: ramas para nuevas funciones, pruebas o correcciones.
- Pull Requests: revision de cambios antes de integrarlos.

## Flujo de trabajo
1. Actualizar la rama main.
2. Crear una rama feature/*.
3. Realizar cambios pequenos y comprobables.
4. Crear un commit descriptivo.
5. Subir la rama a GitHub.
6. Abrir un Pull Request.
7. Revisar las pruebas de GitHub Actions.
8. Integrar los cambios despues de validarlos.

## Pruebas
Antes de enviar cambios ejecutar:

flutter pub get
flutter analyze
flutter test

## Seguridad
No publicar:
- Contrasenas o claves privadas.
- android/key.properties
- Archivos .jks o de firma.
- Archivos .env con secretos.
- Credenciales privadas de Firebase o Meta.

La configuracion local debe obtenerse de forma segura
del responsable del proyecto.

## Entrega
Las versiones estables se identifican mediante tags.
Las APK se distribuyen en GitHub Releases,
sin incluir las llaves privadas utilizadas para firmarlas.
