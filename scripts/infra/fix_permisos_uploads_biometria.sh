#!/usr/bin/env bash
# Ajusta permisos de uploads/biometria en el servidor (Apache/PHP-FPM).
# Uso (en 10.5.213.103, como root o con sudo):
#   bash scripts/infra/fix_permisos_uploads_biometria.sh
set -euo pipefail

BASE="${BIOMETRIA_UPLOAD_BASE:-/var/www/html/smartcset/frontend/web/public/uploads/biometria}"
OWNER="${BIOMETRIA_UPLOAD_OWNER:-www-data}"
GROUP="${BIOMETRIA_UPLOAD_GROUP:-www-data}"

echo "==> Base: $BASE"
echo "==> Owner: $OWNER:$GROUP"

mkdir -p "$BASE"
chown -R "$OWNER:$GROUP" "$BASE"
find "$BASE" -type d -exec chmod 775 {} \;
find "$BASE" -type f -exec chmod 664 {} \;

# Conservar .htaccess / .gitignore si existen
if [[ -f "$BASE/.htaccess" ]]; then
  chown "$OWNER:$GROUP" "$BASE/.htaccess"
  chmod 644 "$BASE/.htaccess"
fi
if [[ -f "$BASE/.gitignore" ]]; then
  chown "$OWNER:$GROUP" "$BASE/.gitignore"
  chmod 644 "$BASE/.gitignore"
fi

echo "==> Verificando escritura como $OWNER..."
if sudo -u "$OWNER" test -w "$BASE"; then
  echo "OK_writable"
else
  echo "FAIL: $OWNER no puede escribir en $BASE" >&2
  exit 1
fi

TEST_FILE="$BASE/.write_test_$$"
if sudo -u "$OWNER" touch "$TEST_FILE"; then
  sudo -u "$OWNER" rm -f "$TEST_FILE"
  echo "OK_touch"
else
  echo "FAIL: no se pudo crear archivo de prueba" >&2
  exit 1
fi

echo "Permisos de uploads/biometria listos."
