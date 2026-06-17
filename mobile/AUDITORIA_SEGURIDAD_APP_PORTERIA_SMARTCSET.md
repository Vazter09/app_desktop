# Auditoría de seguridad completa — App móvil de portería (APK) y API REST asociada

**Documento N°:** FASE1-REP-MOB01
**Versión:** 2.0 — auditoría completa (OWASP + MSPI 11 ejes + ISC2 CC 5 dominios + marco legal colombiano)
**Fecha de elaboración:** 2026-06-12
**Entregable relacionado:** FASE1-BLI-001 — Entregable 1 (Auditoría OWASP Top 10), extendido a superficie nueva `mobile/porteria-app/` + `src/api/porteria/`
**Estado:** ⚠️ Auditado en su totalidad bajo los 4 marcos de referencia del proyecto — sin remediación aplicada todavía
**Elaborado por:** Equipo de Desarrollo - SmartCSET
**Clasificación:** Interno — Seguridad de la Información

> **v2.0 vs v1.0:** la v1.0 (misma fecha) auditó esta superficie solo desde OWASP Top 10. Esta versión añade una revisión sistemática contra **los 11 ejes MSPI** (según el mapeo de FASE0-PSI-006 §11), **los 5 dominios ISC2 CC**, y el **marco legal colombiano completo** (Ley 1581, 1273, 1712, CONPES 3995, Decreto 338/2022). Se conservan los hallazgos H-MOB-01 a H-MOB-09 de la v1.0 y se agregan **H-MOB-10, H-MOB-11 y H-MOB-12**, encontrados al revisar el diseño de negocio (A04/A08) y la continuidad operativa (Eje 10 / ISC2 D2).

---

## 1. Resumen ejecutivo

Se auditó la app móvil **SmartCSET Portería** (`mobile/porteria-app/`, Expo/React Native, APK side-loaded para tablets de portería) y su API REST (`src/api/porteria/v1/`) contra los **4 marcos simultáneos** del proyecto:

1. **OWASP Top 10 2021** (A01-A10 completo)
2. **MSPI MinTIC** (11 ejes de gestión, según FASE0-PSI-006 §11)
3. **ISC2 Certified in Cybersecurity** (5 dominios)
4. **Marco legal colombiano** (Ley 1581/2012, Ley 1273/2009, Ley 1712/2014, CONPES 3995/2020, Decreto 338/2022)

**12 hallazgos** en total:

| Severidad | Cantidad | IDs |
|---|---|---|
| 🔴 Crítico | 2 | H-MOB-01, H-MOB-04 |
| 🟠 Alto | 3 | H-MOB-02, H-MOB-03, H-MOB-10 |
| 🟡 Medio | 4 | H-MOB-05, H-MOB-06, H-MOB-08, H-MOB-12 |
| 🔵 Bajo | 3 | H-MOB-07, H-MOB-09, H-MOB-11 |

**Conclusión principal:** la arquitectura tiene buenas bases (auth por token bcrypt en todos los endpoints, SecureStore, prepared statements reutilizando funciones PL/pgSQL ya auditadas, idempotencia UUID, validación estricta de fotos). Los hallazgos críticos/altos **no son errores de código aislados**, sino consecuencias del **modelo de confianza**: un token de dispositivo (compartido por todo el personal que usa esa tablet) viaja potencialmente sin cifrar (H-MOB-01), no expira (H-MOB-02), no tiene rate limiting (H-MOB-03), y —si se compromete— permite sobrescribir datos de identidad de **cualquier persona ya registrada** en `tab_personas` (H-MOB-10), además de que la propia tablet guarda datos personales y fotos sin cifrar (H-MOB-04).

---

## 2. Alcance auditado

| Componente | Archivos clave |
|---|---|
| App móvil (Expo/RN) | `mobile/porteria-app/app/**`, `src/api/client.ts`, `src/lib/storage.ts`, `src/lib/pdf417.ts`, `src/sync/SyncEngine.ts`, `src/db/schema.ts`, `app.json`, `eas.json`, `package.json` |
| API REST portería | `src/api/porteria/bootstrap.php`, `lib/ApiAuth.php`, `lib/ApiPayload.php`, `lib/ApiResponse.php`, `lib/ApiSync.php`, `v1/**` (8 endpoints) |
| Lógica de negocio reutilizada | `src/modulos/porteria/lib/ingresos_registro.php`, `salidas_registro.php`, `porteria_foto.php` |
| Base de datos | `database/migrations/add_tab_dispositivos_porteria.sql`, `database/functions/porteria/fun_registrar_ingreso_manual.sql`, `fun_upsert_persona_visitante.sql`, `fun_registrar_salida_manual.sql` |
| Herramientas | `tools/generate_device_token.php` |

No se auditó: build/firma del APK (no hay artefactos `.apk`/`.jks` en el repo — correcto), infraestructura de red del centro (fuera del alcance de SmartCSET).

---

## 3. Arquitectura (resumen funcional)

- La tablet se configura **una vez** (`app/setup.tsx`): URL del servidor + token de dispositivo (`tools/generate_device_token.php`, formato `id_dispositivo.secret`, hash bcrypt en `tab_dispositivos_porteria.token_hash`).
- Token y URL en `expo-secure-store` (Keystore/Keychain del OS).
- Todas las llamadas llevan `Authorization: Bearer <token>` (o `X-Device-Token`), validado en `ApiAuth::requireDevice()`.
- Offline-first: SQLite local (`pending_operations`, `local_accesos`, `catalogos_cache`) guarda ingresos/salidas (incluida foto) sin red, sincroniza cada 30s vía `/sync/batch.php` con `client_id` (UUID) idempotente.
- El servidor reutiliza `ingresoRegistrarManual()` / `salidaRegistrarManual()` / `porteriaGuardarFotoRegistro()` → `fun_registrar_ingreso_manual()` → `fun_upsert_persona_visitante()` (PL/pgSQL).
- **Punto clave para el diseño de hallazgos:** el token autentica un **dispositivo**, no una persona. Toda acción de ese dispositivo se ejecuta con el mismo `id_usuario_audit` (1 usuario fijo por tablet) y con **plena capacidad de escritura sobre `tab_personas`** para cualquier documento que el operador digite.

---

# PARTE A — OWASP Top 10:2021 (cobertura completa A01–A10)

| Categoría | Resultado | Hallazgos |
|---|---|---|
| **A01 — Broken Access Control** | ✅ Sin hallazgos nuevos | Los 8 endpoints exigen `porteriaApiRequireDevice()`. Cualquier dispositivo activo puede consultar/registrar para *cualquier* documento — esto es **por diseño** (la portería debe poder atender a cualquier persona), no es un fallo de control de acceso en sí, pero alimenta H-MOB-10. |
| **A02 — Cryptographic Failures** | 🔴 2 hallazgos | H-MOB-01 (tráfico sin TLS), H-MOB-04 (datos/fotos sin cifrar en el dispositivo) |
| **A03 — Injection** | ✅ Sin hallazgos | Todos los parámetros viajan a funciones PL/pgSQL via `%TYPE` con prepared statements (`ApiPayload` solo hace `trim()`/cast). Parsing de PDF417 (`lib/pdf417.ts`) es regex puro en cliente, no se interpola en SQL. Sin concatenación de strings en consultas. |
| **A04 — Insecure Design** | 🟠 2 hallazgos | H-MOB-08 (auditoría por dispositivo, no por operador), **H-MOB-10** (upsert de identidad sin verificación) |
| **A05 — Security Misconfiguration** | 🟡 3 hallazgos | H-MOB-05 (doble header auth), H-MOB-06 (sin cabeceras de seguridad en API), H-MOB-09 (`PORTERIA_API_ENABLED` no documentado) |
| **A06 — Vulnerable and Outdated Components** | 🔵 1 hallazgo | **H-MOB-11** (sin proceso de auditoría de dependencias npm/Expo) |
| **A07 — Identification and Authentication Failures** | 🟠 2 hallazgos | H-MOB-02 (token sin expiración/rotación), H-MOB-03 (sin rate limiting) |
| **A08 — Software and Data Integrity Failures** | 🟠 2 hallazgos | H-MOB-07 (distribución APK sin integridad), **H-MOB-10** (integridad de `tab_personas`) |
| **A09 — Security Logging and Monitoring Failures** | 🟠 1 hallazgo | H-MOB-03 (sin registro de intentos fallidos de auth de dispositivo) |
| **A10 — Server-Side Request Forgery (SSRF)** | ✅ No aplica | La URL del servidor la define el operador en `setup.tsx` para *salir* desde la app hacia el backend (cliente→servidor); el backend no realiza peticiones salientes a URLs controladas por el cliente. |

---

# PARTE B — Hallazgos detallados

### H-MOB-01 — Tráfico API sin cifrado habilitado por defecto (cleartext)
- **Tipo:** Cryptographic Failure — CWE-319 (A02).
- **Evidencia:** `app.json:28` → `"usesCleartextTraffic": true`. README y `setup.tsx:22` usan `http://192.168.1.50:8080`. `src/api/client.ts` no fuerza `https://`.
- **Riesgo:** el token Bearer, los datos personales (documento, nombres, apellidos) y la foto del visitante viajan en texto plano por la LAN del centro. Cualquiera con acceso a la red puede capturar el token y suplantar la tablet, o leer datos de personas.
- **Severidad:** 🔴 Crítico.
- **Medidas:** (1) documentar que producción **debe** usar `https://`; (2) cuando exista certificado, cambiar `usesCleartextTraffic` a `false` (bloquea HTTP a nivel de OS Android); (3) mientras no haya certificado, registrar el riesgo residual en FASE0-RIE-003 y segmentar la red Wi-Fi de portería (VLAN dedicada, coordinación Oficina TI).
- **Estado:** 🔲 Pendiente — mismo bloqueador (certificado TLS) que E4/E8.
- **Marcos:** OWASP A02 · MSPI Eje 6 (comunicaciones) y Eje 11 (Ley 1581 art. 4g) · ISC2 D4 · Ley 1273 art. 269F (riesgo de interceptación de datos personales).

---

### H-MOB-02 — Token de dispositivo sin expiración ni rotación
- **Tipo:** Identification and Authentication Failures — CWE-613 (A07).
- **Evidencia:** `tab_dispositivos_porteria` solo tiene `ind_activo` y `fec_ultimo_uso`, sin columna de expiración. `ApiAuth::requireDevice()` (`lib/ApiAuth.php:39-79`) solo valida `ind_activo` + `password_verify`.
- **Riesgo:** tablet robada o token extraído conserva acceso **indefinido** hasta desactivación manual en BD. Sin alerta automática de inactividad.
- **Severidad:** 🟠 Alto.
- **Medidas:** (1) columna `fec_expiracion` opcional + validación; (2) procedimiento operativo de desactivación inmediata ante pérdida/robo (incorporar a FASE0-INC-008, ver Eje 10/H-MOB-12); (3) revisión periódica de `fec_ultimo_uso` (FASE0-AUD-005).
- **Estado:** 🔲 Pendiente — bajo esfuerzo, sin dependencias externas.
- **Marcos:** OWASP A07 · MSPI Eje 7 (control de acceso) y Eje 5 (seguridad física del dispositivo) · ISC2 D3 · Ley 1581 art. 4g.

---

### H-MOB-03 — Sin rate limiting ni registro de intentos fallidos en la API
- **Tipo:** Authentication + Logging Failures — CWE-307, CWE-778 (A07/A09).
- **Evidencia:** `lib/ApiAuth.php:39-79` — token inválido devuelve 401 sin registrar el intento, sin contador, sin bloqueo.
- **Riesgo:** fuerza bruta sobre `id_dispositivo.secret` (id secuencial, fácil de enumerar) sin rastro ni alerta. El secreto de 24 bytes + bcrypt hace el ataque caro, pero **la falta de logging es en sí un hallazgo**.
- **Severidad:** 🟠 Alto.
- **Medidas:** (1) registrar intentos fallidos (extender el futuro `tab_intentos_login` de E3 con `tipo='api_dispositivo'`); (2) bloqueo temporal por IP/`id_dispositivo`; (3) diseñar la tabla de E3 de forma genérica desde el inicio para cubrir ambos casos.
- **Estado:** 🔲 Pendiente — ligar a E3.
- **Marcos:** OWASP A07/A09 · MSPI Eje 7 (control de acceso) y Eje 9 (gestión de incidentes — detección) · ISC2 D3/D5.

---

### H-MOB-04 — Datos personales y fotos sin cifrar en el almacenamiento local del dispositivo
- **Tipo:** Cryptographic Failure — exposición en reposo (CWE-311, A02).
- **Evidencia:** `src/db/schema.ts` — `pending_operations`/`local_accesos` (SQLite sin SQLCipher) guardan `documento`, `nombres`, `apellidos`, `observaciones`. `SyncEngine.ts:178-184` (`saveFotoLocal`) guarda la foto como JPEG sin cifrar en `documentDirectory/porteria_fotos/`.
- **Riesgo:** tablet perdida/robada/rooteada → cualquiera con acceso al almacenamiento lee datos personales y fotos en texto plano, sin necesitar credenciales de la app ni de la API.
- **Severidad:** 🔴 Crítico — mismo tipo de dato sensible que `tab_personas.documento_identidad` (H-A02/E2 del reporte web), pero ahora **fuera del perímetro del servidor**, en un dispositivo físico que sale del centro.
- **Medidas:** (1) purgar (`DELETE`, no solo `status='synced'`) `pending_operations`/`local_accesos` apenas se confirme el sync; (2) la foto local **ya se borra** tras sync exitoso (`SyncEngine.ts:120-126`) — verificar que cubra también el caso `salida`; (3) evaluar cifrado de `payload_json`/foto a nivel de archivo (clave derivada del `device_token`, o SQLCipher); (4) procedimiento de borrado remoto/wipe ante pérdida (ligar a H-MOB-02 y H-MOB-12).
- **Estado:** 🔲 Pendiente — requiere diseño. Candidato a **E11** (ver §7 / Plan de acción).
- **Marcos:** OWASP A02 · MSPI Eje 6 y Eje 11 (Ley 1581 art. 4g, dato sensible/identificable) · ISC2 D1 (confidencialidad) y D4 · Ley 1273 art. 269F.

---

### H-MOB-05 — Doble mecanismo de autenticación (`Authorization: Bearer` y `X-Device-Token`)
- **Tipo:** Security Misconfiguration — CWE-696 (A05).
- **Evidencia:** `lib/ApiAuth.php:24-34` acepta el token por dos headers. El cliente (`src/api/client.ts`) solo usa `Authorization: Bearer`; `X-Device-Token` parece código de contingencia no documentado.
- **Riesgo:** 🟡 Medio — duplica superficie a asegurar (ej. si se agrega rate limiting a un canal y se olvida el otro).
- **Medidas:** eliminar `X-Device-Token` si no se usa (minimización, Eje 8/E10); si se mantiene, documentarlo y cubrirlo en H-MOB-03.
- **Estado:** 🔲 Pendiente — esfuerzo muy bajo.
- **Marcos:** OWASP A05 · MSPI Eje 8 (SDLC) · ISC2 D3.

---

### H-MOB-06 — Respuestas de la API sin cabeceras de seguridad HTTP
- **Tipo:** Security Misconfiguration — CWE-693 (A05).
- **Evidencia:** `lib/ApiResponse.php:6-19` solo setea `Content-Type`. `bootstrap.php` no incluye `SecurityMiddleware` (sin uso en todo el proyecto, ya documentado en AGENTS.md).
- **Riesgo:** 🟡 Medio — bajo para un cliente nativo, pero falta defensa en profundidad (`X-Content-Type-Options`, `Cache-Control: no-store` para datos personales).
- **Medidas:** al activar `SecurityMiddleware` (E4), incluirlo también en `bootstrap.php` de la API, o al menos agregar `X-Content-Type-Options: nosniff` y `Cache-Control: no-store`.
- **Estado:** 🔲 Pendiente — ligar a E4.
- **Marcos:** OWASP A05 · MSPI Eje 6 · ISC2 D4.

---

### H-MOB-07 — Distribución del APK sin firma/integridad documentada
- **Tipo:** Insecure Design / Supply Chain — CWE-494 (A08).
- **Evidencia:** `eas.json` (perfiles `development`/`preview`/`production`, todos `.apk`). README: *"instalable sin Play Store"*. Sin documentación del canal de distribución ni verificación de hash.
- **Riesgo:** 🔵 Bajo (mitigado porque configurar la app requiere conocer la URL real + generar token desde el servidor legítimo).
- **Medidas:** documentar en SDLC (E10/Fase 2 E5) el canal oficial de distribución (carpeta interna + checksum SHA-256) y quién puede generar builds.
- **Estado:** 🔲 Pendiente — documental.
- **Marcos:** OWASP A08 · MSPI Eje 8.

---

### H-MOB-08 — Auditoría a nivel de dispositivo, no de operador individual
- **Tipo:** Insufficient Logging / no repudio (A04, ISC2 D1/D5).
- **Evidencia:** `tools/generate_device_token.php` asigna **un solo** `id_usuario_audit` por dispositivo. Todas las operaciones quedan auditadas bajo ese mismo usuario.
- **Riesgo:** 🟡 Medio — un incidente no permite identificar **qué guarda** operó la tablet, solo el dispositivo.
- **Medidas:** (1) si varios guardas comparten tablet: PIN/selector de operador al inicio del turno; (2) si hay guarda fijo por tablet: documentar la asignación dispositivo↔guarda en FASE0-ROL-004 como control compensatorio.
- **Estado:** 🔲 Pendiente de decisión operativa.
- **Marcos:** OWASP A04 · MSPI Eje 4 (seguridad del personal) y Eje 7 · ISC2 D1/D5.

---

### H-MOB-09 — `PORTERIA_API_ENABLED` no documentado en `.env.example`
- **Tipo:** Security Misconfiguration — CWE-1188 (A05).
- **Evidencia:** `lib/ApiAuth.php:8` — por defecto `'1'` (habilitada) si la variable no existe. No está en `.env.example`.
- **Riesgo:** 🔵 Bajo — el operador no sabe que existe un "kill switch" para desactivar la API ante incidente.
- **Medidas:** agregar `PORTERIA_API_ENABLED=1` a `.env.example` con comentario explicando el uso como control de contención.
- **Estado:** 🔲 Pendiente — trivial, agrupar con E7.
- **Marcos:** OWASP A05 · MSPI Eje 9 (contención de incidentes) · ISC2 D5.

---

### H-MOB-10 — `fun_upsert_persona_visitante` permite sobrescribir la identidad de cualquier persona ya registrada
- **Tipo:** Insecure Design + Data Integrity Failure — CWE-915 (asignación masiva de propiedades sin control), relacionado con CWE-840 (lógica de negocio incompleta) (A04/A08).
- **Evidencia:**
  - `database/functions/porteria/fun_registrar_ingreso_manual.sql:42-44` llama `fun_upsert_persona_visitante(wid_persona, wid_tipo_docum, wid_tipo_persona, wnom_persona, wape_persona, wusr)` **antes** de insertar el log de ingreso.
  - `database/functions/porteria/fun_upsert_persona_visitante.sql:48-56` — si `id_persona` **ya existe** en `tab_personas` (puede ser un aprendiz, instructor, funcionario o contratista, no solo "visitante"), hace `UPDATE ... SET id_tipo_docum, id_tipo_persona, nom_persona, ape_persona` con **los valores recibidos del request**, sin comparar contra el registro existente ni pedir confirmación.
  - En el flujo móvil, `nom_persona`/`ape_persona`/`id_tipo_persona` provienen directamente del JSON del dispositivo (`ApiPayload::ingresoToPost` → `txt_nombres`, `txt_apellidos`, `sel_tipo_persona`), sin validar que coincidan con los datos ya almacenados de esa persona.
- **Riesgo:** un dispositivo autenticado (token válido, robado o de un guarda con intención maliciosa) puede registrar un "ingreso" para el **documento de un tercero** (ej. la cédula de un instructor) con `nombres`/`apellidos`/`tipo_persona` distintos, y la función **sobrescribe silenciosamente** el registro maestro de esa persona en `tab_personas`. Esto:
  1. Corrompe datos de identidad usados en otros módulos (listados administrativos, reportes SENA DF-49/PE-04).
  2. Permite **falsificar el log de acceso físico** atribuyendo una entrada/salida a una identidad incorrecta — relevante para Ley 1273/2009 **art. 269I (hurto por medios informáticos)** o, en su acepción de suplantación de identidad en sistemas de información, expone al sistema a registros de acceso no confiables.
  3. No es exclusivo del flujo móvil (la función es compartida con el módulo web), pero el **modelo de credencial de dispositivo** (compartida, sin expiración — H-MOB-02, sin rate limiting — H-MOB-03) **amplía considerablemente la ventana de explotación** respecto al flujo web (donde cada operador tiene su propia cuenta).
- **Severidad:** 🟠 Alto.
- **Medidas a tomar:**
  1. **Mínimo viable:** en `fun_upsert_persona_visitante`, si `id_persona` ya existe y **`id_tipo_persona` actual no es 99 (visitante)** (es decir, la persona es aprendiz/instructor/funcionario/contratista — dato "oficial" que viene de cargas SENA), **no permitir** que el flujo de portería sobrescriba `nom_persona`/`ape_persona`/`id_tipo_docum`/`id_tipo_persona` — solo actualizar campos operativos (`fec_ultima_entrada`, etc.) vía `fun_update_persona_tras_ingreso`, que ya existe y es seguro.
  2. Para personas tipo "visitante" (99) sí es razonable permitir corrección de nombre/apellido (caso de uso real: error de tipeo), pero registrar el cambio en auditoría (`usr_update`/`fec_update` ya existen — verificar que se está generando un registro de auditoría consultable, no solo el campo).
  3. Documentar esta regla de negocio explícitamente como control de integridad del dato maestro de personas (Eje 3 — gestión de activos de información, INF-01 según FASE0-INV-002).
- **Estado:** 🔲 Pendiente — requiere diseño + migración de la función PL/pgSQL (cambio de tipo de retorno NO se requiere, solo lógica interna). Riesgo de regresión: medio (afecta también al módulo web de portería) → probar contra BD de test antes de desplegar.
- **Marcos:** OWASP A04/A08 · MSPI Eje 3 (activos de información) y Eje 7 (control de acceso/autorización granular) · ISC2 D1 (integridad) y D3 · Ley 1273 art. 269I.

---

### H-MOB-11 — Sin proceso de auditoría de dependencias (npm/Expo)
- **Tipo:** Vulnerable and Outdated Components — CWE-1104 (A06).
- **Evidencia:** `package.json` fija versiones de `expo ^56`, `react 19.2.3`, `react-native 0.85.3`, `expo-sqlite`, `expo-secure-store`, etc. No hay script ni documentación de `npm audit` / `expo install --check` / dependabot.
- **Riesgo:** 🔵 Bajo (no se identificó ninguna CVE específica en esta auditoría — requeriría acceso a internet/bases de datos de vulnerabilidades para confirmar), pero es un **gap de proceso**: sin revisión periódica, una dependencia con una vulnerabilidad conocida (ej. en `expo-sqlite`, que maneja datos personales — H-MOB-04) podría pasar desapercibida.
- **Medidas:** incorporar `npm audit` (o `pnpm audit`, dado que el proyecto usa `pnpm-lock.yaml`) y `npx expo-doctor` al checklist de auditorías periódicas (FASE0-AUD-005) y/o a E9 (gestión de parches), con SLA por severidad igual al ya definido para componentes del backend (9+=48h, 7-8.9=7d, 4-6.9=30d).
- **Estado:** 🔲 Pendiente — proceso, no código.
- **Marcos:** OWASP A06 · MSPI Eje 8 y Eje 9 (gestión de parches) · ISC2 D5.

---

### H-MOB-12 — Sin RPO/RTO ni límite documentado para la cola offline ante caída prolongada del servidor
- **Tipo:** Availability / Continuidad — relacionado con CWE-400 (consumo de recursos no acotado) en el peor caso (A04, ISC2 D2).
- **Evidencia:** `src/db/schema.ts` (`pending_operations`) no tiene límite de filas ni política de purga por antigüedad. `SyncEngine.ts` reintenta cada 30s indefinidamente. FASE0-INC-008 define **RTO=4h, RPO=24h** para el sistema central, pero no menciona la app móvil ni su cola offline.
- **Riesgo:** si el servidor central está caído más de 24h (supera el RPO del sistema), las tablets seguirían aceptando ingresos/salidas localmente (comportamiento deseado para continuidad operativa de portería), pero:
  1. No hay tope documentado de cuántas operaciones puede acumular una tablet antes de quedarse sin espacio o degradar rendimiento.
  2. No hay procedimiento de **conciliación manual** si, al recuperarse el servidor, hay conflictos (ej. una persona registró salida manualmente en papel mientras la tablet estaba offline, y luego la tablet sincroniza un "ingreso" para esa misma persona).
- **Severidad:** 🟡 Medio.
- **Medidas:**
  1. Definir y documentar un límite razonable (ej. "hasta 500 operaciones pendientes o 72h, lo que ocurra primero; superado eso, alertar visualmente al operador").
  2. Extender el DRP de FASE0-INC-008 con un apéndice "Continuidad — app móvil de portería": qué hacer si el servidor está caído >RPO (registro en papel + conciliación manual al volver, igual que ya se contempla para el módulo web).
  3. La pantalla **Pendientes** (`app/(tabs)/pendientes.tsx`) ya existe para reintentos manuales — verificar que muestre antigüedad de cada pendiente para apoyar la conciliación.
- **Estado:** 🔲 Pendiente — documental + UI menor.
- **Marcos:** MSPI Eje 10 (continuidad del negocio) · ISC2 D2 (10% del examen — BC/DR/IR) · FASE0-INC-008.

---

# PARTE C — MSPI MinTIC: cobertura por los 11 ejes (FASE0-PSI-006 §11)

| Eje | Descripción | Cobertura en `mobile/` | Acción |
|---|---|---|---|
| **1 — Gobierno de seguridad** | Política aprobada por la dirección | La superficie móvil **no estaba contemplada** en FASE0-PSI-006 ni en FASE1-BLI-001 v1.1 cuando se redactaron | Actualizar FASE1-BLI-001 (o anexo) para incluir `mobile/` + `src/api/porteria/` en el alcance del SGSI |
| **2 — Gestión de riesgos** | FASE0-RIE-003 | Los 31 riesgos R-A01..R-G04 no cubren dispositivos móviles ni API de portería | Agregar riesgos nuevos (ej. "R-MOB-01: robo de tablet con token activo", ligado a H-MOB-02/04) en la próxima revisión de FASE0-RIE-003 |
| **3 — Gestión de activos** | FASE0-INV-002 (16 activos INF) | Tablets, APK y la API `src/api/porteria/` son activos nuevos no inventariados | Agregar entradas INF-17 (tablets de portería), INF-18 (API porteria/v1) con su clasificación de confidencialidad |
| **4 — Seguridad del personal** | FASE0-ROL-004 | H-MOB-08 (auditoría por dispositivo, no por operador); falta capacitación específica sobre custodia de tablets | Definir responsable(s) por tablet y reforzar en capacitación (FASE0-AUD-005) |
| **5 — Seguridad física** | FASE0-ACC-007 §9 (cuarto de servidores) | No cubre la custodia física de **tablets** que salen de portería (H-MOB-02, H-MOB-04) | Procedimiento breve: almacenamiento/anclaje de tablets fuera de horario, responsable de turno |
| **6 — Comunicaciones y operaciones** | TLS, backups, parches | H-MOB-01 (TLS), H-MOB-06 (cabeceras), H-MOB-11 (parches de dependencias móviles) | Igual bloqueador que E8 para TLS; H-MOB-11 a E9 |
| **7 — Control de acceso** | Autenticación, autorización, ciclo de vida | H-MOB-02, H-MOB-03, H-MOB-05, H-MOB-08, H-MOB-10 (autorización granular sobre `tab_personas`) | Concentra la mayoría de hallazgos de severidad alta — prioridad de este eje |
| **8 — Adquisición, desarrollo y mantenimiento** | SDLC seguro, gestión de componentes | H-MOB-07 (distribución APK), H-MOB-09, H-MOB-11 | Incluir `mobile/` explícitamente en el checklist de E10 (SDLC) |
| **9 — Gestión de incidentes** | FASE0-INC-008 | Falta runbook específico: "tablet perdida/robada", "token comprometido", "API portería con tráfico anómalo" | Apéndice a FASE0-INC-008 (ligado a H-MOB-02, H-MOB-09) |
| **10 — Continuidad del negocio** | RTO=4h, RPO=24h, DRP 7 pasos | H-MOB-12 — cola offline sin RPO/RTO propio ni procedimiento de conciliación | Apéndice "continuidad app móvil" a FASE0-INC-008 |
| **11 — Cumplimiento legal** | Ley 1581, 1273, 1712, CONPES 3995, Decreto 338/2022 | Ver Parte D | — |

---

# PARTE D — ISC2 Certified in Cybersecurity: cobertura por los 5 dominios

| Dominio (peso examen) | Cobertura en `mobile/` | Hallazgos relacionados |
|---|---|---|
| **D1 — Security Principles (26%)** | CIA triad: confidencialidad afectada por H-MOB-01/04; integridad afectada por H-MOB-10; disponibilidad por H-MOB-12. Principio de mínimo privilegio: el token de dispositivo tiene privilegio amplio sobre `tab_personas` (cualquier documento) | H-MOB-01, H-MOB-04, H-MOB-10, H-MOB-12 |
| **D2 — Business Continuity, Disaster Recovery & Incident Response (10%)** | FASE0-INC-008 no cubre la app móvil; sin runbook para tablet perdida ni para cola offline prolongada | H-MOB-02, H-MOB-09, H-MOB-12 |
| **D3 — Access Controls (22%)** | Autenticación por dispositivo (no por persona); sin expiración, sin rate limiting, sin granularidad de autorización sobre datos de identidad | H-MOB-02, H-MOB-03, H-MOB-05, H-MOB-08, H-MOB-10 |
| **D4 — Network Security (24%)** | Tráfico cleartext habilitado por defecto; respuestas API sin cabeceras de seguridad | H-MOB-01, H-MOB-06 |
| **D5 — Security Operations (18%)** | Sin logging de intentos de auth fallidos; sin kill-switch documentado; sin proceso de auditoría de dependencias | H-MOB-03, H-MOB-09, H-MOB-11 |

---

# PARTE E — Marco legal colombiano (detalle del Eje 11)

| Norma | Aplicabilidad a `mobile/` | Hallazgos / observación |
|---|---|---|
| **Ley 1581/2012** (protección de datos personales) | Alta — la app procesa y almacena documento, nombres, apellidos y fotografías de personas | H-MOB-01 (tránsito), H-MOB-04 (reposo en dispositivo), H-MOB-10 (exactitud/calidad del dato — principio de calidad art. 4°) |
| **Ley 1273/2009** (delitos informáticos) | Media — art. 269F (violación de datos) si se explota H-MOB-01+04; art. 269I si se explota H-MOB-10 para falsificar registros de acceso | H-MOB-01, H-MOB-04, H-MOB-10 |
| **Ley 1712/2014** (transparencia y acceso a información pública) | **No aplica directamente** — `mobile/` es una herramienta operativa interna de portería, no expone información pública. Sin hallazgos. | — |
| **CONPES 3995/2020** (política nacional de seguridad digital) | Indirecta — los hallazgos H-MOB-01/02/03/04 son ejemplos concretos de los riesgos que CONPES 3995 busca mitigar a nivel nacional (gestión de riesgos digitales, identidad digital). Sin acción específica adicional a las ya listadas. | — |
| **Decreto 338/2022** (infraestructura crítica cibernética — ICC) | **No aplica** — FASE0-INV-002 §12 ya concluyó que el centro no califica como ICC a nivel de infraestructura; la app móvil no cambia esa conclusión (no es infraestructura crítica nacional, es un sistema de control de acceso de un centro de formación) | Confirma conclusión previa, sin cambios |

---

# PARTE F — Controles ya implementados correctamente (✅ sin acción)

| Control | Evidencia |
|---|---|
| Autenticación obligatoria en **todos** los endpoints | `porteriaApiRequireDevice()` en los 8 endpoints de `v1/` |
| Token con buena entropía + hash bcrypt | `tools/generate_device_token.php` — `random_bytes(24)` + `password_hash(..., PASSWORD_BCRYPT)` |
| Credenciales en almacenamiento seguro del OS | `expo-secure-store` en `src/lib/storage.ts` |
| Sin SQL nuevo / reutiliza funciones PL/pgSQL auditadas | `ApiAuth`/`bootstrap.php` → `ingresoRegistrarManual`, `salidaRegistrarManual`, `porteriaGuardarFotoRegistro` |
| Validación estricta de fotos subidas | `porteria_foto.php` — `data:image/(jpeg\|png\|webp);base64`, decodifica, límite 500KB, redimensiona a 800px |
| Idempotencia en sync offline | `client_id` UUID v4 + `tab_porteria_sync_client`, `ApiSync::isValidUuid()` |
| Límite de tamaño de lote en sync | `sync/batch.php` — máx. 20 operaciones por request |
| Sin secretos/artefactos sensibles en el repo | No hay `.apk`, `.jks`, `.env` en `mobile/` (verificado contra `.gitignore`) |
| Borrado de foto local tras sync exitoso | `SyncEngine.ts:120-126` |
| Sin inyección SQL | Prepared statements + `%TYPE` en toda la cadena PHP→PL/pgSQL |
| Sin SSRF | Backend no realiza requests salientes a URLs controladas por cliente |

---

# PARTE G — Tabla consolidada de hallazgos (12)

| ID | Hallazgo | Severidad | OWASP | MSPI Eje(s) | ISC2 | Estado |
|---|---|---|---|---|---|---|
| H-MOB-01 | Tráfico API sin TLS (cleartext) | 🔴 Crítico | A02 | 6, 11 | D4 | 🔲 Bloqueado (cert. TLS) |
| H-MOB-02 | Token de dispositivo sin expiración/rotación | 🟠 Alto | A07 | 5, 7 | D3 | 🔲 Pendiente |
| H-MOB-03 | Sin rate limiting / logging de auth en API | 🟠 Alto | A07, A09 | 7, 9 | D3, D5 | 🔲 Pendiente (ligar a E3) |
| H-MOB-04 | Datos/fotos sin cifrar en dispositivo | 🔴 Crítico | A02 | 6, 11 | D1, D4 | 🔲 Pendiente (diseño) |
| H-MOB-05 | Doble header de auth (`Bearer` + `X-Device-Token`) | 🟡 Medio | A05 | 8 | D3 | 🔲 Pendiente |
| H-MOB-06 | API sin cabeceras de seguridad HTTP | 🟡 Medio | A05 | 6 | D4 | 🔲 Pendiente (ligar a E4) |
| H-MOB-07 | Distribución APK sin canal/integridad documentada | 🔵 Bajo | A08 | 8 | D5 | 🔲 Pendiente (documental) |
| H-MOB-08 | Auditoría por dispositivo, no por operador | 🟡 Medio | A04 | 4, 7 | D1, D5 | 🔲 Pendiente de decisión |
| H-MOB-09 | `PORTERIA_API_ENABLED` no documentado | 🔵 Bajo | A05 | 9 | D5 | 🔲 Pendiente |
| H-MOB-10 | Upsert de identidad sin verificación (`tab_personas`) | 🟠 Alto | A04, A08 | 3, 7 | D1, D3 | 🔲 Pendiente (diseño + migración) |
| H-MOB-11 | Sin auditoría de dependencias npm/Expo | 🔵 Bajo | A06 | 8, 9 | D5 | 🔲 Pendiente (proceso) |
| H-MOB-12 | Sin RPO/RTO para cola offline | 🟡 Medio | — | 10 | D2 | 🔲 Pendiente (documental + UI) |

---

# PARTE H — Plan de acción priorizado

1. **Quick wins (sin dependencias externas, esfuerzo bajo):** H-MOB-02, H-MOB-05, H-MOB-09, H-MOB-07 → agrupar con **E7**.
2. **Diseño de seguridad de negocio (prioridad alta, esfuerzo medio):** H-MOB-10 → requiere ajuste de `fun_upsert_persona_visitante` + pruebas de regresión (afecta también módulo web). Recomendado **antes** de ampliar el despliegue de tablets.
3. **Ligados a entregables ya planeados:** H-MOB-03 → E3; H-MOB-06 → E4; H-MOB-01 → E4/E8 (bloqueado por certificado TLS).
4. **Documental (Eje 9/10):** H-MOB-12 → apéndice a FASE0-INC-008; H-MOB-11 → FASE0-AUD-005/E9.
5. **Requiere diseño propio + decisión operativa:** H-MOB-04 (cifrado local) y H-MOB-08 (modelo de auditoría por operador) → candidatos a un **nuevo entregable E11 — Hardening de la app móvil de portería**.
6. **Actualizaciones de gobierno/activos/riesgos (Ejes 1, 2, 3):** incorporar `mobile/` + `src/api/porteria/` a FASE1-BLI-001 (alcance), FASE0-RIE-003 (riesgos nuevos) y FASE0-INV-002 (activos INF-17/INF-18).

**No se modificó ningún archivo de código ni de planificación en esta sesión** — este documento es un insumo para decidir, junto con Anderson, cómo priorizar e integrar estos hallazgos.

---

**Fin del documento**
