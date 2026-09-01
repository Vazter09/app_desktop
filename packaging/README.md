# Empaquetado — SmartCSET Portería (Windows)

## Resultado

Un solo archivo, sin `_internal` y sin `.py`:

`app_desktop/dist/SmartCSET_Porteria.exe`

Doble clic en el icono. El codigo fuente no viaja con el ejecutable.

Al **primer arranque** pueden aparecer junto al `.exe` (no son codigo):

- `app_config.json` — URL del servidor (`https://10.5.213.111/smartcset`)
- `logs/` — registro de la app

## Regenerar y dejarlo en el Escritorio

Desde `app_desktop`:

```powershell
powershell -ExecutionPolicy Bypass -File packaging\build_exe_to_desktop.ps1
```

Solo build (queda en `dist/`):

```powershell
powershell -ExecutionPolicy Bypass -File packaging\build_exe.ps1
```

Icono: `src/assets/img/img-ejecutable.png` → `packaging/smartcset_porteria.ico`.
