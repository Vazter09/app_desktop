#!/usr/bin/env bash
# Aplica solo migración de tab_config_sistema (instalaciones existentes).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/../.env"

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
[[ -n "$PSQL" ]] || { echo "psql no encontrado." >&2; exit 1; }

run() { echo "==> $(basename "$1")"; "$PSQL" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f "$1"; }

run "$ROOT/migrations/add_tab_config_sistema.sql"
run "$ROOT/functions/config/fun_update_tab_config_sistema.sql"
run "$ROOT/migrations/add_menu_config_y_registro.sql"

if command -v php >/dev/null 2>&1; then
  hash_reg="$(php -r "echo password_hash('usuariocset', PASSWORD_BCRYPT);")"
  "$PSQL" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    -c "UPDATE tab_config_sistema SET pass_registro_hash = '$hash_reg' WHERE id_config = 1 AND (pass_registro_hash IS NULL OR pass_registro_hash = '');"
fi

unset PGPASSWORD
echo "Listo: tab_config_sistema + menús 0205 y 03xx."
