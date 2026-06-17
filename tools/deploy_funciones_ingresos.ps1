# Despliega funciones SQL del módulo registro de ingresos (portería).
# Uso: .\tools\deploy_funciones_ingresos.ps1
# Nota: preferir deploy_funciones_acceso.ps1 (ingreso + salida).

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
    'fun_registrar_ingreso_manual.sql'
)

$env:PGPASSWORD = $DB_PASS
$functionsDir = Join-Path $root 'database\functions\porteria'
$failed = @()

foreach ($name in $files) {
    $path = Join-Path $functionsDir $name
    Write-Host "==> $name" -ForegroundColor Cyan
    & $psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1 -f $path
    if ($LASTEXITCODE -ne 0) { $failed += $name }
}

# Secuencia e índice de unicidad (una persona / día)
Write-Host '==> seq_log_ingresos' -ForegroundColor Cyan
& $psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "CREATE SEQUENCE IF NOT EXISTS seq_log_ingresos START WITH 1 INCREMENT BY 1;"
if ($LASTEXITCODE -ne 0) { $failed += 'seq_log_ingresos' }

$migration = Join-Path $root 'database\migrations\add_unique_ingreso_persona_dia.sql'
if (Test-Path $migration) {
    Write-Host '==> add_unique_ingreso_persona_dia.sql' -ForegroundColor Cyan
    & $psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1 -f $migration
    if ($LASTEXITCODE -ne 0) { $failed += 'add_unique_ingreso_persona_dia.sql' }
}

Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue

if ($failed.Count -gt 0) {
    Write-Host "Fallaron: $($failed -join ', ')" -ForegroundColor Red
    exit 1
}

Write-Host 'Funciones de ingresos desplegadas. Para salida use: .\tools\deploy_funciones_acceso.ps1' -ForegroundColor Yellow
