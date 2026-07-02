#!/usr/bin/env bash
# Smoke test de routers JSON principales (requiere servidor en :8080)
set -euo pipefail
BASE="${1:-http://localhost:8080}"

curl -sf "$BASE/routers/porteria/v1/health.php" | grep -q '"ok":true' && echo "OK health"
curl -sf -o /dev/null -w "%{http_code}" "$BASE/index.php" | grep -q 200 && echo "OK login page"
curl -sf -o /dev/null -w "%{http_code}" "$BASE/pages/admin/parametros.php" | grep -qE '^(200|302)$' && echo "OK parametros page"

php "$(dirname "$0")/../tools/generate_openapi.php" --check && echo "OK openapi spec"
curl -sf "$BASE/docs/openapi.yaml" | grep -q 'openapi:' && echo "OK openapi public"

echo "Smoke básico completado."
