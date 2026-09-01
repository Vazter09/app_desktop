# App de Escritorio SGI — SmartCSET

**Versión:** 1.0.0 (documental) | **Estado:** Operativo (as-built)

Cliente de escritorio (Python + Tkinter) para el módulo **SGI (portería)** de SmartCSET. No tiene BD propia ni login propio — se comunica por **HTTPS** con el backend PHP existente usando el mismo login de usuario/contraseña que la web.

---

## Documentación de entrega

El paquete documental profesional está en **[`docs/`](docs/README.md)**:

| Audiencia | Documento |
|-----------|-----------|
| Entrega / académico | [Qué debe contener un proyecto](docs/00-que-debe-contener-un-proyecto.md) |
| Operario de portería | [Manual de usuario](docs/06-manual-usuario.md) |
| TI / instalador | [Manual de instalación](docs/05-manual-instalacion.md) |
| Desarrollador | [Arquitectura](docs/03-arquitectura.md) · [API](docs/07-contrato-integracion.md) |
| Auditor MSPI | [Seguridad](docs/09-seguridad-mspi.md) |

Documentos internos de ingeniería (pueden estar desactualizados): [`HANDOFF.md`](HANDOFF.md), [`REGLAS_APP_ESCRITORIO_SGI.md`](REGLAS_APP_ESCRITORIO_SGI.md).

---

## Estado actual (as-built)

| Funcionalidad | Estado |
|---------------|--------|
| Login sesión PHP real | Operativo |
| Pantalla de reconocimiento multibiométrico (post-login) | Operativo |
| Identificación facial (YuNet + SFace, 128 dims) | Operativo |
| Enrolamiento con foto | Operativo |
| Confirmación visual antes de registrar | Operativo |
| Ingreso/salida automático (decide según estado persona) | Operativo |
| Captura manual por documento | Operativo |
| Lectura pistola (QR / barras / PDF417) | Operativo |
| Huella dactilar (hardware) | Placeholder (UI visual) |
| Empaquetado Windows (.exe) | Operativo |
| Dashboard / Salida / Entradas en menú | Código presente, **no expuesto en UI** |
| Motor biométrico proceso HTTPS separado | Pendiente (Fase 2) |
| Cifrado E2 fotos en reposo | Diferido institucionalmente |
| Consentimiento biométrico en UI | Pendiente (Fase 0 MSPI) |

---

## Requisitos

- Python 3.11+ con Tkinter.
- Webcam conectada.
- Backend SmartCSET accesible por HTTPS.
- PostgreSQL con pgvector en el servidor.

---

## Ejecutar (desarrollo)

```bash
cd app_desktop/src
python main.py
```

`bootstrap.py` crea automáticamente `runtime/.venv/` e instala dependencias la primera vez.

Configuración local (se crea al primer arranque): `runtime/app_config.json`

```json
{
  "base_url": "https://localhost/smartcset"
}
```

**Usuario de prueba:** `porteria` / `Porteria2026!`

---

## Tests

```bash
cd app_desktop/tests
python -m unittest discover -v
```

**34 casos** (17 integración HTTP + 17 unitarios) contra backend real, sin mocks.

Detalle: [`docs/08-plan-y-evidencia-pruebas.md`](docs/08-plan-y-evidencia-pruebas.md)

---

## Empaquetado Windows

```powershell
cd app_desktop
powershell -ExecutionPolicy Bypass -File packaging\build_exe.ps1
```

Resultado: `dist/SmartCSET_Porteria.exe`

Guía: [`packaging/README.md`](packaging/README.md)

---

## Estructura

```
app_desktop/
├── README.md
├── CHANGELOG.md
├── requirements.txt
├── docs/                 ← documentación de entrega
├── src/                  ← código fuente
│   ├── main.py
│   ├── bootstrap.py
│   ├── config.py
│   ├── smartcset_client.py
│   ├── motor/            ← YuNet + SFace (128 dims, in-process)
│   └── ui/               ← Tkinter
├── tests/
├── packaging/            ← PyInstaller
└── runtime/              ← NO versionado (venv, config, logs)
```

---

## Stack técnico

| Componente | Tecnología |
|------------|------------|
| UI | Tkinter + ttk |
| HTTP | urllib (stdlib) + http.cookiejar |
| Biometría | opencv-python-headless + ONNX (YuNet, SFace) |
| Imágenes | Pillow |
| Auth | Sesión PHP (cookie PHPSESSID) |
| Backend | SmartCSET PHP + PostgreSQL (pgvector) |

---

## Changelog

Ver [`CHANGELOG.md`](CHANGELOG.md).
