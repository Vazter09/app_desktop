# Despliega funciones SQL del módulo acceso portería (ingreso + salida).
# Uso: .\tools\deploy_funciones_acceso.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$envFile = Join-Path $root '.env'
if (-not (Test-Path $envFile)) { throw "No existe .env en $root" }

Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#=]+)=(.*)$') {
        Set-Variable -Name $matches[1].Trim() -Value $matches[2].Trim() -Scope Script
    }
}

$psql = 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
if (-not (Test-Path $psql)) {
    $cmd = Get-Command psql -ErrorAction SilentlyContinue
    if ($cmd) { $psql = $cmd.Source } else { throw 'No se encontró psql.' }
}

$files = @(
    'fun_upsert_persona_visitante.sql',
    'fun_insert_log_ingreso.sql',
    'fun_update_persona_tras_ingreso.sql',
    'fun_registrar_ingreso_manual.sql',
    'fun_update_log_salida.sql',
    'fun_update_persona_tras_salida.sql',
    'fun_registrar_salida_manual.sql'
)

$env:PGPASSWORD = $DB_PASS
$helpersSql = Join-Path $root 'database\functions\_helpers\smartcset_raise.sql'
if (Test-Path $helpersSql) {
    Write-Host '==> smartcset_raise.sql' -ForegroundColor Cyan
    & $psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1 -f $helpersSql
    if ($LASTEXITCODE -ne 0) { throw 'Falló smartcset_raise.sql' }
}

$functionsDir = Join-Path $root 'database\functions\porteria'
$migrationsDir = Join-Path $root 'database\migrations'
$failed = @()

foreach ($name in $files) {
    $path = Join-Path $functionsDir $name
    Write-Host "==> $name" -ForegroundColor Cyan
    & $psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1 -f $path
    if ($LASTEXITCODE -ne 0) { $failed += $name }
}

Write-Host '==> seq_log_ingresos' -ForegroundColor Cyan
& $psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "CREATE SEQUENCE IF NOT EXISTS seq_log_ingresos START WITH 1 INCREMENT BY 1;"
if ($LASTEXITCODE -ne 0) { $failed += 'seq_log_ingresos' }

foreach ($mig in @('refactor_ingreso_abierto_salida.sql', 'add_menu_registro_salida_0103.sql')) {
    $path = Join-Path $migrationsDir $mig
    if (Test-Path $path) {
        Write-Host "==> $mig" -ForegroundColor Cyan
        & $psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1 -f $path
        if ($LASTEXITCODE -ne 0) { $failed += $mig }
    }
}

Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue

if ($failed.Count -gt 0) {
    Write-Host "Fallaron: $($failed -join ', ')" -ForegroundColor Red
    exit 1
}

Write-Host 'Funciones de acceso (ingreso/salida) desplegadas correctamente.' -ForegroundColor Green
