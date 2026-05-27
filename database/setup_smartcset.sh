#!/usr/bin/env bash
# Instala db_smartcset y aplica script-BD-SMARTCSET V.1.6.sql + funciones/seeds
# Uso: ./database/setup_smartcset.sh
# ATENCIÓN: Si la BD ya existe, el paso de esquema BORRA todas las tablas (DROP).
#           Solo usar en instalación nueva o cuando quiera resetear por completo.

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"

read_env() {
  local key="$1" default="$2"
  if [[ -f "$ENV_FILE" ]] && grep -q "^${key}=" "$ENV_FILE"; then
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
[[ -n "$PSQL" ]] || { echo "psql no encontrado. Instale PostgreSQL." >&2; exit 1; }

SCHEMA="$ROOT/database/schema/script-BD-SMARTCSET V.1.6.sql"
[[ -f "$SCHEMA" ]] || { echo "No existe: $SCHEMA" >&2; exit 1; }

echo "==> Base de datos $DB_NAME"
exists="$("$PSQL" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc \
  "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'")"
if [[ "$exists" != "1" ]]; then
  "$PSQL" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres \
    -c "CREATE DATABASE $DB_NAME WITH ENCODING 'UTF8' TEMPLATE template0;"
else
  echo "    Ya existe."
fi

echo "==> Esquema V.1.6"
"$PSQL" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f "$SCHEMA"

run_sql() {
  local f="$1"
  echo "==> $(basename "$f")"
  "$PSQL" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f "$f"
}

echo "==> Migración tab_sesiones"
run_sql "$ROOT/database/migrations/add_tab_sesiones.sql"

echo "==> Helpers de excepciones"
run_sql "$ROOT/database/functions/_helpers/smartcset_raise.sql"

if [[ -f "$ROOT/database/migrations/drop_functions_void_return.sql" ]]; then
  run_sql "$ROOT/database/migrations/drop_functions_void_return.sql"
fi

FUNCS=(
  "$ROOT/database/functions/acceso/usuarios/fun_insert_tab_usuarios.sql"
  "$ROOT/database/functions/acceso/usuarios/fun_update_tab_usuarios.sql"
  "$ROOT/database/functions/acceso/usuarios/fun_actualizar_password.sql"
  "$ROOT/database/functions/acceso/menus/fun_insert_tab_menus.sql"
  "$ROOT/database/functions/acceso/menus/fun_update_tab_menus.sql"
  "$ROOT/database/functions/acceso/menus/fun_trigger_menu.sql"
  "$ROOT/database/functions/acceso/menus/fun_trigger_menu_admin.sql"
  "$ROOT/database/functions/acceso/menus/fun_trigger_desasignar_menu.sql"
  "$ROOT/database/functions/acceso/menus/fun_delete_tab_menus.sql"
  "$ROOT/database/functions/acceso/menus/fun_insert_menu_usuarios.sql"
  "$ROOT/database/functions/acceso/menus/fun_delete_perfil_usuario.sql"
  "$ROOT/database/functions/acceso/sesiones/fun_registrar_sesion.sql"
  "$ROOT/database/functions/porteria/fun_upsert_persona_visitante.sql"
  "$ROOT/database/functions/porteria/fun_insert_log_ingreso.sql"
  "$ROOT/database/functions/porteria/fun_update_persona_tras_ingreso.sql"
  "$ROOT/database/functions/porteria/fun_registrar_ingreso_manual.sql"
  "$ROOT/database/functions/porteria/fun_update_log_salida.sql"
  "$ROOT/database/functions/porteria/fun_update_persona_tras_salida.sql"
  "$ROOT/database/functions/porteria/fun_registrar_salida_manual.sql"
  "$ROOT/database/functions/config/fun_update_tab_config_sistema.sql"
)
for f in "${FUNCS[@]}"; do
  run_sql "$f"
done
"$PSQL" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
  -c "CREATE SEQUENCE IF NOT EXISTS seq_log_ingresos START WITH 1 INCREMENT BY 1;"

for f in \
  "$ROOT/database/seeds/seed_acceso_dev.sql" \
  "$ROOT/database/seeds/seed_menus_admin.sql" \
  "$ROOT/database/migrations/add_menu_accesos_0203_0204.sql" \
  "$ROOT/database/migrations/sync_admin_menu_access.sql" \
  "$ROOT/database/migrations/update_nom_programa_subfolders.sql" \
  "$ROOT/database/migrations/add_menu_registro_ingreso_0102.sql" \
  "$ROOT/database/migrations/refactor_ingreso_abierto_salida.sql" \
  "$ROOT/database/migrations/add_menu_registro_salida_0103.sql" \
  "$ROOT/database/migrations/add_tab_config_sistema.sql" \
  "$ROOT/database/migrations/add_menu_config_y_registro.sql" \
  "$ROOT/database/migrations/update_modulos_rutas_organizadas.sql" \
  "$ROOT/database/migrations/update_menu_registro_listado_admin.sql" \
  "$ROOT/database/migrations/add_unique_ingreso_persona_dia.sql"
do
  [[ -f "$f" ]] && run_sql "$f"
done

if command -v php >/dev/null 2>&1; then
  hash="$(php -r "echo password_hash('AdminSmart2026!', PASSWORD_BCRYPT);")"
  "$PSQL" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    -c "UPDATE tab_usuarios SET pass_usuario = '$hash' WHERE id_usuario = 'admin.smart';"
  hash2="$(php -r "echo password_hash('Porteria2026!', PASSWORD_BCRYPT);")"
  "$PSQL" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    -c "UPDATE tab_usuarios SET pass_usuario = '$hash2' WHERE id_usuario = 'porteria';"
  hash_reg="$(php -r "echo password_hash('usuariocset', PASSWORD_BCRYPT);")"
  "$PSQL" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    -c "UPDATE tab_config_sistema SET pass_registro_hash = '$hash_reg' WHERE id_config = 1 AND pass_registro_hash IS NULL;"
fi

unset PGPASSWORD
echo ""
echo "Listo. Base: $DB_NAME | Esquema V.1.6"
echo "Login: admin.smart / AdminSmart2026! | porteria / Porteria2026!"
