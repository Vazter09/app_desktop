# Servidor de desarrollo PHP (no requiere pdo_pgsql en Apache)
# Uso: .\tools\start_dev.ps1
# Abrir: http://localhost:8080/

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Write-Host "SMARTCSET en http://localhost:8080/ (Ctrl+C para detener)"
& C:\php\php.exe -S localhost:8080 -t $root
