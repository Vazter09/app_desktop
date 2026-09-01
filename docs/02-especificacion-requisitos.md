# 02 — Especificación de requisitos (SRS)

**Módulo:** App de Escritorio SGI — SmartCSET  
**Versión documental:** 1.0.0  
**Fecha:** 2026-09-01  
**Estado:** As-built (refleja implementación actual en `src/`)

---

## 1. Introducción

Este documento enumera los requisitos funcionales (RF) y no funcionales (RNF) del cliente de escritorio de portería. Los requisitos marcados como **huérfanos** tienen código implementado pero **no están expuestos** al operario en la UI actual.

---

## 2. Requisitos funcionales

### RF-01 — Autenticación con sesión web

| Campo | Valor |
|-------|-------|
| **Descripción** | El operario ingresa usuario y contraseña de SmartCSET. La app obtiene cookie de sesión PHP. |
| **Prioridad** | Alta |
| **Implementación** | `LoginView` → `SmartcsetClient.login()` |
| **Endpoint** | `POST /routers/auth/v1/login.php` con `origen: "desktop"` |
| **Estado** | **Operativo** |

**Criterios de aceptación:**
- Login exitoso muestra pantalla de portería.
- Credenciales incorrectas muestran mensaje de error del servidor.
- Sin sesión, endpoints protegidos fallan.

---

### RF-02 — Pantalla de portería unificada

| Campo | Valor |
|-------|-------|
| **Descripción** | Tras login, la app muestra cámara, formulario central y área de huella en una sola vista. |
| **Prioridad** | Alta |
| **Implementación** | `AppShell.navigate("ingreso")` → `IngresoPage` → `FacialRecognitionPanel` |
| **Estado** | **Operativo** |

**Criterios de aceptación:**
- No se requiere navegación por menú lateral para operar.
- Topbar muestra usuario activo y botón de salir.

---

### RF-03 — Identificación facial

| Campo | Valor |
|-------|-------|
| **Descripción** | Captura rostro, extrae embedding 128-d, consulta servidor, devuelve persona si hay match. |
| **Prioridad** | Alta |
| **Implementación** | `FaceEmbedder` + `biometria_identificar()` |
| **Endpoint** | `POST /routers/porteria/v1/biometria/identificar.php` |
| **Estado** | **Operativo** |

**Criterios de aceptación:**
- Match devuelve documento, nombre, foto de enrolamiento en base64.
- Sin match, operario puede usar captura manual.
- Umbral de distancia coseno configurable en servidor.

---

### RF-04 — Enrolamiento facial con foto

| Campo | Valor |
|-------|-------|
| **Descripción** | Registra vector facial de referencia y foto JPG asociada para una persona. |
| **Prioridad** | Alta |
| **Implementación** | `_enrolar()` en `facial_modal.py` |
| **Endpoint** | `POST /routers/porteria/v1/biometria/enrolar.php` |
| **Estado** | **Operativo** |

**Criterios de aceptación:**
- Foto válida (JPEG/PNG/WebP) se guarda en filesystem del servidor.
- Ruta relativa queda en `tab_enrolamiento_facial.ruta_foto_enrolamiento`.
- Foto inválida es rechazada (E6).
- Enrolar sin foto es rechazado por el servidor.

---

### RF-05 — Confirmación visual antes de registrar

| Campo | Valor |
|-------|-------|
| **Descripción** | Tras identificar, se muestra panel con foto del servidor, datos personales y opción de registrar. |
| **Prioridad** | Alta |
| **Implementación** | `IdentificationConfirmationPanel` |
| **Estado** | **Operativo** |

**Criterios de aceptación:**
- Foto mostrada es la del enrolamiento (servidor), no frame en vivo.
- Auto-registro tras 2,5 s si el operario no cancela (configurable en código).
- Cancelar no registra ingreso/salida.

---

### RF-06 — Registro de ingreso y salida

| Campo | Valor |
|-------|-------|
| **Descripción** | Según estado de la persona, registra ingreso o salida en `tab_log_ingresos`. |
| **Prioridad** | Alta |
| **Implementación** | `_resolver_modo_acceso()` + `ingreso_registrar()` / `salida_registrar()` |
| **Estado** | **Operativo** |

**Criterios de aceptación:**
- Ingreso biométrico usa `id_metodo_aut = 4`.
- Salida actualiza `fec_salida` del ingreso abierto.
- Mismas validaciones de negocio que la web (duplicados, scope de entrada).

---

### RF-07 — Captura manual por documento

| Campo | Valor |
|-------|-------|
| **Descripción** | Operario ingresa tipo y número de documento, consulta persona, registra ingreso/salida. |
| **Prioridad** | Alta |
| **Implementación** | `IngresoFormPanel` |
| **Estado** | **Operativo** |

**Criterios de aceptación:**
- `id_metodo_aut = 1` en registro manual puro.
- Validación de documento (solo dígitos, longitud).

---

### RF-08 — Lectura por pistola (QR / barras / PDF417)

| Campo | Valor |
|-------|-------|
| **Descripción** | Escaneo rellena documento y nombres; determina método 2 (QR) o 3 (barras). |
| **Prioridad** | Media |
| **Implementación** | `scan_capture.parse_captura_escaneo()` |
| **Estado** | **Operativo** |

**Criterios de aceptación:**
- PDF417 de cédula colombiana parsea documento y nombres sin incluir RH como nombre.
- Payload inválido no corrompe el formulario.

---

### RF-09 — Fallback ante fallo biométrico

| Campo | Valor |
|-------|-------|
| **Descripción** | Si no hay match, falla motor o no hay cámara, el formulario manual sigue disponible. |
| **Prioridad** | Alta |
| **Implementación** | Formulario siempre visible en `FacialRecognitionPanel` |
| **Estado** | **Operativo** |

---

### RF-10 — Cierre de sesión

| Campo | Valor |
|-------|-------|
| **Descripción** | Al cerrar ventana o pulsar Salir, se invoca logout en servidor y se limpian cookies. |
| **Prioridad** | Alta |
| **Implementación** | `main.py` → `client.logout()` en `WM_DELETE_WINDOW` y `atexit` |
| **Estado** | **Operativo** |

---

### RF-11 — Empaquetado como ejecutable Windows

| Campo | Valor |
|-------|-------|
| **Descripción** | Generar `.exe` onefile con modelos ONNX y assets embebidos. |
| **Prioridad** | Media |
| **Implementación** | `packaging/SmartCSET_Porteria.spec` |
| **Estado** | **Operativo** |

---

### RF-12 — Dashboard de inicio (HUÉRFANO)

| Campo | Valor |
|-------|-------|
| **Descripción** | KPIs de ingresos/salidas del día y personas dentro. |
| **Implementación** | `InicioPage` registrada en `AppShell._pages["inicio"]` |
| **Estado** | **Código presente, UI no expuesta** — no hay navegación al dashboard |

---

### RF-13 — Página de salida dedicada (HUÉRFANO)

| Campo | Valor |
|-------|-------|
| **Descripción** | Vista con tabla de salidas del día y diálogo de nueva salida. |
| **Implementación** | `SalidaPage` en `AppShell._pages["salida"]` |
| **Estado** | **Código presente, UI no expuesta** — salida se resuelve desde pantalla principal |

---

### RF-14 — Administración de entradas/puertas (HUÉRFANO)

| Campo | Valor |
|-------|-------|
| **Descripción** | Listar, crear y eliminar puertas del centro. |
| **Implementación** | `EntradasPage` — **no registrada** en `AppShell._pages` |
| **Estado** | **Código presente, UI no expuesta** |

---

### RF-15 — Huella dactilar (PLACEHOLDER)

| Campo | Valor |
|-------|-------|
| **Descripción** | Enrolamiento e identificación por huella con lector hardware. |
| **Implementación** | UI visual + `motor/huella.py` (template sintético) + endpoints de prueba |
| **Estado** | **Placeholder** — sin SDK de hardware real |

---

## 3. Requisitos no funcionales

### RNF-01 — Comunicación HTTPS

- Todas las llamadas al backend usan HTTPS.
- Verificación TLS activa por defecto; desactivable explícitamente en `app_config.json` para laboratorio.

### RNF-02 — Timeout HTTP

- Timeout de 15 segundos por request (`SmartcsetClient._request`).

### RNF-03 — Thread-safety del cliente HTTP

- `threading.RLock` protege el opener y cookie jar.

### RNF-04 — Sin redirects silenciosos

- Redirects 3xx no se siguen automáticamente (evita parsear HTML de login como JSON).

### RNF-05 — Logs rotativos

- Archivo `smartcset_desktop.log`, rotación 2 MiB × 5 archivos.
- No loguear documentos, vectores faciales ni fotos en texto plano.

### RNF-06 — Estándar de código Python

- PEP8, `snake_case`, imports al inicio del módulo.
- Validación con `ruff check` antes de commit (política del monorepo).

### RNF-07 — Dependencias versionadas

- `requirements.txt` con versiones fijadas (`==`) salvo `tzdata`.

### RNF-08 — Pruebas sin mocks de BD

- Tests de integración golpean backend y PostgreSQL reales.

### RNF-09 — Identidad visual SmartCSET

- Colores corporativos en `ui/theme.py` alineados con `AppConfig` del backend web.

### RNF-10 — Responsive básico

- Escalado de fuentes y dimensiones según resolución (`ui/responsive.py`).

---

## 4. Requisitos de datos sensibles

| Dato | Tratamiento en app | Tratamiento en servidor |
|------|-------------------|------------------------|
| Vector facial (128 floats) | Calculado en memoria local; enviado por HTTPS; no persistido en disco local | `tab_enrolamiento_facial.facial_embedding` (pgvector) |
| Foto de enrolamiento | Recibida en base64; mostrada en UI; no cacheada localmente en código actual | Filesystem `uploads/biometria/` |
| Documento de identidad | En formulario y payloads HTTP | `tab_personas`, `tab_log_ingresos` |
| Cookie de sesión | `http.cookiejar` en memoria | `tab_sesiones` |

---

## 5. Restricciones de negocio heredadas

La app **no redefine** estas reglas; las hereda del backend:

- Un ingreso abierto por persona por día.
- Scope de entrada/centro según catálogos del servidor.
- Usuario debe tener permiso de menú de portería.
- Administración de entradas requiere rol admin en servidor.

---

## Documentos relacionados

- Trazabilidad RF → código → tests: [`11-matriz-trazabilidad.md`](11-matriz-trazabilidad.md)
- Contrato HTTP: [`07-contrato-integracion.md`](07-contrato-integracion.md)
- Seguridad: [`09-seguridad-mspi.md`](09-seguridad-mspi.md)
