# AGENTS.md — Frontend SmartCSET

## Capa

Solo presentación: vistas PHP en `pages/`, layout HTML, assets en `public/assets/`.

## Contratos

- Vistas: `require_once` de `frontend/web/init.php` (o `pages/modulos/*/init.php`).
- Mutaciones: `fetch` vía `public/assets/js/services/*` → `/routers/{modulo}/v1/`.
- Assets: rutas absolutas `/assets/css|js|img/...`.
- URLs de menú: `nom_programa` relativo a `public/` (ej. `pages/menu/menus.php`).

## Document root

`frontend/web/public/` — login en `index.php`, vistas en `/pages/...` (symlink), routers en `/routers/...` (symlink → `backend/routers`).

## Ejecución

- **Producción:** Apache con `DocumentRoot` en `public/`; no usar `php -S`.
- **Desarrollo:** `bash scripts/dev/start_dev.sh` (manual en cada sesión de trabajo).
