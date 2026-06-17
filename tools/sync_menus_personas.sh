#!/usr/bin/env bash
# Sincroniza menús Personas + grupo Configuración (admin) y permisos.
# Idempotente: ejecutar cuantas veces quieras en desarrollo.
#
# Uso:
#   bash tools/sync_menus_personas.sh
#   bash tools/sync_menus_personas.sh admin.smart
#   bash tools/sync_menus_personas.sh admin.smart otro.usuario
#
# Requiere: .env en la raíz del proyecto y psql en PATH.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"
SQL_PERSONAS="$ROOT/database/seeds/seed_menus_personas_dev.sql"
SQL_CONFIG="$ROOT/database/seeds/seed_menus_configuracion_dev.sql"

[[ -f "$ENV_FILE" ]] || {
  echo "No existe .env en $ROOT" >&2
  exit 1
}

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
[[ -n "$PSQL" ]] || {
  echo "psql no encontrado. Instale PostgreSQL o: brew install libpq" >&2
  exit 1
}

PSQL_BASE=("$PSQL" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1)

echo "==> Menús Configuración (04, 0401, 0402) → $DB_NAME @ $DB_HOST:$DB_PORT"
"${PSQL_BASE[@]}" -f "$SQL_CONFIG"

echo "==> Menús Personas (03, 0300, 0301–0304) → $DB_NAME"
"${PSQL_BASE[@]}" -f "$SQL_PERSONAS"

MENU_PERSONAS="'03','0300','0301','0302','0303','0304'"
MENU_CONFIG="'04','0401','0402'"

grant_menus() {
  local uid="$1"
  local menu_list="$2"
  local label="$3"
  if [[ -z "$uid" ]]; then
    return
  fi
  if [[ ! "$uid" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    echo "ID de usuario inválido: $uid" >&2
    exit 1
  fi
  local exists
  exists="$("${PSQL_BASE[@]}" -tAc "SELECT 1 FROM tab_usuarios WHERE id_usuario = '$uid' LIMIT 1" 2>/dev/null || true)"
  if [[ "$exists" != "1" ]]; then
    echo "    (omitido: no existe tab_usuarios.id_usuario = $uid)" >&2
    return
  fi
  echo "==> Permisos $label → $uid"
  "${PSQL_BASE[@]}" -c "
    INSERT INTO tab_menu_usuarios (id_usuario, id_menu, usr_insert, fec_insert)
    SELECT '$uid', id_menu, 'seed_personas', NOW()
    FROM tab_menus
    WHERE id_menu IN ($menu_list)
    ON CONFLICT (id_usuario, id_menu) DO NOTHING;
  "
}

if [[ $# -gt 0 ]]; then
  for uid in "$@"; do
    grant_menus "$uid" "$MENU_CONFIG" "Configuración"
    grant_menus "$uid" "$MENU_PERSONAS" "Personas"
  done
else
  grant_menus "admin.smart" "$MENU_CONFIG" "Configuración"
  grant_menus "admin.smart" "$MENU_PERSONAS" "Personas"
fi

unset PGPASSWORD

echo ""
echo "Listo."
echo "  Configuración (04)"
echo "    0401 Config. sistema  → src/admin/configuracion.php"
echo "    0402 Config. módulo   → src/admin/personas/config.php"
echo "  Personas (03)"
echo "    0301–0304 listados  → src/admin/personas/{tipo}/index.php"
echo "    0300 Panel registro → src/modulos/registro/index.php"
