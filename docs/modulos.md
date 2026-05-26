# Módulos de aplicación (`src/modulos`)

Estructura por dominio. Las rutas en menú (`tab_menus.nom_programa`) son relativas a la **raíz del proyecto**.

## Árbol

```
src/modulos/
├── entradas/                 # Catálogo de puertas (admin)
│   ├── init.php
│   └── index.php
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

Migración: [`database/migrations/update_modulos_rutas_organizadas.sql`](../database/migrations/update_modulos_rutas_organizadas.sql)

## Assets y subcarpetas

`smartcsetModulosAssetHref()` en `src/core/helpers.php` calcula el prefijo `../` para CSS/JS y enlaces del menú según la profundidad de la página.

## Documentación relacionada

- [porteria-codigo-linea-a-linea.md](porteria-codigo-linea-a-linea.md) — flujo ingreso/salida documentado por líneas
- [database.md](database.md) — instalación y migraciones
- [database-functions.md](database-functions.md) — funciones PL/pgSQL de portería
