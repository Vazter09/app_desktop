#!/usr/bin/env bash
# Descarga Swagger UI para docs offline (sin depender del CDN).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DEST="$ROOT/frontend/web/public/docs/vendor"
VER="5.17.14"
BASE="https://cdn.jsdelivr.net/npm/swagger-ui-dist@${VER}"

mkdir -p "$DEST"
curl -fsSL "$BASE/swagger-ui.css" -o "$DEST/swagger-ui.css"
curl -fsSL "$BASE/swagger-ui-bundle.js" -o "$DEST/swagger-ui-bundle.js"
curl -fsSL "$BASE/swagger-ui-standalone-preset.js" -o "$DEST/swagger-ui-standalone-preset.js"
echo "Swagger UI ${VER} instalado en frontend/web/public/docs/vendor/"
