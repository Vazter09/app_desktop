# Carpeta `files/` (compatibilidad)

El módulo de registro de personas se integró en el proyecto principal.

## Ubicación actual

| Antes | Ahora |
|-------|--------|
| `files/index.php` | [`src/modulos/registro/index.php`](../src/modulos/registro/index.php) |
| `files/login.php` | [`src/modulos/registro/login.php`](../src/modulos/registro/login.php) |
| `files/forms/*` | [`src/modulos/registro/forms/`](../src/modulos/registro/forms/) |
| `files/assets/style.css` | [`css/registro.css`](../css/registro.css) |

Los archivos `index.php` y `login.php` en esta carpeta redirigen a las nuevas rutas.

## Configuración (colores, login del módulo)

Administración → **Config. sistema** (`src/admin/configuracion.php`), o tabla `tab_config_sistema` en PostgreSQL.

Migración: `database/migrations/add_tab_config_sistema.sql`

## Base de datos

Use únicamente [`database/`](../database/). No hay scripts SQL duplicados en `files/`.
