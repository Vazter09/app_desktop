# Despliega funciones PL/pgSQL mínimas: login (sesiones), menús y usuario admin.
# La BD y tablas deben existir ya. Uso: .\tools\setup_db.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$envFile = Join-Path $root '.env'
if (-not (Test-Path $envFile)) { throw "No existe .env en $root" }

Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#=]+)=(.*)$') {
        Set-Variable -Name $matches[1].Trim() -Value $matches[2].Trim() -Scope Script
    }
}
if (-not $DB_PORT) { $DB_PORT = '5432' }

$psql = 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
if (-not (Test-Path $psql)) {
    $cmd = Get-Command psql -ErrorAction SilentlyContinue
    if ($cmd) { $psql = $cmd.Source } else { throw 'No se encontró psql.' }
}

$env:PGPASSWORD = $DB_PASS
$dbArgs = @('-h', $DB_HOST, '-p', $DB_PORT, '-U', $DB_USER, '-d', $DB_NAME, '-v', 'ON_ERROR_STOP=1')

function Invoke-SqlFile([string]$relPath) {
    $path = Join-Path $root ($relPath -replace '/', '\')
    Write-Host "==> $(Split-Path -Leaf $path)" -ForegroundColor Cyan
    & $psql @dbArgs -f $path
    if ($LASTEXITCODE -ne 0) { throw "Falló: $relPath" }
}

Write-Host "==> Base de datos existente: $DB_NAME" -ForegroundColor Cyan

Invoke-SqlFile 'database/functions/_helpers/smartcset_raise.sql'

Write-Host '==> Sesiones (login)' -ForegroundColor Cyan
@(
    'database/functions/acceso/sesiones/fun_ingreso_sesion.sql',
    'database/functions/acceso/sesiones/fun_salida_sesion.sql',
    'database/functions/acceso/sesiones/fun_actualizar_sesion_actividad.sql',
    'database/migrations/drop_fun_registrar_sesion.sql'
) | ForEach-Object { Invoke-SqlFile $_ }

Write-Host '==> Menús' -ForegroundColor Cyan
@(
    'database/functions/acceso/menus/fun_insert_tab_menus.sql',
    'database/functions/acceso/menus/fun_update_tab_menus.sql',
    'database/functions/acceso/menus/fun_delete_tab_menus.sql',
    'database/functions/acceso/menus/fun_insert_menu_usuarios.sql',
    'database/functions/acceso/menus/fun_delete_perfil_usuario.sql'
) | ForEach-Object { Invoke-SqlFile $_ }

Write-Host '==> Usuarios (admin)' -ForegroundColor Cyan
@(
    'database/functions/acceso/usuarios/fun_insert_tab_usuarios.sql',
    'database/functions/acceso/usuarios/fun_update_tab_usuarios.sql',
    'database/functions/acceso/usuarios/fun_actualizar_password.sql'
) | ForEach-Object { Invoke-SqlFile $_ }

Write-Host '==> Menús y permisos admin.smart' -ForegroundColor Cyan
Invoke-SqlFile 'database/seeds/seed_menus_admin.sql'

$php = 'C:\php\php.exe'
if (-not (Test-Path $php)) {
    $phpCmd = Get-Command php -ErrorAction SilentlyContinue
    if ($phpCmd) { $php = $phpCmd.Source }
}
if (-not (Test-Path $php)) { throw 'php es necesario para hashear la contraseña de admin.smart.' }

$hash = & $php -r "echo password_hash('AdminSmart2026!', PASSWORD_BCRYPT);"

Write-Host '==> Usuario admin.smart' -ForegroundColor Cyan
$sqlAdmin = @"
INSERT INTO tab_usuarios (
    id_usuario, nom_usuario, pass_usuario, mail_usuario,
    ind_usuario, ind_estado, usr_insert, fec_insert
) VALUES (
    'admin.smart',
    'Administrador SMARTCSET',
    '$hash',
    'admin@cset.sena.edu.co',
    TRUE,
    TRUE,
    'setup_db',
    NOW()
) ON CONFLICT (id_usuario) DO UPDATE SET
    pass_usuario = EXCLUDED.pass_usuario,
    ind_usuario = TRUE,
    ind_estado = TRUE;
"@
& $psql @dbArgs -c $sqlAdmin

Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
Write-Host ''
Write-Host "Listo. Funciones desplegadas en: $DB_NAME" -ForegroundColor Green
Write-Host 'Login: admin.smart / AdminSmart2026!'
