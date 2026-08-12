# Build + copia inmediata al Escritorio (evita que dist quede vacio).
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Runtime = Join-Path $Root "runtime"
$Pack = $PSScriptRoot
$VenvPython = Join-Path $Runtime ".venv\Scripts\python.exe"
$Spec = Join-Path $Pack "SmartCSET_Porteria.spec"
$BuildDir = Join-Path $Root "build"
$DistRoot = Join-Path $Root "dist"
$OutFolder = Join-Path $DistRoot "SmartCSET_Porteria"
$DesktopOut = Join-Path ([Environment]::GetFolderPath("Desktop")) "SmartCSET_Porteria"

Write-Host "== Build SmartCSET Porteria =="
Write-Host "Root: $Root"
Write-Host "DesktopOut: $DesktopOut"

if (-not (Test-Path $VenvPython)) {
    throw "No existe venv: $VenvPython"
}

Write-Host "Icono..."
& $VenvPython (Join-Path $Pack "make_icon.py")
if ($LASTEXITCODE -ne 0) { throw "make_icon fallo" }

if (Test-Path $BuildDir) { Remove-Item -Recurse -Force $BuildDir }
if (Test-Path $OutFolder) { Remove-Item -Recurse -Force $OutFolder }
if (Test-Path $DesktopOut) { Remove-Item -Recurse -Force $DesktopOut }

Write-Host "PyInstaller..."
Push-Location $Root
try {
    & $VenvPython -m PyInstaller --noconfirm --clean --distpath $DistRoot --workpath $BuildDir $Spec
    if ($LASTEXITCODE -ne 0) { throw "PyInstaller fallo: $LASTEXITCODE" }
} finally {
    Pop-Location
}

$ExePath = Join-Path $OutFolder "SmartCSET_Porteria.exe"
$Internal = Join-Path $OutFolder "_internal"
Write-Host "Exe existe: $(Test-Path $ExePath)"
Write-Host "_internal existe: $(Test-Path $Internal)"

if (-not (Test-Path $ExePath)) {
    throw "Falta SmartCSET_Porteria.exe en dist"
}
if (-not (Test-Path $Internal)) {
    throw "Falta carpeta _internal en dist"
}

Copy-Item -Force (Join-Path $Pack "app_config.porteria.json") (Join-Path $OutFolder "app_config.json")
Copy-Item -Recurse -Force $OutFolder $DesktopOut

Write-Host ""
Write-Host "LISTO en Escritorio:"
Write-Host "  $DesktopOut"
Write-Host "  base_url = https://10.5.213.111/smartcset"
Get-ChildItem $DesktopOut | ForEach-Object { Write-Host ("  - " + $_.Name) }
Get-Content (Join-Path $DesktopOut "app_config.json")
