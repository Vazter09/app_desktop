#!/usr/bin/env bash
# Despliega funciones PL/pgSQL mínimas: login (sesiones), menús y usuario admin.
# La BD y tablas deben existir ya (p. ej. schema V.1.7 aplicado antes).
# Uso: bash tools/setup_db.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"

[[ -f "$ENV_FILE" ]] || { echo "No existe .env en $ROOT" >&2; exit 1; }

read_env() {
  local key="$1" default="$2"
  if grep -q "^${key}=" "$ENV_FILE"; then
    grep "^${key}=" "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
  else
    echo "$default"
  fi
}

DB_HOST="$(read_env DB_HOST localhost)"
DB_PORT="$(read_env DB_PORT 5432)"
DB_NAME="$(read_env DB_NAME db_smartcset)"
DB_USER="$(read_env DB_USER postgres)"
DB_PASS="$(read_env DB_PASS postgres)"
export PGPASSWORD="$DB_PASS"

PSQL=""
for candidate in \
  "/Library/PostgreSQL/18/bin/psql" \
  "/opt/homebrew/opt/libpq/bin/psql" \
  "$(command -v psql 2>/dev/null || true)"
do
  [[ -n "$candidate" && -x "$candidate" ]] && PSQL="$candidate" && break
done
[[ -n "$PSQL" ]] || { echo "psql no encontrado. Instale PostgreSQL o libpq." >&2; exit 1; }

run_sql() {
  local f="$1"
  echo "==> $(basename "$f")"
  "$PSQL" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f "$f"
}

echo "==> Base de datos existente: $DB_NAME"

run_sql "$ROOT/database/functions/_helpers/smartcset_raise.sql"

echo "==> Sesiones (auditoría)"
run_sql "$ROOT/database/migrations/alter_tab_sesiones_auditoria.sql"
run_sql "$ROOT/database/functions/acceso/sesiones/fun_ingreso_sesion.sql"
run_sql "$ROOT/database/functions/acceso/sesiones/fun_salida_sesion.sql"
run_sql "$ROOT/database/functions/acceso/sesiones/fun_actualizar_sesion_actividad.sql"
run_sql "$ROOT/database/migrations/drop_fun_sesiones_table_returns.sql"
run_sql "$ROOT/database/functions/acceso/sesiones/fun_validar_sesion_activa.sql"
run_sql "$ROOT/database/functions/acceso/sesiones/fun_archivar_sesiones_antiguas.sql"
run_sql "$ROOT/database/migrations/drop_fun_registrar_sesion.sql"
run_sql "$ROOT/database/migrations/add_menu_sesiones_0206.sql"

echo "==> Menús"
run_sql "$ROOT/database/functions/acceso/menus/fun_insert_tab_menus.sql"
run_sql "$ROOT/database/functions/acceso/menus/fun_update_tab_menus.sql"
run_sql "$ROOT/database/functions/acceso/menus/fun_delete_tab_menus.sql"
run_sql "$ROOT/database/functions/acceso/menus/fun_insert_menu_usuarios.sql"
run_sql "$ROOT/database/functions/acceso/menus/fun_delete_perfil_usuario.sql"

echo "==> Usuarios (admin)"
run_sql "$ROOT/database/functions/acceso/usuarios/fun_insert_tab_usuarios.sql"
run_sql "$ROOT/database/functions/acceso/usuarios/fun_update_tab_usuarios.sql"
run_sql "$ROOT/database/functions/acceso/usuarios/fun_actualizar_password.sql"

if ! command -v php >/dev/null 2>&1; then
  echo "    ERROR: php es necesario para hashear la contraseña de admin.smart." >&2
  exit 1
fi

hash="$(php -r "echo password_hash('AdminSmart2026!', PASSWORD_BCRYPT);")"

echo "==> Usuario admin.smart (antes de permisos de menú)"
"$PSQL" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 <<SQL
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
SQL

echo "==> Menús y permisos admin.smart"
run_sql "$ROOT/database/migrations/update_menu_padre_raiz_00.sql"
run_sql "$ROOT/database/seeds/seed_menus_admin.sql"

unset PGPASSWORD
echo ""
echo "Listo. Funciones desplegadas en: $DB_NAME"
echo "Login: admin.smart / AdminSmart2026!"
