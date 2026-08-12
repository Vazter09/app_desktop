# Empaquetado — SmartCSET Portería (Windows)

## Resultado del build

Carpeta lista para copiar al PC de portería:

`app_desktop/dist/SmartCSET_Porteria/`

- `SmartCSET_Porteria.exe` — doble clic
- `app_config.json` — `base_url = https://10.5.213.111/smartcset`
- `_internal/` — dependencias (no borrar)

**Importante:** copiar **toda** la carpeta, no solo el `.exe`.

## Regenerar

Desde `app_desktop`:

```powershell
powershell -ExecutionPolicy Bypass -File packaging\build_exe.ps1
```

Icono: `src/assets/img/img-ejecutable.png` → `packaging/smartcset_porteria.ico`.
