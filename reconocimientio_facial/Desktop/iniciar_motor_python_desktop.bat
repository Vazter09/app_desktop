@echo off
chcp 65001 >nul
title Motor Biométrico Desktop - Reconocimiento Facial

echo ========================================
echo Motor Biométrico Desktop
echo Sistema de Reconocimiento Biométrico Multimodal
echo ========================================
echo.

:: Verificar si Python está instalado
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python no encontrado en el PATH del sistema.
    echo Por favor, instale Python 3.11+ y agréguelo al PATH.
    echo.
    pause
    exit /b 1
)

:: Verificar si pip está instalado
pip --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] pip no encontrado.
    echo Por favor, instale pip: python -m ensurepip --upgrade
    echo.
    pause
    exit /b 1
)

:: Verificar e instalar dependencias
echo [INFO] Verificando dependencias...
if exist "requirements_desktop.txt" (
    echo [INFO] Instalando dependencias desde requirements_desktop.txt...
    pip install -r requirements_desktop.txt
    if errorlevel 1 (
        echo [ERROR] Error al instalar dependencias.
        pause
        exit /b 1
    )
)

:: Verificar si el motor ya está ejecutándose
netstat -an | findstr :5000 >nul
if not errorlevel 1 (
    echo [ADVERTENCIA] El motor biométrico ya está ejecutándose en el puerto 5000.
    echo [INFO] Presione Ctrl+C para detener el motor actual.
    echo.
)

:: Configurar variables de entorno para modo desktop
:: IMPORTANTE: cambiar BIOMETRIA_API_KEY a un valor real generado en este PC
:: (debe coincidir con la que use app_desktop.py, ver BIOMETRIA_API_KEY en el
:: entorno o en config_desktop.py). NUNCA dejar el valor por defecto.
set BIOMETRIA_HOST=127.0.0.1
set BIOMETRIA_PORT=5000
if "%BIOMETRIA_API_KEY%"=="" set BIOMETRIA_API_KEY=cambiar-api-key-segura
set BIOMETRIA_TEMP_DIR=%TEMP%\biometria_temp_desktop
set BIOMETRIA_LOG_LEVEL=INFO
set BIOMETRIA_MODEL=Facenet512
set BIOMETRIA_CALIDAD_MINIMA=50.0
set BIOMETRIA_LOG_DIR=%CD%\logs
set BIOMETRIA_DATA_DIR=%CD%\data

:: Crear directorios necesarios
if not exist "%BIOMETRIA_TEMP_DIR%" mkdir "%BIOMETRIA_TEMP_DIR%"
if not exist "%BIOMETRIA_LOG_DIR%" mkdir "%BIOMETRIA_LOG_DIR%"
if not exist "%BIOMETRIA_DATA_DIR%" mkdir "%BIOMETRIA_DATA_DIR%"

:: Iniciar motor biométrico en modo desktop
echo [INFO] Iniciando motor biométrico en modo desktop...
echo [INFO] Host: %BIOMETRIA_HOST%
echo [INFO] Puerto: %BIOMETRIA_PORT%
echo [INFO] Modelo: %BIOMETRIA_MODEL%
echo [INFO] Directorio temporal: %BIOMETRIA_TEMP_DIR%
echo [INFO] Directorio de logs: %BIOMETRIA_LOG_DIR%
echo [INFO] Presione Ctrl+C para detener el motor.
echo.

python motor_biometrico_desktop.py

if errorlevel 1 (
    echo.
    echo [ERROR] El motor biométrico se detuvo con errores.
    echo [INFO] Verifique los logs en: %BIOMETRIA_LOG_DIR%
)

pause
