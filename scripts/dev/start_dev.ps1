# PowerShell — servidor de desarrollo (document root: frontend/web/public)
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$public = Join-Path $root "frontend\web\public"
$router = Join-Path $public "router.php"
$php = if (Get-Command php -ErrorAction SilentlyContinue) { "php" } else { "C:\php\php.exe" }
Write-Host "SmartCSET → http://localhost:8080/ (Ctrl+C para detener)"
& $php -S localhost:8080 -t $public $router
