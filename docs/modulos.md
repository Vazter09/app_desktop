# Módulos de aplicación (`src/modulos`)

Estructura por dominio. Las rutas en menú (`tab_menus.nom_programa`) son relativas a la **raíz del proyecto**.

## Árbol

```
src/modulos/
├── entradas/                 # Catálogo de puertas (admin)
│   ├── init.php
│   └── index.php
├── registro/                 # Registro de personas (ex carpeta files/)
│   ├── init.php
│   ├── index.php             # Panel público (tarjetas → formularios)
│   ├── login.php             # Login propio del módulo (standalone)
│   ├── ajax_ciudades.php
│   ├── ajax_personas.php     # AJAX JSON: listado por tipo (tab_personas)
│   ├── lib/
│   │   ├── access.php
│   │   ├── catalogos.php
│   │   └── personas_list.php
│   └── forms/
│       ├── aprendiz.php
│       ├── instructor.php
│       ├── funcionario.php
│       └── contratista.php
└── porteria/                 # Ingreso y salida
    ├── lib/                  # Lógica PHP compartida
    │   ├── init.php
    │   ├── acceso_documento.php
    │   ├── acceso_parse_captura.php
    │   ├── porteria_consulta.php
    │   ├── ingresos_registro.php
    │   ├── salidas_registro.php
    │   ├── porteria_foto.php
    │   └── porteria_modos_ui.php
    ├── ingreso/
    │   ├── index.php         # Pantalla registro ingreso
    │   ├── procesar.php      # POST
    │   └── consultar.php     # AJAX JSON
    └── salida/
        ├── index.php
        ├── procesar.php
        └── consultar.php
```

No hay archivos `.php` sueltos en la raíz de `modulos/`; solo subcarpetas.

## URLs de menú (BD)

| Menú | `nom_programa` |
|------|----------------|
| Entradas | `src/modulos/entradas/index.php` |
| Registro ingreso | `src/modulos/porteria/ingreso/index.php` |
| Registro salida | `src/modulos/porteria/salida/index.php` |
| Panel registro (operadores) | `src/modulos/registro/index.php` |
| Aprendiz / Instructor / … (admin) | `src/admin/registro/listado.php?menu=030x` |

Migración: [`database/migrations/update_modulos_rutas_organizadas.sql`](../database/migrations/update_modulos_rutas_organizadas.sql)

## Configuración visual y módulo registro

- Tabla: `tab_config_sistema` (una fila).
- Admin: **Config. sistema** → `src/admin/configuracion.php` (menú `0205`).
- Estilos del módulo registro: [`css/registro.css`](../css/registro.css) + variables inyectadas desde [`src/layout/theme_vars.php`](../src/layout/theme_vars.php).
- Migración en BD existente: `./database/migrations/run_config_sistema.sh`

### Flujo de acceso del módulo registro (resumen)

- **Administrador**: entra por `index.php` (login principal) y configura el módulo en **Config. sistema** (habilitar módulo + credenciales del login de registro).
- **Registrantes/operadores**: entran por `src/modulos/registro/login.php` y registran desde el panel `src/modulos/registro/index.php` (tarjetas con enlace a formularios).
- **Administrador (listados)**: menús 0301–0304 abren `src/admin/registro/listado.php` con tabla por tipo.

## Assets y subcarpetas

`smartcsetModulosAssetHref()` en `src/core/helpers.php` calcula el prefijo `../` para CSS/JS y enlaces del menú según la profundidad de la página.

## Documentación relacionada

- [porteria-codigo-linea-a-linea.md](porteria-codigo-linea-a-linea.md) — flujo ingreso/salida documentado por líneas
- [database.md](database.md) — instalación y migraciones
- [database-functions.md](database-functions.md) — funciones PL/pgSQL de portería
