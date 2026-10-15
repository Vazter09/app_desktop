# ADR-01 — UI Tkinter y HTTP con stdlib

**Módulo:** `app_desktop`  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 5 (gestión de activos / stack controlado), 7 (continuidad — menos superficie de ataque), 8 (seguridad — menos deps de red)

**Estado:** Aceptada (as-built)

---

## Contexto

La app de portería debe correr en PCs Windows del centro SENA, con instalación sencilla, pocas dependencias y sin cadena de suministro amplia (npm, Electron, frameworks GUI pesados). El cliente solo orquesta captura y llama al backend PHP existente; no necesita un stack web embebido.

Alternativas evaluadas: Electron/React, .NET WinForms/WPF, Qt, Tkinter + stdlib Python.

---

## Decisión

Usar **Python 3.11+ con Tkinter** (incluido en la instalación estándar de Windows) para la UI, y **`urllib` + `json` + `http.cookiejar` + `ssl` (stdlib)** para el cliente HTTP ([`../src/smartcset_client.py`](../../src/smartcset_client.py)).

Dependencias de terceros permitidas solo donde stdlib no alcanza:

| Paquete | Motivo |
|---------|--------|
| `opencv-python-headless` | Cámara + modelos YuNet/SFace |
| `numpy` | Tensores/frames del motor |
| `Pillow` | Conversión frame ↔ imagen/base64 |

No se introduce `requests`, frameworks GUI ni bundlers web.

---

## Consecuencias

**Positivas**

- Instalación y empaquetado más simples; menor superficie de vulnerabilidades de dependencias.
- Misma habilidad Python que el resto del tooling del monorepo (`scripts/`, tests).
- Alineado a MSPI Eje 5/7: inventario de componentes acotado y documentado.

**Negativas / trade-offs**

- UI menos “moderna” que web/Electron; hay que cuidar tema y responsive a mano ([`../src/ui/`](../../src/ui/)).
- Tkinter en Windows requiere build de Python con Tcl/Tk; el `.exe` onefile debe empaquetar esos binarios.
- Sin hot-reload ni ecosistema de componentes; cambios de UX son más manuales.
