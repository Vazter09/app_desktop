# App de Escritorio SGI — SmartCSET

**Versión documental:** 1.2.0 | **Estado:** Operativo (as-built) · entrega técnica monolítica 2026-09-14

Cliente de escritorio (Python + Tkinter) para el módulo **SGI (portería)** de SmartCSET. Habla por **HTTPS** con el backend PHP existente (mismo login de usuario/contraseña que la web).

---

## Documentación de entrega

**Entrega técnica completa (un solo archivo):** [`DOCUMENTACION_TECNICA.md`](DOCUMENTACION_TECNICA.md) — arc42, C4, ADR, ISO 29148/25010/27001, Diátaxis, API, BD, operación y anexos MSPI.

Índice modular (espejo por carpeta + Word): [`docs/CHECKLIST_DOCUMENTACION.md`](docs/CHECKLIST_DOCUMENTACION.md) · [`docs/README.md`](docs/README.md)

| Audiencia | Documento |
|-----------|-----------|
| Todo rol / auditor | [DOCUMENTACION_TECNICA.md](DOCUMENTACION_TECNICA.md) |
| Operario | [Tutorial primer uso](docs/usuario/tutorial-primer-uso.md) (también §G en el monolítico) |
| TI / instalador | [Instalación](docs/operacion/instalacion.md) (también §F en el monolítico) |
| Desarrollador | Monolítico PARTES A–E · o [arquitectura/](docs/arquitectura/) + [API](docs/api/contrato-http.md) |
| Auditor MSPI | Monolítico §8 / §11 / PARTE I · o [incidentes](docs/operacion/incidentes-seguridad.md) |

Entrega Word: [`docs/word/`](docs/word/) (regenerar con `python docs/_tools/export_to_docx.py`).

Notas internas (pueden divergir del as-built): [`HANDOFF.md`](HANDOFF.md), [`REGLAS_APP_ESCRITORIO_SGI.md`](REGLAS_APP_ESCRITORIO_SGI.md).

---

## Estado actual (as-built)

| Funcionalidad | Estado |
|---------------|--------|
| Login sesión PHP | Operativo |
| Reconocimiento facial (YuNet + SFace, 128-d, in-process) | Operativo |
| Enrolamiento con foto | Operativo |
| Confirmación visual + ingreso/salida automático | Operativo |
| Captura manual y pistola (QR/barras/PDF417) | Operativo |
| Huella hardware | Placeholder |
| Empaquetado `.exe` | Operativo |
| Menú Inicio / Salida / Entradas | Código presente, no expuesto en UI |

---

## Ejecutar (desarrollo)

```bash
cd app_desktop/src
python main.py
```

Config: `runtime/app_config.json` · Usuario prueba: `porteria` / `Porteria2026!`

## Tests

```bash
cd app_desktop/tests
python -m unittest discover -v
```

## Empaquetado

```powershell
powershell -ExecutionPolicy Bypass -File packaging\build_exe.ps1
```

## Estructura

```
app_desktop/
├── docs/           ← documentación checklist + word/
├── src/            ← código
├── tests/
├── packaging/
└── runtime/        ← no versionado
```

## Changelog

Ver [`CHANGELOG.md`](CHANGELOG.md) y [`docs/historial/CHANGELOG.md`](docs/historial/CHANGELOG.md).
