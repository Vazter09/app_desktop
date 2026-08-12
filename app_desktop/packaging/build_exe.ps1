# Build del ejecutable de portería (solo app_desktop).
# Uso (desde app_desktop):
#   powershell -ExecutionPolicy Bypass -File packaging\build_exe.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Src = Join-Path $Root "src"
$Runtime = Join-Path $Root "runtime"
$Pack = $PSScriptRoot
$VenvPython = Join-Path $Runtime ".venv\Scripts\python.exe"
$Spec = Join-Path $Pack "SmartCSET_Porteria.spec"
$DistDir = Join-Path $Root "dist\SmartCSET_Porteria"
$ConfigSrc = Join-Path $Pack "app_config.porteria.json"
$MakeIcon = Join-Path $Pack "make_icon.py"
$Requirements = Join-Path $Root "requirements.txt"

Write-Host "== SmartCSET Porteria - build .exe =="
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
Write-Host "  base_url = https://10.5.213.111/smartcset"
Write-Host ""
Write-Host "Copia TODA la carpeta dist\SmartCSET_Porteria al PC de porteria."
