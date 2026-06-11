# CHECKLIST DE IMPLEMENTACIÓN — FASE 1 BLINDAJE TÉCNICO INMEDIATO
## Sistema SmartCSET — Servicio Nacional de Aprendizaje (SENA)

---

| Campo | Valor |
|---|---|
| **Documento N°** | FASE1-CHK-002 |
| **Versión** | 1.0 |
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
| E10 — SDLC seguro (adopción) | 🟠 | 🔲 Pendiente | 0% |
| E7 — Corrección setup_smartcset.sh | 🟠 | ⚠️ Parcial (schema y migraciones ya corregidos; faltan 4 funciones en FUNCS) | ~60% |
| E4 — Hardening de sesiones PHP | 🔴 | 🔲 Pendiente (SecurityMiddleware existe pero es código muerto) | 0% |
| E6 — Verificación de uploads | 🟡 | ⚠️ Código PHP ya correcto; falta verificación de servidor + .htaccess | ~70% |
| E5 — Tokens anti-CSRF | 🔴 | 🔲 Pendiente | 0% |
| E3 — Rate limiting + logging de autenticación | 🔴 | 🔲 Pendiente | 0% |
| E1 — Auditoría OWASP Top 10 | 🔴 | ⚠️ Parcial (A01 remediado; A02 auditado con 1/3 hallazgos preparados en código; A03-A10 pendientes) | ~20% |
| E2 — Cifrado en reposo (pgcrypto) | 🔴 | 🔲 Pendiente | 0% |
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

## E10 — SDLC SEGURO: CHECKLIST DE CÓDIGO Y DESPLIEGUE (§12) — Día 0, sin código

- [ ] Leer y adoptar el checklist pre-commit (§12.2) como práctica desde el primer commit de la Fase 1
- [ ] Leer y adoptar el checklist pre-deploy (§12.3)
- [ ] Conocer el procedimiento de rollback de emergencia (§12.4)
- [ ] Adoptar las 6 prohibiciones absolutas (§12.5): no editar en producción, no hardcodear credenciales, no `$_POST` en SQL directo, no `var_dump` en producción, no desactivar prepared statements reales, no `push --force` a main

**Verificación (§14.1):**
- [ ] Último commit revisado contra el checklist pre-commit: 0 hallazgos críticos
- [ ] `git status` en el servidor de producción muestra árbol limpio (sin ediciones directas)

---

## E7 — CORRECCIÓN DE setup_smartcset.sh (§9) — riesgo cero

**Ya corregido (verificado 2026-06-08/10):**
- [x] Bug 1 — Script apunta a schema V.1.7 (antes V.1.5)
- [x] Bug 2a/2b/2c — `fun_trigger_menu.sql`, `fun_trigger_menu_admin.sql`, `fun_delete_perfil_usuarios.sql` ya en FUNCS
- [x] Bug 3 — Las 3 migraciones críticas ya están en el script

**Pendiente — agregar al array FUNCS (§9.2):**
- [ ] `database/functions/acceso/usuarios/fun_validar_correo.sql` (tras `fun_actualizar_password.sql`) — sin ella la recuperación de contraseña falla en instalación limpia
- [ ] `database/functions/acceso/usuarios/fun_validar_login.sql`
- [ ] `database/functions/acceso/usuarios/fun_validar_usuario.sql`
- [ ] `database/functions/acceso/menus/fun_tab_menu_usuarios.sql` (tras `fun_insert_menu_usuarios.sql`)

**Verificación (§9.3 y §14.1):**
- [ ] Ejecutar `setup_smartcset.sh` contra BD de test (`db_smartcset_test`) sin errores
- [ ] `\df fun_*` muestra las 4 funciones desplegadas
- [ ] Flujo de `src/auth/recuperar.php` contra BD de test funciona sin error 500
- [ ] Restaurar `DB_NAME` en `.env` tras la prueba

---

## E4 — HARDENING DE SESIONES PHP (§6)

- [ ] Agregar `require_once __DIR__ . '/SecurityMiddleware.php';` + `SecurityMiddleware::initialize();` al inicio de `src/core/prepare.php`
- [ ] Eliminar `session_start()` de `index.php` (initialize() ya lo hace)
- [ ] Eliminar los 4 headers hardcodeados de `index.php` (setSecurityHeaders() los reemplaza con la versión completa)
- [ ] Verificar que ningún otro archivo llama `session_start()` antes de prepare.php
- [ ] Descomentar/activar el bloque de redirección HTTPS para producción en `index.php` (condicionado a `APP_ENV === 'production'`)
- [ ] Verificar `php.ini` de producción: `session.gc_maxlifetime=1800`, `display_errors=Off`, `log_errors=On`, `expose_php=Off`

**Verificación (§6.5 y §14.1):**
- [ ] Cookie de sesión con `HttpOnly`, `SameSite=Strict` (y `Secure` en producción con HTTPS) — DevTools → Application → Cookies
- [ ] `PHPSESSID` cambia tras login exitoso (anti session fixation) — nota: el `session_regenerate_id(true)` se inserta en el flujo de login junto con E3
- [ ] Headers de seguridad presentes en TODAS las páginas del sistema, no solo en el login
- [ ] Login/logout completo funciona sin regresión

---

## E6 — VERIFICACIÓN DE SUBIDA DE ARCHIVOS (§8)

**Ya implementado correctamente (auditado 2026-06-08):**
- [x] `src/core/LogoUpload.php` — finfo MIME real, whitelist, límite 5MB, `is_uploaded_file()`, nombre aleatorio, permisos 0644
- [x] `src/modulos/porteria/lib/porteria_foto.php` — base64 estricto, regex de data URL, recompresión JPEG que destruye payloads

**Pendiente:**
- [ ] Crear `.htaccess` en `public/uploads/logos/` que bloquee ejecución de PHP/scripts y fuerce Content-Type de imagen (§8.3) — o equivalente Nginx vía Oficina TI
- [ ] Crear `.htaccess` en `storage/porteria/` con el mismo contenido
- [ ] Confirmar tipo de servidor (Apache/Nginx) con Oficina TI (prerrequisito 3)

**Verificación (§8.2 y §14.1):**
- [ ] `curl https://host/storage/porteria/test.php` → 403/404, nunca ejecuta PHP
- [ ] Mismo test en `public/uploads/logos/`
- [ ] Intento de subir `.php` como logo → rechazado por validación MIME

---

## E5 — TOKENS ANTI-CSRF EN FORMULARIOS (§7) — requiere E4 activo

**Infraestructura:**
- [ ] Agregar helper `validarCSRFoAbortar()` a `src/core/helpers.php` (§7.4): 403 + `error_log` + flash + redirect
- [ ] Decidir punto de generación del token: por formulario o una vez en `src/layout/head.php` (§7.3)

**Campo oculto `csrf_token` en cada formulario + validación en su procesador (§7.2):**
- [ ] `index.php` (login — se auto-procesa) — 🔴 Alta
- [ ] `src/auth/cambiar_clave.php` — 🔴 Alta
- [ ] `src/auth/recuperar.php` — 🔴 Alta
- [ ] `src/usuarios/usuarios.php` + su(s) procesador(es) — 🔴 Alta
- [ ] `src/menu/menus.php` → `procesar_perfil.php` — 🟠
- [ ] `src/menu/` → `procesar_permiso.php` — 🟠
- [ ] `src/menu/` → `procesar_copiar_perfil.php` — 🟠
- [ ] `src/admin/configuracion.php` — 🟠
- [ ] `src/modulos/porteria/ingreso/index.php` → `procesar.php` — 🟠
- [ ] `src/modulos/porteria/salida/index.php` → `procesar.php` — 🟠
- [ ] `src/modulos/registro/forms/aprendiz.php` — 🟠
- [ ] `src/modulos/registro/forms/instructor.php` — 🟠
- [ ] `src/modulos/registro/forms/funcionario.php` — 🟠
- [ ] `src/modulos/registro/forms/contratista.php` — 🟠
- [ ] `src/modulos/registro/forms/persona.php` — 🟠

**Verificación (§7.6 y §14.1):**
- [ ] `curl -X POST` sin token a un procesador → 403 o redirect con flash de sesión expirada
- [ ] Cada formulario probado manualmente con token válido → procesa correctamente

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

**A02 — Cryptographic Failures:** ⚠️ Auditado (2026-06-11) — ver `REPORTE_E1-A02_CRYPTOGRAPHIC_FAILURES_SMARTCSET.md`
- [x] Contraseñas con bcrypt (`password_verify`) — ya verificado
- [ ] Cifrado en reposo → se cierra con E2 (bloqueado: prereq. 1 y 2)
- [x] TLS BD — infraestructura de código (`DB_SSLMODE` en `config.php`/`Db.php`) lista (2026-06-11); activación → se cierra con E8 (bloqueado: Oficina TI)
- [ ] HTTPS forzado en producción → se cierra con E4 (bloqueado: prereq. 6)

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
- [ ] Rate limiting → se cierra con E3
- [ ] `session_regenerate_id` → se cierra con E3/E4
- [ ] Cookie flags → se cierra con E4
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

---

*Fin del documento — Checklist de Implementación Fase 1 — SmartCSET FASE1-CHK-002 v1.0*
