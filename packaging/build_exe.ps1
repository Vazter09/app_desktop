# Build onefile: un solo SmartCSET_Porteria.exe (sin _internal ni .py).
# Uso (desde app_desktop):
#   powershell -ExecutionPolicy Bypass -File packaging\build_exe.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Runtime = Join-Path $Root "runtime"
$Pack = $PSScriptRoot
$VenvPython = Join-Path $Runtime ".venv\Scripts\python.exe"
$Spec = Join-Path $Pack "SmartCSET_Porteria.spec"
$Requirements = Join-Path $Root "requirements.txt"

Write-Host "== SmartCSET Porteria - build .exe unico =="
Write-Host "Root: $Root"

if (-not (Test-Path $VenvPython)) {
    Write-Host "Creando runtime/.venv e instalando requirements..."
    New-Item -ItemType Directory -Force -Path $Runtime | Out-Null
    & py -3 -m venv (Join-Path $Runtime ".venv")
    & (Join-Path $Runtime ".venv\Scripts\pip.exe") install -r $Requirements
}

Write-Host "Instalando PyInstaller..."
& $VenvPython -m pip install --quiet "pyinstaller==6.16.0"

Write-Host "Generando icono .ico..."
& $VenvPython (Join-Path $Pack "make_icon.py")
if ($LASTEXITCODE -ne 0) { throw "make_icon fallo" }

Write-Host "Limpiando builds previos..."
$BuildDir = Join-Path $Root "build"
$DistRoot = Join-Path $Root "dist"
$OldFolder = Join-Path $DistRoot "SmartCSET_Porteria"
if (Test-Path $BuildDir) { Remove-Item -Recurse -Force $BuildDir }
if (Test-Path $OldFolder) { Remove-Item -Recurse -Force $OldFolder }
$OldExe = Join-Path $DistRoot "SmartCSET_Porteria.exe"
if (Test-Path $OldExe) { Remove-Item -Force $OldExe }

Write-Host "PyInstaller (onefile, sin consola)..."
Push-Location $Root
try {
    & $VenvPython -m PyInstaller --noconfirm --clean --distpath $DistRoot --workpath $BuildDir $Spec
    if ($LASTEXITCODE -ne 0) { throw "PyInstaller fallo con codigo $LASTEXITCODE" }
} finally {
    Pop-Location
}

$ExePath = Join-Path $DistRoot "SmartCSET_Porteria.exe"
if (-not (Test-Path $ExePath)) {
    throw "No se genero SmartCSET_Porteria.exe"
}

Write-Host ""
Write-Host "LISTO (archivo unico):"
Write-Host "  $ExePath"
Write-Host "  base_url embebida = https://10.5.213.111/smartcset"
Write-Host "Copia solo ese .exe al PC de porteria."
