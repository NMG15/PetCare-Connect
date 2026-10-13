$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter no esta disponible en PATH. Ejecuta flutter doctor.' }
if (-not (Test-Path 'android/key.properties') -or -not (Test-Path 'android/app/upload-keystore.jks')) {
  throw 'Falta la firma original: copia localmente android/key.properties y android/app/upload-keystore.jks desde tu proyecto anterior.'
}
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get fallo.' }
flutter analyze --no-fatal-infos
if ($LASTEXITCODE -ne 0) { throw 'flutter analyze reporto errores; revisar antes de construir.' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'flutter test fallo.' }
# Fire OS: deshabilita el login nativo de Google/FCM; Facebook se prueba aparte.
flutter build apk --release --dart-define=AMAZON_BUILD=true
if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear la APK Amazon.' }
New-Item -ItemType Directory -Force 'dist' | Out-Null
Copy-Item 'build/app/outputs/flutter-apk/app-release.apk' 'dist/PetCare_Amazon_Fire_v21.apk' -Force
Write-Host 'APK AMAZON LISTA: dist/PetCare_Amazon_Fire_v21.apk' -ForegroundColor Green
