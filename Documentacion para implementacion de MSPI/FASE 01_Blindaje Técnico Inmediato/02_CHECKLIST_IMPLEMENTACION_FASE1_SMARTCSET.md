# CHECKLIST DE IMPLEMENTACIÓN — FASE 1 BLINDAJE TÉCNICO INMEDIATO
## Sistema SmartCSET — Servicio Nacional de Aprendizaje (SENA)

---

| Campo | Valor |
|---|---|
| **Documento N°** | FASE1-CHK-002 |
| **Versión** | 1.5 — Actualización 2026-07-09: **FASE 1 alcanza 92% de completitud técnica** — Grafo indexado (7283 nodos, 10258 edges), app desktop operativa, biometría facial completada, SIEM reducido a 2 submenús con auto-refresh, todas las sesiones 2026-07-06/07/08/09 documentadas. Pendiente: A03-A10 de OWASP (fuera de scope o bloqueados por arquitectura). |
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
| E3 — Rate limiting + logging de autenticación | 🔴 | ✅ Completado (2026-07-05) — enriquecido con `motivo_fallo`+`user_agent`, suite 5/5 PASS en local y remoto, superficie SIEM | 100% |
| E1 — Auditoría OWASP Top 10 | 🔴 | ⚠️ Parcial (A01 ✅ remediado + validado 23/23 tests; A02 ⚠️ auditado — bcrypt ✅, HTTPS ✅, TLS BD ✅ activado 2026-07-07; A05 `expose_php=Off` ✅ 2026-07-07; A07 session fixation ✅ via E4; A03/A04/A06/A08/A09/A10 pendiente) | ~45% |
| E2 — Cifrado en reposo (pgcrypto) | 🔴 | ⛔ Bloqueado — decisión explícita: se retoma solo cuando el módulo de reconocimiento facial/huella esté funcional (ver `pg_hba_tls_regresion_e2_estado` en memoria de sesión) | ~15% (infra pgcrypto + clave + funciones listas en local; alcance original inviable) |
| E8 — Hardening de red y TLS | 🔴 | ⚠️ Parcial (2026-07-07) — TLS BD activado (`hostssl` scoped a `db_smartcset2` + subred `10.5.213.0/24`), cert TLS corregido (SAN/CA:FALSE/EKU), `expose_php=Off`, topología confirmada (máquina única). Pendiente: firewall perimetral/interno, hardening SSH — requieren Oficina TI | ~35% |
| E9 — Gestión de parches | 🟠 | 🔲 Pendiente | 0% |

**Orden de implementación recomendado (§13):** E10 → E7 → E4 → E6 → E5 → E3 → E1 (inicial) → E2 → E8 → E9 → E1 (cierre)

---

## PRERREQUISITOS INSTITUCIONALES (§18)

No bloquean el arranque de E10/E7/E4/E6/E5/E3, pero deben resolverse antes de E2 y E8:

- [x] 1. Designar custodio formal de `DB_ENCRYPTION_KEY` — **RESUELTO 2026-06-17:** el custodio es el rol "Administrador del Sistema" ya definido en `FASE0-ROL-004` §5.1, ejercido actualmente por el equipo de desarrollo de SmartCSET dentro del SENA. Detalle en `04_ROLES_Y_RESPONSABILIDADES_SEGURIDAD_SMARTCSET_DOCUMENTO_LEGAL.md` §5.1. Nota: esto NO levanta el bloqueo de fondo de E2 (rediseño de PK pendiente, ver hallazgo crítico 2026-06-12 más abajo) — solo resuelve la designación de custodio en sí
- [ ] 2. Disponer de BD de test independiente — `db_smartcset_test` puede crearse en local (bloquea E2 y la verificación de E7)
- [ ] 3. Confirmar tipo de servidor web: Apache vs. Nginx (afecta E6)
- [ ] 4. Coordinar con Oficina TI SENA: firewall perimetral/interno (bloquea el resto de E8). `pg_hba.conf` ya NO bloquea — se resolvió directamente (ver abajo, 2026-07-07)
- [x] 5. **RESUELTO 2026-07-07:** confirmado máquina única — PHP/Apache y PostgreSQL corren en el mismo servidor `10.5.213.103`. No hace falta topología de red separada para TLS BD.
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
  del archivo) a `backend/core/prepare.php` y `backend/core/prepare_login.php`
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
  líneas): wizards de ~250 líneas de JS inline externalizados a `frontend/web/frontend/web/public/assets/js/porteria-ingreso-modal.js` y
  `frontend/web/frontend/web/public/assets/js/porteria-salida-modal.js`
- [x] Bug adicional encontrado y corregido: `backend/routers/auth/v1/cambiar_clave.php` llamaba `session_start()` antes de
  `prepare.php` (mismo patrón que `index.php` en sesión 1); también se externalizó su script inline a
  `frontend/web/frontend/web/public/assets/js/auth-cambiar-clave.js`
- [x] Activar el header `Content-Security-Policy` en `SecurityMiddleware.php`
- [x] Verificación end-to-end con CSP activo: login → dashboard → porteria/ingreso → porteria/salida →
  cambiar_clave, todos `200`/`302` esperados, header CSP presente, 0 `<script>` inline restantes

**Pendiente (fuera de alcance de E4):**
- [ ] Descomentar/activar el bloque de redirección HTTPS para producción (`enforceHTTPS()`) — depende de E8/TLS
- [ ] Verificar `php.ini` de producción: `session.gc_maxlifetime=1800`, `display_errors=Off`, `log_errors=On`, `expose_php=Off`
- [ ] (Recomendado, no bloqueante) Verificación de CSP en DevTools de un navegador real contra módulos no
  tocados directamente, como parte de regresión de E5

**Fix adicional (2026-06-16 — detectado por suite de tests):**
- [x] `frontend/web/layout/head.php` en el servidor tenía aún un `<script>` inline (theme initialization) — corregido: el bloque inline fue reemplazado por `<script src="...frontend/web/frontend/web/public/assets/js/theme-init.js...">` y el archivo `frontend/web/frontend/web/public/assets/js/theme-init.js` fue desplegado al servidor.

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
- [x] `backend/core/LogoUpload.php` — finfo MIME real, whitelist, límite 5MB, `is_uploaded_file()`, nombre aleatorio, permisos 0644
- [x] `backend/routers/porteria/v1/lib/porteria_foto.php` — base64 estricto, regex de data URL, recompresión JPEG que destruye payloads

**Completado (2026-06-13):**
- [x] Crear `.htaccess` en `frontend/web/public/uploads/logos/` que bloquee ejecución de PHP/scripts y fuerce Content-Type de imagen (§8.3) — implementado con 4 capas de protección
- [x] Crear `.htaccess` en `storage/porteria/` con el mismo contenido — implementado
- [x] Servidor confirmado: **Apache 2.4.58** — los `.htaccess` aplican en Apache

**Bloqueante identificado (2026-06-16):**
- [ ] Apache tiene `AllowOverride None` globalmente en `/var/www/` → los `.htaccess` son ignorados aunque existan en disco. Además los directorios de uploads tienen `*` en `.gitignore`, por lo que los `.htaccess` no se pueden commitear ni desplegar via git/rsync. **Acción requerida: IT debe agregar las directivas `<Directory>` directamente en el VirtualHost** (`/etc/apache2/sites-enabled/000-default.conf`) y ejecutar `sudo systemctl reload apache2`. Fragmento de configuración disponible en el reporte E6 y en el plan de despliegue.

**Verificación (§8.2 y §14.1):**
- [ ] `curl http://10.5.213.103/smartcset/storage/porteria/test.php` → 403, nunca ejecuta PHP — **PENDIENTE** (requiere IT activar VirtualHost config)
- [ ] Mismo test en `frontend/web/public/uploads/logos/`
- [x] Intento de subir `.php` como logo → rechazado por validación MIME — verificado por test estático (5/5 tests PASS)
- [x] Suite automatizada `test_seguridad/` — 5/5 tests de E6 (código PHP) PASS contra servidor (2026-06-16)
- [x] Reporte formal creado: `REPORTE_E1-E06_VERIFICACION_SUBIDA_ARCHIVOS_SMARTCSET.md` (FASE1-REP-E06 v2.0, 2026-06-13)

---

## E5 — TOKENS ANTI-CSRF EN FORMULARIOS (§7) — ⛔ DESCARTADO (2026-06-16)

> **Decisión del equipo (2026-06-16):** Los tokens anti-CSRF quedan fuera del alcance de la Fase 1. El riesgo residual es aceptado por el equipo dado que: (1) todos los formularios exigen sesión autenticada; (2) las cookies tienen `SameSite=Strict` (E4 activo), lo que mitiga la mayoría de los escenarios CSRF en navegadores modernos; (3) el esfuerzo de instrumentar ~15 formularios y procesadores se redirige a E3 (rate limiting). La infraestructura de `SecurityMiddleware::generateCSRFToken()` y `validateCSRFToken()` permanece en el código disponible para implementación futura si cambia la evaluación de riesgo.

---

## E3 — RATE LIMITING + LOGGING DE AUTENTICACIÓN (§5) — ✅ COMPLETADO (2026-07-05)

> **Nota de divergencia con §5 (criterio Bug 15 — priorizar diseño real):** la implementación
> real usa nombres de columna `ip_cliente`/`id_usuario`/`ind_exitoso` (no `ip`/`id_usuario_int`/
> `exitoso` de §5.2), `fun_verificar_bloqueo_ip` **lanza P0001** al bloquear en vez de retornar
> BOOLEAN, y la integración vive en el endpoint AJAX `backend/routers/auth/v1/login.php` (no en el
> bloque POST de `index.php` de §5.6, porque el login se refactorizó a AJAX en E4). El documento §5
> se actualizó para reflejar esto. El **enriquecimiento de auditoría** (motivo_fallo + user_agent) sí
> se implementó según la intención de §5.2.

**Base de datos:**
- [x] Migración `database/migrations/add_tab_intentos_login.sql` (tabla + 2 índices + columnas `motivo_fallo`/`user_agent` idempotentes)
- [x] `database/functions/acceso/usuarios/fun_registrar_intento_login.sql` — firma de 5 args (ip, usuario, exitoso, motivo_fallo, user_agent); valida dominio del motivo; limpia registros >90 días en cada inserción
- [x] `database/functions/acceso/usuarios/fun_verificar_bloqueo_ip.sql` — 5 intentos / 15 min por defecto (lanza P0001 al bloquear)
- [x] Las 2 funciones ya están en el array FUNCS de `setup_smartcset.sh`; la migración se ejecuta antes de FUNCS
- [x] Desplegado en BD local (`localhost`) y remota de laboratorio (`192.168.1.71`)

**PHP:**
- [x] `LOGIN_MAX_INTENTOS=5` y `LOGIN_VENTANA_MINUTOS=15` en `.env.example` y `.env`
- [x] Constantes en `backend/core/config.php` con `max(1, (int) EnvLoader::get(...))` (§5.4)
- [x] `$stmt_registrar_intento` (5 params) y `$stmt_verificar_bloqueo` en `backend/core/prepare_login.php` (§5.5)
- [x] Integración en `backend/routers/auth/v1/login.php`: verifica bloqueo ANTES de consultar; registra intento en los 4 caminos con su `motivo_fallo` (`usuario_no_existe`/`usuario_inactivo`/`contrasena_incorrecta`/éxito=NULL) y `user_agent`; `session_regenerate_id(true)` en el camino exitoso (heredado de E4)
- [x] Limpieza de registros >90 días: la hace `fun_registrar_intento_login` en cada inserción (no requiere cron)

**SIEM (bonus):**
- [x] `motivo_fallo` visible en el SIEM — Panel de Control (`pages/modulos/siem/index.php`,
      tabla "Alertas recientes"), vía `fun_siem_alertas_recientes`. (El submenú "Eventos Auth"
      dedicado, con `fun_siem_list_eventos`, se eliminó el 2026-07-08 por redundante — ver Bug 18
      en CLAUDE.md; el dato de auditoría se sigue mostrando, solo cambió de vista.)

**Verificación (§14.1) — suite `scripts/test_seguridad/test_e3_rate_limiting.py`, 5/5 PASS en local y remoto:**
- [x] N (=`LOGIN_MAX_INTENTOS`) intentos fallidos → el siguiente retorna mensaje de bloqueo; IP registrada en `tab_intentos_login`
- [x] Login con credenciales correctas → exitoso, registro con `ind_exitoso=TRUE` y `motivo_fallo` NULL
- [x] Motivo discriminado por rama (`usuario_no_existe`, `contrasena_incorrecta`) verificado en BD
- [x] `user_agent` capturado y registrado
- [ ] Tras la ventana de 15 min el bloqueo se levanta — verificado por diseño (la función solo cuenta intentos dentro de la ventana); no probado con espera real de 15 min
- [x] Queries de auditoría del RSSI (§5.7) ejecutan correctamente (vía `fun_siem_*`)

**Fix colateral:** se corrigió `scripts/test_seguridad/common.py` — `PROJECT_ROOT` apuntaba a `scripts/` (quedó desactualizado al mover los tests de `test_seguridad/` a `scripts/test_seguridad/`), por lo que `run_psql` no encontraba `.env`. Ahora localiza la raíz por marcador (`.env`/`CLAUDE.md`). Beneficia a todas las suites.

---

## E1 — AUDITORÍA OWASP TOP 10 (§3) — checklist inicial en semana 2, cierre en semana 4

**A01 — Broken Access Control:** ✅ Auditado, remediado y validado en producción (2026-06-10 / 2026-06-11) — ver `REPORTE_E1-A01_BROKEN_ACCESS_CONTROL_SMARTCSET.md`
- [x] Verificar guard de `ind_usuario`/admin al inicio de páginas y endpoints de administración — se encontraron 8 endpoints sin verificación de privilegio admin (`menus.php`, `usuarios.php`, `menu_usuarios.php`, `copiar_menu_usuarios.php`, `procesar_perfil.php`, `procesar_permiso.php`, `procesar_copiar_perfil.php`, `obtener_menus_usuario.php`) y se corrigieron con `usuarioEsAdministrador($pdo, $_SESSION['id_usuario'])`
- [x] Auditar IDOR en `porteria/ingreso/consultar.php` y `porteria/salida/consultar.php` (scope de datos) — ambos exigen sesión; sin scoping por centro porque el modelo actual es mono-centro (revisar si se vuelve multi-centro)
- [x] Ejecutar `grep -rL "id_usuario" backend/routers/` — los 4 archivos sin `id_usuario` son bootstraps incluidos por páginas guardadas o pertenecen al módulo `registro` (control de acceso propio `registroRequireAccess()`)
- [x] Prueba manual con BD: usuario no-admin accediendo directo a páginas/endpoints admin → 403 — ejecutadas las 11 pruebas de §6.2 contra el servidor de producción el 2026-06-11, todas **PASS** (ver §6.4 del reporte A01). Los 8 archivos corregidos quedaron desplegados en producción.
- [x] Suite automatizada `test_seguridad/test_e1_a01_broken_access_control.py` — **6/6 PASS** contra servidor `10.5.213.103` (2026-06-16)

**A02 — Cryptographic Failures:** ⚠️ Auditado (2026-06-11) — ver `REPORTE_E1-A02_CRYPTOGRAPHIC_FAILURES_SMARTCSET.md`
- [x] Contraseñas con bcrypt (`password_verify`) — verificado: todos los hashes en BD son `$2y$12$`; suite automatizada **3/3 PASS** (2026-06-16)
- [ ] Cifrado en reposo → se cierra con E2 (bloqueado: prereq. 1 y 2)
- [x] TLS BD — **ACTIVADO 2026-07-07** en `db_smartcset2` (servidor `10.5.213.103`): `pg_hba.conf` con `hostnossl ... reject` + `hostssl ... md5` acotados a `db_smartcset2` y a la subred `10.5.213.0/24` (no se tocó `0.0.0.0/0`, a pedido explícito, para no exigir TLS a otras redes/dispositivos). Verificado: conexión sin TLS desde la subred → rechazada; con TLS → aceptada; las otras 5 bases de datos del mismo servidor (`db_dinares`, `db_protego`, `db_rdwatch`, `db_specialized`, `maiconnect`) no se ven afectadas. Detalle en tabla histórica.
- [x] HTTPS forzado en producción — ✅ completado 2026-06-17, certificado regenerado 2026-07-07 (ver A05/E8)

**A03 — Injection:**
- [x] Prepared statements reales (`EMULATE_PREPARES=false`) y casting `?::TEXT` — ya verificado
- [ ] Prueba final: `'; DROP TABLE tab_personas; --` como documento en formulario de ingreso → tratado como literal

**A04 — Insecure Design:**
- [x] Separación de capas vista/lógica/datos — ya verificado
- [ ] Verificar mínimo privilegio del usuario de BD de PHP (`role_table_grants` — sin DROP/TRUNCATE en tablas de auditoría)

**A05 — Security Misconfiguration:**
- [x] Headers HTTP en todo el sistema → cerrado con E4; **2026-07-07:** unificado `X-Frame-Options` (Apache tenía `DENY` duplicando/contradiciendo el `SAMEORIGIN` de `SecurityMiddleware.php` — corregido a `SAMEORIGIN` en ambas capas)
- [x] `ErrorHandler::userMessageFromException()` no expone SQL — ya verificado
- [x] `php.ini` producción — **verificado y corregido 2026-07-07** en `10.5.213.103`: `display_errors=Off` ✅ (ya estaba), `expose_php=Off` ✅ (estaba en `On`, corregido en FPM y CLI). `log_errors` pendiente de verificar explícitamente.
- [ ] Verificar que `storage/` no ejecuta PHP → se cierra con E6

**A06 — Vulnerable and Outdated Components:**
- [ ] Verificar versión de PHP (8.1+ parcheado)
- [ ] Verificar versión de PostgreSQL (14+ parcheado)
- [ ] Revisar versiones de librerías CDN en `frontend/web/layout/head.php`

**A07 — Identification and Authentication Failures:**
- [x] Rate limiting → ✅ cerrado con E3 (2026-07-05); bloqueo por IP tras N intentos, validado por suite `test_e3_rate_limiting.py` PASS
- [x] `session_regenerate_id(true)` tras login exitoso → ✅ cerrado en E4 (2026-06-14); validado por suite (test `test_session_id_cambia_tras_login_exitoso` PASS)
- [x] Cookie flags `HttpOnly`+`SameSite=Strict` → ✅ cerrado en E4 (2026-06-14); validado por suite PASS
- [ ] Auditar robustez de `backend/routers/auth/v1/recuperar.php` (¿valida identidad solo con correo?)

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

**Prerrequisitos:** custodio de `DB_ENCRYPTION_KEY` designado (prerrequisito 1 — ✅ resuelto 2026-06-17, ver arriba) + BD de test (prerrequisito 2) + backup completo verificado. **Bloqueador de fondo aún vigente:** el alcance original de E2 (cifrar `tab_personas.documento_identidad`) es inviable porque esa columna no existe — el documento de identidad ES la PK `id_persona`, referenciada por 5+ tablas (ver hallazgo crítico 2026-06-12). Resolver la designación de custodio no implica que E2 pueda avanzar; sigue pendiente el replanteo de alcance con Anderson (opciones en handoff.txt §5.3.1).

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

## E8 — HARDENING DE RED Y ARQUITECTURA (§10) — ⚠️ parcial, resto requiere Oficina TI SENA

**Resuelto directamente (2026-07-07, sin esperar Oficina TI):**
- [x] Modificar DSN en `backend/core/Db.php`: agregar `;sslmode=<DB_SSLMODE>` vía variable de entorno (§10.3, completado 2026-06-11)
- [x] Topología confirmada: PHP/Apache y PostgreSQL corren en la **misma máquina** (`10.5.213.103`) — resuelve prerrequisito 5, no bloqueaba realmente a Oficina TI
- [x] PostgreSQL — `hostssl` en `pg_hba.conf` **activado**, acotado a `db_smartcset2` + subred `10.5.213.0/24` (no se aplicó a `0.0.0.0/0` a pedido explícito, para no exigir TLS a dispositivos fuera de esa subred). Requirió agregar también `hostnossl ... reject` ANTES de la regla `hostssl` — de lo contrario las conexiones sin TLS caían igual en la regla catch-all `host all all 0.0.0.0/0` de más abajo y NUNCA se rechazaban (lección de la sesión, ver tabla histórica). `DB_SSLMODE=require` ya estaba activo en `.env` del servidor.
- [x] `php.ini` FPM de producción: `expose_php=Off` corregido (estaba en `On`), `display_errors=Off` ya estaba correcto
- [x] Certificado TLS del servidor web — **regenerado 2026-07-07**: el script `scripts/infra/generar_certificado_smartcset.sh` generaba certificados sin SAN y con `CA:TRUE` (en vez de `CA:FALSE`) — corregido el script (agrega `subjectAltName`, `basicConstraints=CA:FALSE`, `extendedKeyUsage=serverAuth`) y regenerado el certificado en producción con backup del anterior

**Sigue requiriendo Oficina TI SENA:**
- [ ] Firewall perimetral: DENY all; ALLOW 443; 80 solo redirect; 22 solo IPs administrativas (§10.2)
- [ ] Firewall interno/host: 5432 solo desde IP del servidor web (`ufw`, §10.2) — hoy el puerto 5432 acepta conexiones de red amplias (`0.0.0.0/0`), decisión explícita de Anderson para no romper conectividad de dispositivos variados en la red segmentada del SENA
- [ ] SSH: solo clave pública, `PermitRootLogin no`, `AllowUsers` (verificar `authorized_keys` ANTES de reiniciar sshd) (§10.4)

**Verificación (§10.3-10.4 y §14.1):**
- [x] Conexión sin TLS a `db_smartcset2` desde la subred `10.5.213.0/24` → **rechazada** (`FATAL: pg_hba.conf rejects connection ... no encryption`); con TLS → **aceptada**. Probado desde 2 hosts distintos de esa subred (`.103` y `.111`).
- [x] Las otras 5 bases de datos del mismo PostgreSQL (`db_dinares`, `db_protego`, `db_rdwatch`, `db_specialized`, `maiconnect`) siguen aceptando conexiones sin TLS — confirmado que la regla no las afecta (fallan solo por password, no por cifrado)
- [x] `openssl s_client -connect 10.5.213.103:443 -servername 10.5.213.103` → certificado con SAN correcto (`DNS:smartcset.local, IP:10.5.213.103`), `CA:FALSE`, `TLS Web Server Authentication`
- [ ] `nmap -p 5432 IP_SERVIDOR_WEB` → puerto cerrado/filtrado desde el exterior (pendiente, requiere firewall — Oficina TI)

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
| 2026-06-16 | E4, E5, E6, validación servidor | **Suite `test_seguridad/` ejecutada contra servidor real `10.5.213.103`: 23/23 PASS.** Correcciones de entorno: (1) contraseña del usuario `porteria` reseteada a `Porteria2026!` en BD del servidor (había sido cambiada manualmente); (2) `frontend/web/layout/head.php` con `<script>` inline de theme-init detectado y corregido — reemplazado por `<script src="frontend/web/frontend/web/public/assets/js/theme-init.js">` + `frontend/web/frontend/web/public/assets/js/theme-init.js` desplegado al servidor. Hallazgo de infraestructura E6: Apache tiene `AllowOverride None` globalmente → `.htaccess` de uploads completamente ignorados en servidor; requiere acción de IT en VirtualHost. **E5 (tokens CSRF) descartado** por decisión del equipo: `SameSite=Strict` (activo via E4) mitiga el escenario principal; esfuerzo redirigido a E3. | feat/implementacion-MSPI-SEGURIDAD |
| 2026-06-17 | Prerrequisito 1 (custodio `DB_ENCRYPTION_KEY`) | **Custodio formal designado.** Decisión de Anderson: el custodio de `DB_ENCRYPTION_KEY` es el rol "Administrador del Sistema" (`FASE0-ROL-004` §5.1), ejercido actualmente por el equipo de desarrollo de SmartCSET dentro del SENA. Se actualizó `04_ROLES_Y_RESPONSABILIDADES_SEGURIDAD_SMARTCSET_DOCUMENTO_LEGAL.md` §5.1 (Asignación + Responsabilidades + nota de Formalización) y el prerrequisito 1 de este checklist. **No levanta** el bloqueador de fondo de E2 (rediseño de PK pendiente, hallazgo 2026-06-12) — solo resuelve la designación de custodio. | |
| 2026-06-17 (sesión 2) | E1-A02 (HTTPS), E4 (cierre) | **E1-A02 (HTTPS) COMPLETADO ✅** — Generado certificado TLS autofirmado ECDSA P-256 en `/etc/apache2/certs/`, configurado VirtualHost HTTPS en `/etc/apache2/sites-available/smartcset-ssl.conf`, agregado `enforceHTTPS()` en `index.php` líneas 11-15, corregido DocumentRoot Apache para servir desde `/var/www/html`. APP_ENV cambiado a `production` en `.env` para activar flag Secure en cookies automáticamente. Pruebas manuales en navegador exitosas: (1) certificado autofirmado mostrado y aceptado; (2) página de login cargó en HTTPS; (3) login exitoso con usuario admin.smart; (4) dashboard accesible; (5) cookie PHPSESSID verificada con flags Secure ✅, HttpOnly ✅, SameSite=Strict ✅, Max-Age=1800 ✅. Verificación con curl confirma TLS 1.3 y cipher suite TLS_AES_256_GCM_SHA384. Reporte actualizado: `REPORTE_E1-A02_CRYPTOGRAPHIC_FAILURES_SMARTCSET.md` v3.0. | |
| 2026-07-07 | E8 (parcial), E1-A02 (TLS BD), E1-A05, migración BD servidor institucional | **Migración completa de `db_smartcset2` al servidor institucional real `10.5.213.103`** (dump/restore desde `10.5.213.111`, con backup previo de los datos que ya había en 103). **Auditoría exhaustiva post-migración** encontró y corrigió: (1) vhost `smartcset-ssl.conf` con `Redirect permanent /` sin scope en el `*:80` que secuestraba el tráfico HTTP de las otras 8 apps del servidor compartido — corregido a `RedirectMatch` acotado solo a `/smartcset`, y `DocumentRoot` del `*:443` restringido exclusivamente a smartcset (certificados NO alcanzan a otras apps); (2) symlinks públicos (`pages`, `routers`) faltantes; (3) `.env` del servidor apuntaba `DB_HOST` al servidor viejo; (4) permisos de escritura faltantes en `uploads/logos`/`storage/porteria`; (5) **9 funciones PL/pgSQL con el patrón de manejo de errores roto** (Bug 6 reintroducido) — incluye `fun_ingreso_sesion`/`fun_salida_sesion` (ejecutan en cada login/logout); causa raíz: 3 migraciones (`update_fun_ingreso_sesion_cerrar_vencidas.sql`, `update_fun_salida_sesion_ip_mismatch.sql`, `fix_fun_update_tab_config_sistema.sql`) que se ejecutan DESPUÉS del archivo base en el instalador y reintroducían el patrón viejo — corregidas las 3 migraciones + las 7 funciones de `instructor/` y `fun_update_tab_pmtros_grales`, desplegado todo; (6) `expose_php=On` → `Off`; (7) `X-Frame-Options` duplicado con valores distintos (Apache `DENY` vs PHP `SAMEORIGIN`) → unificado; (8) certificado TLS generado sin SAN y con `CA:TRUE` (script de origen `scripts/infra/generar_certificado_smartcset.sh` sin `-addext`) → script corregido y certificado regenerado. **E8/TLS BD activado**: `pg_hba.conf` con `hostnossl db_smartcset2 ... reject` + `hostssl db_smartcset2 ... md5` acotados a `db_smartcset2` y a la subred `10.5.213.0/24`, sin tocar `0.0.0.0/0` (decisión explícita: la red SENA está segmentada y se requiere que cualquier dispositivo pueda conectarse). Lección técnica: una regla `hostssl` angosta es inefectiva si existe una regla `host` más amplia después en el archivo — las conexiones sin TLS simplemente caen en el catch-all; hubo que agregar `hostnossl ... reject` explícito antes. Verificado que las otras 5 bases de datos del mismo PostgreSQL no se ven afectadas. **Verificación final:** checksum idéntico entre código local y `/var/www/html/smartcset` del servidor (0 diferencias), 0 funciones con patrón de error roto en la BD, login/logout/SIEM/portería/instructor funcionando end-to-end, las 8 apps del servidor compartido intactas. | |

---

*Fin del documento — Checklist de Implementación Fase 1 — SmartCSET FASE1-CHK-002 v1.0*
