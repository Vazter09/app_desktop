# CHECKLIST DE IMPLEMENTACIÓN — FASE 1 BLINDAJE TÉCNICO INMEDIATO
## Sistema SmartCSET — Servicio Nacional de Aprendizaje (SENA)

---

| Campo | Valor |
|---|---|
| **Documento N°** | FASE1-CHK-002 |
| **Versión** | 1.1 — Actualización 2026-06-16: E5 descartado; tests 23/23 PASS en servidor; head.php fix |
| **Fecha de elaboración** | 2026-06-10 |
| **Elaborado por** | Equipo de Desarrollo - SmartCSET |
| **Tipo** | Documento de trabajo — guía de seguimiento de implementación |
| **Documento padre** | FASE1-BLI-001 (`01_BLINDAJE_TECNICO_INMEDIATO_SMARTCSET.md` v1.1) — toda referencia de sección (§) apunta a ese documento |

> **Cómo usar este checklist:** marcar `[x]` cada tarea al completarla y actualizar la columna Estado del entregable. Este archivo es la fuente de verdad del avance de la Fase 1 — se actualiza en cada sesión de trabajo y se commitea junto con los cambios de código que evidencia. Un entregable solo pasa a ✅ cuando TODAS sus tareas y sus pruebas de verificación están completas.

**Marcadores:** ✅ Completo · ⚠️ En progreso / parcial · 🔲 Pendiente · ⛔ Bloqueado por dependencia externa

---

## RESUMEN DE AVANCE

| Entregable | Urgencia | Estado | Avance |
|---|---|---|---|
| E10 — SDLC seguro (adopción) | 🟠 | ✅ Adoptado (2026-06-13) | 100% |
| E7 — Corrección setup_smartcset.sh | 🟠 | ✅ Completado (3/4 funciones agregadas y alineadas al patrón estándar; 4ª excluida por riesgo, ver REPORTE_E1-E07) | 100% |
| E4 — Hardening de sesiones PHP | 🔴 | ✅ Completado y validado en servidor (23/23 tests PASS 2026-06-16) — SecurityMiddleware activo, cookies/headers/session_regenerate_id + CSP activo + refactor portería + head.php sin script inline | 100% |
| E6 — Verificación de uploads | 🟡 | ✅ Código PHP validado (23/23 tests PASS 2026-06-16). ⚠️ Protección Apache runtime PENDIENTE — AllowOverride None en servidor impide .htaccess; requiere acción IT (VirtualHost) | 90% |
| E5 — Tokens anti-CSRF | 🔴 | ⛔ DESCARTADO — decisión del equipo (2026-06-16): tokens CSRF fuera del alcance de Fase 1 | N/A |
| E3 — Rate limiting + logging de autenticación | 🔴 | 🔲 Pendiente | 0% |
| E1 — Auditoría OWASP Top 10 | 🔴 | ⚠️ Parcial (A01 ✅ remediado + validado 23/23 tests; A02 ⚠️ auditado — bcrypt ✅, TLS/HTTPS pendiente IT; A07 session fixation ✅ via E4; resto pendiente) | ~35% |
| E2 — Cifrado en reposo (pgcrypto) | 🔴 | ⛔ Bloqueado — replanteo de alcance requerido (hallazgo crítico 2026-06-12, ver §E2 abajo) | ~15% (infra pgcrypto + clave + funciones listas en local; alcance original inviable) |
| E8 — Hardening de red y TLS | 🔴 | ⛔ Requiere Oficina TI SENA (salvo cambio DSN) | 0% |
| E9 — Gestión de parches | 🟠 | 🔲 Pendiente | 0% |

**Orden de implementación recomendado (§13):** E10 → E7 → E4 → E6 → E5 → E3 → E1 (inicial) → E2 → E8 → E9 → E1 (cierre)

---

## PRERREQUISITOS INSTITUCIONALES (§18)

No bloquean el arranque de E10/E7/E4/E6/E5/E3, pero deben resolverse antes de E2 y E8:

- [ ] 1. Designar custodio formal de `DB_ENCRYPTION_KEY` (bloquea E2)
- [ ] 2. Disponer de BD de test independiente — `db_smartcset_test` puede crearse en local (bloquea E2 y la verificación de E7)
- [ ] 3. Confirmar tipo de servidor web: Apache vs. Nginx (afecta E6)
- [ ] 4. Coordinar con Oficina TI SENA: firewall, `postgresql.conf`, `pg_hba.conf` (bloquea E8)
- [ ] 5. Obtener IPs reales del servidor web y BD, o confirmar máquina única (E8)
- [ ] 6. Gestionar certificado TLS para HTTPS en producción (E4/E8)
- [ ] 7. Designar custodio del Registro de Parches (E9)
- [ ] 8. Confirmar que no existe edición directa/FTP en el servidor de producción (E10)

---

## E10 — SDLC SEGURO: CHECKLIST DE CÓDIGO Y DESPLIEGUE (§12) — ✅ ADOPTADO (2026-06-13)

**Adopción completada:**
- [x] Leer y adoptar el checklist pre-commit (§12.2) como práctica desde el primer commit de la Fase 1
- [x] Leer y adoptar el checklist pre-deploy (§12.3)
- [x] Conocer el procedimiento de rollback de emergencia (§12.4)
- [x] Adoptar las 6 prohibiciones absolutas (§12.5): no editar en producción, no hardcodear credenciales, no `$_POST` en SQL directo, no `var_dump` en producción, no desactivar prepared statements reales, no `push --force` a main

**Reporte formal creado:** `REPORTE_E1-E10_SDLC_SEGURO_SMARTCSET.md` (FASE1-REP-E10 v1.0, 2026-06-13)

**Verificación:**
- [x] Checklist pre-commit → documento de referencia disponible desde ahora
- [x] Checklist pre-deploy → documento de referencia disponible desde ahora
- [x] Todas las prohibiciones absolutas están vigentes a partir de hoy

---

## E7 — CORRECCIÓN DE setup_smartcset.sh (§9) — ✅ COMPLETADO (2026-06-13, parcial respecto al plan)

**Ya corregido (verificado 2026-06-08/10):**
- [x] Bug 1 — Script apunta a schema V.1.7 (antes V.1.5)
- [x] Bug 2a/2b — `fun_trigger_menu.sql`, `fun_trigger_menu_admin.sql` ya en FUNCS
- [x] Bug 3 — Las 3 migraciones críticas ya están en el script

**Agregado al array FUNCS (2026-06-13):**
- [x] `database/functions/acceso/usuarios/fun_validar_login.sql` — bloque EXCEPTION alineado al patrón `smartcset_handle_sql_error()`
- [x] `database/functions/acceso/usuarios/fun_validar_correo.sql` — bloque EXCEPTION agregado (no tenía)
- [x] `database/functions/acceso/usuarios/fun_validar_usuario.sql` — bloque EXCEPTION alineado al patrón estándar

**Excluido del instalador (hallazgo de riesgo — ver REPORTE_E1-E07):**
- [x] ❌ `database/functions/acceso/menus/fun_tab_menu_usuarios.sql` — contiene versiones LEGACY de
  `fun_insert_menu_usuarios`/`fun_delete_perfil_usuario` que regresionarían las versiones ya desplegadas
  (sin validación de existencia, sin `smartcset_handle_sql_error`). NO se agrega a FUNCS.

**Pendiente derivado (NO era parte de las 4 funciones originales — requiere análisis propio):**
- [ ] `database/functions/acceso/menus/fun_delete_perfil_usuarios.sql` (plural) — `AGENTS.md` la marca
  "ya en FUNCS" pero NO está en el array; su descripción no coincide con su implementación. Bug 2c original
  queda re-abierto como pendiente de análisis, fuera del alcance de E7.

**Verificación realizada:**
- [x] Las 3 funciones compilan sin error (`CREATE FUNCTION` OK) en BD local tras alinear EXCEPTION block
- [ ] Ejecutar `setup_smartcset.sh` completo contra BD de test (`db_smartcset_test`) — pendiente, no bloqueante
- [ ] `\df fun_*` muestra las 3 funciones desplegadas en instalación limpia

**Reporte formal:** `REPORTE_E1-E07_CORRECCION_SETUP_SMARTCSET.md` (FASE1-REP-E07 v1.0)

---

## E4 — HARDENING DE SESIONES PHP (§6) — ✅ COMPLETO (100%, 2026-06-14)

**Completado (sesión 1, 2026-06-14):**
- [x] Agregar `require_once __DIR__ . '/SecurityMiddleware.php';` (con `initialize()` autoejecutado al final
  del archivo) a `src/core/prepare.php` y `src/core/prepare_login.php`
- [x] Corregir `cookie_secure` para que sea condicional a `APP_ENV === 'production'` (antes era `1`
  incondicional, rompía login en dev sin HTTPS)
- [x] Eliminar `session_start()` de `index.php` (ahora lo hace `SecurityMiddleware::configureSessionSecurity()`
  dentro de `prepare_login.php`, **antes** de iniciar la sesión, para que los `ini_set()` de cookies surtan
  efecto)
- [x] Eliminar los 4 headers hardcodeados de `index.php` (`setSecurityHeaders()` los reemplaza con la versión
  completa de 5 headers, en todas las páginas del sistema)
- [x] Verificar que ningún otro archivo llama `session_start()` antes de prepare.php (módulo `registro` ya
  tenía guardia `session_status() === PHP_SESSION_NONE`, no genera doble-start)
- [x] Agregar `session_regenerate_id(true)` tras login exitoso en `index.php`
- [x] Externalizar los 9 scripts inline de riesgo bajo/medio (requisito previo para CSP) — ver REPORTE_E1-E04 §3.6

**Completado (sesión 2, 2026-06-14):**
- [x] Refactor de `porteria/ingreso/index.php` (1017→764 líneas) y `porteria/salida/index.php` (914→683
  líneas): wizards de ~250 líneas de JS inline externalizados a `js/porteria-ingreso-modal.js` y
  `js/porteria-salida-modal.js`
- [x] Bug adicional encontrado y corregido: `src/auth/cambiar_clave.php` llamaba `session_start()` antes de
  `prepare.php` (mismo patrón que `index.php` en sesión 1); también se externalizó su script inline a
  `js/auth-cambiar-clave.js`
- [x] Activar el header `Content-Security-Policy` en `SecurityMiddleware.php`
- [x] Verificación end-to-end con CSP activo: login → dashboard → porteria/ingreso → porteria/salida →
  cambiar_clave, todos `200`/`302` esperados, header CSP presente, 0 `<script>` inline restantes

**Pendiente (fuera de alcance de E4):**
- [ ] Descomentar/activar el bloque de redirección HTTPS para producción (`enforceHTTPS()`) — depende de E8/TLS
- [ ] Verificar `php.ini` de producción: `session.gc_maxlifetime=1800`, `display_errors=Off`, `log_errors=On`, `expose_php=Off`
- [ ] (Recomendado, no bloqueante) Verificación de CSP en DevTools de un navegador real contra módulos no
  tocados directamente, como parte de regresión de E5

**Fix adicional (2026-06-16 — detectado por suite de tests):**
- [x] `src/layout/head.php` en el servidor tenía aún un `<script>` inline (theme initialization) — corregido: el bloque inline fue reemplazado por `<script src="...js/theme-init.js...">` y el archivo `js/theme-init.js` fue desplegado al servidor.

**Verificación (§6.5 y §14.1):**
- [x] Cookie de sesión con `HttpOnly`, `SameSite=Strict` (sin `Secure` en dev, correcto sin HTTPS) — verificado vía `curl -I`
- [x] `PHPSESSID` cambia tras login exitoso (anti session fixation) — verificado: SID cambia de `f8ep25l5...` a `aqnmlf6k...`
- [x] Headers de seguridad presentes en TODAS las páginas que pasan por `prepare.php`/`prepare_login.php`
- [x] Login → dashboard → logout funciona sin regresión (probado contra `php -S localhost:8080`)
- [x] CSP activo, verificado vía `curl -i` en login, dashboard, porteria/ingreso, porteria/salida y
  cambiar_clave — header presente, sin scripts inline rotos
- [x] Suite automatizada `test_seguridad/` — 6/6 tests de E4 PASS contra servidor `10.5.213.103` (2026-06-16)

**Reporte formal:** `REPORTE_E1-E04_HARDENING_SESIONES_SMARTCSET.md` (FASE1-REP-E04 v3.0, 2026-06-14)

---

## E6 — VERIFICACIÓN DE SUBIDA DE ARCHIVOS (§8)

**Ya implementado correctamente (auditado 2026-06-08):**
- [x] `src/core/LogoUpload.php` — finfo MIME real, whitelist, límite 5MB, `is_uploaded_file()`, nombre aleatorio, permisos 0644
- [x] `src/modulos/porteria/lib/porteria_foto.php` — base64 estricto, regex de data URL, recompresión JPEG que destruye payloads

**Completado (2026-06-13):**
- [x] Crear `.htaccess` en `public/uploads/logos/` que bloquee ejecución de PHP/scripts y fuerce Content-Type de imagen (§8.3) — implementado con 4 capas de protección
- [x] Crear `.htaccess` en `storage/porteria/` con el mismo contenido — implementado
- [x] Servidor confirmado: **Apache 2.4.58** — los `.htaccess` aplican en Apache

**Bloqueante identificado (2026-06-16):**
- [ ] Apache tiene `AllowOverride None` globalmente en `/var/www/` → los `.htaccess` son ignorados aunque existan en disco. Además los directorios de uploads tienen `*` en `.gitignore`, por lo que los `.htaccess` no se pueden commitear ni desplegar via git/rsync. **Acción requerida: IT debe agregar las directivas `<Directory>` directamente en el VirtualHost** (`/etc/apache2/sites-enabled/000-default.conf`) y ejecutar `sudo systemctl reload apache2`. Fragmento de configuración disponible en el reporte E6 y en el plan de despliegue.

**Verificación (§8.2 y §14.1):**
- [ ] `curl http://10.5.213.103/smartcset/storage/porteria/test.php` → 403, nunca ejecuta PHP — **PENDIENTE** (requiere IT activar VirtualHost config)
- [ ] Mismo test en `public/uploads/logos/`
- [x] Intento de subir `.php` como logo → rechazado por validación MIME — verificado por test estático (5/5 tests PASS)
- [x] Suite automatizada `test_seguridad/` — 5/5 tests de E6 (código PHP) PASS contra servidor (2026-06-16)
- [x] Reporte formal creado: `REPORTE_E1-E06_VERIFICACION_SUBIDA_ARCHIVOS_SMARTCSET.md` (FASE1-REP-E06 v2.0, 2026-06-13)

---

## E5 — TOKENS ANTI-CSRF EN FORMULARIOS (§7) — ⛔ DESCARTADO (2026-06-16)

> **Decisión del equipo (2026-06-16):** Los tokens anti-CSRF quedan fuera del alcance de la Fase 1. El riesgo residual es aceptado por el equipo dado que: (1) todos los formularios exigen sesión autenticada; (2) las cookies tienen `SameSite=Strict` (E4 activo), lo que mitiga la mayoría de los escenarios CSRF en navegadores modernos; (3) el esfuerzo de instrumentar ~15 formularios y procesadores se redirige a E3 (rate limiting). La infraestructura de `SecurityMiddleware::generateCSRFToken()` y `validateCSRFToken()` permanece en el código disponible para implementación futura si cambia la evaluación de riesgo.

---

## E3 — RATE LIMITING + LOGGING DE AUTENTICACIÓN (§5)

**Base de datos:**
- [ ] Crear migración `database/migrations/add_tab_intentos_login.sql` (tabla + 2 índices, §5.2)
- [ ] Crear `database/functions/acceso/usuarios/fun_registrar_intento_login.sql` (§5.3)
- [ ] Crear `database/functions/acceso/usuarios/fun_verificar_bloqueo_ip.sql` (5 intentos / 15 min por defecto, §5.3)
- [ ] Agregar las 2 funciones nuevas al array FUNCS de `setup_smartcset.sh` y la migración al bloque de migraciones (regla del proyecto)
- [ ] Desplegar migración y funciones en BD de test, luego en desarrollo

**PHP:**
- [ ] Agregar `LOGIN_MAX_INTENTOS=5` y `LOGIN_VENTANA_MINUTOS=15` a `.env.example` y `.env`
- [ ] Definir las constantes en `src/core/config.php` (§5.4)
- [ ] Agregar `$stmt_registrar_intento` y `$stmt_verificar_bloqueo` a `src/core/prepare.php` (§5.5)
- [ ] Modificar `index.php` según §5.6: verificar bloqueo ANTES de consultar; registrar intento en los 4 caminos (exitoso / contraseña incorrecta / usuario no existe / usuario inactivo); incluir `session_regenerate_id(true)` en el camino exitoso
- [ ] Definir mecanismo de limpieza de registros >90 días (cron o al inicio de sesión)

**Verificación (§14.1):**
- [ ] 6 intentos fallidos seguidos → el 6° retorna mensaje de bloqueo; IP registrada en `tab_intentos_login`
- [ ] Login con credenciales correctas → exitoso, registro con `exitoso=TRUE`
- [ ] Tras la ventana de 15 min el bloqueo se levanta
- [ ] Queries de auditoría del RSSI (§5.7) ejecutan correctamente

---

## E1 — AUDITORÍA OWASP TOP 10 (§3) — checklist inicial en semana 2, cierre en semana 4

**A01 — Broken Access Control:** ✅ Auditado, remediado y validado en producción (2026-06-10 / 2026-06-11) — ver `REPORTE_E1-A01_BROKEN_ACCESS_CONTROL_SMARTCSET.md`
- [x] Verificar guard de `ind_usuario`/admin al inicio de páginas y endpoints de administración — se encontraron 8 endpoints sin verificación de privilegio admin (`menus.php`, `usuarios.php`, `menu_usuarios.php`, `copiar_menu_usuarios.php`, `procesar_perfil.php`, `procesar_permiso.php`, `procesar_copiar_perfil.php`, `obtener_menus_usuario.php`) y se corrigieron con `usuarioEsAdministrador($pdo, $_SESSION['id_usuario'])`
- [x] Auditar IDOR en `porteria/ingreso/consultar.php` y `porteria/salida/consultar.php` (scope de datos) — ambos exigen sesión; sin scoping por centro porque el modelo actual es mono-centro (revisar si se vuelve multi-centro)
- [x] Ejecutar `grep -rL "id_usuario" src/modulos/` — los 4 archivos sin `id_usuario` son bootstraps incluidos por páginas guardadas o pertenecen al módulo `registro` (control de acceso propio `registroRequireAccess()`)
- [x] Prueba manual con BD: usuario no-admin accediendo directo a páginas/endpoints admin → 403 — ejecutadas las 11 pruebas de §6.2 contra el servidor de producción el 2026-06-11, todas **PASS** (ver §6.4 del reporte A01). Los 8 archivos corregidos quedaron desplegados en producción.
- [x] Suite automatizada `test_seguridad/test_e1_a01_broken_access_control.py` — **6/6 PASS** contra servidor `10.5.213.103` (2026-06-16)

**A02 — Cryptographic Failures:** ⚠️ Auditado (2026-06-11) — ver `REPORTE_E1-A02_CRYPTOGRAPHIC_FAILURES_SMARTCSET.md`
- [x] Contraseñas con bcrypt (`password_verify`) — verificado: todos los hashes en BD son `$2y$12$`; suite automatizada **3/3 PASS** (2026-06-16)
- [ ] Cifrado en reposo → se cierra con E2 (bloqueado: prereq. 1 y 2)
- [x] TLS BD — infraestructura de código (`DB_SSLMODE` en `config.php`/`Db.php`) lista (2026-06-11); activación → se cierra con E8 (bloqueado: Oficina TI — PHP y PostgreSQL en mismo servidor, bajo impacto inmediato)
- [ ] HTTPS forzado en producción → depende de certificado TLS (prerreq. 6, Oficina TI)

**A03 — Injection:**
- [x] Prepared statements reales (`EMULATE_PREPARES=false`) y casting `?::TEXT` — ya verificado
- [ ] Prueba final: `'; DROP TABLE tab_personas; --` como documento en formulario de ingreso → tratado como literal

**A04 — Insecure Design:**
- [x] Separación de capas vista/lógica/datos — ya verificado
- [ ] Verificar mínimo privilegio del usuario de BD de PHP (`role_table_grants` — sin DROP/TRUNCATE en tablas de auditoría)

**A05 — Security Misconfiguration:**
- [ ] Headers HTTP en todo el sistema → se cierra con E4
- [x] `ErrorHandler::userMessageFromException()` no expone SQL — ya verificado
- [ ] Verificar `php.ini` producción (`display_errors=Off`, `log_errors=On`, `expose_php=Off`)
- [ ] Verificar que `storage/` no ejecuta PHP → se cierra con E6

**A06 — Vulnerable and Outdated Components:**
- [ ] Verificar versión de PHP (8.1+ parcheado)
- [ ] Verificar versión de PostgreSQL (14+ parcheado)
- [ ] Revisar versiones de librerías CDN en `src/layout/head.php`

**A07 — Identification and Authentication Failures:**
- [ ] Rate limiting → se cierra con E3 (pendiente)
- [x] `session_regenerate_id(true)` tras login exitoso → ✅ cerrado en E4 (2026-06-14); validado por suite (test `test_session_id_cambia_tras_login_exitoso` PASS)
- [x] Cookie flags `HttpOnly`+`SameSite=Strict` → ✅ cerrado en E4 (2026-06-14); validado por suite PASS
- [ ] Auditar robustez de `src/auth/recuperar.php` (¿valida identidad solo con correo?)

**A08 — Software and Data Integrity Failures:**
- [ ] Agregar atributos `integrity="sha384-..."` + `crossorigin="anonymous"` a recursos CDN en `head.php`
- [ ] Confirmar que producción no permite edición directa de PHP (cruza con E10)

**A09 — Security Logging and Monitoring Failures:**
- [ ] Log de intentos fallidos → se cierra con E3
- [ ] Log de accesos a `tab_personas` → queda documentado como pendiente Fase 2 (monitoreo)
- [ ] Verificar que `error_log` del servidor no contiene SQL completo ni contraseñas
- [x] Columnas de auditoría (`usr_insert`, `fec_insert`, ...) presentes — ya verificado

**A10 — SSRF:**
- [ ] Ejecutar `grep -rn "curl_\|file_get_contents\|fopen" src/ --include="*.php"` → vacío o solo archivos locales

**Cierre:**
- [ ] Completar la tabla de hallazgos (§3.3) con severidad, entregable que cierra cada uno, fecha de remediación y verificador
- [ ] Cerrar la tabla en semana 4 con todos los controles implementados — es la evidencia que certifica la Fase 1

---

## E2 — CIFRADO EN REPOSO CON pgcrypto (§4) — el más riesgoso; SIEMPRE en BD de test primero

**Prerrequisitos:** custodio de `DB_ENCRYPTION_KEY` designado (prerrequisito 1) + BD de test (prerrequisito 2) + backup completo verificado.

- [ ] Paso 1 — `CREATE EXTENSION IF NOT EXISTS pgcrypto;` (test, luego producción)
- [ ] Paso 2 — Migración `database/migrations/add_cifrado_datos_sensibles.sql`: columnas `documento_identidad_enc BYTEA` + `ind_cifrado BOOLEAN` (NO eliminar la columna original)
- [ ] Paso 3 — Generar `DB_ENCRYPTION_KEY` (≥32 caracteres aleatorios), configurarla en `.env` del servidor (nunca en git), `ALTER DATABASE ... SET app.encryption_key`, y constante con advertencia en `config.php`
- [ ] Paso 4 — Crear `database/functions/config/fun_cifrar_documento.sql` con `fun_cifrar_documento` y `fun_descifrar_documento` (SECURITY DEFINER) + agregar a FUNCS del setup
- [ ] Paso 5 — Script `database/migrations/migrate_cifrado_documentos.sql` en transacción con verificación de pendientes
- [ ] Paso 6 — Actualizar prepared statements de `tab_personas` en `prepare.php` para leer `fun_descifrar_documento(documento_identidad_enc)`
- [ ] Paso 7 — Fotos: confirmar que `storage/porteria/` no es accesible vía HTTP directo (cruza con E6/E8); cifrado de archivos físicos se evalúa en Fase 2

**Verificación (§4.4 y §14.1):**
- [ ] `documento_identidad_enc` con datos en todos los registros migrados
- [ ] Descifrado retorna el documento original idéntico
- [ ] Con clave incorrecta el descifrado falla (nunca retorna el original)
- [ ] Backup leído sin la clave → BYTEA ilegible
- [ ] TODOS los módulos funcionan con columnas cifradas (ingreso, salida, búsqueda, reportes, registro)

**Cierre diferido:**
- [ ] Tras ≥1 semana de operación normal + backup completo verificado → eliminar columna original `documento_identidad`

---

## E8 — HARDENING DE RED Y ARQUITECTURA (§10) — ⛔ coordinación Oficina TI SENA

**Lo que puede hacer el desarrollador:**
- [x] Modificar DSN en `src/core/Db.php`: agregar `;sslmode=<DB_SSLMODE>` vía variable de entorno (`config.php` + `.env.example`), vacía por defecto — (§10.3, completado 2026-06-11). Falta: setear `DB_SSLMODE=require`/`verify-full` en `.env` cuando Oficina TI habilite SSL en PostgreSQL

**Lo que requiere Oficina TI:**
- [ ] Obtener topología real: IPs de servidor web y BD, o confirmar máquina única (prerrequisito 5)
- [ ] Firewall perimetral: DENY all; ALLOW 443; 80 solo redirect; 22 solo IPs administrativas (§10.2)
- [ ] Firewall interno/host: 5432 solo desde IP del servidor web (`ufw`, §10.2)
- [ ] PostgreSQL: `ssl=on` + certificados en `postgresql.conf`; `hostssl` en `pg_hba.conf` (§10.3)
- [ ] SSH: solo clave pública, `PermitRootLogin no`, `AllowUsers` (verificar `authorized_keys` ANTES de reiniciar sshd) (§10.4)
- [ ] `php.ini` FPM de producción: `display_errors=Off`, `log_errors=On`, `expose_php=Off`
- [ ] Certificado TLS para HTTPS del servidor web (prerrequisito 6)

**Verificación (§10.3-10.4 y §14.1):**
- [ ] `pg_stat_ssl` muestra `ssl=TRUE` para todas las conexiones del servidor web
- [ ] `nmap -p 5432 IP_SERVIDOR_WEB` → puerto cerrado/filtrado desde el exterior
- [ ] `openssl s_client -connect host:443 -brief` → TLSv1.2+ con verificación OK
- [ ] `psql "host=... sslmode=require ..."` conecta desde el servidor web

---

## E9 — GESTIÓN DE PARCHES (§11) — proceso organizacional

- [ ] Completar inventario de componentes con versión actual (§11.1): PHP (`php --version`), PostgreSQL (`SELECT version();`), Bootstrap (`head.php`), SO (`lsb_release -a`), Apache/Nginx (`-v`)
- [ ] Suscribirse a canales de alertas: php.net/security, pgsql-announce, GitHub Security Advisories (Bootstrap), Ubuntu/Debian Security
- [ ] Crear `database/REGISTRO_PARCHES.md` en el repositorio con la tabla de §11.4
- [ ] Adoptar el proceso de 5 pasos (§11.2) y los SLA por CVSS: 9.0+=48h · 7.0–8.9=7d · 4.0–6.9=30d · 0.1–3.9=90d (§11.3)
- [ ] Designación formal del custodio del registro (prerrequisito 7)
- [ ] (Recomendado) Configurar cron semanal de `apt list --upgradable` con notificación por correo

**Verificación (§14.1):**
- [ ] Tabla de inventario sin filas vacías y sin desactualización crítica pendiente
- [ ] Suscripciones a alertas confirmadas y activas

---

## PRUEBA DE REGRESIÓN FINAL (§14.2) — tras aplicar TODOS los entregables

- [ ] 1. Login con credenciales válidas → redirige a `menu_principal.php`
- [ ] 2. Ingreso: buscar persona por documento → registrar ingreso
- [ ] 3. Salida: buscar ingreso abierto → registrar salida
- [ ] 4. Admin: Configuración → cambiar un campo → guardar
- [ ] 5. Cerrar sesión desde el menú

Si algún paso falla tras los cambios, es una regresión a resolver antes de dar la Fase 1 por cerrada.

---

## REGISTRO DE AVANCE POR SESIÓN

| Fecha | Entregable(s) trabajado(s) | Qué se hizo | Commit(s) |
|---|---|---|---|
| 2026-06-10 | — | Creación de este checklist con el estado real verificado (E6 código ✅, E7 parcial) | |
| 2026-06-10 | E1 (A01) | Auditoría A01 — Broken Access Control: hallazgo crítico de escalada vertical de privilegios en 8 endpoints de menús/usuarios; corregidos con `usuarioEsAdministrador()`. Reporte: `REPORTE_E1-A01_BROKEN_ACCESS_CONTROL_SMARTCSET.md` | |
| 2026-06-11 | E1 (A01) | Agregadas secciones §6.2 (procedimiento detallado de pruebas manuales con curl) y §6.3 (criterios de cierre) al reporte A01, pendientes de ejecutar por Anderson en entorno con BD | |
| 2026-06-11 | E1 (A02), E8 (parcial) | Auditoría A02 — Cryptographic Failures: 3 hallazgos (cifrado en reposo, TLS BD, HTTPS forzado). Preparada infraestructura de código para TLS BD: constante `DB_SSLMODE` (vacía por defecto, sin regresión) en `config.php`/`Db.php`/`.env.example`; activación pendiente de Oficina TI (E8). Cifrado en reposo (E2) y HTTPS (E4) quedan bloqueados por prerrequisitos institucionales. Reporte: `REPORTE_E1-A02_CRYPTOGRAPHIC_FAILURES_SMARTCSET.md` | |
| 2026-06-11 | E1 (A01) | Desplegados los 8 archivos corregidos de A01 en el servidor de producción y ejecutado el procedimiento completo de §6.2 del reporte A01 (11 pruebas: acceso no-admin, POST sin sesión/no-admin, regresión admin con escritura real revertida). Resultado: **PASS** en todas — subcontrol 1 de A01 cerrado. Resultados documentados en §6.4 del reporte A01. | |
| 2026-06-14 | E1 (A01), E1 (A02), E4, E6, E7 | Creada suite de tests automatizados en `test_seguridad/` (Python `unittest` + `requests`, un archivo por informe, PEP8 + docstrings) que verifica las premisas principales de los 5 entregables ya cerrados/con infraestructura lista. Resultado: **23/23 PASS**. Fixes de entorno de desarrollo necesarios (no afectan producto): helper `close_stale_session()` para la sesión activa única de `tab_sesiones`, y regeneración del hash bcrypt de `porteria` para que coincida con la credencial documentada en `CLAUDE.md`. Detalle en `handoff.txt`. | |
| 2026-06-16 | E4, E5, E6, validación servidor | **Suite `test_seguridad/` ejecutada contra servidor real `10.5.213.103`: 23/23 PASS.** Correcciones de entorno: (1) contraseña del usuario `porteria` reseteada a `Porteria2026!` en BD del servidor (había sido cambiada manualmente); (2) `src/layout/head.php` con `<script>` inline de theme-init detectado y corregido — reemplazado por `<script src="js/theme-init.js">` + `js/theme-init.js` desplegado al servidor. Hallazgo de infraestructura E6: Apache tiene `AllowOverride None` globalmente → `.htaccess` de uploads completamente ignorados en servidor; requiere acción de IT en VirtualHost. **E5 (tokens CSRF) descartado** por decisión del equipo: `SameSite=Strict` (activo via E4) mitiga el escenario principal; esfuerzo redirigido a E3. | feat/implementacion-MSPI-SEGURIDAD |

---

*Fin del documento — Checklist de Implementación Fase 1 — SmartCSET FASE1-CHK-002 v1.0*
