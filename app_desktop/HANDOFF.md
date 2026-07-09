# HANDOFF.md — App de Escritorio SGI (Portería)

**Última actualización:** 2026-07-09 (tarde — Foto de enrolamiento Opción A + Modal confirmación + fix de aridad PL/pgSQL + tests)  
**Estado actual:** ✅ OPERATIVA — biometría con foto real, probada 13/13 tests contra servidor de laboratorio (`.env` → `192.168.1.71`)  
**Próximo hito:** Feature #1 (Caché offline) | Feature #3 (Validaciones mejoradas)

> **Nota de precisión (2026-07-09):** documentos previos de esta misma
> sesión afirmaron "23/23 tests PASS en producción (10.5.213.103)" para
> el ciclo de biometría — eso era cierto para el ciclo **sin foto**
> (validado el 2026-07-09 temprano). La extensión con foto de este
> bloque se probó y se corrigió contra el servidor de laboratorio
> (`192.168.1.71`, el que usa `.env` en este entorno de desarrollo) —
> **no** se ha vuelto a validar contra 10.5.213.103 todavía. No asumir
> que está en producción institucional hasta desplegar y probar ahí.

---

## 📊 Estado Consolidado (2026-07-09 — Tarde)

### ✅ Completado

#### Funcionalidad Base
- **Login:** Auténtico contra backend PHP, sesión real, usuario `porteria` prellenado
- **Dashboard:** KPIs en vivo (ingresos/salidas hoy, personas dentro), acciones rápidas, actividad reciente
- **Ingreso/Salida:** Flujo completo probado end-to-end contra BD real
- **Entradas:** CRUD de puertas (admin-only, respeta permisos web)

#### Biometría Facial COMPLETA (2026-07-09)
- **Backend:**
  - `tab_enrolamiento_facial` (pgvector 128-dims, HNSW)
  - Columna nueva: `ruta_foto_enrolamiento` (relativa a document root)
  - Funciones PL/pgSQL: `fun_guardar_*` / `fun_identificar_*` (4-arg exception handling)
  - Servicio: `BiometriaPhotoService` (guardar + leer fotos, validación MIME E6)
  - Endpoints: `/porteria/v1/biometria/{enrolar,identificar}.php` — ahora con foto ✨

- **Flujo de Enrolamiento (NUEVO):**
  1. Operario captura rostro
  2. Motor extrae embedding (128-dims) + calidad
  3. **Modal captura último frame → base64 JPG** ✨
  4. Envía a `enrolar.php` con: documento + embedding + foto_base64
  5. Servidor guarda: vector en BD + foto en `frontend/web/public/uploads/biometria/{id}/{id}_{nombre}.jpg`
  6. Retorna: id_enrolamiento

- **Flujo de Identificación (NUEVO):**
  1. Operario captura rostro
  2. Motor extrae embedding → envía a `identificar.php`
  3. Servidor busca match en pgvector
  4. **Si hay match: lee foto desde filesystem → base64 → devuelve** ✨
  5. **Modal se abre automáticamente** (E1, E4 — confirmación visual)
  6. Modal muestra: **Izq: Foto | Centro: Datos | Der: Huella (TODO)**
  7. Operario confirma → registra ingreso/salida con `metodo_aut=4`

- **App Desktop (Caché Local):**
  - Descarga foto en base64 desde `identificar.php`
  - Guarda localmente en `app_desktop/app/images/{id}_{nombre}.jpg` (cache)
  - Modal carga foto desde base64 recibido
  - `.gitignore` — imágenes NO se versionan

- **Auditoría:** `usr_insert = porteria` (usuario real, no genérico) ✅
- **Tests:** 13/13 PASS (`app_desktop/app/tests/test_smartcset_client.py`, incluye 3 tests nuevos de foto), contra servidor de laboratorio (`192.168.1.71`)
- **Seguridad:** TLS validation `verify_tls=True` siempre, cliente HTTP stdlib puro (urllib)

#### Modal de Confirmación (NUEVO — 2026-07-09)
- **`identification_confirmation_modal.py`** — Se abre automáticamente tras identificar
- **Layout 3 columnas:**
  - **Izq:** Foto de enrolamiento (150x180px)
  - **Centro:** Datos personales (ID, nombre, documento, tipo, entrada, programa, ficha)
  - **Der:** Placeholder huella dactilar (Feature TODO Fase 3)
- **Botones:** Registrar Ingreso | Ver Detalles | Cancelar
- **Cumple:** E1 (validación visual) + E4 (confirmación explícita) + E10 (auditoría)

### 🐛 Bugs de esta sesión (2026-07-09, tarde) — encontrados y corregidos

1. **`parameter was not defined`** al enrolar — `backend/core/prepare.php` seguía
   preparando el statement de `fun_guardar_enrolamiento_facial` con 3 placeholders
   (`?::NUMERIC, ?::VECTOR, ?::NUMERIC`) pero la función y el cliente ya enviaban 4.
   **Fix:** agregado el 4º `?::VARCHAR` al SQL preparado.

2. **`function fun_guardar_enrolamiento_facial(numeric,...) does not exist`** tras el
   fix anterior — la función en BD todavía tenía la firma vieja de 3 args (el
   `CREATE OR REPLACE` del archivo `.sql` con distinta aridad no la había
   reemplazado). Desplegado manualmente el `.sql` actualizado.

3. **Firma duplicada real en BD** — al auditar después de los 2 fixes de arriba,
   `pg_proc` mostraba **dos** funciones `fun_guardar_enrolamiento_facial` (3-arg
   vieja + 4-arg nueva) coexistiendo. Es exactamente la lección ya documentada en
   `CLAUDE.md` (E3): un `CREATE OR REPLACE` con distinta aridad no reemplaza, crea
   una sobrecarga. **Fix:** `DROP FUNCTION IF EXISTS` explícito de la firma vieja
   agregado dentro del propio archivo `.sql` (idempotente), ejecutado en BD real;
   verificado que solo queda 1 firma. Además, `add_ruta_foto_enrolamiento.sql`
   **no estaba** en `database/setup_smartcset.sh` — agregado en el punto correcto
   (junto a las otras 2 migraciones de la misma tabla, antes del array `FUNCS`).
   Sin este paso, una instalación limpia nueva no tendría la columna de foto.

4. **Modal mostraba la captura en vivo, no la foto guardada de enrolamiento** —
   `_identificar()` en `facial_modal.py` priorizaba el frame recién capturado por
   encima de la foto que devolvía el servidor. **Fix:** invertida la prioridad —
   `foto_base64` del servidor (la real, guardada en el enrolamiento) gana siempre;
   el frame local solo se usa como fallback si el servidor no devolvió nada.
   Cubierto ahora por `test_enrolar_con_foto_guarda_ruta_y_se_recupera_al_identificar`.

5. **Cámara no detectada al abrir "Reconocimiento facial" en Salida** — reportado
   y confirmado resuelto por el usuario tras los cambios de feedback visual en
   `_identificar()`/`_enrolar()` (que fuerzan `self.update()` antes de operaciones
   largas). **No se identificó la causa raíz con certeza** — no descartar que
   reaparezca; si vuelve a pasar, revisar liberación de `cv2.VideoCapture` entre
   aperturas sucesivas del modal en la misma sesión de la app.

### 🔲 Pendiente
- Verificación con persona real frente a cámara (no hay entorno físico con rostro en dev)
- Separar motor en proceso HTTPS local aparte (Fase 2, endurecimiento futuro)
- **E2 — Cifrado en reposo de fotos:** decisión explícita de Anderson (2026-07-09):
  se resuelve del lado del SENA, no en este ciclo de desarrollo. Fotos quedan como
  JPG planos en `uploads/biometria/` por ahora — mismo estado que el resto de datos
  de personas en el sistema (ver Entregable 2 de FASE1, pendiente a nivel de todo
  el proyecto, no solo de biometría).
- Validar el ciclo completo con foto contra el servidor institucional (10.5.213.103)
  — solo se probó en laboratorio (192.168.1.71) hasta ahora.

---

## 📐 Diagrama de Flujo Completo (2026-07-09)

### ENROLAMIENTO (con foto)
```
OPERARIO
  ↓
  ┌─ Abre "Reconocimiento facial"
  ├─ Presiona "Iniciar captura"
  │   ↓
  │   [CÁMARA EN VIVO — 30fps]
  │   Motor: YuNet detecta rostro
  │   ↓
  ├─ Ingresa DOCUMENTO + Presiona "Enrolar"
  │   ↓
  │   Motor: SFace extrae embedding (128-dims)
  │   Frame → base64 JPG ← NUEVO
  │   ↓
  └─→ APP (facial_modal.py)
      └─→ client.biometria_enrolar(doc, embedding, calidad, foto_base64) ← NUEVO
          ↓
          SERVIDOR (enrolar.php)
          ├─ BiometriaPhotoService::guardarFoto()
          │   └─→ frontend/web/public/uploads/biometria/12345/12345_juan.jpg ← NUEVO
          ├─ fun_guardar_enrolamiento_facial(id, vector, calidad, ruta_foto) ← ACTUALIZADO
          └─→ BD: INSERT tab_enrolamiento_facial(vector, ruta_foto_enrolamiento)
              ↓
              ✅ ENROLADO CON FOTO
```

### IDENTIFICACIÓN (retorna foto)
```
OPERARIO
  ↓
  ┌─ Abre "Reconocimiento facial"
  ├─ Presiona "Iniciar captura"
  │   ↓
  │   [CÁMARA EN VIVO]
  │   Motor: YuNet detecta rostro → SFace embedding (128-dims)
  │   ↓
  ├─ Presiona "Identificar"
  │   ↓
  └─→ APP (facial_modal.py)
      └─→ client.biometria_identificar(embedding)
          ↓
          SERVIDOR (identificar.php) ← ACTUALIZADO
          ├─ fun_identificar_persona_por_rostro() — busca en pgvector
          ├─ SELECT ... FROM tab_enrolamiento_facial WHERE id_persona = ?
          │   └─→ Lee ruta_foto_enrolamiento
          ├─ BiometriaPhotoService::leerFoto(ruta) → base64 ← NUEVO
          └─→ JSON: { match: true, persona: {...}, foto_base64: "..." } ← NUEVO
              ↓
          APP cachea: app_desktop/app/images/12345_juan.jpg ← NUEVO
          ↓
          ✨ ABRE MODAL DE CONFIRMACIÓN (IdentificationConfirmationModal) ← NUEVO
             ┌─────────────────────────────────────────┐
             │ IDENTIFICACIÓN CONFIRMADA              │
             ├─────────┬──────────────┬────────────────┤
             │  FOTO   │  INFORMACIÓN │  HUELLA (TODO) │
             │ (izq)   │  (centro)    │  (derecha)     │
             ├─────────┴──────────────┴────────────────┤
             │ [✓ REGISTRAR]  [CANCELAR]  [DETALLES] │
             └─────────────────────────────────────────┘
             ↓
             OPERARIO: Revisa foto + datos personales
             ↓
             Presiona "✓ Registrar Ingreso"
             ↓
          APP: registra con metodo_aut=4 (biométrico facial)
          ✅ INGRESO/SALIDA REGISTRADO

CUMPLIMIENTO MSPI + FASE 0-1:
- E1: Validación visual (foto + datos confirman identidad) ✅
- E2: Cifrado en reposo — 🔲 DIFERIDO explícitamente (decisión SENA, no de este ciclo).
  Fotos en filesystem plano, no BYTEA — mejor que antes, pero no cifrado real.
- E4: Confirmación explícita (usuario aprueba antes de registrar) ✅
- E6: Validación MIME (finfo: JPEG/PNG/WebP, prueba real: rechaza payload inválido) ✅
- E10: Auditoría (usr_insert = porteria, ruta_foto en BD, tests automatizados) ✅
```

---

## 🚀 Plan de Desarrollo Futuro (MSPI + Fase 0-1)

**Consigna obligatoria (desde 2026-07-09):** TODO desarrollo en app_desktop DEBE cumplir MSPI + Fase 0 + Fase 1. Ver [`CLAUDE.md`](../CLAUDE.md) sección "PREMISAS PRINCIPALES".

### Feature #1: Caché Offline + Sincronización ⭐ RECOMENDADO
**Prioridad:** 🔴 ALTA  
**Esfuerzo:** 3h  
**MSPI:** Eje 5 (Disponibilidad)  
**E-tasks aplicables:** E4 (hardening sesión offline), E10 (SDLC seguro)

**Qué es:**
- SQLite local en `~/.smartcset/cache.db` almacena: catálogos (tipos persona, documento, entradas), últimas personas registradas, estado de sesión
- Si la red cae, portería puede seguir capturando ingresos/salidas localmente (modo fallback)
- Al recuperarse la conexión, sincroniza automáticamente con el servidor

**Implementación:**
- `app/cache/sync_manager.py` — gestor de sincronización
- `app/ui/offline_status.py` — indicador visual en topbar
- Modificar `SmartcsetClient` para detectar fallo de red y switchear a cache
- Tests: `tests/test_offline_sync.py`

**Checklist de cumplimiento MSPI:**
- [ ] MSPI: Mapeo Eje 5 (disponibilidad) + Eje 3 (confidencialidad: cache encriptado)
- [ ] E4: ¿Sesión válida offline? Validar token antes de registrar
- [ ] E10: Tests automatizados de sincronización
- [ ] Datos sensibles: ¿Cache cifrado? → Usar `sqlite3` con PRAGMA `key`
- [ ] TLS: Al sincronizar, exigir HTTPS (E8)

**Post-implementación:** Portería puede registrar 50+ ingresos/salidas sin internet, sin bloqueo. ✅ Listo para producción.

---

### Feature #2: Reportes de Auditoría Local
**Prioridad:** 🟠 MEDIA  
**Esfuerzo:** 2h  
**MSPI:** Eje 6 (No-repudio), Eje 8 (Seguridad en desarrollo)  
**E-tasks:** E10 (SDLC seguro, logs/auditoría)

**Qué es:**
- Vista "Reportes" en la app que muestra: ingresos/salidas por fecha, by operario, fallos de biometría, intenios de sincronización fallidos
- Exporta a PDF/CSV (sin salir de la app)
- Logs locales en `~/.smartcset/logs/` (rotados, max 30 días)

**Implementación:**
- `app/ui/pages/reportes.py` — nueva página de reportes
- `app/reports/generator.py` — generador de PDF (reportlab + PyPDF2 ligeros)
- Modificar `motor/embeddings.py` para loguear intentos (éxito/fallo)

**Checklist:**
- [ ] MSPI: Eje 6 (no-repudio: cada acción queda auditada)
- [ ] E10: Logs con timestamp, usuario, acción, resultado
- [ ] Tests: `test_reportes.py` valida que los datos coincidan con servidor
- [ ] Datos sensibles: ¿Foto en logs? NO — solo ID de persona + timestamp
- [ ] TLS: Reportes generados localmente, no se suben a menos que el usuario quiera

---

### Feature #3: Validaciones de Seguridad Mejoradas
**Prioridad:** 🔴 ALTA  
**Esfuerzo:** 2.5h  
**MSPI:** Eje 5 (Control de acceso), Eje 7 (Desarrollo seguro)  
**E-tasks:** E1 (validación), E3 (rate limit), E10 (SDLC)

**Qué es:**
- Detectar y bloquear intentos de ingreso duplicado en corto tiempo (persona intenta enrolar 2 veces en 10s → rechazo)
- Respetar rate limit del servidor (E3): si servidor dice "bloqueada por IP", mostrar countdown visual
- Validar documento contra BD local antes de permitir ingreso (más rápido, feedback inmediato)
- Timeout de sesión: si lleva 30min sin actividad, cierra sesión (logout automático)

**Implementación:**
- Modificar `ingreso.py` / `salida.py` para chequeos duplicados
- `smartcset_client.py`: parsear headers de rate limit del servidor
- `ui/shell.py`: mostrar contador de sesión activa
- Migración `add_session_timeout_tracking.sql` (opcional, si queremos que el servidor also track timeouts)

**Checklist:**
- [ ] MSPI: Eje 5 (control de acceso robusto)
- [ ] E1: ¿Quién puede registrar? Validar sesión + menú (porteria)
- [ ] E3: ¿Rate limit respetado? Si servidor rechaza con 429, app muestra countdown
- [ ] Tests: `test_validation_security.py` simula 5+ ingresos simultáneos
- [ ] Datos sensibles: Cache de validación es local, no persiste después de sesión

---

### Feature #4: UI/UX Endurecida
**Prioridad:** 🟠 MEDIA  
**Esfuerzo:** 2.5h  
**MSPI:** Eje 5 (usabilidad segura)  
**E-tasks:** E4 (hardening sesión: indicador visual claro)

**Qué es:**
- Indicador claro en topbar: "🔐 Sesión activa (30 min)" con countdown
- Botón "Salir" siempre visible (logout)
- Modal de confirmación antes de acción crítica (ej. "¿Registrar ingreso para Pérez?")
- Temas de color: rojo si sesión va a expirar (<5 min), verde si todo está OK
- Layout responsive: si ventana muy pequeña, collapse sidebar automáticamente

**Implementación:**
- `ui/theme.py`: agregar tema "warning" (amarillo/rojo)
- `ui/shell.py`: mejorar topbar con timer de sesión
- Todas las páginas: agregar modales de confirmación
- `ui/camera.py`: feedback visual durante captura de rostro (spinner, "Detectando cara...")

**Checklist:**
- [ ] MSPI: Eje 5 (usabilidad = seguridad, menos errores operario)
- [ ] E4: Sesión clara: ¿cuánto tiempo queda? ¿Quién está logueado?
- [ ] Tests: UI no se freezea durante operaciones largas (captura, sincronización)
- [ ] Accesibilidad: botones suficientemente grandes (touch-friendly si llega a ser tablet)

---

### Feature #5: Documentación de Usuario + Capacitación
**Prioridad:** 🟡 BAJA técnica, 🔴 ALTA estratégica  
**Esfuerzo:** 1.5h  
**MSPI:** Eje 7 (Gestión del cambio)  
**E-tasks:** E10 (SDLC seguro: documentación)

**Qué es:**
- Guía PDF: "Cómo usar la app de portería" (screenshots, paso a paso)
- Video 5min: captura de pantalla + voz en español (screencast con ffmpeg)
- FAQ: preguntas frecuentes de operarios (¿qué pasa si se cuelga? ¿Cómo resetear?)
- Help integrado en la app: botón "?" en cada página que abre tooltips contextuales

**Implementación:**
- `docs/USUARIO_GUIA.md` en app_desktop
- `docs/screenshots/` con capturas anotadas
- `app/ui/help_modal.py` — modal de ayuda por página
- Video se genera con `ffmpeg` + audio narrado (plantilla Audacity)

**Checklist:**
- [ ] MSPI: Eje 7 (gestión cambio: capacitación obligatoria)
- [ ] E10: Documentación clara, en español, sin jerga técnica
- [ ] Accesibilidad: video con subtítulos (ASR automático o manual)
- [ ] Tests: FAQ cubre 80% de preguntas de usuarios reales

---

## 🎯 Roadmap Recomendado

### **Fase 2 (Presentación Director SENA — 29-07-2026)**
1. ✅ Feature #1 — Caché offline (3h) → **CRÍTICO para prod**
2. ✅ Feature #3 — Validaciones mejoradas (2.5h) → **Cierra E1/E3/E10**
3. ✅ Feature #5 — Documentación + video (1.5h) → **Impacto percibido**

**Total:** 7h = Completable en 1 sesión de desarrollo + testing

### **Fase 3 (Post-presentación — Agosto 2026)**
4. ✅ Feature #2 — Reportes de auditoría (2h) → Auditoría interna
5. ✅ Feature #4 — UI/UX endurecida (2.5h) → Pulir experiencia

**Total:** 4.5h

---

## 🔧 Infraestructura Técnica Disponible

### Backend (Todos los endpoints ya existen, reutilizables)
```
✅ /auth/v1/login.php                    — Login real + sesión PHP
✅ /porteria/v1/ingreso/{consultar,registrar}.php
✅ /porteria/v1/salida/{consultar,registrar}.php
✅ /porteria/v1/catalogos.php            — Tipos doc, persona, entradas
✅ /porteria/v1/biometria/{enrolar,identificar}.php  — Facial (2026-07-09)
✅ /entradas/v1/{list,create,delete}.php — Admin
```

### Base de Datos
```
✅ tab_log_ingresos       — Tabla principal de ingresos/salidas
✅ tab_enrolamiento_facial — Vectores biométricos (pgvector 128) +
                              ruta_foto_enrolamiento (2026-07-09)
✅ tab_intentos_login     — Rate limiting (E3)
✅ tab_sesiones           — Sesiones activas (E4)
```

### Filesystem de fotos (Opción A, 2026-07-09)
```
✅ frontend/web/public/uploads/biometria/{id}/{id}_{nombre}.jpg  — servidor (fuente de verdad)
✅ app_desktop/app/images/{id}_{nombre}.jpg                      — caché local de la app (no versionado)
✅ backend/services/porteria/biometria_photo_service.php         — guardar/leer, valida MIME real
```

### Cliente HTTP
```
✅ SmartcsetClient (app/smartcset_client.py)
   — urllib stdlib puro (sin requests)
   — TLS validation activo (verify_tls=True)
   — Manejo de cookies (sesión PHP)
   — Retry automático en transient errors
```

### Motor Biométrico
```
✅ motor/embeddings.py     — YuNet + SFace (128 dims)
✅ motor/models/           — ONNX vendorizados (no deps externas)
✅ Detección + captura real en vivo
```

---

## 📝 Notas de Implementación

### Convenciones
- **Python:** PEP8 estricto (línea ≤79 caracteres)
- **Funciones:** `snake_case`, docstrings con `"""..."""`
- **Clases UI:** heredar de `tk.Frame`, `tk.Toplevel`
- **Errores:** loguear con `logging.error()`, mostrar al usuario con `SmartToast.error(msg)`

### Testing
- Todos los tests golpean el backend real (sin mocks)
- Limpiar datos propios antes/después de cada test
- Usar `psql` para verificaciones críticas (transacciones, auditoría)
- Suite: `cd app_desktop/app/tests && python3 -m unittest test_*.py -v`

### Seguridad
- **Datos sensibles:** Nunca loguear documentos, fotos, vectores faciales en texto plano
- **Caché:** Encriptar con `sqlite3` PRAGMA `key=<salt>`
- **Red:** HTTPS siempre, TLS validation `verify_tls=True`
- **Sesión:** Timeout 30min inactividad, logout explícito obligatorio

### Depuración
- Logs locales en `~/.smartcset/logs/app.log` (rotado diario)
- Activar modo verbose: `SMARTCSET_DEBUG=1 python3 main.py`
- Conectar a BD real para inspeccionar auditoría: `psql -h 10.5.213.103 -U postgres -d db_smartcset2`

---

## 📞 Contacto / Escalación

- **Lead Developer:** Anderson (smartcset owner)
- **Backend issues:** Ver `CLAUDE.md` bugs documentados (1-19)
- **BD issues:** Conectar con servidor remoto, ver `HANDOFF.md` principal del proyecto
- **Presentación Director:** 29-07-2026 (20 días desde 2026-07-09)

---

**Fin del HANDOFF.md — Actualizar este documento al completar cada feature.**
