@echo off
chcp 65001 >nul
title Generando Ejecutable - Reconocimiento Biométrico

echo ========================================
echo Generando Ejecutable Desktop
echo Sistema de Reconocimiento Biométrico
echo ========================================
echo.

:: Verificar Python
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python no encontrado.
    pause
    exit /b 1
)

echo [INFO] Verificando e instalando dependencias...
pip install Pillow opencv-python pyinstaller >nul 2>&1

echo [INFO] Generando ejecutable...
echo.

pyinstaller ^
    --name "ReconocimientoBiometrico" ^
    --onefile ^
    --windowed ^
    --noconfirm ^
    --clean ^
    --hidden-import "PIL" ^
    --hidden-import "PIL._tkinter_finder" ^
    --hidden-import "cv2" ^
    --hidden-import "numpy" ^
    app_desktop.py

if errorlevel 1 (
    echo.
    echo [ERROR] Error al generar el ejecutable.
    pause
    exit /b 1
)

echo.
echo ========================================
echo EJECUTABLE GENERADO EXITOSAMENTE
echo ========================================
echo.
echo Ubicación: dist\ReconocimientoBiometrico.exe
echo.
echo Para usar:
echo   1. Copiar dist\ReconocimientoBiometrico.exe al directorio del proyecto
echo   2. Tener el motor biometrico corriendo localmente (iniciar_motor_python_desktop.bat)
echo   3. Ejecutar ReconocimientoBiometrico.exe (pedira URL de SmartCSET + token de dispositivo)
echo.

if exist "dist\ReconocimientoBiometrico.exe" (
    echo Copiando ejecutable al directorio del proyecto...
    copy "dist\ReconocimientoBiometrico.exe" "." >nul 2>&1
    echo [OK] Ejecutable copiado: ReconocimientoBiometrico.exe
)

pause
