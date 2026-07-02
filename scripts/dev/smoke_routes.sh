#!/usr/bin/env bash
# Smoke test de routers JSON principales (requiere servidor en :8080)
set -euo pipefail
BASE="${1:-http://localhost:8080}"

curl -sf "$BASE/routers/porteria/v1/health.php" | grep -q '"ok":true' && echo "OK health"
curl -sf -o /dev/null -w "%{http_code}" "$BASE/index.php" | grep -q 200 && echo "OK login page"

echo "Smoke básico completado."
