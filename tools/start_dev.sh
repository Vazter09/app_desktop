#!/usr/bin/env bash
# Servidor PHP integrado (desarrollo). No requiere Apache.
# Uso: bash tools/start_dev.sh
# Abrir: http://localhost:8080/  o  http://smartcset.local:8080/ (con 127.0.0.1 smartcset.local en /etc/hosts)
#
# Si Apache (httpd) ya usa el puerto 8080, deténgalo antes:
#   brew services stop httpd

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${SMARTCSET_DEV_PORT:-8080}"

if lsof -i ":${PORT}" -sTCP:LISTEN -t >/dev/null 2>&1; then
  echo "Puerto ${PORT} en uso. Opciones:"
  echo "  brew services stop httpd"
  echo "  SMARTCSET_DEV_PORT=8081 bash tools/start_dev.sh"
  lsof -i ":${PORT}" -sTCP:LISTEN 2>/dev/null || true
  exit 1
fi

echo "SmartCSET → http://127.0.0.1:${PORT}/ (Ctrl+C para detener)"
exec php -S "127.0.0.1:${PORT}" -t "$ROOT"
