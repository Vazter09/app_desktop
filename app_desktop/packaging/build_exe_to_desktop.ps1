# Build onefile y copia SmartCSET_Porteria.exe al Escritorio (archivo unico).
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Pack = $PSScriptRoot
$DesktopExe = Join-Path ([Environment]::GetFolderPath("Desktop")) "SmartCSET_Porteria.exe"
$DesktopOldFolder = Join-Path ([Environment]::GetFolderPath("Desktop")) "SmartCSET_Porteria"

Write-Host "== Build + Escritorio (exe unico) =="
& powershell -ExecutionPolicy Bypass -File (Join-Path $Pack "build_exe.ps1")
if ($LASTEXITCODE -ne 0) { throw "build_exe.ps1 fallo" }

$ExePath = Join-Path $Root "dist\SmartCSET_Porteria.exe"
if (-not (Test-Path $ExePath)) {
    throw "Falta dist\SmartCSET_Porteria.exe"
}

if (Test-Path $DesktopOldFolder) {
    Remove-Item -Recurse -Force $DesktopOldFolder
}
if (Test-Path $DesktopExe) {
    Remove-Item -Force $DesktopExe
}

Copy-Item -Force $ExePath $DesktopExe

Write-Host ""
Write-Host "LISTO en Escritorio (archivo unico):"
Write-Host "  $DesktopExe"
Write-Host "  Doble clic para abrir. Sin carpetas de codigo."
