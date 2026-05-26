# Instalación inicial de BD SMARTCSET (Windows / PostgreSQL)
# Uso: .\tools\setup_db.ps1
# Lee DB_* desde .env en la raíz del proyecto

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
if (-not (Test-Path $psql)) { throw "No se encontró psql en $psql" }

$env:PGPASSWORD = $DB_PASS
Write-Host "Creando base de datos $DB_NAME ..."
& $psql -h $DB_HOST -U $DB_USER -d postgres -c "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" -tA | Out-Null
$exists = & $psql -h $DB_HOST -U $DB_USER -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'"
if (-not $exists) {
    & $psql -h $DB_HOST -U $DB_USER -d postgres -c "CREATE DATABASE $DB_NAME ENCODING 'UTF8' TEMPLATE template0"
}

Write-Host "Ejecutando esquema V.1.5 ..."
& $psql -h $DB_HOST -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1 -f (Join-Path $root 'database\schema\script_BD_SMARTCSET V.1.5.sql')

& $psql -h $DB_HOST -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1 -f (Join-Path $root 'database\migrations\add_tab_sesiones.sql')

& $psql -h $DB_HOST -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1 -f (Join-Path $root 'database\functions\_helpers\smartcset_raise.sql')

Write-Host "Cargando funciones de acceso (obligatorias) ..."
$funcionesObligatorias = @(
    'database\functions\acceso\usuarios\fun_insert_tab_usuarios.sql',
    'database\functions\acceso\usuarios\fun_update_tab_usuarios.sql',
    'database\functions\acceso\usuarios\fun_actualizar_password.sql',
    'database\functions\acceso\menus\fun_insert_tab_menus.sql',
    'database\functions\acceso\menus\fun_update_tab_menus.sql',
    'database\functions\acceso\menus\fun_delete_tab_menus.sql',
    'database\functions\acceso\menus\fun_insert_menu_usuarios.sql',
    'database\functions\acceso\menus\fun_delete_perfil_usuario.sql',
    'database\functions\acceso\sesiones\fun_registrar_sesion.sql'
)
foreach ($rel in $funcionesObligatorias) {
    $path = Join-Path $root $rel
    & $psql -h $DB_HOST -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1 -f $path
}

& (Join-Path $root 'tools\deploy_funciones_acceso.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Falló deploy_funciones_acceso.ps1' }

Write-Host "Datos de desarrollo ..."
& $psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f (Join-Path $root 'database\seeds\seed_acceso_dev.sql')
& $psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f (Join-Path $root 'database\seeds\seed_menus_admin.sql')

$hash = & C:\php\php.exe -r "echo password_hash('AdminSmart2026!', PASSWORD_BCRYPT);"
& $psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "UPDATE tab_usuarios SET pass_usuario = '$hash' WHERE id_usuario = 'admin.smart';"

Write-Host "Listo. Usuario: admin.smart / AdminSmart2026!"
Write-Host "URL: http://localhost/smartcset/"
