# 11 — Matriz de trazabilidad

**Módulo:** App de Escritorio SGI — SmartCSET  
**Versión documental:** 1.0.0  
**Fecha:** 2026-09-01

---

## Propósito

Relaciona cada requisito funcional con su implementación en código, pruebas automatizadas y entregables MSPI aplicables.

**Leyenda de estado:**

| Símbolo | Significado |
|---------|-------------|
| ✅ | Operativo y expuesto al operario |
| ⚠️ | Código presente pero no expuesto en UI |
| 🔲 | Placeholder o pendiente |
| — | No aplica |

---

## Matriz principal

| ID | Requisito | Archivo(s) principal(es) | Test(s) | MSPI | Estado |
|----|-----------|---------------------------|---------|------|--------|
| RF-01 | Login/logout sesión PHP | `login_view.py`, `smartcset_client.py`, `main.py` | `TestLogin` (4) | E3, E4 | ✅ |
| RF-02 | Pantalla portería unificada | `shell.py`, `ingreso.py`, `facial_modal.py` | — (sin test UI) | E5 | ✅ |
| RF-03 | Identificación facial | `motor/embeddings.py`, `facial_modal.py` | `TestBiometriaFacial` (8) | E1, E2 | ✅ |
| RF-04 | Enrolamiento con foto | `facial_modal.py`, `smartcset_client.py` | `test_enrolar_con_foto_*`, `test_enrolar_foto_invalida_*` | E2, E6 | ✅ |
| RF-05 | Confirmación visual | `identification_confirmation_modal.py` | Indirecto vía `test_ingreso_por_identificacion_*` | E1, E4 | ✅ |
| RF-06 | Ingreso/salida | `facial_modal.py`, `ingreso_form_panel.py` | `test_ciclo_ingreso_y_salida`, `test_ingreso_por_identificacion_*` | E11 | ✅ |
| RF-07 | Captura manual | `ingreso_form_panel.py`, `field_validators.py` | `test_ciclo_ingreso_y_salida` | E1 | ✅ |
| RF-08 | Pistola QR/barras | `scan_capture.py` | `TestScanCapture*` (14), `TestFieldValidators` (3) | — | ✅ |
| RF-09 | Fallback biométrico | `facial_modal.py`, `ingreso_form_panel.py` | — (manual) | E5 | ✅ |
| RF-10 | Cierre de sesión | `main.py`, `shell.py` | `test_relogin_desktop_*` | E4 | ✅ |
| RF-11 | Empaquetado .exe | `packaging/*.spec`, `build_exe.ps1` | — | E10 | ✅ |
| RF-12 | Dashboard inicio | `pages/inicio.py` | `test_catalogos_disponibles` (parcial) | — | ⚠️ |
| RF-13 | Página salida | `pages/salida.py` | `test_ciclo_ingreso_y_salida` (indirecto) | — | ⚠️ |
| RF-14 | CRUD entradas | `pages/entradas.py` | `test_entradas_crud_requiere_admin` | E1 | ⚠️ |
| RF-15 | Huella hardware | `motor/huella.py`, `huella_scan.py` | `TestBiometriaHuella` (3) | E2 | 🔲 |

---

## Requisitos no funcionales

| ID | Requisito | Implementación | Verificación | MSPI | Estado |
|----|-----------|----------------|--------------|------|--------|
| RNF-01 | HTTPS + TLS configurable | `config.py`, `smartcset_client.py` | Manual / config JSON | E8 | ✅ |
| RNF-02 | Timeout 15s | `smartcset_client._request` | Código | — | ✅ |
| RNF-03 | Thread-safe HTTP | `RLock` en cliente | Código | — | ✅ |
| RNF-04 | No follow redirects | `_NoFollowRedirectHandler` | `test_endpoint_protegido_sin_sesion` | E1 | ✅ |
| RNF-05 | Logs rotativos | `app_log.py` | Manual | E10 | ✅ |
| RNF-06 | PEP8 | Todo `src/` | `ruff check` (manual) | E10 | ✅ |
| RNF-07 | Deps versionadas | `requirements.txt` | Archivo | E10 | ✅ |
| RNF-08 | Tests sin mocks BD | `tests/` | Política | E10 | ✅ |
| RNF-09 | Tema corporativo | `ui/theme.py` | Visual | — | ✅ |
| RNF-10 | Responsive | `ui/responsive.py` | Visual | — | ✅ |

---

## Huecos y deuda documentada

| Hueco | Impacto | MSPI | Prioridad sugerida |
|-------|---------|------|-------------------|
| CI/CD ausente | Regresiones no detectadas automáticamente | E10 | Media |
| Consentimiento biométrico en UI | Cumplimiento Ley 1581 / Fase 0 | Fase 0 | Alta |
| Cifrado E2 fotos en reposo | Riesgo de fuga en filesystem | E2 | Institucional |
| Motor biométrico 2 procesos HTTPS | Diseño original no implementado | E1-A02 | Baja (Fase 2) |
| SDK huella real | Feature incompleta | E2 | Media |
| Cache fotos local | HANDOFF menciona; código no escribe | — | Baja |
| Tests UI Tkinter | Sin cobertura automatizada de pantallas | E10 | Media |
| Versión semver en app | Sin etiqueta de release formal | — | Baja |
| LICENSE | Sin licencia explícita en módulo | — | Institucional |

---

## Mapeo MSPI por eje

| Eje MSPI | Requisitos / controles cubiertos | Huecos |
|----------|----------------------------------|--------|
| **Eje 3 — Confidencialidad** | TLS tránsito, sesión autenticada, no loguear datos sensibles | E2 reposo fotos/vectores |
| **Eje 5 — Disponibilidad** | Fallback manual, no bloquear portería | Caché offline no implementado |
| **Eje 6 — Integridad** | Auditoría `usr_insert`, confirmación visual | — |
| **Eje 7 — Desarrollo seguro** | Tests reales, validación input, PEP8 | CI ausente |
| **Eje 8 — Seguridad en redes** | HTTPS obligatorio, TLS configurable | `verify_tls: false` en lab |

### Entregables Fase 1 (E-tasks)

| E-task | Cobertura en app_desktop | Evidencia |
|--------|--------------------------|-----------|
| E1 — Control de acceso | Sesión PHP + menú portería en servidor | Tests login + endpoints protegidos |
| E2 — Cifrado reposo | **Parcial** — vectores en pgvector sin cifrado adicional; fotos JPG planas | Documentado como diferido |
| E3 — Rate limiting | Heredado del login del servidor | `TestLogin.test_login_clave_incorrecta` |
| E4 — Hardening sesión | Logout al cerrar, cookie en memoria | `main.py` atexit |
| E6 — Validación uploads | Servidor valida MIME de fotos | `test_enrolar_foto_invalida_es_rechazada` |
| E8 — TLS | Cliente con verificación configurable | `config.verify_tls` |
| E10 — SDLC seguro | Suite unittest, sin mocks | 34 tests totales |
| E11 — SIEM | Ingresos con `usr_insert` real, mismo canal que web | `test_ciclo_ingreso_y_salida` |

---

## Inventario de pruebas (34 casos)

### `test_smartcset_client.py` (17)

| Clase | Casos | RF cubiertos |
|-------|-------|--------------|
| `TestLogin` | 4 | RF-01, RF-10 |
| `TestPorteriaFlujoReal` | 4 | RF-06, RF-07, RF-14 |
| `TestBiometriaFacial` | 8 | RF-03, RF-04, RF-05, RF-06 |
| `TestBiometriaHuella` | 3 | RF-15 (placeholder) |

### `test_scan_capture.py` (17)

| Clase | Casos | RF cubiertos |
|-------|-------|--------------|
| `TestFieldValidators` | 3 | RF-07 |
| `TestScanCapturePdf417` | 6 | RF-08 |
| `TestScanCaptureQrYBarras` | 8 | RF-08 |

---

## Documentos relacionados

- Requisitos: [`02-especificacion-requisitos.md`](02-especificacion-requisitos.md)
- Plan de pruebas: [`08-plan-y-evidencia-pruebas.md`](08-plan-y-evidencia-pruebas.md)
- Seguridad MSPI: [`09-seguridad-mspi.md`](09-seguridad-mspi.md)
