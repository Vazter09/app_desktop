# 09 — Decisiones (índice ADR)

**Módulo:** app_desktop  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3, 7, 8

---

## 9.1 Propósito

Índice de Architecture Decision Records (ADR) que anclan la arquitectura **as-built**. Los textos completos viven en `docs/adr/`; aquí solo el mapa y el estado.

## 9.2 Índice

| ID | Título | Estado | Enlace |
|----|--------|--------|--------|
| ADR-01 | Tkinter + HTTP stdlib (sin Electron/Qt/`requests`) | Aceptada | [`../adr/ADR-01-tkinter-stdlib.md`](../adr/ADR-01-tkinter-stdlib.md) |
| ADR-02 | Sesión web PHP real (no token de dispositivo) | Aceptada | [`../adr/ADR-02-sesion-web-real.md`](../adr/ADR-02-sesion-web-real.md) |
| ADR-03 | Motor facial in-process (no proceso HTTPS loopback) | Aceptada | [`../adr/ADR-03-motor-biometrico-in-process.md`](../adr/ADR-03-motor-biometrico-in-process.md) |
| ADR-04 | Embedding SFace 128 dimensiones | Aceptada | [`../adr/ADR-04-sface-128-dims.md`](../adr/ADR-04-sface-128-dims.md) |
| ADR-05 | URL del servidor preconfigurada (fuera del login) | Aceptada | [`../adr/ADR-05-url-preconfigurada.md`](../adr/ADR-05-url-preconfigurada.md) |
| ADR-06 | Empaquetado PyInstaller onefile | Aceptada | [`../adr/ADR-06-pyinstaller-onefile.md`](../adr/ADR-06-pyinstaller-onefile.md) |

## 9.3 Resumen ejecutivo

### ADR-01 — Tkinter + stdlib HTTP

- **Contexto:** intranet SENA; minimizar deps y superficie de ataque.
- **Decisión:** UI Tkinter/ttk; cliente `urllib` + cookie jar.
- **Descartado:** Electron, Qt, `requests`.

### ADR-02 — Sesión web

- **Contexto:** auditoría por usuario real; coherencia con web.
- **Decisión:** login a `auth/v1/login.php` con cookie `PHPSESSID`.
- **Descartado:** token de `tab_dispositivos_porteria` (móvil).

### ADR-03 — Motor in-process

- **Contexto:** diseño original proponía 2 procesos + HTTPS 127.0.0.1.
- **Decisión:** `FaceEmbedder` en el mismo proceso que la UI.
- **Descartado (por ahora):** motor separado con API key; queda Fase 2.

### ADR-04 — SFace 128

- **Contexto:** primer borrador asumía 512 dims sin modelo elegido.
- **Decisión:** YuNet + SFace ONNX vendorizados; vector 128; BD alineada.
- **Descartado:** Facenet512 / otras dims sin migración explícita.

### ADR-05 — URL preconfigurada

- **Contexto:** operario no debe “configurar red”.
- **Decisión:** `base_url` (y `verify_tls`) en `app_config.json`; TI edita.
- **Descartado:** campo de servidor en pantalla de login.

### ADR-06 — PyInstaller onefile

- **Contexto:** despliegue repetible en PCs de portería.
- **Decisión:** `SmartCSET_Porteria.exe` onefile con modelos/assets.
- **Descartado:** solo venv + `.bat` como entrega oficial.

## 9.4 Decisiones menores documentadas (sin ADR formal)

| Tema | Decisión as-built |
|------|-------------------|
| Post-login UI | Solo `ingreso`; sin sidebar |
| Foto en confirmación | Prioridad foto del servidor sobre frame vivo |
| TLS lab | `verify_tls: false` permitido explícitamente |
| Huella | Placeholder UI + template sintético |
| Código fuente | Árbol `src/` (no `app/`) |
| Foto enrolamiento | Opción A: archivo en servidor, no BYTEA |

## 9.5 Cómo agregar un ADR nuevo

1. Crear `docs/adr/ADR-0N-slug.md` con contexto, decisión, consecuencias.
2. Añadir fila en la tabla §9.2 de este índice.
3. Actualizar [`04-estrategia-de-solucion.md`](04-estrategia-de-solucion.md) si cambia el pilar arquitectónico.
