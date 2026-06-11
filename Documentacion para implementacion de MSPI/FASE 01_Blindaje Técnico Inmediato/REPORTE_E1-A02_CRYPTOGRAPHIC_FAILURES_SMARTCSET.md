# Reporte de auditoría — E1-A02: Cryptographic Failures

**Documento N°:** FASE1-REP-A02
**Versión:** 1.0
**Fecha de elaboración:** 2026-06-11
**Entregable padre:** FASE1-BLI-001 — Entregable 1 (Auditoría OWASP Top 10)
**Control OWASP:** A02:2021 — Cryptographic Failures
**Estado:** ⚠️ Auditado — 1 de 3 hallazgos preparado en código (activación pendiente de E8/Oficina TI); 2 de 3 hallazgos bloqueados por prerrequisitos institucionales de E2 y E4
**Elaborado por:** Equipo de Desarrollo - SmartCSET
**Clasificación:** Interno — Seguridad de la Información

---

## 1. Resumen ejecutivo

Se ejecutó la auditoría del control **A02 — Cryptographic Failures** del OWASP Top 10 2021 sobre SmartCSET, cubriendo sus 4 subcontroles documentados en FASE1-BLI-001 §3.2.

A diferencia de **A01** (8 endpoints, fix autocontenido y de riesgo cero), los hallazgos de A02 **no se cierran con cambios de código aislados**: dependen de los entregables **E2** (cifrado en reposo, pgcrypto), **E4** (hardening de sesiones / HTTPS) y **E8** (TLS en la conexión PHP↔PostgreSQL, en su mayor parte responsabilidad de la Oficina TI SENA).

**Resultado de la auditoría:**

1. ✅ **Contraseñas con bcrypt** — ya cumplía, sin acción.
2. ❌ **Cifrado en reposo de `tab_personas.documento_identidad`** — no implementado. Plan completo en E2, **bloqueado** por prerrequisitos institucionales (custodio de `DB_ENCRYPTION_KEY` y BD de test).
3. ⚠️ **TLS en la conexión PHP↔PostgreSQL** — DSN sin `sslmode`. Se preparó hoy la **infraestructura de código** (config flexible, sin romper el entorno actual); la **activación** depende de que la Oficina TI habilite SSL en PostgreSQL (E8).
4. ❌ **HTTPS forzado en producción** — bloque de redirección comentado y `SecurityMiddleware` sin incluir. Plan en E4, **bloqueado** por la obtención de un certificado TLS (prerrequisito 6).

Este reporte documenta el estado real (sin afirmar remediaciones que no existen, conforme a la regla de honestidad temporal del proyecto) y dejar trazado el plan de cierre de cada hallazgo.

---

## 2. Alcance de la auditoría

| Subcontrol A02 (FASE1-BLI-001 §3.2) | Resultado | Acción |
|---|---|---|
| **1. Contraseñas hasheadas con algoritmo robusto** | ✅ Cumple — `password_verify()` con bcrypt | Sin acción |
| **2. Datos sensibles cifrados en reposo** (`tab_personas`) | ❌ No implementado | Plan de remediación → **E2** (bloqueado) |
| **3. TLS en conexión PHP↔PostgreSQL** (DSN) | ⚠️ Sin `sslmode` — infraestructura preparada hoy | Activación → **E8** (bloqueado por Oficina TI) |
| **4. HTTPS forzado en producción** | ❌ Redirect comentado, `SecurityMiddleware` no incluido | Plan de remediación → **E4** (bloqueado) |

---

## 3. Hallazgos detallados

### 3.1 Hallazgo 1 — Cifrado en reposo ausente en `tab_personas`

- **Tipo:** Cryptographic Failure — exposición de datos sensibles en reposo (CWE-311).
- **Evidencia:** `\d tab_personas` en psql no muestra columnas `_enc`; el campo `documento_identidad` se almacena en texto plano. El inventario de activos (FASE0-INV-002, INF-01) clasifica `tab_personas` con confidencialidad **Muy Alta**.
- **Riesgo:** cualquiera con acceso a un `pg_dump`, backup, o réplica de la BD —sin pasar por la capa de aplicación ni por `password_verify`— puede leer el número de documento de identidad de cada persona registrada (visitantes, aprendices, instructores, funcionarios, contratistas).
- **Severidad:** Crítico (dato personal sensible bajo Ley 1581/2012, art. 269F Ley 1273/2009 si hay fuga).
- **Plan de remediación:** **Entregable 2** (FASE1-BLI-001 §4) — 7 pasos con `pgcrypto`: extensión, columnas `documento_identidad_enc BYTEA` + `ind_cifrado BOOLEAN`, `DB_ENCRYPTION_KEY`, funciones `fun_cifrar_documento`/`fun_descifrar_documento` (`SECURITY DEFINER`), migración de datos en transacción, actualización de `prepare.php`.
- **Bloqueadores (FASE1-CHK-002, prerrequisitos institucionales 1 y 2):**
  - Prerrequisito 1: designar custodio formal de `DB_ENCRYPTION_KEY`.
  - Prerrequisito 2: disponer de `db_smartcset_test` para validar la migración antes de tocar producción.
- **Estado:** 🔲 Pendiente, sin fecha — depende de decisiones institucionales, no de disponibilidad de tiempo de desarrollo.

---

### 3.2 Hallazgo 2 — Conexión PHP↔PostgreSQL sin TLS (DSN sin `sslmode`)

- **Tipo:** Cryptographic Failure — datos en tránsito sin cifrar (CWE-319).
- **Evidencia (antes del cambio):** `src/core/Db.php:26` construía el DSN como `pgsql:host=...;port=...;dbname=...`, sin `sslmode`. libpq usa por defecto `prefer` (intenta TLS, pero si el servidor no lo soporta, **continúa en texto plano sin avisar**).
- **Riesgo:** en una red interna compartida, el tráfico PHP↔PostgreSQL —incluyendo credenciales de aplicación y los datos de `tab_personas`— viaja sin cifrar y es susceptible de captura (sniffing/ARP spoofing en LAN).
- **Severidad:** Crítico (mismo dato sensible que el Hallazgo 1, pero en tránsito).

**Remediación aplicada hoy (preparación de infraestructura, sin activar):**

Se siguió el patrón de `src/core/config.php` (todo via `.env`/`EnvLoader`, nunca hardcodeado) y se hizo el cambio **configurable y retrocompatible**, en lugar de forzar `sslmode=require` directamente — porque ese valor **rompería la conexión** en cualquier PostgreSQL local que no tenga `ssl=on` configurado (el caso actual de desarrollo, según FASE1-BLI-001 §10.3).

| Archivo | Cambio |
|---|---|
| `src/core/config.php` | + `define('DB_SSLMODE', EnvLoader::get('DB_SSLMODE', ''))` — vacío por defecto |
| `src/core/Db.php` | El DSN agrega `;sslmode=<DB_SSLMODE>` **solo si** la variable no está vacía |
| `.env.example` | + `DB_SSLMODE=` documentada con instrucciones de activación |

```php
// src/core/Db.php — connect()
$dsn = 'pgsql:host=' . DB_HOST . ';port=' . DB_PORT . ';dbname=' . DB_NAME;

$sslmode = defined('DB_SSLMODE') ? trim((string) DB_SSLMODE) : '';
if ($sslmode !== '') {
    $dsn .= ';sslmode=' . $sslmode;
}
```

Con `DB_SSLMODE` vacío (no presente en `.env`), el comportamiento es **idéntico al actual** — cero riesgo de regresión en el entorno de desarrollo de Anderson.

**Pendiente para cierre (depende de E8 — Oficina TI SENA, FASE1-BLI-001 §10.3):**

1. Oficina TI habilita `ssl = on` + `ssl_cert_file`/`ssl_key_file` en `postgresql.conf`, y cambia `host` → `hostssl` en `pg_hba.conf`.
2. Una vez habilitado, agregar a `.env` del servidor correspondiente:
   - Desarrollo / misma red interna confiable: `DB_SSLMODE=require` (cifra el canal, no valida CN del certificado).
   - Producción: `DB_SSLMODE=verify-full` (valida también el CN del certificado del servidor BD).
3. Verificar con `pg_stat_ssl` (ver §5).

- **Estado:** ⚠️ Infraestructura de código lista y verificada (lint); **activación bloqueada por E8** hasta que Oficina TI habilite SSL en PostgreSQL.

---

### 3.3 Hallazgo 3 — HTTPS no forzado en producción

- **Tipo:** Cryptographic Failure — datos en tránsito sin cifrar entre navegador y servidor web (CWE-319).
- **Evidencia:**
  - `index.php:14-15` — bloque de redirección a HTTPS está **comentado**:
    ```php
    // Forzar HTTPS en producción (comentar en desarrollo)
    // if (APP_ENV === 'production' && empty($_SERVER['HTTPS'])) {
    //     header("Location: https://" . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI']);
    ```
  - `src/core/SecurityMiddleware.php:35-41` — `enforceHTTPS()` existe y está bien escrito, pero el método **no se llama** (`initialize()` lo tiene comentado, línea 15) y, además, **el archivo entero nunca se incluye** vía `require_once` en el flujo real (código muerto, hallazgo ya documentado en AGENTS.md §6).
- **Riesgo:** si el servidor web no fuerza HTTPS, un usuario que acceda por `http://` envía credenciales de login y la cookie `PHPSESSID` en texto plano.
- **Severidad:** Crítico.
- **Plan de remediación:** **Entregable 4** (FASE1-BLI-001 §6) — activar `SecurityMiddleware::initialize()` desde `prepare.php`, descomentar el redirect condicionado a `APP_ENV === 'production'`, y configurar `session.cookie_secure=1` (también condicionado a producción, para no romper desarrollo en HTTP).
- **Bloqueador:** prerrequisito 6 del checklist (certificado TLS para HTTPS en producción) — sin certificado, forzar HTTPS en producción dejaría el sitio inaccesible.
- **Estado:** 🔲 Pendiente — se resuelve como parte de E4 completo, no solo de A02.

---

## 4. Cambios aplicados en esta sesión

| Archivo | Cambio | Riesgo de regresión |
|---|---|---|
| `src/core/config.php` | + constante `DB_SSLMODE` (vía `EnvLoader`, default `''`) | Ninguno — valor por defecto preserva el comportamiento actual |
| `src/core/Db.php` | DSN agrega `;sslmode=<DB_SSLMODE>` solo si la variable no está vacía | Ninguno mientras `DB_SSLMODE` no se defina en `.env` |
| `.env.example` | + `DB_SSLMODE=` documentada (valores válidos, cuándo activarla, qué pasa si se activa sin soporte SSL en PG) | — |

**No se modificó** el `.env` real de Anderson (no versionado) — no se agregó `DB_SSLMODE` ahí, por lo que el sistema sigue conectando exactamente igual que antes de este cambio.

---

## 5. Verificación pendiente (a ejecutar cuando haya acceso al servidor / BD)

1. **Sin cambios en `.env` (estado actual, `DB_SSLMODE` ausente o vacío):** confirmar que el login y la conexión a BD funcionan igual que antes de este cambio → **sin regresión**. Esto se puede probar hoy mismo en el entorno habitual de Anderson.
2. **Cuando la Oficina TI habilite `ssl=on` en PostgreSQL:**
   ```bash
   # Agregar a .env:
   DB_SSLMODE=require
   ```
   Luego verificar en `psql` (conectado como el usuario de PHP):
   ```sql
   SELECT pg_stat_ssl.pid, pg_stat_ssl.ssl, pg_stat_ssl.version, pg_stat_ssl.cipher
   FROM pg_stat_ssl
   JOIN pg_stat_activity ON pg_stat_ssl.pid = pg_stat_activity.pid
   WHERE pg_stat_activity.datname = 'db_smartcset';
   ```
   - **Resultado esperado:** columna `ssl = TRUE` para las conexiones del servidor web, `version` muestra TLSv1.2 o superior.
3. **Prueba de fallo controlado (NO ejecutar en el entorno de desarrollo activo de Anderson si PG no tiene SSL):** en una BD de test sin `ssl=on`, setear `DB_SSLMODE=require` y confirmar que la conexión **falla** con un error claro tipo `SSL connection has been closed unexpectedly` o `server does not support SSL` → confirma que el flag tiene efecto real y no se ignora silenciosamente.

---

## 6. Tabla de hallazgos consolidada (actualiza FASE1-BLI-001 §3.3)

| Hallazgo | Detalle | Severidad | Entregable que cierra | Estado | Verificador |
|---|---|---|---|---|---|
| A02 — Cifrado en reposo | `tab_personas.documento_identidad` sin cifrar | Crítico | Entregable 2 | 🔲 Bloqueado (prereq. 1 y 2) | — |
| A02 — TLS BD | DSN sin `sslmode` | Crítico | Entregable 8 | ⚠️ Código listo, activación pendiente | — |
| A02 — HTTPS forzado | Redirect comentado, `SecurityMiddleware` no incluido | Crítico | Entregable 4 | 🔲 Bloqueado (prereq. 6) | — |

---

## 7. Trazabilidad normativa / certificación

| Marco | Mapeo |
|---|---|
| **OWASP Top 10 2021** | A02:2021 — Cryptographic Failures |
| **ISC2 CC** | Dominio 1 — Security Principles (confidencialidad, criptografía); Dominio 4 — Network Security (cifrado en tránsito) |
| **ISO/IEC 27001** | A.8.24 — Uso de criptografía; A.8.20/A.8.21 — Seguridad de redes y servicios de red |
| **MSPI MinTIC** | Eje 6 — Seguridad en comunicaciones y operaciones |
| **Ley 1581/2012** | Art. 4 (g) Principio de seguridad — medidas técnicas para proteger datos personales contra acceso no autorizado |
| **FASE0-RIE-003** | Riesgo R-E1 (cifrado de datos sensibles) — no se cierra con este reporte; queda condicionado a E2 |

---

## 8. Pendientes derivados (fuera del alcance cerrable de A02)

- **`database/migrations/password_migrator.php:17`** construye su propio DSN sin `sslmode` (no usa `Db::connect()`). Es un script marcado como *"BORRAR DESPUÉS DE USAR"* — su eliminación o actualización queda como tarea de **E10 (SDLC)**, fuera del alcance de A02.
- El cierre real de A02 requiere completar **E2** (cifrado en reposo) y **E4** (HTTPS forzado), y la **activación** de `DB_SSLMODE` cuando Oficina TI complete su parte de **E8**. Este reporte deja la infraestructura de código lista para esos tres entregables, pero **A02 no puede marcarse ✅ hasta que los tres avancen**.
- Recomendación: dar seguimiento a los prerrequisitos institucionales 1, 2 y 6 del checklist (FASE1-CHK-002) — son la dependencia crítica común a A02, E2, E4 y E8.

---

**Fin del documento**
