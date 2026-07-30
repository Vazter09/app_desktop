# Build del ejecutable de portería (solo app_desktop).
# Uso (desde app_desktop):
#   powershell -ExecutionPolicy Bypass -File packaging\build_exe.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$App = Join-Path $Root "app"
$Pack = $PSScriptRoot
$VenvPython = Join-Path $App ".venv\Scripts\python.exe"
$Spec = Join-Path $Pack "SmartCSET_Porteria.spec"
$DistDir = Join-Path $Root "dist\SmartCSET_Porteria"
$ConfigSrc = Join-Path $Pack "app_config.porteria.json"
$MakeIcon = Join-Path $Pack "make_icon.py"

Write-Host "== SmartCSET Porteria - build .exe =="
Write-Host "Root: $Root"

if (-not (Test-Path $VenvPython)) {
    Write-Host "Creando .venv e instalando requirements..."
    & py -3 -m venv (Join-Path $App ".venv")
    & (Join-Path $App ".venv\Scripts\pip.exe") install -r (Join-Path $App "requirements.txt")
}

Write-Host "Instalando PyInstaller..."
& $VenvPython -m pip install --quiet "pyinstaller==6.16.0"

Write-Host "Generando icono .ico..."
& $VenvPython $MakeIcon

Write-Host "Limpiando builds previos..."
$BuildDir = Join-Path $Root "build"
$DistRoot = Join-Path $Root "dist"
if (Test-Path $BuildDir) { Remove-Item -Recurse -Force $BuildDir }
$OutFolder = Join-Path $DistRoot "SmartCSET_Porteria"
if (Test-Path $OutFolder) { Remove-Item -Recurse -Force $OutFolder }

Write-Host "PyInstaller (onedir, sin consola)..."
Push-Location $Root
try {
    & $VenvPython -m PyInstaller --noconfirm --clean --distpath $DistRoot --workpath $BuildDir $Spec
    if ($LASTEXITCODE -ne 0) { throw "PyInstaller fallo con codigo $LASTEXITCODE" }
} finally {
    Pop-Location
}

$ExePath = Join-Path $DistDir "SmartCSET_Porteria.exe"
if (-not (Test-Path $ExePath)) {
    throw "No se genero SmartCSET_Porteria.exe"
}

Copy-Item -Force $ConfigSrc (Join-Path $DistDir "app_config.json")
Write-Host ""
Write-Host "LISTO:"
Write-Host "  $ExePath"
Write-Host "  $(Join-Path $DistDir 'app_config.json')"
Write-Host "  base_url = https://10.5.213.103/smartcset"
Write-Host ""
Write-Host "Copia TODA la carpeta dist\SmartCSET_Porteria al PC de porteria."
