# AGENTS.md — Backend SmartCSET

## Capa

HTTP → services → PostgreSQL (`database/functions/`).

## Contratos

- `backend/core/prepare.php` — PDO, `$stmt_*`, sesión.
- `backend/routers/{modulo}/v1/*.php` — JSON `{ ok, data, error }`; logout GET es excepción.
- `backend/services/` — orquestación sin `$_POST` ni HTML.
- `backend/middleware/` — guards reutilizables.

## Portería

Routers unificados web + móvil en `backend/routers/porteria/v1/` con `require_session_or_device.php`.

## OpenAPI

- Spec base: `backend/openapi/openapi.base.json` (info, tags, securitySchemes, schemas compartidos).
- Cada router en `backend/routers/**/v1/` debe incluir docblock `@openapi { ... }` con metadatos JSON.
- Regenerar: `php scripts/tools/generate_openapi.php` (escribe `backend/openapi/openapi.yaml` y copia a `frontend/web/public/docs/openapi.yaml`).
- Validar sincronización: `php scripts/tools/generate_openapi.php --check`.
- Swagger UI (dev): `http://localhost:8080/docs/`.

El generador infiere automáticamente path (`/routers/...`), método HTTP y auth desde los `require_*` del router. Sobrescribir en el JSON cuando el endpoint sea excepcional (redirect, multipart, auth dual).
