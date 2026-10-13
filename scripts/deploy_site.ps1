$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) { throw 'Instala Firebase CLI primero: npm install -g firebase-tools' }
Write-Host 'Publicando SOLO el micrositio de PetCare Connect (sin tocar APK).' -ForegroundColor Cyan
firebase deploy --only hosting --project petcare-connect-67787
if ($LASTEXITCODE -ne 0) { throw 'Error al publicar el micrositio.' }
Write-Host 'Listo: https://petcare-connect-67787.web.app/' -ForegroundColor Green
