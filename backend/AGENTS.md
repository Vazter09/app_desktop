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
