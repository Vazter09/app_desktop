#!/usr/bin/env bash
# Servidor de desarrollo — document root: frontend/web/public
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
PORT="${1:-8080}"
echo "SmartCSET dev: http://localhost:${PORT}/"
exec php -S "localhost:${PORT}" -t frontend/web/public frontend/web/public/router.php
