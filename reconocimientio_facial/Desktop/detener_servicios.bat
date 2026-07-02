@echo off
chcp 65001 >nul
title Detener Servicios - Sistema de Reconocimiento Biométrico

echo ========================================
echo Detener Servicios
echo Sistema de Reconocimiento Biométrico Multimodal
echo ========================================
echo.

:: Detener motor biométrico
echo [INFO] Deteniendo motor biométrico...
taskkill /FI "WINDOWTITLE eq Motor Biométrico*" /F >nul 2>&1
if errorlevel 1 (
    echo [ADVERTENCIA] No se encontró el motor biométrico ejecutándose.
) else (
    echo [OK] Motor biométrico detenido.
)

:: Verificar procesos en puerto del motor
echo [INFO] Verificando procesos en puertos...
netstat -an | findstr :5000 >nul
if not errorlevel 1 (
    echo [ADVERTENCIA] Aún hay procesos ejecutándose en el puerto 5000.
    echo [INFO] Puede ser necesario cerrar manualmente estos procesos.
)

echo.
echo [INFO] Servicios detenidos.
echo [INFO] Presione cualquier tecla para salir...
pause >nul
