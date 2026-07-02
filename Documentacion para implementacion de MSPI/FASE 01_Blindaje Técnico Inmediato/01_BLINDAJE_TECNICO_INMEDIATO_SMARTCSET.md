# PLAN DE IMPLEMENTACIÓN — BLINDAJE TÉCNICO INMEDIATO
## Sistema SmartCSET — Servicio Nacional de Aprendizaje (SENA)

---

| Campo | Valor |
|---|---|
| **Documento N°** | FASE1-BLI-001 |
| **Versión** | 1.2 — Actualización 2026-06-16: estado de avance real; E5 descartado; tests 23/23 PASS en servidor |
| **Fecha de elaboración** | 2026-06-08 |
| **Elaborado por** | Equipo de Desarrollo - SmartCSET |
| **Estado** | 🟡 En ejecución — E10✅ E7✅ E4✅ E6⚠️(IT) E1⚠️(parcial) · E3🔲 E2⛔ E8⛔(IT) E9🔲 · E5⛔ DESCARTADO |
| **Fundamento normativo / metodológico** | OWASP Top 10 2021; ISO/IEC 27001 Annex A (controles técnicos); MSPI MinTIC Ejes 3, 5, 6, 7, 8; ISC2 Certified in Cybersecurity — Dominios 3 (Access Control), 4 (Network Security) y 5 (Security Operations) |
| **Insumos directos de Fase 0** | FASE0-POL-001 (Tratamiento de Datos); FASE0-INV-002 (Inventario de Activos C-I-D); FASE0-RIE-003 (Matriz de Riesgos); FASE0-ROL-004 (Roles y Responsabilidades); FASE0-AUD-005 (Cronograma de Auditorías); FASE0-PSI-006 (Política General de Seguridad); FASE0-ACC-007 (Control de Acceso y Seguridad Física); FASE0-INC-008 (Marco de Gestión de Incidentes y Continuidad) |
| **Auditoría de codebase** | Realizada el 2026-06-08 sobre el código fuente real de SmartCSET — todos los extractos de código en este documento son del estado actual verificado |

---

> ⚠️ **Nota de gobernanza esencial:** La Fase 0 estableció la base documental (política, inventario de activos, matriz de riesgos, roles, cronograma de auditorías). Sin la Fase 1, esos documentos son solo papel — cualquier auditor que llegue al SENA pedirá, inmediatamente después de revisar la Política de Tratamiento de Datos, evidencia de que los controles técnicos documentados *realmente existen y funcionan* en el código. Este documento es el puente entre tener una política y poder demostrar que la política se aplica.
>
> 🔲 **La implementación de esta fase NO requiere reescribir SmartCSET.** Todos los cambios son localizados y verificables. Varios controles ya tienen código escrito (SecurityMiddleware, CSRF tokens, validación de subida de archivos) — lo que falta es **integrarlos** al flujo real de la aplicación.

---

## TABLA DE CONTENIDO

1. [Objetivo y alcance](#1-objetivo-y-alcance)
2. [Estado de partida — diagnóstico técnico de referencia](#2-estado-de-partida--diagnóstico-técnico-de-referencia)
3. [Entregable 1 — Auditoría OWASP Top 10](#3-entregable-1--auditoría-owasp-top-10)
4. [Entregable 2 — Cifrado en reposo de datos sensibles](#4-entregable-2--cifrado-en-reposo-de-datos-sensibles)
5. [Entregable 3 — Rate limiting y logging de autenticación](#5-entregable-3--rate-limiting-y-logging-de-autenticación)
6. [Entregable 4 — Hardening de sesiones PHP](#6-entregable-4--hardening-de-sesiones-php)
7. [Entregable 5 — Tokens anti-CSRF en formularios](#7-entregable-5--tokens-anti-csrf-en-formularios)
8. [Entregable 6 — Verificación de subida de archivos](#8-entregable-6--verificación-de-subida-de-archivos)
9. [Entregable 7 — Corrección de bugs en setup_smartcset.sh](#9-entregable-7--corrección-de-bugs-en-setup_smartcsetsh)
10. [Entregable 8 — Hardening de red y arquitectura de despliegue](#10-entregable-8--hardening-de-red-y-arquitectura-de-despliegue)
11. [Entregable 9 — Gestión de parches y actualización de componentes](#11-entregable-9--gestión-de-parches-y-actualización-de-componentes)
12. [Entregable 10 — SDLC seguro: checklist de código y despliegue](#12-entregable-10--sdlc-seguro-checklist-de-código-y-despliegue)
13. [Orden de implementación recomendado](#13-orden-de-implementación-recomendado)
14. [Plan de pruebas y verificación integral](#14-plan-de-pruebas-y-verificación-integral)
15. [Estimación de esfuerzo](#15-estimación-de-esfuerzo)
16. [Alineación con ISC2 CC por entregable](#16-alineación-con-isc2-cc-por-entregable)
17. [Referencias cruzadas con documentos de Fase 0](#17-referencias-cruzadas-con-documentos-de-fase-0)
18. [Resumen de puntos que requieren acción institucional](#18-resumen-de-puntos-que-requieren-acción-institucional)

---

## 1. OBJETIVO Y ALCANCE

### 1.1 Objetivo
Aplicar los 8 entregables de blindaje técnico definidos en el Plan de Blindaje Institucional (sección 4.2 — FASE 1), cerrando las vulnerabilidades críticas identificadas en la Matriz de Riesgos (FASE0-RIE-003) mediante cambios localizados y verificables en el código fuente de SmartCSET, su base de datos PostgreSQL y su arquitectura de red/despliegue.

### 1.2 Qué se hace en esta fase
- Integrar los controles de seguridad que ya existen en el código pero no están activos (`SecurityMiddleware`, CSRF tokens, headers HTTP).
- Implementar los controles que faltan completamente (rate limiting, cifrado en reposo, TLS en conexión BD).
- Corregir los bugs de instalación documentados en `SETUP_AUDIT.md` que aún persisten.
- Documentar y verificar el estado de los controles existentes que ya son correctos (subida de archivos).

### 1.3 Qué NO se hace en esta fase
- No se reescribe ningún módulo funcional de SmartCSET (portería, registro, menús, usuarios).
- No se cambia la arquitectura de base de datos (tablas, columnas, relaciones existentes), salvo la adición de la tabla nueva para rate limiting.
- No se implementan controles de Fase 2 (DRP, monitoreo, plan de respuesta a incidentes).
- No se produce documentación de gobernanza adicional (eso ya está en Fase 0).

### 1.4 Mapa de vulnerabilidades vs. entregables

| Riesgo en FASE0-RIE-003 | Entregable que lo cierra | Urgencia |
|---|---|---|
| R-A01 — Fuerza bruta / credential stuffing en login | Entregable 3 (Rate limiting) | 🔴 Crítico |
| R-A03 — Secuestro/fijación de sesión | Entregable 4 (Hardening sesiones) | 🔴 Crítico |
| R-B02 — IDOR en datos de personas | Entregable 1 (Auditoría OWASP A01) | 🔴 Crítico |
| R-C04 — CSRF en cambio de contraseña y formularios | Entregable 5 (Tokens anti-CSRF) | 🔴 Crítico |
| R-E1 — Fuga de datos de identificación (cédula, foto) | Entregable 2 (Cifrado en reposo) | 🔴 Crítico |
| R-E2 — Fuga de datos en tránsito (PHP↔PostgreSQL) | Entregable 8 (Hardening de red, TLS) | 🔴 Crítico |
| R-F3 — Servidor web sin headers de seguridad activos | Entregable 4 (SecurityMiddleware) | 🟠 Alto |
| R-F4 — Información sensible en logs del servidor | Entregable 1 (Auditoría OWASP A09) | 🟠 Alto |
| R-G04 — Bugs en setup_smartcset.sh | Entregable 7 (Corrección de bugs) | 🟠 Alto |
| R-C02 — XSS en subida de archivos | Entregable 6 (Verificación de uploads) | 🟡 Medio |
| R-F5 — Componentes desactualizados con vulnerabilidades conocidas | Entregable 9 (Gestión de parches) | 🟠 Alto |
| R-G05 — Despliegue sin revisión introduce vulnerabilidades nuevas | Entregable 10 (SDLC seguro) | 🟠 Alto |

---

## 2. ESTADO DE PARTIDA — DIAGNÓSTICO TÉCNICO DE REFERENCIA

Auditoría realizada el 2026-06-08 sobre el código fuente de SmartCSET. Esta sección define el "antes" contra el cual se verificará el "después" de cada entregable.

### 2.1 Tabla de diagnóstico consolidado

| Área de control | Archivo principal | Estado actual | Urgencia |
|---|---|---|---|
| Rate limiting en login | `index.php` | ❌ No existe — cero throttling; un atacante puede hacer ilimitados intentos de contraseña | 🔴 |
| Regeneración de ID de sesión tras login | `index.php` líneas 54-68 | ❌ No existe `session_regenerate_id()` — vulnerable a session fixation | 🔴 |
| Tokens anti-CSRF | `backend/core/SecurityMiddleware.php` líneas 76-90 | ⚠️ Código implementado pero **nunca llamado** — cero protección activa | 🔴 |
| Cookie flags (HttpOnly, Secure, SameSite) | `backend/core/config.php` | ❌ No configurados — SecurityMiddleware los define pero el archivo nunca se incluye | 🔴 |
| TLS en conexión PHP↔PostgreSQL | `backend/core/Db.php` líneas 24-39 | ❌ DSN sin `sslmode` — credenciales y datos en texto plano sobre la red | 🔴 |
| Security headers HTTP | `backend/core/SecurityMiddleware.php` | ⚠️ Definidos pero no activos — 4 headers hardcodeados en `index.php`, el resto del sistema sin ellos | 🟠 |
| Cifrado en reposo (cédula, foto) | PostgreSQL / `storage/` | ❌ Todos los datos en texto plano — una copia del disco expone datos de miles de personas | 🔴 |
| Validación de subida de archivos (logo) | `backend/core/LogoUpload.php` | ✅ Bien implementado — finfo, whitelist MIME, límite de tamaño | — |
| Validación de subida (foto portería) | `backend/routers/porteria/v1/lib/porteria_foto.php` | ✅ Bien implementado — base64 estricto, recompresión JPEG, JSONB | — |
| Bugs setup_smartcset.sh (funciones faltantes) | `database/setup_smartcset.sh` | ⚠️ 4 funciones PL/pgSQL existen en disco pero no están en el array FUNCS del script de instalación | 🟠 |
| Arquitectura de red / firewall | Infraestructura SENA | ❌ Sin documentar ni verificar — estado desconocido | 🟠 |

### 2.2 Extractos del código actual problemático

**Login sin rate limiting ni session regeneration (`index.php` líneas 36-81):**
```php
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $w_user = trim($_POST['txt_usuario'] ?? '');
    $w_pass = $_POST['txt_clave'] ?? '';
    // ...
    $stmt_login->execute([$w_user]);
    $w_reg = $stmt_login->fetch();

    if ($w_reg) {
        if (password_verify($w_pass, $w_reg['pass_usuario'])) {
            // ← FALTA: session_regenerate_id(true);
            // ← FALTA: registrar intento exitoso
            $_SESSION['id_usuario'] = $w_reg['id_usuario'];
            // ...
        } else {
            $w_error = "ID de usuario o contraseña incorrectos.";
            // ← FALTA: registrar intento fallido + verificar bloqueo
        }
    }
}
```

**DSN sin TLS (`backend/core/Db.php` líneas 24-39):**
```php
$dsn = 'pgsql:host=' . DB_HOST . ';port=' . DB_PORT . ';dbname=' . DB_NAME;
// ← FALTA: ;sslmode=require (o verify-full en producción)
$pdo = new PDO($dsn, DB_USER, DB_PASS, [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,   // ← Bien: prepared statements reales
]);
```

**CSRF + headers definidos pero nunca llamados (`backend/core/SecurityMiddleware.php`):**
```php
// El código EXISTE — generateCSRFToken(), validateCSRFToken(), setSecurityHeaders()
// PERO el archivo nunca se incluye con require_once en el flujo real de la aplicación.
// Solo index.php tiene 4 headers hardcodeados manualmente (sin CSP, sin STS, sin Permissions-Policy).
```

**Funciones PL/pgSQL ausentes del instalador (`database/setup_smartcset.sh`):**
```bash
# ESTAS FUNCIONES EXISTEN EN DISCO pero NO están en el array FUNCS del script:
# database/functions/acceso/usuarios/fun_validar_correo.sql
# database/functions/acceso/usuarios/fun_validar_login.sql
# database/functions/acceso/usuarios/fun_validar_usuario.sql
# database/functions/acceso/menus/fun_tab_menu_usuarios.sql
# Una instalación limpia ejecutada HOY no las desplegará → recuperación de contraseña falla.
```

---

## 3. ENTREGABLE 1 — AUDITORÍA OWASP TOP 10

### 3.1 Propósito
El OWASP Top 10 2021 es el catálogo de referencia de vulnerabilidades web más críticas. Este entregable produce un checklist formal que certifica el estado de SmartCSET frente a cada control, usando los hallazgos del análisis de código como punto de partida.

> **ISC2 CC:** Este entregable es la materialización operativa del Dominio 5 — Security Operations (gestión de vulnerabilidades) y del Dominio 3 — Access Control (verificación de controles de acceso).

### 3.2 Checklist OWASP Top 10 2021 — SmartCSET

#### A01 — Broken Access Control ✅ Remediado y validado en producción (auditoría 2026-06-10, despliegue y pruebas 2026-06-11)

> Resultado de la auditoría y remediación en `REPORTE_E1-A01_BROKEN_ACCESS_CONTROL_SMARTCSET.md` (esta carpeta). Resultados de las pruebas manuales en producción: §6.4 de ese reporte (11/11 PASS).

| Subcontrol | Archivo a inspeccionar | Comando de verificación | Criterio de aprobación | Estado actual |
|---|---|---|---|---|
| Validación de privilegio admin antes de acciones de admin | `backend/routers/menus/v1/menus.php`, `backend/routers/usuarios/v1/usuarios.php`, `backend/routers/menus/v1/menu_usuarios.php`, `backend/routers/menus/v1/copiar_menu_usuarios.php`, `backend/routers/menus/v1/procesar_perfil.php`, `backend/routers/menus/v1/procesar_permiso.php`, `backend/routers/menus/v1/procesar_copiar_perfil.php`, `backend/routers/menus/v1/obtener_menus_usuario.php` | `grep -n "usuarioEsAdministrador(\$pdo, \$_SESSION\['id_usuario'\])" archivo.php` | Cada archivo admin verifica `usuarioEsAdministrador($pdo, $_SESSION['id_usuario'])` antes de cualquier lógica sensible | ✅ Corregido y desplegado en producción — 8 endpoints reforzados (antes solo validaban sesión, no privilegio); validado con 11 pruebas manuales (403/200 según rol) el 2026-06-11 |
| IDOR: usuario solo accede a datos de su centro | `backend/routers/porteria/v1/ingreso/consultar.php`, `backend/routers/porteria/v1/salida/consultar.php` | Inspección manual: ¿los resultados del SELECT están filtrados por algún scope de usuario? | Los endpoints AJAX exigen sesión válida | ✅ Ambos exigen sesión; modelo mono-centro actual no requiere scoping por centro (marcado para revisión en escenario multi-centro) |
| Rutas de módulos requieren sesión válida | Todos los archivos bajo `backend/routers/` | `grep -rL "id_usuario" backend/routers/` | No debe existir ningún archivo de módulo que no verifique sesión activa | ✅ Verificado: los archivos sin `id_usuario` son bootstraps incluidos por páginas guardadas o el módulo `registro` con su propio `registroRequireAccess()`/`registroTieneSesionStandalone()` |

**Procedimiento de auditoría para A01:**
1. Abrir cada archivo de módulo administrativo (`menus.php`, `usuarios.php`, `configuracion.php`).
2. Verificar que la primera lógica ejecutable comprueba `$_SESSION['ind_usuario']` o equivalente.
3. Probar manualmente: con un usuario sin permisos de admin, intentar acceder directamente a `backend/routers/admin/configuracion.php` — debe redirigir, no mostrar contenido.
4. Documentar el resultado en la tabla de hallazgos (sección 3.3).

#### A02 — Cryptographic Failures ⚠️ Auditado (2026-06-11) — ver `REPORTE_E1-A02_CRYPTOGRAPHIC_FAILURES_SMARTCSET.md`

| Subcontrol | Archivo | Verificación | Estado actual |
|---|---|---|---|
| Contraseñas hasheadas con algoritmo robusto | `backend/core/prepare.php` (stmt_login), `backend/routers/usuarios/v1/usuarios.php` | `grep -n "password_hash\|password_verify\|bcrypt" src/` | ✅ Usa `password_verify()` con bcrypt |
| Datos sensibles cifrados en reposo | `tab_personas` en PostgreSQL, `storage/` | `\d tab_personas` en psql — verificar si existe columna `_enc` | ❌ No cifrados — ver Entregable 2 (bloqueado por prereq. 1 y 2) |
| TLS en conexión BD | `backend/core/Db.php`, `backend/core/config.php` | Ver DSN en `Db::connect()` y constante `DB_SSLMODE` | ⚠️ Infraestructura `DB_SSLMODE` lista (2026-06-11); activación pendiente de Entregable 8 (Oficina TI) |
| HTTPS forzado en producción | `index.php` líneas 13-17 | Ver bloque comentado | ❌ Código existe pero está comentado — ver Entregable 4 (bloqueado por prereq. 6) |

#### A03 — Injection 🟢 Bien cubierto

| Subcontrol | Verificación | Estado actual |
|---|---|---|
| 100% de queries usan prepared statements | `grep -rn "query\|exec\b" src/ --include="*.php"` — verificar que no hay concatenación SQL | ✅ `PDO::ATTR_EMULATE_PREPARES => false` garantiza statements reales |
| Casting explícito en PostgreSQL | `grep -n "::TEXT\|::NUMERIC\|::BOOLEAN" backend/core/prepare.php` | ✅ Patrón `?::TEXT` usado consistentemente |
| Sin concatenación de input en SQL | `grep -rn "\$_POST\|\$_GET\|\$_REQUEST" src/ --include="*.php"` — verificar que ningún resultado se concatena a un string SQL | ✅ No hay evidencia de concatenación SQL |

**Prueba final A03:** Enviar `'; DROP TABLE tab_personas; --` como valor de documento en el formulario de ingreso → debe generar error de validación o tratarse como literal string, nunca ejecutarse como SQL.

#### A04 — Insecure Design 🟡 Revisar

| Subcontrol | Verificación | Estado actual |
|---|---|---|
| Separación de capas (vista/lógica/datos) | Inspección de que las vistas (`index.php`) no contienen lógica de negocio directa | ✅ Patrón `index.php → procesar.php → lib/` bien implementado |
| Principio de mínimo privilegio en BD | Verificar permisos del usuario de BD que usa PHP: `SELECT * FROM information_schema.role_table_grants WHERE grantee = 'usuario_php';` | 🔲 Verificar — idealmente el usuario PHP no tiene DROP ni TRUNCATE en tablas de auditoría |

#### A05 — Security Misconfiguration 🟡 Mayormente cubierto

| Subcontrol | Archivo | Estado actual |
|---|---|---|
| Headers HTTP de seguridad | `SecurityMiddleware.php` incluido en `prepare.php`/`prepare_login.php` | ✅ 5 headers activos en TODO el sistema desde E4 (2026-06-14); CSP `script-src 'self'` activo; validado por test PASS |
| CSP sin scripts inline | `frontend/web/layout/head.php`, módulos portería | ✅ `head.php` y portería sin scripts inline; `frontend/web/frontend/web/public/assets/js/theme-init.js` externalizado y desplegado (2026-06-16) |
| Mensajes de error sin exposición técnica | `backend/core/ErrorHandler.php` | ✅ `ErrorHandler::userMessageFromException()` traduce SQLSTATE a mensajes en español |
| `php.ini` en producción | `/etc/php/*/php.ini` o equivalente | 🔲 Verificar: `display_errors = Off`, `log_errors = On`, `expose_php = Off` |
| Directorio `storage/` no ejecutable via web | Config Apache VirtualHost | ⚠️ Pendiente IT — Apache tiene `AllowOverride None`; directivas deben ir en VirtualHost (ver E6) |

#### A06 — Vulnerable and Outdated Components 🟡 Verificar

| Subcontrol | Verificación | Estado actual |
|---|---|---|
| Versión de PHP actualizada | `php --version` en el servidor | 🔲 Verificar: debe ser PHP 8.1+ con parches de seguridad aplicados |
| Versión de PostgreSQL actualizada | `SELECT version();` en psql | 🔲 Verificar: debe ser PostgreSQL 14+ con parches al día |
| Dependencias de frontend (Bootstrap, etc.) | Revisar versiones en `frontend/web/layout/head.php` | 🔲 Verificar versión de Bootstrap y otras librerías CDN |

#### A07 — Identification and Authentication Failures 🟡 Parcialmente cerrado

| Subcontrol | Archivo | Estado actual |
|---|---|---|
| Rate limiting en login | `index.php` | ❌ No existe — ver Entregable 3 (pendiente) |
| Regeneración de sesión tras login | `index.php` | ✅ `session_regenerate_id(true)` activo tras E4 (2026-06-14); validado por test PASS |
| Cookie flags `HttpOnly`+`SameSite=Strict` | `SecurityMiddleware.php` | ✅ Activos desde E4 (2026-06-14); validado por test PASS |
| Recuperación de contraseña robusta | `backend/routers/auth/v1/recuperar.php` | 🔲 Auditar: ¿valida identidad con múltiples factores o solo correo? |

#### A08 — Software and Data Integrity Failures 🟡 Revisar

| Subcontrol | Verificación | Estado actual |
|---|---|---|
| Integridad de scripts externos (CDN) | En `frontend/web/layout/head.php`, verificar si Bootstrap y otras librerías cargan con `integrity="sha384-..."` y `crossorigin="anonymous"` | 🔲 Agregar atributos `integrity` a todos los recursos de CDN |
| Control de cambios en código | `git log --oneline -10` — verificar que los cambios están versionados | 🔲 Confirmar que el servidor de producción no permite edición directa de archivos PHP |

#### A09 — Security Logging and Monitoring Failures 🔴 Crítico — pendiente

| Subcontrol | Archivo | Estado actual |
|---|---|---|
| Log de intentos fallidos de autenticación | No existe tabla ni log | ❌ No existe — ver Entregable 3 |
| Log de accesos a datos personales | No existe log de consultas a `tab_personas` | ❌ No existe — a implementar en Fase 2 (monitoreo) |
| `error_log` del servidor no expone SQL | `/var/log/apache2/error.log` o equivalente | 🔲 Verificar que los logs de PHP no contienen queries SQL completas ni contraseñas |
| Columnas de auditoría en tablas | `usr_insert`, `fec_insert`, `usr_update`, `fec_update` | ✅ Presentes en todas las tablas operativas |

#### A10 — Server-Side Request Forgery (SSRF) 🟢 Bajo riesgo

SmartCSET no realiza requests externos iniciados por input del usuario (no llama a URLs externas basándose en parámetros del formulario). El riesgo de SSRF es bajo. Acción: confirmar que no existe ningún `curl`, `file_get_contents(url)` o `fopen(url)` que use input del usuario.

```bash
grep -rn "curl_\|file_get_contents\|fopen" src/ --include="*.php"
```
Si el resultado es vacío o solo apunta a archivos locales → ✅ Sin riesgo de SSRF.

### 3.3 Tabla de hallazgos de la auditoría OWASP (plantilla a completar)

| Control OWASP | Hallazgo | Severidad | Entregable que lo cierra | Fecha de remediación | Verificado por |
|---|---|---|---|---|---|
| A01 — Escalada vertical de privilegios | 8 endpoints de menús/usuarios (`menus.php`, `usuarios.php`, `menu_usuarios.php`, `copiar_menu_usuarios.php`, `procesar_perfil.php`, `procesar_permiso.php`, `procesar_copiar_perfil.php`, `obtener_menus_usuario.php`) validaban solo sesión, no privilegio admin → cualquier usuario autenticado (y `procesar_perfil`/`procesar_permiso` sin sesión) podía operar funciones de administración | Crítico | Entregable 1 (este) | 2026-06-10 (código) / 2026-06-11 (desplegado y validado en producción, 11/11 pruebas PASS) | Equipo de Desarrollo - SmartCSET |
| A02 — Cifrado en reposo | Datos de `tab_personas.documento_identidad` sin cifrar | Crítico | Entregable 2 (bloqueado: prereq. 1 y 2) | | |
| A02 — TLS BD | DSN sin `sslmode` — infraestructura `DB_SSLMODE` lista en código (config.php/Db.php), activación pendiente | Crítico | Entregable 8 (bloqueado: Oficina TI) | 2026-06-11 (código) | Equipo de Desarrollo - SmartCSET |
| A02 — HTTPS forzado | Redirect HTTPS comentado en `index.php`; `SecurityMiddleware` no incluido | Crítico | Entregable 4 (bloqueado: prereq. 6) | | |
| A03 | Sin hallazgos — ✅ | — | — | — | — |
| A07 — Rate limiting | No existe throttling en login | Crítico | Entregable 3 | | |
| A07 — Session fixation | Sin `session_regenerate_id()` tras login | Crítico | Entregable 4 | | |
| A07 — Cookie flags | `cookie_httponly/secure/samesite` no configurados | Crítico | Entregable 4 | | |
| A05 — Headers HTTP | Headers solo en `index.php`, no en todo el sistema | Alto | Entregable 4 | | |
| A09 — Auth logging | Sin log de intentos fallidos | Crítico | Entregable 3 | | |

---

## 4. ENTREGABLE 2 — CIFRADO EN REPOSO DE DATOS SENSIBLES

### 4.1 Qué datos cifrar y por qué

| Dato | Tabla / Ubicación | Clasificación C-I-D | Justificación de cifrado |
|---|---|---|---|
| Número de documento de identidad | `tab_personas.documento_identidad` | Confidencialidad: **Muy Alta** | Es el dato de identificación único — su exposición masiva permite suplantación de identidad |
| Fotos de personas | `storage/porteria/{ingreso|salida}/YYYY-MM-DD/*.jpg` | Confidencialidad: **Alta** | Dato biométrico visual — protegido con especial énfasis por Ley 1581 |
| Contraseñas | `tab_usuarios.pass_usuario` | Confidencialidad: **Crítica** | ✅ Ya está hasheada con bcrypt — no requiere cifrado adicional, el hash es suficiente |
| Correo electrónico del usuario | `tab_usuarios.mail_usuario` | Confidencialidad: **Media** | Dato de contacto — evaluar cifrado como mejora futura, no prioritario en esta fase |

> ⚠️ **Análisis técnico de respaldo:** El escenario de riesgo que justifica el cifrado en reposo es un atacante que obtiene una copia de la base de datos (backup robado, acceso físico al disco, volcado de BD por una vulnerabilidad). Sin cifrado, ese atacante tiene acceso inmediato al número de documento y la foto de cada persona que pasó por la portería del centro. Con cifrado en reposo, la copia del archivo de backup es ilegible sin la clave de cifrado, que se almacena separada de los datos (variable de entorno en el servidor, no en el repositorio de código ni en el archivo `.env` versionado).

### 4.2 Evaluación de opciones de implementación

| Opción | Descripción | Pros | Contras | Recomendación |
|---|---|---|---|---|
| **A — pgcrypto en PostgreSQL** | Las funciones `pgp_sym_encrypt()` / `pgp_sym_decrypt()` cifran/descifran dentro de la BD usando una clave almacenada como `current_setting()` | Pocos cambios de código PHP; la lógica de cifrado es portable entre cualquier cliente que conecte a la BD | La clave pasa por la conexión BD en cada query (si TLS no está activo, esto anula parte del beneficio); mayor acoplamiento con PostgreSQL | ✅ **Recomendada como primera implementación** — más simple, menos riesgo de errores de código |
| **B — libsodium en PHP** | PHP cifra antes del INSERT y descifra después del SELECT usando `sodium_crypto_secretbox()` | La clave nunca sale del servidor de aplicación; independiente del motor de BD | Más cambios en código PHP (cada SELECT/INSERT de columnas cifradas); hay que gestionar nonces por registro | Recomendada como evolución futura si se migra de PostgreSQL |

### 4.3 Implementación con pgcrypto (Opción A)

#### Paso 1 — Habilitar la extensión en la BD
```sql
-- Ejecutar una sola vez en la BD de desarrollo y luego en producción:
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Verificar:
SELECT * FROM pg_extension WHERE extname = 'pgcrypto';
```

#### Paso 2 — Agregar las columnas cifradas (migración no destructiva)
Crear el archivo `database/migrations/add_cifrado_datos_sensibles.sql`:

```sql
-- Agregar columnas cifradas nuevas (las columnas originales se mantienen durante la transición)
ALTER TABLE tab_personas
    ADD COLUMN IF NOT EXISTS documento_identidad_enc BYTEA,
    ADD COLUMN IF NOT EXISTS ind_cifrado BOOLEAN NOT NULL DEFAULT FALSE;

-- NOTA: No se elimina documento_identidad hasta que:
-- (1) todos los registros estén migrados (ind_cifrado = TRUE para todos)
-- (2) el código PHP esté actualizado y probado
-- (3) se haya validado en BD de test durante al menos una semana
```

#### Paso 3 — Configurar la clave de cifrado

**En `.env` del servidor de producción** (NUNCA en el repositorio git):
```
DB_ENCRYPTION_KEY=una-clave-aleatoria-de-al-menos-32-caracteres-aqui
```

**En `database/setup_smartcset.sh`** (o en el proceso de inicio del servidor):
```bash
# Al iniciar la aplicación, configurar la clave como parámetro de sesión de PostgreSQL:
psql -c "ALTER DATABASE db_smartcset SET app.encryption_key = '$DB_ENCRYPTION_KEY';"
```

**En `backend/core/config.php`**, agregar después de las constantes de BD:
```php
define('DB_ENCRYPTION_KEY', EnvLoader::get('DB_ENCRYPTION_KEY', ''));
if (empty(DB_ENCRYPTION_KEY)) {
    error_log('[SmartCSET] ADVERTENCIA: DB_ENCRYPTION_KEY no configurada.');
}
```

#### Paso 4 — Funciones PL/pgSQL de cifrado/descifrado

Crear `database/functions/config/fun_cifrar_documento.sql`:
```sql
CREATE OR REPLACE FUNCTION fun_cifrar_documento(
    p_texto TEXT
) RETURNS BYTEA AS $$
BEGIN
    IF p_texto IS NULL OR p_texto = '' THEN RETURN NULL; END IF;
    RETURN pgp_sym_encrypt(
        p_texto,
        current_setting('app.encryption_key')::TEXT
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fun_descifrar_documento(
    p_enc BYTEA
) RETURNS TEXT AS $$
BEGIN
    IF p_enc IS NULL THEN RETURN NULL; END IF;
    RETURN pgp_sym_decrypt(
        p_enc,
        current_setting('app.encryption_key')::TEXT
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### Paso 5 — Script de migración de datos existentes

Crear `database/migrations/migrate_cifrado_documentos.sql`:
```sql
-- Ejecutar en una transacción para poder hacer rollback si algo falla
BEGIN;

UPDATE tab_personas
SET
    documento_identidad_enc = fun_cifrar_documento(documento_identidad::TEXT),
    ind_cifrado = TRUE
WHERE ind_cifrado = FALSE
  AND documento_identidad IS NOT NULL;

-- Verificar que todos los registros fueron migrados:
DO $$
DECLARE v_pendientes INT;
BEGIN
    SELECT COUNT(*) INTO v_pendientes FROM tab_personas WHERE ind_cifrado = FALSE;
    IF v_pendientes > 0 THEN
        RAISE EXCEPTION 'Migración incompleta: % registros sin cifrar.', v_pendientes;
    END IF;
    RAISE NOTICE 'Migración completada. Todos los documentos cifrados.';
END;
$$;

COMMIT;
```

#### Paso 6 — Actualizar el prepared statement en PHP

En `backend/core/prepare.php`, el statement que lee `tab_personas` debe usar la columna cifrada:
```php
// ANTES (código actual):
$stmt = $pdo->prepare("SELECT id_persona, documento_identidad, ... FROM tab_personas WHERE ...");

// DESPUÉS:
$stmt = $pdo->prepare(
    "SELECT id_persona,
            fun_descifrar_documento(documento_identidad_enc) AS documento_identidad,
            ...
     FROM tab_personas WHERE ..."
);
```

#### Paso 7 — Cifrado de fotos en `storage/`
Las fotos son archivos en disco, no en la BD. Opciones:
- **Corto plazo:** Garantizar que el directorio `storage/porteria/` no es accesible directamente vía HTTP (solo PHP puede leerlos y servirlos con el header correcto). Esto se implementa en el Entregable 8 (configuración del servidor web).
- **Mediano plazo:** Cifrar los archivos físicos usando PHP antes de escribirlos a disco (`sodium_crypto_secretstream_*`) — esto es complejidad adicional; evaluar en Fase 2.

### 4.4 Pruebas de verificación del cifrado

```sql
-- 1. Verificar que la columna cifrada tiene datos (no NULL):
SELECT COUNT(*) FROM tab_personas WHERE documento_identidad_enc IS NOT NULL;

-- 2. Verificar descifrado correcto (debe retornar el documento original):
SELECT documento_identidad, fun_descifrar_documento(documento_identidad_enc)
FROM tab_personas LIMIT 5;
-- Los dos valores deben ser idénticos.

-- 3. Verificar que sin la clave correcta el descifrado falla:
-- Cambiar temporalmente en una sesión de test:
SET app.encryption_key = 'clave-incorrecta';
SELECT fun_descifrar_documento(documento_identidad_enc) FROM tab_personas LIMIT 1;
-- Debe lanzar error o retornar basura, nunca el documento original.
```

🔲 **Antes de eliminar la columna original `documento_identidad`:** esperar mínimo 1 semana de operación normal con las columnas cifradas activas, confirmar que todos los módulos funcionan correctamente (ingreso, salida, búsqueda de persona, reportes), y hacer un backup completo verificado.

---

## 5. ENTREGABLE 3 — RATE LIMITING Y LOGGING DE AUTENTICACIÓN

### 5.1 Por qué es crítico

Sin rate limiting, un atacante puede intentar contraseñas a razón de miles por hora desde un script automatizado. El formulario de login de SmartCSET en `index.php` actualmente no tiene ningún mecanismo de defensa contra esto — un ataque de diccionario pasaría completamente desapercibido.

> 🔴 **Este es el control de mayor urgencia de toda la Fase 1** junto con el cifrado. La combinación "base de datos sin cifrar + login sin rate limiting" significa que los datos de miles de personas están expuestos tanto a ataques de fuerza bruta como a brechas físicas.

### 5.2 Diseño de la tabla de intentos

Crear `database/migrations/add_tab_intentos_login.sql`:

```sql
CREATE TABLE IF NOT EXISTS tab_intentos_login (
    id              BIGSERIAL       PRIMARY KEY,
    ip              TEXT            NOT NULL,
    id_usuario_int  TEXT            NOT NULL DEFAULT '',  -- usuario intentado (puede no existir)
    fec_intento     TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    exitoso         BOOLEAN         NOT NULL DEFAULT FALSE,
    motivo_fallo    TEXT,           -- 'usuario_no_existe' | 'contrasena_incorrecta' | 'usuario_inactivo'
    user_agent      TEXT            -- para análisis forense
);

-- Índice para la consulta de bloqueo (frecuente):
CREATE INDEX IF NOT EXISTS idx_intentos_login_ip_fec
    ON tab_intentos_login (ip, fec_intento DESC);

CREATE INDEX IF NOT EXISTS idx_intentos_login_usuario_fec
    ON tab_intentos_login (id_usuario_int, fec_intento DESC);

-- Limpiar registros viejos automáticamente (retener 90 días):
-- Ejecutar periódicamente via cron o al inicio de sesión:
-- DELETE FROM tab_intentos_login WHERE fec_intento < NOW() - INTERVAL '90 days';
```

### 5.3 Funciones PL/pgSQL

**Crear `database/functions/acceso/usuarios/fun_registrar_intento_login.sql`:**
```sql
CREATE OR REPLACE FUNCTION fun_registrar_intento_login(
    wparam_ip           TEXT,
    wparam_usuario      TEXT,
    wparam_exitoso      BOOLEAN,
    wparam_motivo       TEXT DEFAULT NULL,
    wparam_user_agent   TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    INSERT INTO tab_intentos_login (ip, id_usuario_int, exitoso, motivo_fallo, user_agent)
    VALUES (wparam_ip, wparam_usuario, wparam_exitoso, wparam_motivo, wparam_user_agent);
EXCEPTION
    WHEN OTHERS THEN
        -- Log silencioso: si falla el insert, no debe bloquear el flujo de login
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
```

**Crear `database/functions/acceso/usuarios/fun_verificar_bloqueo_ip.sql`:**
```sql
CREATE OR REPLACE FUNCTION fun_verificar_bloqueo_ip(
    wparam_ip               TEXT,
    wparam_max_intentos     INT     DEFAULT 5,
    wparam_ventana_minutos  INT     DEFAULT 15
) RETURNS BOOLEAN AS $$
DECLARE
    v_cantidad INT;
BEGIN
    SELECT COUNT(*) INTO v_cantidad
    FROM tab_intentos_login
    WHERE ip = wparam_ip
      AND exitoso = FALSE
      AND fec_intento > NOW() - (wparam_ventana_minutos || ' minutes')::INTERVAL;

    RETURN v_cantidad >= wparam_max_intentos;
END;
$$ LANGUAGE plpgsql;
```

### 5.4 Nuevas variables de entorno

Agregar a `.env.example` y a `.env` en el servidor:
```
# Rate limiting de login
LOGIN_MAX_INTENTOS=5
LOGIN_VENTANA_MINUTOS=15
```

Agregar a `backend/core/config.php`:
```php
define('LOGIN_MAX_INTENTOS',   (int) EnvLoader::get('LOGIN_MAX_INTENTOS',   '5'));
define('LOGIN_VENTANA_MINUTOS',(int) EnvLoader::get('LOGIN_VENTANA_MINUTOS','15'));
```

### 5.5 Nuevos prepared statements

Agregar a `backend/core/prepare.php` (o al archivo de prepare del login):
```php
// Rate limiting
$stmt_registrar_intento = $pdo->prepare(
    "SELECT fun_registrar_intento_login(?::TEXT, ?::TEXT, ?::BOOLEAN, ?::TEXT, ?::TEXT)"
);
$stmt_verificar_bloqueo = $pdo->prepare(
    "SELECT fun_verificar_bloqueo_ip(?::TEXT, ?::INT, ?::INT)"
);
```

### 5.6 Cambios en `index.php`

```php
// ── PUNTO DE INSERCIÓN: ANTES del bloque "if ($_SERVER['REQUEST_METHOD'] == 'POST')" ──

// Obtener IP real del cliente (ya existe la función smartcsetClientIp() en helpers.php):
$w_ip = smartcsetClientIp();

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $w_user = trim($_POST['txt_usuario'] ?? '');
    $w_pass = $_POST['txt_clave'] ?? '';
    $w_user_agent = $_SERVER['HTTP_USER_AGENT'] ?? '';

    try {
        // ── NUEVO: Verificar bloqueo por IP antes de cualquier consulta ──
        $stmt_verificar_bloqueo->execute([$w_ip, LOGIN_MAX_INTENTOS, LOGIN_VENTANA_MINUTOS]);
        $w_bloqueado = (bool) $stmt_verificar_bloqueo->fetchColumn();

        if ($w_bloqueado) {
            $w_error = "Demasiados intentos fallidos. Espere " . LOGIN_VENTANA_MINUTOS . " minutos e intente de nuevo.";
            // No continuar con la validación:
        } else {
            $stmt_login->execute([$w_user]);
            $w_reg = $stmt_login->fetch();

            if ($w_reg) {
                if ($w_reg['ind_estado'] == false) {
                    $w_error = "ACCESO DENEGADO: Su usuario se encuentra inhabilitado.";
                    // ── NUEVO: Registrar intento (usuario inactivo) ──
                    $stmt_registrar_intento->execute([$w_ip, $w_user, false, 'usuario_inactivo', $w_user_agent]);
                } else {
                    if (password_verify($w_pass, $w_reg['pass_usuario'])) {
                        // ── NUEVO: Regenerar sesión antes de asignar variables ──
                        session_regenerate_id(true);

                        // ── NUEVO: Registrar intento exitoso ──
                        $stmt_registrar_intento->execute([$w_ip, $w_user, true, null, $w_user_agent]);

                        $w_ip_login = smartcsetClientIp();
                        $w_id_sesion = accesoIngresoSesion(
                            $stmt_fun_ingreso_sesion,
                            (string) $w_reg['id_usuario'],
                            $w_ip_login
                        );
                        $_SESSION['id_usuario']  = $w_reg['id_usuario'];
                        $_SESSION['nom_usuario'] = $w_reg['nom_usuario'];
                        $_SESSION['ind_usuario'] = !empty($w_reg['ind_usuario']);
                        $_SESSION['id_sesion']   = $w_id_sesion;

                        header("Location: backend/routers/menus/v1/menu_principal.php");
                        exit();
                    } else {
                        $w_error = "ID de usuario o contraseña incorrectos.";
                        // ── NUEVO: Registrar intento fallido ──
                        $stmt_registrar_intento->execute([$w_ip, $w_user, false, 'contrasena_incorrecta', $w_user_agent]);
                    }
                }
            } else {
                $w_error = "ID de usuario o contraseña incorrectos.";
                // ── NUEVO: Registrar intento fallido (usuario no existe) ──
                $stmt_registrar_intento->execute([$w_ip, $w_user, false, 'usuario_no_existe', $w_user_agent]);
            }
        }
    } catch (PDOException $e) {
        $w_error = ErrorHandler::userMessageFromException($e);
    } catch (Exception $e) {
        $w_error = ErrorHandler::userMessageFromException($e);
    }
}
```

### 5.7 Query de auditoría para el RSSI

```sql
-- Top IPs con intentos fallidos en las últimas 24 horas:
SELECT ip, COUNT(*) AS intentos_fallidos,
       MIN(fec_intento) AS primer_intento,
       MAX(fec_intento) AS ultimo_intento
FROM tab_intentos_login
WHERE exitoso = FALSE
  AND fec_intento > NOW() - INTERVAL '24 hours'
GROUP BY ip
ORDER BY intentos_fallidos DESC
LIMIT 20;

-- Usuarios con más intentos fallidos (posible credential stuffing):
SELECT id_usuario_int, COUNT(*) AS intentos_fallidos
FROM tab_intentos_login
WHERE exitoso = FALSE
  AND fec_intento > NOW() - INTERVAL '7 days'
GROUP BY id_usuario_int
ORDER BY intentos_fallidos DESC
LIMIT 10;
```

---

## 6. ENTREGABLE 4 — HARDENING DE SESIONES PHP

### 6.1 Situación actual — lo que ya existe pero no está activo

`backend/core/SecurityMiddleware.php` contiene un método `configureSessionSecurity()` (líneas 64-74) que configura exactamente los flags que faltan, y un método `setSecurityHeaders()` (líneas 24-33) con los headers HTTP completos. El problema es que **este archivo nunca se incluye** con `require_once` en el flujo real de la aplicación — solo `index.php` tiene 4 headers hardcodeados manualmente, y el resto del sistema no tiene ninguno.

La tarea de este entregable es **integrar lo que ya existe**, no reescribirlo.

### 6.2 Integrar SecurityMiddleware en el flujo real

**En `backend/core/prepare.php`** (se incluye en TODOS los módulos), agregar al inicio del archivo:

```php
<?php
// ── Agregar al inicio de prepare.php, antes de cualquier session_start() ──
require_once __DIR__ . '/SecurityMiddleware.php';
SecurityMiddleware::initialize();
// initialize() llama internamente: configureSessionSecurity() + session_start() + setSecurityHeaders()
```

> ⚠️ **Importante:** `SecurityMiddleware::initialize()` llama `session_start()` internamente (ver línea 94 del archivo). Por eso hay que verificar que `prepare.php` o los archivos que lo incluyen **no llamen `session_start()` antes** de este punto. En el estado actual `index.php` llama `session_start()` en la línea 19 — ese `session_start()` debe **eliminarse** de `index.php` porque `SecurityMiddleware::initialize()` ya lo hace.

**En `index.php`**, eliminar:
```php
// ELIMINAR esta línea (línea 19 actual):
session_start();

// ELIMINAR los 4 headers hardcodeados (líneas 8-11 actuales) porque
// SecurityMiddleware::setSecurityHeaders() los reemplaza con la versión completa:
header("X-Content-Type-Options: nosniff");
header("X-Frame-Options: SAMEORIGIN");
header("X-XSS-Protection: 1; mode=block");
header("Referrer-Policy: strict-origin-when-cross-origin");
```

### 6.3 Configuración de `php.ini` o fallback en `config.php`

`SecurityMiddleware::configureSessionSecurity()` ya hace el `ini_set` correcto. Verificar que el `php.ini` del servidor de producción tenga al menos:

```ini
; En /etc/php/X.Y/php.ini o equivalente:
session.gc_maxlifetime = 1800
display_errors = Off
log_errors = On
expose_php = Off
```

### 6.4 Activar HTTPS en producción

Descomentar el bloque que ya existe en `index.php` (líneas 13-17):

```php
// Antes (comentado):
// if (APP_ENV === 'production' && empty($_SERVER['HTTPS'])) {
//     header("Location: https://" . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI']);
//     exit();
// }

// Después (activo):
if (defined('APP_ENV') && APP_ENV === 'production' && empty($_SERVER['HTTPS'])) {
    header("Location: https://" . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI'], true, 301);
    exit();
}
```

### 6.5 Verificación de sesiones seguras

**En el navegador (DevTools → Application → Cookies)**, tras el login, verificar que la cookie `PHPSESSID` tiene los atributos:
- `HttpOnly: ✅`
- `Secure: ✅` (solo en producción con HTTPS)
- `SameSite: Strict`

**Verificar session fixation** — prueba manual:
1. Abrir el navegador, tomar nota del valor de `PHPSESSID` antes de hacer login.
2. Hacer login exitoso.
3. Verificar que el valor de `PHPSESSID` **cambió** después del login.
4. Si el valor es el mismo antes y después → `session_regenerate_id(true)` no está activo.

---

## 7. ENTREGABLE 5 — TOKENS ANTI-CSRF EN FORMULARIOS ⛔ DESCARTADO (2026-06-16)

> **Decisión del equipo (2026-06-16):** Este entregable queda fuera del alcance de la Fase 1. Las cookies con `SameSite=Strict` (activas desde E4) mitigan el vector CSRF principal en navegadores modernos. El esfuerzo se redirige a E3 (rate limiting). La infraestructura de `SecurityMiddleware::generateCSRFToken()` y `validateCSRFToken()` permanece disponible para una Fase 2 si cambia la evaluación de riesgo. El resto de esta sección se conserva como documentación de diseño para implementación futura.

### 7.1 Situación actual

El código de CSRF ya existe en `SecurityMiddleware`:
- `SecurityMiddleware::generateCSRFToken()` — genera un token de 32 bytes aleatorios como hex
- `SecurityMiddleware::validateCSRFToken()` — compara `$_POST['csrf_token']` contra `$_SESSION['csrf_token']`

Lo que falta: incluir el token en CADA formulario POST y validarlo en CADA procesador. Al integrar `SecurityMiddleware::initialize()` en `prepare.php` (Entregable 4), el token se genera automáticamente en la sesión. Solo hay que insertar el campo oculto en los formularios y agregar la validación en los procesadores.

### 7.2 Lista completa de formularios POST que requieren protección

| Formulario (vista) | Procesador | Prioridad |
|---|---|---|
| `index.php` (login) | `index.php` (se auto-procesa) | 🔴 Alta |
| `backend/routers/auth/v1/cambiar_clave.php` | `backend/routers/auth/v1/cambiar_clave.php` | 🔴 Alta — cambio de contraseña |
| `backend/routers/auth/v1/recuperar.php` | `backend/routers/auth/v1/recuperar.php` | 🔴 Alta |
| `backend/routers/usuarios/v1/usuarios.php` | `backend/routers/usuarios/v1/procesar_*.php` (si existe) | 🔴 Alta |
| `backend/routers/menus/v1/menus.php` | `backend/routers/menus/v1/procesar_perfil.php`, `procesar_permiso.php`, `procesar_copiar_perfil.php` | 🟠 Media |
| `backend/routers/admin/v1/configuracion.php` | (Se auto-procesa o llama endpoint) | 🟠 Media |
| `backend/routers/porteria/v1/ingreso/index.php` | `backend/routers/porteria/v1/ingreso/procesar.php` | 🟠 Media |
| `backend/routers/porteria/v1/salida/index.php` | `backend/routers/porteria/v1/salida/procesar.php` | 🟠 Media |
| `backend/routers/registro/v1/forms/*.php` | Cada form de registro de persona | 🟠 Media |

### 7.3 Patrón de implementación — en las vistas (formularios)

Agregar dentro de cada `<form method="POST">`:
```html
<input type="hidden"
       name="csrf_token"
       value="<?= htmlspecialchars(SecurityMiddleware::generateCSRFToken()) ?>">
```

**Alternativa para `frontend/web/layout/head.php`:** si todos los formularios incluyen el mismo layout, se puede generar el token una sola vez en el head y pasarlo como variable PHP global:
```php
// En frontend/web/layout/head.php (o al inicio del include de layout):
$csrf_token = SecurityMiddleware::generateCSRFToken();
```

### 7.4 Helper centralizado de validación

Agregar a `backend/core/helpers.php` (para no duplicar el `if` en cada procesador):

```php
/**
 * Valida el token CSRF del POST o termina la ejecución con error 403.
 * Llamar al inicio de CADA procesador POST antes de cualquier lógica de negocio.
 */
function validarCSRFoAbortar(): void {
    if (!SecurityMiddleware::validateCSRFToken()) {
        http_response_code(403);
        // Registrar el intento en log:
        error_log('[SmartCSET][CSRF] Token inválido. IP: ' . smartcsetClientIp()
            . ' URI: ' . ($_SERVER['REQUEST_URI'] ?? ''));
        // Mensaje al usuario (sin exponer detalle técnico):
        $_SESSION['flash_msg']  = 'Su sesión ha expirado o la solicitud no es válida. Por favor, intente de nuevo.';
        $_SESSION['flash_tipo'] = 'warning';
        header('Location: ' . ($_SERVER['HTTP_REFERER'] ?? '/'));
        exit();
    }
}
```

### 7.5 Patrón de implementación — en los procesadores

Al inicio de CADA `procesar_*.php`, antes de cualquier lógica:

```php
<?php
require_once dirname(__DIR__, N) . '/core/prepare.php';
// N = número de niveles hasta core/, según la ubicación del archivo

validarCSRFoAbortar();  // ← Primera línea de lógica real

// ... resto del procesador sin cambios
```

### 7.6 Verificación de CSRF

**Prueba manual con curl:**
```bash
# Intento de POST sin token (debe retornar 403 o redirigir con flash de error):
curl -X POST https://smartcset.sena.edu.co/backend/routers/auth/v1/cambiar_clave.php \
     -d "nueva_clave=hacked123&confirmar_clave=hacked123" \
     -v 2>&1 | grep "HTTP/"
# Resultado esperado: HTTP/1.1 403 o redirección con mensaje de sesión expirada.
```

---

## 8. ENTREGABLE 6 — VERIFICACIÓN DE SUBIDA DE ARCHIVOS

### 8.1 Estado confirmado: los controles ya están bien implementados

La auditoría del código confirmó que ambos módulos de subida de archivos tienen controles robustos:

**`backend/core/LogoUpload.php`:**
- ✅ `finfo_open(FILEINFO_MIME_TYPE)` — detecta el MIME real del archivo, no la extensión declarada
- ✅ Whitelist: solo `image/png`, `image/jpeg`, `image/gif`, `image/webp`
- ✅ Límite de 5 MB (`const MAX_BYTES = 5 * 1024 * 1024`)
- ✅ `is_uploaded_file()` — verifica que el archivo llegó vía HTTP POST real
- ✅ Nombre del archivo guardado: generado aleatoriamente (no preserva el nombre original)
- ✅ Permisos del archivo: `0644`

**`backend/routers/porteria/v1/lib/porteria_foto.php`:**
- ✅ Acepta base64 de data URL (no upload directo) — elimina la posibilidad de WebShell upload
- ✅ `preg_match` valida el formato exacto `data:image/(jpeg|jpg|png|webp);base64,...`
- ✅ `base64_decode($m[2], true)` con modo estricto — falla si el base64 es inválido
- ✅ Recompresión a JPEG con `imagecreatefromstring()` — destruye cualquier payload oculto en metadatos o streams alternativos
- ✅ Almacenamiento en path estructurado fuera del root web si la configuración lo permite

### 8.2 Checklist de verificación formal (lo que hay que confirmar, no reimplementar)

| Control | Archivo | Cómo verificar | Estado a confirmar |
|---|---|---|---|
| `storage/porteria/` no ejecuta PHP | Config de Apache/Nginx o `.htaccess` | `curl https://smartcset.sena.edu.co/storage/porteria/test.php` → debe retornar 403 o 404, nunca ejecutar PHP | 🔲 Verificar |
| `frontend/web/public/uploads/logos/` no ejecuta PHP | Config de Apache/Nginx o `.htaccess` | Mismo test con un archivo `.php` de prueba | 🔲 Verificar |
| Logos subidos no son servibles como scripts | `frontend/web/public/uploads/logos/` + header `Content-Type` | El servidor debe forzar `Content-Type: image/jpeg` para todo lo de esa carpeta | 🔲 Verificar |

### 8.3 Configuración de `.htaccess` para bloquear ejecución PHP en directorios de uploads

Crear o verificar `frontend/web/public/uploads/logos/.htaccess`:
```apache
# Bloquear ejecución de PHP y scripts en este directorio:
<FilesMatch "\.(php|php3|php4|php5|phtml|pl|py|cgi|sh)$">
    Order Deny,Allow
    Deny from all
</FilesMatch>

# Forzar Content-Type para imágenes:
<FilesMatch "\.(jpg|jpeg|png|gif|webp)$">
    Header set Content-Type "image/jpeg"
    Header set X-Content-Type-Options "nosniff"
</FilesMatch>
```

Crear o verificar `storage/porteria/.htaccess` con el mismo contenido.

> ⚠️ Si el servidor usa Nginx en lugar de Apache, estas reglas se implementan en el bloque `location` del virtual host — solicitar a la Oficina TI SENA que aplique el equivalente Nginx.

---

## 9. ENTREGABLE 7 — CORRECCIÓN DE BUGS EN setup_smartcset.sh

### 9.1 Estado actual tras revisión del 2026-06-08 (✅ cerrado el 2026-06-13, ver REPORTE_E1-E07)

La auditoría del script reveló que **algunos bugs documentados en SETUP_AUDIT.md ya fueron corregidos** en versiones posteriores del archivo. El estado al cierre de E7 es:

| Bug original en SETUP_AUDIT.md | Estado |
|---|---|
| Bug 1: Schema V.1.5 en lugar de V.1.6 (líneas 37, 50, 124) | ✅ **CORREGIDO** — el script ya apunta a V.1.7 |
| Bug 2a: `fun_trigger_menu.sql` no en FUNCS | ✅ **CORREGIDO** — ya presente en el script |
| Bug 2b: `fun_trigger_menu_admin.sql` no en FUNCS | ✅ **CORREGIDO** — ya presente en el script |
| Bug 3: 3 migraciones críticas faltantes | ✅ **CORREGIDO** |
| Bug 2d: `fun_validar_correo.sql` no en FUNCS | ✅ **CORREGIDO (E7)** — agregada al array FUNCS, alineada al patrón estándar de manejo de errores |
| Bug 2e: `fun_validar_login.sql` no en FUNCS | ✅ **CORREGIDO (E7)** — agregada al array FUNCS, alineada al patrón estándar de manejo de errores |
| Bug 2f: `fun_validar_usuario.sql` no en FUNCS | ✅ **CORREGIDO (E7)** — agregada al array FUNCS, alineada al patrón estándar de manejo de errores |
| Bug 2g: `fun_tab_menu_usuarios.sql` no en FUNCS | ❌ **EXCLUIDA DELIBERADAMENTE (E7)** — ver sección 9.2 |
| `fun_delete_perfil_usuarios.sql` (plural) no en FUNCS | 🔲 **PENDIENTE** — fuera del alcance de E7; su descripción no coincide con su implementación real y requiere análisis propio. Nota: la entrada de FUNCS que esta tabla atribuía a "Bug 2c" corresponde en realidad a `fun_delete_perfil_usuario.sql` (singular), una función distinta. |

### 9.2 Resultado de la corrección (E7, 2026-06-13)

**3 de las 4 funciones identificadas se agregaron al array FUNCS de `database/setup_smartcset.sh`**,
tras revisar y alinear su bloque `EXCEPTION` al patrón estándar del proyecto
(`smartcset_handle_sql_error()`):

```bash
  "$ROOT/database/functions/acceso/usuarios/fun_validar_login.sql"
  "$ROOT/database/functions/acceso/usuarios/fun_validar_correo.sql"
  "$ROOT/database/functions/acceso/usuarios/fun_validar_usuario.sql"
```

**La 4ª función, `fun_tab_menu_usuarios.sql`, NO se agregó.** Contiene versiones legacy de
`fun_insert_menu_usuarios` y `fun_delete_perfil_usuario`, ya presentes en FUNCS con una implementación
más segura (validación de existencia, `ON CONFLICT DO NOTHING`, manejo de errores estándar). Agregarla
habría hecho que su `CREATE OR REPLACE FUNCTION` sobreescribiera silenciosamente las versiones seguras
en cada instalación nueva — una regresión de seguridad real. El archivo permanece en el repo como
referencia histórica.

**Impacto real verificado (corrige la estimación original de este documento):**
- `fun_validar_correo.sql`, `fun_validar_login.sql`, `fun_validar_usuario.sql` — se verificó que
  `backend/routers/auth/v1/recuperar.php` y el flujo de login (`prepare.php`) usan SQL directo
  (`$stmt_valida_mail`, `$stmt_login`, `$stmt_upd_pass`), **no** estas funciones PL/pgSQL. Su ausencia
  era una brecha documental (función documentada como parte del catálogo pero ausente del instalador),
  no una falla funcional activa — la recuperación de contraseña **no** fallaba por su ausencia.
- `fun_tab_menu_usuarios.sql` — su inclusión habría sido un riesgo nuevo, no una corrección.

Detalle completo en
`Documentacion para implementacion de MSPI/FASE 01_Blindaje Técnico Inmediato/REPORTE_E1-E07_CORRECCION_SETUP_SMARTCSET.md`.

### 9.3 Verificación post-corrección

```bash
# 1. Ejecutar setup_smartcset.sh contra una BD de test (NO la de producción):
BD_DE_TEST=db_smartcset_test

# Cambiar temporalmente DB_NAME en .env a db_smartcset_test, luego ejecutar:
bash database/setup_smartcset.sh

# 2. Verificar que TODAS las funciones esperadas existen:
psql -U postgres -d db_smartcset_test -c "\df fun_*" | grep -E "validar_correo|validar_login|validar_usuario|tab_menu_usuarios"
# Debe mostrar las 4 funciones.

# 3. Probar recuperación de contraseña:
# Iniciar el servidor de desarrollo apuntando a db_smartcset_test
# Ir a backend/routers/auth/v1/recuperar.php, ingresar un correo de prueba
# Debe ejecutar sin error 500 (antes del fix, lanzaba excepción de función inexistente)

# 4. Restaurar DB_NAME a db_smartcset en .env.
```

> 🔲 **Antes de ejecutar el script contra producción:** hacer un backup completo de la BD (`pg_dump -U postgres -d db_smartcset > backup_prefix1.sql`). El script con `set -euo pipefail` aborta ante el primer error, pero el schema se aplica con DROP implícito en el script SQL — confirmar que el esquema V.1.7 es idempotente para datos existentes.

---

## 10. ENTREGABLE 8 — HARDENING DE RED Y ARQUITECTURA DE DESPLIEGUE

> **ISC2 CC — Dominio 4 (Network Security):** Este es el entregable que cubre el único dominio del temario ISC2 CC que no estaba representado en el plan anterior. Abarca segmentación de red, firewalls, comunicaciones seguras (TLS) y hardening del servidor host.

### 10.1 Arquitectura de red objetivo

```
INTERNET / RED INTERNA DEL CENTRO DE FORMACIÓN SENA
        │
        │  Solo HTTPS (443) / HTTP→HTTPS redirect
        ▼
┌─────────────────────────┐
│   FIREWALL PERIMETRAL   │  ← Regla: DENY all, ALLOW 443 desde red del centro
│   (hardware/software)   │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│    SERVIDOR WEB (DMZ)   │  Apache / Nginx + PHP-FPM
│    IP: 192.168.X.A      │  Puertos abiertos: 443 (HTTPS entrante)
│    SmartCSET PHP        │  Puerto 22: solo desde IPs administrativas
└──────────┬──────────────┘
           │
           │  Solo PostgreSQL (5432), TLS requerido
           │  Solo desde IP del servidor web
           ▼
┌─────────────────────────────┐
│   FIREWALL INTERNO          │  ← Regla: ALLOW 5432 solo desde IP servidor web
│   (iptables / ufw)          │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────┐
│   SERVIDOR BD (interno) │  PostgreSQL 14+
│   IP: 192.168.X.B       │  Puerto 5432: solo desde IP servidor web
│   db_smartcset          │  Puerto 22: solo desde IPs administrativas
└─────────────────────────┘
```

> 🔲 Las IPs exactas `192.168.X.A` y `192.168.X.B` dependen de la infraestructura de red del SENA — la Oficina TI debe proporcionar la topología real y confirmar qué segmentos de red existen. El diagrama arriba es el objetivo; puede que ambos servidores estén en la misma máquina física en instalaciones pequeñas — en ese caso, `sslmode=require` aplica igualmente, y las reglas de firewall de host son las relevantes.

### 10.2 Tabla de reglas de firewall

**Firewall perimetral (hacia el servidor web):**

| Protocolo | Puerto | Origen | Destino | Acción | Justificación |
|---|---|---|---|---|---|
| TCP | 443 (HTTPS) | Red del Centro SENA / Internet | Servidor web | ALLOW | Acceso normal al sistema |
| TCP | 80 (HTTP) | Cualquiera | Servidor web | ALLOW → redirect 301 | Solo para redirigir a HTTPS |
| TCP | 22 (SSH) | IPs administrativas (lista blanca) | Servidor web | ALLOW | Administración del servidor |
| TCP/UDP | Cualquier otro | Cualquiera | Servidor web | DENY | Principio de mínima superficie |

**Firewall de host en servidor web (hacia la BD):**

| Protocolo | Puerto | Origen | Destino | Acción | Justificación |
|---|---|---|---|---|---|
| TCP | 5432 (PostgreSQL) | IP del servidor web | Servidor BD | ALLOW | Única conexión autorizada a la BD |
| TCP | 22 (SSH) | IPs administrativas | Servidor BD | ALLOW | Administración de BD |
| TCP/UDP | Cualquier otro | Cualquiera | Servidor BD | DENY | BD no debe ser accesible desde afuera |

**Comandos para implementar con `ufw` en el servidor BD (Linux):**
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.X.A to any port 5432  # Solo desde servidor web
sudo ufw allow from IP_ADMIN_1 to any port 22      # SSH administrativo
sudo ufw enable
sudo ufw status verbose
```

### 10.3 TLS en la conexión PHP↔PostgreSQL

#### Configuración en PostgreSQL (`postgresql.conf`)

```ini
# /etc/postgresql/14/main/postgresql.conf (o equivalente):
ssl = on
ssl_cert_file = 'server.crt'   # Ruta al certificado del servidor BD
ssl_key_file  = 'server.key'   # Ruta a la clave privada

# Opcional pero recomendado: forzar TLS para todas las conexiones:
# (Esto va en pg_hba.conf, no en postgresql.conf)
```

En `pg_hba.conf`:
```
# Reemplazar líneas de 'host' por 'hostssl' para forzar TLS:
# ANTES:
# host    db_smartcset    usuario_php    192.168.X.A/32    md5
# DESPUÉS:
hostssl   db_smartcset    usuario_php    192.168.X.A/32    md5
```

#### Cambio en `backend/core/Db.php` — ✅ Aplicado en código (2026-06-11), activación pendiente

En lugar de derivar `sslmode` automáticamente de `APP_ENV` (lo que forzaría `require`/`verify-full` en cualquier entorno y rompería conexiones contra un PostgreSQL sin `ssl=on`), se implementó vía variable de entorno `DB_SSLMODE` — vacía por defecto, sin efecto hasta que se configure explícitamente:

```php
// backend/core/config.php:
define('DB_SSLMODE', EnvLoader::get('DB_SSLMODE', ''));

// backend/core/Db.php — connect():
$dsn = 'pgsql:host=' . DB_HOST . ';port=' . DB_PORT . ';dbname=' . DB_NAME;

$sslmode = defined('DB_SSLMODE') ? trim((string) DB_SSLMODE) : '';
if ($sslmode !== '') {
    $dsn .= ';sslmode=' . $sslmode;
}
```

**Activación (cuando Oficina TI complete `ssl=on` + certificados en PostgreSQL):** agregar a `.env` del servidor correspondiente:
- Desarrollo / misma red interna confiable: `DB_SSLMODE=require` (cifra el canal, no valida CN del certificado)
- Producción: `DB_SSLMODE=verify-full` (valida el CN del certificado, más seguro)

> Detalle de la auditoría y el cambio: `REPORTE_E1-A02_CRYPTOGRAPHIC_FAILURES_SMARTCSET.md` §3.2.

#### Verificar que TLS está activo

```sql
-- En psql, después de conectar desde el servidor de aplicación:
SELECT pg_ssl.pid, pg_ssl.ssl, pg_ssl.version, pg_ssl.cipher
FROM pg_stat_ssl
JOIN pg_stat_activity ON pg_stat_ssl.pid = pg_stat_activity.pid
WHERE pg_stat_activity.datname = 'db_smartcset';
-- La columna 'ssl' debe ser TRUE para todas las conexiones del servidor web.
```

### 10.4 Hardening del servidor host

#### SSH — autenticación solo por clave pública

En `/etc/ssh/sshd_config` del servidor (tanto web como BD):
```ini
# Deshabilitar login por contraseña:
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no

# Solo permitir usuarios específicos:
AllowUsers admin_sena

# Deshabilitar root login:
PermitRootLogin no
```

```bash
# Reiniciar SSH después del cambio:
sudo systemctl restart sshd

# Verificar que la clave pública del administrador está en authorized_keys ANTES de reiniciar:
cat ~/.ssh/authorized_keys  # Debe mostrar la clave pública
```

#### PHP — configuración de producción

```ini
# /etc/php/8.X/fpm/php.ini:
display_errors = Off
log_errors = On
error_log = /var/log/php/error.log  # Asegurar que este directorio existe y no es web-accesible
expose_php = Off
```

#### Verificación integral de red

```bash
# Desde un cliente externo, verificar que los puertos no expuestos están cerrados:
nmap -p 5432,3306,5433 IP_SERVIDOR_WEB
# PostgreSQL NO debe responder desde el exterior.

# Verificar TLS del servidor web:
openssl s_client -connect smartcset.sena.edu.co:443 -brief
# Debe mostrar: Protocol: TLSv1.2 (o TLSv1.3), Verify return code: 0

# Desde el servidor web, verificar TLS hacia PostgreSQL:
psql "host=IP_SERVIDOR_BD sslmode=require dbname=db_smartcset user=usuario_php" -c "SELECT 1;"
# Debe conectar sin error y mostrar resultado '1'.
```

---

## 11. ENTREGABLE 9 — GESTIÓN DE PARCHES Y ACTUALIZACIÓN DE COMPONENTES

> **ISC2 CC — Dominio 5 (Security Operations):** La gestión de parches es uno de los controles operativos de mayor impacto en la postura de seguridad de cualquier sistema. Un componente con vulnerabilidad conocida y sin parchear es un vector de ataque garantizado. Este entregable establece el proceso formal para mantener SmartCSET y su infraestructura actualizados frente a vulnerabilidades publicadas.
>
> **MSPI MinTIC — Eje 6 (Seguridad en comunicaciones y operaciones):** El modelo exige que las entidades mantengan actualizados sus sistemas de información y gestionen formalmente el ciclo de vida de los componentes de software.

### 11.1 Inventario de componentes con versión (base inicial)

El primer paso es saber exactamente qué versiones están en producción. Completar y mantener actualizada la siguiente tabla:

| Componente | Categoría | Versión actual en producción | Versión estable más reciente | Canal de alertas de seguridad |
|---|---|---|---|---|
| PHP | Motor de aplicación | 🔲 Verificar con `php --version` | php.net/releases | https://www.php.net/security.php |
| PostgreSQL | Motor de BD | 🔲 Verificar con `SELECT version();` | postgresql.org/support/versioning | pgsql-announce@postgresql.org |
| Bootstrap | Frontend CDN | 🔲 Revisar `frontend/web/layout/head.php` | getbootstrap.com | GitHub Security Advisories |
| Sistema operativo (servidor) | Infraestructura | 🔲 Verificar con `lsb_release -a` | Ubuntu LTS / Debian stable | Ubuntu Security Notices / Debian Security |
| Apache / Nginx | Servidor web | 🔲 Verificar con `apache2 -v` o `nginx -v` | httpd.apache.org / nginx.org | CVE DB |
| pgcrypto (extensión PG) | Extensión BD | Incluida con PostgreSQL | Con PostgreSQL | Mismo que PostgreSQL |

🔲 **Acción inmediata:** completar la columna "Versión actual en producción" ejecutando los comandos indicados. Este inventario se mantiene en el historial de cambios del repositorio git.

### 11.2 Proceso de gestión de parches

```
PASO 1 — MONITOREO CONTINUO
   Suscribirse a las fuentes de alertas de cada componente (columna
   "Canal de alertas de seguridad" en la tabla anterior). Revisar
   al menos una vez por semana. Tiempo estimado: 15 min/semana.
        ↓
PASO 2 — EVALUACIÓN DE LA ALERTA
   Al recibir una alerta, clasificar según la tabla de SLA (Sección 11.3).
   Determinar si SmartCSET usa el componente afectado y si la
   vulnerabilidad es explotable en el contexto de SmartCSET.
        ↓
PASO 3 — PREPARACIÓN EN BD DE TEST
   Aplicar el parche en la BD/servidor de test PRIMERO.
   Ejecutar el flujo de regresión (Sección 14.2).
   Documentar el resultado.
        ↓
PASO 4 — DESPLIEGUE EN PRODUCCIÓN
   Notificar a la Dirección del tiempo de ventana de mantenimiento.
   Tomar backup completo ANTES del parche.
   Aplicar el parche.
   Verificar que SmartCSET funciona correctamente.
   Documentar en el Registro de Parches (Sección 11.4).
        ↓
PASO 5 — CIERRE
   Actualizar el inventario de componentes con la nueva versión.
   Archivar el boletín de seguridad original como evidencia.
```

### 11.3 SLA de aplicación de parches por severidad

| CVSS Score | Severidad | SLA (plazo máximo desde publicación) | Justificación |
|---|---|---|---|
| 9.0 – 10.0 | Crítica | **48 horas** | Vulnerabilidades con exploit público disponible — riesgo de compromiso inmediato |
| 7.0 – 8.9 | Alta | **7 días** | Alta probabilidad de explotación activa en la naturaleza dentro de días |
| 4.0 – 6.9 | Media | **30 días** | Requiere condiciones específicas para explotar; ventana aceptable para test+deploy |
| 0.1 – 3.9 | Baja | **90 días** | Bajo impacto; puede esperarse a la próxima ventana de mantenimiento regular |

> ⚠️ Los SLA son **plazos máximos**, no objetivos. Si el parche puede aplicarse antes sin riesgo, aplicarlo antes.

### 11.4 Registro de parches aplicados

| N° | Fecha | Componente | Versión previa | Versión nueva | CVE / Boletín | CVSS | SLA aplicable | Aplicado por | Probado en test | Resultado |
|---|---|---|---|---|---|---|---|---|---|---|
| | | | | | | | | | | |

Este registro se mantiene en el repositorio git como archivo `database/REGISTRO_PARCHES.md` para tener trazabilidad completa con historial de cambios.

### 11.5 Automatización de detección de versiones desactualizadas

Para componentes de frontend (Bootstrap, etc.) cargados desde CDN, verificar periódicamente:

```bash
# Extraer versiones de librerías en head.php:
grep -oP "(bootstrap|jquery|popper)[^\"']*\d+\.\d+\.\d+" frontend/web/layout/head.php

# Verificar PHP actual:
php --version | head -1

# Verificar PostgreSQL:
psql -U postgres -c "SELECT version();" | grep -oP "PostgreSQL \d+\.\d+"

# Verificar SO (Ubuntu/Debian):
apt list --upgradable 2>/dev/null | grep -i "security"
```

🔲 **Acción recomendada:** configurar un cron semanal que ejecute `apt list --upgradable` y envíe el resultado por correo al Administrador del sistema, para no depender de revisiones manuales.

---

## 12. ENTREGABLE 10 — SDLC SEGURO: CHECKLIST DE CÓDIGO Y DESPLIEGUE

> **ISC2 CC — Dominio 5 (Security Operations):** La seguridad debe integrarse en el ciclo de vida del desarrollo de software (SDLC) — no como una revisión de último momento, sino como parte de cada cambio de código. Este entregable cierra la brecha del MSPI Eje 8 y establece las prácticas mínimas de desarrollo seguro para SmartCSET.
>
> **MSPI MinTIC — Eje 8 (Adquisición, desarrollo y mantenimiento):** El modelo exige que las entidades definan prácticas de desarrollo seguro, incluyendo revisión de código, pruebas de seguridad y procedimientos de despliegue controlado.

### 12.1 Principios del SDLC seguro aplicados a SmartCSET

| Principio | Aplicación concreta en SmartCSET |
|---|---|
| **Security by design** | Los controles de seguridad (prepared statements, validación de entrada, bcrypt) son parte del diseño base, no parches posteriores |
| **Menor privilegio** | El usuario PHP de la BD no tiene DDL; los módulos no tienen acceso a datos que no necesitan |
| **Defensa en profundidad** | Validación en formulario + prepared statement + función PL/pgSQL = tres capas de defensa contra SQLi |
| **Fail securely** | En caso de error, ErrorHandler muestra mensaje genérico; nunca expone SQLSTATE ni stack trace al usuario |
| **Control de cambios obligatorio** | Todo cambio al código fuente se registra en git antes de desplegar — no hay edición directa en producción |

### 12.2 Checklist de revisión de código (pre-commit)

Antes de hacer `git commit` de cualquier cambio en SmartCSET, verificar:

**Seguridad obligatoria:**
- [ ] ¿El cambio introduce nueva entrada de usuario sin validar? → Si sí, agregar validación antes del procesamiento
- [ ] ¿El cambio usa SQL? → Verificar que usa prepared statements con parámetros posicionales, nunca concatenación de strings
- [ ] ¿El cambio accede a `$_POST`, `$_GET` o `$_REQUEST`? → Verificar que el valor nunca se usa sin sanear en echo/print
- [ ] ¿El cambio agrega nuevas rutas/archivos accesibles desde el navegador? → Verificar que requieren sesión activa (`$_SESSION['id_usuario']`)
- [ ] ¿El cambio incluye contraseñas, claves de API, tokens o conexiones hardcodeadas? → **BLOQUEO TOTAL** — mover a `.env`
- [ ] ¿El cambio modifica la lógica de autenticación o autorización? → Requiere revisión adicional antes del merge

**Calidad de código:**
- [ ] ¿Las nuevas funciones PL/pgSQL siguen el patrón con `EXCEPTION WHEN SQLSTATE 'P0001' THEN RAISE; WHEN OTHERS THEN PERFORM smartcset_handle_sql_error();`?
- [ ] ¿Los nuevos archivos PHP usan `require_once` relativo con `__DIR__`, nunca paths absolutos del sistema?
- [ ] ¿Los nuevos módulos que acceden a datos de personas tienen columnas de auditoría (`usr_insert`, `fec_insert`)?

### 12.3 Checklist de despliegue a producción (pre-deploy)

Antes de cada despliegue a producción:

**Preparación:**
- [ ] ✅ Todos los cambios están en git con mensaje de commit descriptivo
- [ ] ✅ El cambio fue probado en el entorno de desarrollo local con datos de prueba
- [ ] ✅ Se ejecutó el flujo de regresión básico (login → ingreso → salida → logout)
- [ ] 🔲 Se tomó un backup completo de la BD antes del despliegue: `pg_dump -U postgres -Fc -d db_smartcset > backup_predespliegue_$(date +%Y%m%d_%H%M%S).pgdump`
- [ ] 🔲 Si el cambio incluye migraciones de BD, se ejecutaron en BD de test primero

**Durante el despliegue:**
- [ ] Copiar archivos PHP modificados al servidor (nunca editar directamente en producción)
- [ ] Si hay migraciones SQL: ejecutar como transacción (`BEGIN; ... COMMIT;`) para poder hacer rollback
- [ ] Si hay nuevas funciones PL/pgSQL: desplegarlas con `psql -f archivo.sql`
- [ ] Si hay cambios en `.env.example`: actualizar `.env` en producción con las nuevas variables

**Verificación post-despliegue:**
- [ ] Login exitoso con credenciales de administrador
- [ ] Flujo de ingreso de persona funciona correctamente
- [ ] No hay errores en el log del servidor web (`tail -f /var/log/apache2/error.log` o equivalente)
- [ ] No hay errores en el log de PHP
- [ ] Si el cambio afectó la BD: verificar integridad de datos con conteo de registros

### 12.4 Procedimiento de rollback de emergencia

Si después del despliegue el sistema no funciona:

```bash
# 1. Revertir archivos PHP al commit anterior:
git log --oneline -5                          # Identificar el commit previo al despliegue
git checkout <commit-id> -- src/             # Revertir solo el directorio src/

# 2. Si hay migraciones de BD, restaurar desde el backup previo al despliegue:
pg_restore -U postgres -d db_smartcset \
  --clean \
  backup_predespliegue_FECHA.pgdump

# 3. Verificar que el sistema funciona con la versión anterior.
# 4. Analizar el problema en el entorno de desarrollo antes de reintentar el despliegue.
```

### 12.5 Prohibiciones absolutas del SDLC

Las siguientes prácticas están **prohibidas** en el desarrollo y operación de SmartCSET:

| Práctica prohibida | Riesgo | Alternativa correcta |
|---|---|---|
| Editar archivos PHP directamente en el servidor de producción mediante SSH o FTP | Cambios no versionados, sin rollback posible, sin revisión | Git → deploy desde repositorio |
| Hardcodear credenciales, tokens o claves en el código fuente | Exposición al comprometer el repositorio | Variables de entorno en `.env` |
| Usar `$_POST['campo']` directamente en una query SQL sin pasar por prepared statement | SQLi | `$stmt->execute([$_POST['campo']])` siempre |
| Hacer `var_dump()` o `print_r()` de objetos PDO, sesiones o arrays de configuración en código de producción | Exposición de estructura interna y datos sensibles | Usar `error_log()` con nivel apropiado; nunca a pantalla |
| Deshabilitar `PDO::ATTR_EMULATE_PREPARES` false | Permite que PDO emule prepared statements, anulando la protección real contra SQLi | Mantener siempre `false` (ya está configurado así) |
| Subir cambios con `git push --force` a main sin revisión | Sobrescribe historial, puede destruir evidencia de auditoría | Usar branches y merge request |

### 12.6 Herramienta de análisis estático (futuro)

Para elevar el nivel del SDLC, evaluar la incorporación de:

| Herramienta | Para qué | Cómo usar |
|---|---|---|
| **phpstan / psalm** | Análisis estático de PHP — detecta errores de tipo, variables indefinidas, paths inseguros | `composer require --dev phpstan/phpstan && vendor/bin/phpstan analyse src/` |
| **semgrep** | Análisis de seguridad de código — detecta patrones de vulnerabilidades (SQLi, XSS, SSRF) | `semgrep --config=p/php src/` |
| **trivy** | Análisis de vulnerabilidades en imágenes Docker o dependencias del sistema | `trivy fs .` |

🔲 Estos no son requisitos de la Fase 1 — son mejoras a evaluar en la Fase 5 (Mejora Continua).

---

## 13. ORDEN DE IMPLEMENTACIÓN RECOMENDADO

La secuencia minimiza el riesgo de romper la aplicación:

```
SEMANA 1

  Día 0 (antes de empezar): ENTREGABLE 10 — Checklist SDLC activado
  │  └─ No requiere código: solo leer el checklist y adoptarlo como práctica
  │     desde el primer commit de la Fase 1. Costo: 0 horas de implementación.
  │
  Día 1-2: ENTREGABLE 7 — Corrección de setup_smartcset.sh
  │  └─ No toca código de aplicación; el riesgo es cero.
  │     Verificar en BD de test antes de producción.
  │
  Día 3-4: ENTREGABLE 4 — Hardening de sesiones (SecurityMiddleware)
  │  └─ Integrar SecurityMiddleware en prepare.php.
  │     Quitar session_start() y headers duplicados de index.php.
  │     Probar login/logout completo antes de continuar.
  │
  Día 5: ENTREGABLE 6 — Verificación de uploads
     └─ Solo checklist + agregar .htaccess en carpetas de uploads.
        Sin cambios de código PHP.

SEMANA 2

  Día 1-2: ENTREGABLE 5 — Tokens anti-CSRF
  │  └─ Agregar helper validarCSRFoAbortar() a helpers.php.
  │     Agregar campo oculto a formularios (empezar por login y cambio de contraseña).
  │     Continuar con el resto de formularios.
  │     Probar cada formulario antes de continuar.
  │
  Día 3-4: ENTREGABLE 3 — Rate limiting + logging
  │  └─ Crear migración y ejecutar en BD de test.
  │     Crear funciones PL/pgSQL y desplegarlas.
  │     Actualizar index.php con la nueva lógica.
  │     Probar: login exitoso → no se bloquea. 6 intentos fallidos → se bloquea.
  │
  Día 5: ENTREGABLE 1 — Auditoría OWASP (checklist inicial)
     └─ Completar la tabla de hallazgos con el estado actual de cada control.
        Los controles que no están cubiertos aún se marcan como "pendiente Fase 2".

SEMANA 3

  Día 1-3: ENTREGABLE 2 — Cifrado en reposo
  │  └─ El más riesgoso: requiere migración de datos.
  │     NUNCA ejecutar en producción sin backup verificado primero.
  │     Ejecutar y probar completamente en BD de test.
  │     Validar que TODOS los módulos funcionan con columnas cifradas.
  │     Ejecutar en producción solo tras confirmación de 1 semana en test.
  │
  Día 4-5: ENTREGABLE 8 — Hardening de red y TLS
     └─ Requiere coordinación con Oficina TI SENA para reglas de firewall.
        El cambio de sslmode en Db.php es de 2 líneas — el trabajo real
        es la configuración de infraestructura (postgresql.conf, pg_hba.conf, firewall).

SEMANA 4

  Día 1-2: ENTREGABLE 1 — Auditoría OWASP (cierre)
  │  └─ Con todos los controles implementados, completar y cerrar la tabla de hallazgos.
  │     Este es el documento de evidencia que certifica el estado de Fase 1.
  │
  Día 3: ENTREGABLE 9 — Inventario de componentes + suscripción a alertas
     └─ Completar tabla de versiones actuales (30 min de trabajo técnico).
        Suscribirse a canales de alertas de cada componente.
        Crear archivo REGISTRO_PARCHES.md en el repositorio.
        El proceso en sí ya está operativo desde este momento.
```

---

## 14. PLAN DE PRUEBAS Y VERIFICACIÓN INTEGRAL

### 14.1 Pruebas por entregable

| Entregable | Prueba | Cómo ejecutarla | Resultado esperado |
|---|---|---|---|
| E1 — OWASP | SQLi en campo documento | `'; DROP TABLE tab_personas; --` como input | Sin efecto — string literal; sin error SQL visible |
| E1 — OWASP | IDOR en ingreso | Modificar `?id=` en URL con ID de otro usuario | Error 403 o redirección, nunca datos de otro centro |
| E2 — Cifrado | Descifrar dato cifrado | `SELECT fun_descifrar_documento(doc_enc) FROM tab_personas LIMIT 1;` | Retorna el número de documento original |
| E2 — Cifrado | Backup sin clave | Intentar leer backup SQL sin conocer `DB_ENCRYPTION_KEY` | Columna `documento_identidad_enc` es BYTEA ilegible |
| E3 — Rate limiting | 6 intentos fallidos | Script que envía 6 POST seguidos con contraseña incorrecta | El 6to retorna el mensaje de bloqueo; IP aparece en `tab_intentos_login` |
| E3 — Rate limiting | Login normal | 1 intento con credenciales correctas | Login exitoso; `tab_intentos_login` muestra registro con `exitoso=TRUE` |
| E4 — Sesiones | Session fixation | PHPSESSID antes vs. después del login | El ID de sesión **cambia** tras el login |
| E4 — Sesiones | Cookie flags | DevTools → Application → Cookies | Cookie con `HttpOnly=true`, `SameSite=Strict` |
| E5 — CSRF | POST sin token | `curl -X POST URL -d "campo=valor"` sin `csrf_token` | 403 o redirect con flash de sesión expirada |
| E5 — CSRF | POST con token válido | Usar el formulario normal del sistema | Procesamiento exitoso |
| E6 — Uploads | WebShell upload | Intentar subir archivo `.php` como logo | Error de validación de MIME; archivo no guardado |
| E6 — Uploads | Ejecutar PHP en storage | `curl https://host/storage/porteria/test.php` | 403 o 404, nunca ejecución de PHP |
| E7 — Setup | Instalación limpia | `bash database/setup_smartcset.sh` en BD de test | Sin errores; `\df fun_validar_correo` retorna la función |
| E7 — Setup | Recuperación de contraseña | Flujo de `backend/routers/auth/v1/recuperar.php` en BD de test | Sin error 500 |
| E8 — TLS BD | TLS activo | `SELECT ssl FROM pg_stat_ssl JOIN pg_stat_activity ON...` | Columna `ssl = TRUE` para todas las conexiones |
| E8 — TLS BD | Puerto BD cerrado externamente | `nmap -p 5432 IP_SERVIDOR_WEB` | Puerto cerrado o filtrado |
| E9 — Parches | Inventario completo | Tabla Sección 11.1 sin filas vacías | Todas las versiones documentadas y sin desactualización crítica pendiente |
| E9 — Parches | Alertas configuradas | Confirmar suscripción a php.net/security + PostgreSQL announce | Confirmación de suscripción activa |
| E10 — SDLC | Checklist pre-commit | Revisar el último commit: ¿hay credenciales? ¿concatenación SQL? | Checklist limpio — 0 hallazgos críticos |
| E10 — SDLC | Prohibición edición directa | Verificar que no existe ningún archivo modificado en el servidor que no esté en git | `git status` en producción muestra árbol limpio |

### 14.2 Prueba de regresión — flujo normal de portería

Después de aplicar TODOS los entregables, verificar el flujo completo de trabajo:
1. Abrir `index.php` → Login con credenciales válidas → Redirige a `menu_principal.php` ✅
2. Ir a Ingreso → Ingresar documento de persona → Sistema busca persona → Registrar ingreso ✅
3. Ir a Salida → Buscar ingreso abierto por documento → Registrar salida ✅
4. Admin: ir a Configuración → Cambiar algún campo → Guardar ✅
5. Cerrar sesión desde el menú ✅

Si alguno de estos pasos falla tras los cambios, es un problema de regresión a resolver antes de continuar.

---

## 15. ESTIMACIÓN DE ESFUERZO

| Entregable | Esfuerzo estimado | Archivos principales a modificar | Dependencia externa |
|---|---|---|---|
| E1 — Auditoría OWASP | 15-20 h (auditoría + documentación) | Lectura de código, no escritura | Ninguna |
| E2 — Cifrado en reposo | 35-45 h (incluye migración y testing extensivo) | `backend/core/Db.php`, `prepare.php`, nuevas funciones SQL, migración | BD de test disponible |
| E3 — Rate limiting | 15-20 h | `index.php`, `prepare.php`, 2 funciones SQL, 1 migración | Ninguna |
| E4 — Hardening sesiones | 8-10 h | `backend/core/SecurityMiddleware.php` (activar), `prepare.php`, `index.php` | Ninguna |
| E5 — CSRF | 18-25 h (por la cantidad de formularios) | Todos los `procesar_*.php`, vistas con formularios, `helpers.php` | Ninguna |
| E6 — Verificación uploads | 5-8 h | Solo `.htaccess`, sin cambios PHP | Confirmar tipo de servidor (Apache/Nginx) con Oficina TI |
| E7 — Bugs setup | 4-6 h | `database/setup_smartcset.sh` | BD de test para verificar |
| E8 — Hardening red | 20-30 h (incluye coordinación con TI) | `backend/core/Db.php` (2 líneas), config de infraestructura | Oficina TI SENA para firewall y postgresql.conf |
| E9 — Gestión de parches | 4-6 h (inventario + suscripciones + proceso) | `database/REGISTRO_PARCHES.md` (nuevo), `.env.example` | Ninguna — proceso organizacional, no técnico |
| E10 — SDLC seguro | 3-5 h (checklist + adopción del proceso) | Ningún archivo de código — solo proceso y checklist | Ninguna — adopción de práctica |
| **TOTAL** | **~127-175 h** (3-4 semanas a ~40 h/semana) | | |

---

## 16. ALINEACIÓN CON ISC2 CC POR ENTREGABLE

| Entregable | Dominio ISC2 CC cubierto | Concepto específico del temario |
|---|---|---|
| E1 — Auditoría OWASP | Dominio 5 — Security Operations | Gestión de vulnerabilidades; identificación y evaluación de riesgos técnicos |
| E2 — Cifrado en reposo | Dominio 5 — Security Operations | Controles criptográficos; protección de datos en reposo |
| E3 — Rate limiting + logging | Dominio 3 — Access Control + D5 Security Ops | Controles de autenticación; logging y monitoreo de eventos de seguridad |
| E4 — Hardening sesiones | Dominio 3 — Access Control | Gestión de sesiones; autenticación segura; principios de menor privilegio |
| E5 — Tokens anti-CSRF | Dominio 3 — Access Control | Controles de acceso en aplicaciones web; protección de identidad de la solicitud |
| E6 — Verificación uploads | Dominio 5 — Security Operations | Hardening de aplicaciones; validación de entrada en límites del sistema |
| E7 — Bugs setup | Dominio 5 — Security Operations | Gestión de configuración; integridad del proceso de despliegue |
| E8 — Hardening red | Dominio 4 — Network Security | Segmentación de red; firewalls; comunicaciones cifradas (TLS); hardening de host |
| E9 — Gestión de parches | Dominio 5 — Security Operations | Gestión de vulnerabilidades y parches; ciclo de vida de componentes; monitoreo de amenazas conocidas |
| E10 — SDLC seguro | Dominio 5 — Security Operations + D3 Access Control | Desarrollo seguro; control de cambios; revisión de código; principios de seguridad en el ciclo de desarrollo |

---

## 17. REFERENCIAS CRUZADAS CON DOCUMENTOS DE FASE 0

- **FASE0-POL-001** (Política de Tratamiento de Datos, Sección 13 — Medidas de Seguridad): el cifrado en reposo (E2), el rate limiting (E3) y el hardening de sesiones (E4) son la implementación técnica concreta de las "medidas de seguridad" declaradas en esa sección.
- **FASE0-INV-002** (Inventario de Activos C-I-D): los activos `tab_personas` (INF-01, Confidencialidad Muy Alta) y `tab_log_ingresos` (INF-02) son los que justifican la prioridad de los Entregables 2 y 3. El control de cifrado recomendado en la Sección 12 del inventario se materializa en el E2.
- **FASE0-RIE-003** (Matriz de Riesgos): los riesgos R-A01 (fuerza bruta) y R-E1 (fuga de datos) aparecen en el Top 10 prioritario de esa matriz — son exactamente los que cierran los Entregables 3 y 2 respectivamente.
- **FASE0-ROL-004** (Roles y Responsabilidades): el Administrador del Sistema es el responsable técnico de implementar los entregables E1 a E7; la Oficina TI SENA es la responsable de E8 (infraestructura de red). La matriz RACI de ese documento aplica directamente a esta fase.
- **FASE0-AUD-005** (Cronograma de Auditorías): la tabla de hallazgos del Entregable 1 (Auditoría OWASP) alimenta directamente las auditorías trimestrales definidas en ese cronograma. El estado "cerrado" de cada hallazgo se verifica en la siguiente auditoría trimestral.
- **FASE0-PSI-006** (Política General de Seguridad, Objetivo O-02 — integridad y O-06 — SDLC): los Entregables 10 (SDLC seguro) y 9 (gestión de parches) son la implementación técnica de esos objetivos. El código de conducta de la Sección 9 de esa política prohíbe explícitamente las prácticas que el E10 formaliza como prohibidas.
- **FASE0-ACC-007** (Control de Acceso, Sección 8 — accesos privilegiados): los Entregables 4 (hardening de sesiones) y 5 (CSRF) implementan técnicamente las reglas de sesión y autenticación definidas en esa política. El E10 garantiza que esos controles no se revierten en futuros despliegues.
- **FASE0-INC-008** (Marco de Incidentes, Sección 13 — backups): el procedimiento de backup pre-despliegue del Entregable 10 (checklist de despliegue) está alineado con la política de backups del Marco de Incidentes, usando el mismo comando `pg_dump -Fc`.

---

## 18. RESUMEN DE PUNTOS QUE REQUIEREN ACCIÓN INSTITUCIONAL

Antes de iniciar la implementación, la Dirección del Centro y la Oficina TI SENA deben resolver:

🔲 **1. Definir y custodiar la clave de cifrado (`DB_ENCRYPTION_KEY`).**
La clave de cifrado en reposo (Entregable 2) no puede estar en el código ni en el repositorio git. Alguien en la organización debe ser el custodio formal de esta clave y del procedimiento para recuperarla si el servidor se repone desde cero.

🔲 **2. Proveer una base de datos de test independiente.**
Los Entregables 2 (cifrado) y 7 (setup) requieren probar migraciones de datos en una BD separada de producción. Sin BD de test, no se puede validar de forma segura antes de aplicar en producción.

🔲 **3. Confirmar el tipo de servidor web (Apache vs. Nginx).**
El Entregable 6 necesita saber si se usa Apache (para los `.htaccess`) o Nginx (para bloques `location` en el virtual host). La Oficina TI debe confirmar.

🔲 **4. Coordinar con Oficina TI la configuración de firewall y TLS (Entregable 8).**
Los cambios de `postgresql.conf`, `pg_hba.conf` y las reglas de firewall perimetral e interno requieren acceso de administrador a la infraestructura del SENA — es responsabilidad de la Oficina TI, no solo del desarrollador de SmartCSET.

🔲 **5. Confirmar IPs de la arquitectura real.**
El diagrama de red del Entregable 8 usa IPs de placeholder. La Oficina TI debe proporcionar las IPs reales del servidor web y del servidor de BD (o confirmar si ambos corren en la misma máquina, que es el caso típico de instalaciones pequeñas).

🔲 **6. Decidir sobre la habilitación de HTTPS en producción.**
El bloque de redirección HTTPS está comentado en `index.php`. Para activarlo, el servidor de producción necesita un certificado TLS válido (puede ser Let's Encrypt, gratuito). La Oficina TI debe gestionar la emisión del certificado.

🔲 **7. Designar custodio del Registro de Parches (Entregable 9).**
El Administrador del sistema es el responsable técnico de mantener el registro actualizado. La Dirección debe confirmar esta asignación formalmente para que exista trazabilidad institucional ante auditorías del MIPG o la Contraloría.

🔲 **8. Confirmar que no existe edición directa en producción (Entregable 10).**
La Oficina TI debe confirmar que el servidor de producción no tiene FTP activo ni carpetas de SmartCSET con permisos de escritura para usuarios no administrativos. Si existe acceso FTP heredado, debe ser deshabilitado antes de activar el checklist SDLC.

---

*Fin del documento — Plan de Implementación de Blindaje Técnico Inmediato — SmartCSET FASE1-BLI-001 v1.1*
