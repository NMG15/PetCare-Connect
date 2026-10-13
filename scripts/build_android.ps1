$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter no esta disponible en PATH. Ejecuta flutter doctor.' }
if (-not (Test-Path 'android/key.properties') -or -not (Test-Path 'android/app/upload-keystore.jks')) {
  throw 'Falta la firma original: copia localmente android/key.properties y android/app/upload-keystore.jks desde tu proyecto anterior, sin enviarlos a nadie.'
}
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get fallo.' }
flutter analyze --no-fatal-infos
if ($LASTEXITCODE -ne 0) { throw 'flutter analyze reporto errores; revisar antes de construir.' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'flutter test fallo.' }
flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear la APK Android.' }
New-Item -ItemType Directory -Force 'dist' | Out-Null
Copy-Item 'build/app/outputs/flutter-apk/app-release.apk' 'dist/PetCare_Android_v21.apk' -Force
Write-Host 'APK ANDROID LISTA: dist/PetCare_Android_v21.apk' -ForegroundColor Green
