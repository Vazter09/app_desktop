# AGENTS.md — src/admin/personas/

## Propósito

Administración del catálogo de personas (`tab_personas`): listados por tipo con consultas y fragmentos propios, y configuración del módulo standalone (`src/modulos/registro/`).

Menú padre en BD: **Personas** (`id_menu = 03`).

## Estructura

```
personas/
├── config.php              ← Config. módulo (0402, hijo del menú raíz Configuración 04)
├── lib/
│   ├── listado_index.php   ← Bootstrap común de listados (layout + partial AJAX)
│   ├── fragment_tabla_base.php
│   └── tipo_id.php
├── aprendices/             ← 0301
├── instructores/           ← 0302
├── funcionarios/           ← 0303
└── contratistas/           ← 0304
```

Cada tipo incluye:

- `index.php` — define `$personasListado` e incluye `lib/listado_index.php`
- `query.php` — función `personasListadoFetch*` (paginación + filtros; extender por tipo)

Componentes reutilizables: `src/layout/components/listado/` + `src/core/listado_ui.php`.

Filtros por defecto: búsqueda (`q`), estado (`estado`). Paginación: `page`, `per_page` (10/25/50/100).

## URLs (desarrollo)

- Aprendices: `src/admin/personas/aprendices/index.php`
- Instructores: `src/admin/personas/instructores/index.php`
- Funcionarios: `src/admin/personas/funcionarios/index.php`
- Contratistas: `src/admin/personas/contratistas/index.php`
- Config: `src/admin/personas/config.php`

Partial AJAX: misma URL con `?partial=1` (manejado por `js/personas-listado-admin.js`).

## Compatibilidad

`src/admin/registro/listado.php` y `config.php` redirigen con 301 a esta carpeta.

## Qué NO tocar sin entender

- No unificar de nuevo todos los tipos en un solo `listado.php` si divergen filtros/columnas.
- Mantener `nom_programa` en `tab_menus` alineado con las rutas anteriores tras cambios de carpeta.
