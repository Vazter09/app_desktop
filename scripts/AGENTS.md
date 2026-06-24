# AGENTS.md — scripts/

## Propósito

Scripts operacionales: desarrollo, base de datos, deploy y utilidades CLI.

## Estructura

```
scripts/
├── dev/           # Servidor local (start_dev.sh, smoke_routes.sh, start_dev.ps1)
├── db/            # Instalación BD, setup parcial, sync menús, diagnose_bd.php
├── deploy/        # Deploy funciones PL/pgSQL (PowerShell)
├── tools/         # Utilidades CLI (generate_device_token.php)
├── infra/         # Certificados SSL, tareas de servidor
├── test_seguridad/# Tests Python de blindaje MSPI
├── start_dev.sh   # Wrapper → dev/start_dev.sh
└── start_dev.ps1  # Wrapper → dev/start_dev.ps1
```

## Comandos habituales

```bash
bash scripts/dev/start_dev.sh              # http://localhost:8080/
bash scripts/dev/smoke_routes.sh
bash database/setup_smartcset.sh           # instalación completa (canónico)
bash scripts/db/setup_db.sh                # solo funciones/seeds en BD existente
bash scripts/db/sync_menus_personas.sh
php scripts/tools/generate_device_token.php "Tablet 1" porteria 1
```

Diagnóstico web (desarrollo): `http://localhost:8080/tools/diagnose_bd.php`

## Convenciones

- Instalador **canónico** de BD: `database/setup_smartcset.sh` (no duplicar lógica).
- `scripts/db/setup_smartcset.sh` solo delega al de `database/`.
- Leer `.env` desde la raíz del proyecto.
- PowerShell en `deploy/`; bash en `db/` y `dev/`.

## Obsoleto

La carpeta `tools/` en la raíz fue eliminada; usar `scripts/` con la estructura anterior.
