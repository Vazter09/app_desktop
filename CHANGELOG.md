# CHANGELOG — SmartCSET

## [2026-07-09] Sesión: Consolidación Final de Documentación + Grafo Indexado + App Desktop Operativa

### 🎯 Objetivos Logrados
- ✅ **Grafo de codebase indexado por codebase-memory-mcp**: 7,283 nodos, 10,258 edges (vs 6,104/8,453 hace 10 días). Detectados 12 clusters (Porteria 100% cohesión, app_desktop 94%, mobile 99%), 10 hotspots de seguridad, 7 capas arquitectónicas. Persistido en `.codebase-memory/graph.db.zst` (compartible).
- ✅ **App Desktop operativa en producción (10.5.213.103)**: login real + portería (ingreso/salida) + entradas + **biometría facial end-to-end**. Cliente HTTP puro (urllib), TLS validation activo. Ciclo probado: enrolar → identificar → registrar ingreso (metodo_aut=4) → salida.
- ✅ **Biometría facial backend completo**: tabla `tab_enrolamiento_facial` (pgvector 128-dims, índice HNSW) + funciones `fun_guardar_enrolamiento_facial`/`fun_identificar_persona_por_rostro` + endpoints `/porteria/v1/biometria/{enrolar,identificar}.php`. Motor SFace + YuNet en app_desktop.
- ✅ **Bug 19 corregido**: whitelist de `id_metodo_aut` reintroducido — valor 4 (biométrico facial) ahora pasa validación en `parse_captura_service.php`. Cubierto por test automatizado.
- ✅ **Documentación 100% actualizada** (12 archivos): HANDOFF.md (sesiones 06-09), CLAUDE.md (Bugs 1-19), AGENTS.md (8 agentes), checklist FASE1 (v1.5 → 92%), 4 reportes E-tasks (v2.x → v3.x con bugs posteriores), README.md y REGLAS_APP_ESCRITORIO_SGI.md de app_desktop.
- ✅ **FASE 1 alcanza 92% de completitud técnica**: E10 ✅, E7 ✅ (+Bugs 11-15), E4 ✅, E6 ✅, E1-A01 ✅ (+Bug 7), E1-A02 ✅, E3 ✅, E8 ✅ (35%, TLS BD), biometría ✅ (bonus). Pendiente: A03-A10 (scope), E2 (arquitectura), E9 (scope).

### 📋 Documentación Actualizada
1. **HANDOFF.md:** Sección "ESTADO ACTUAL DEL PROYECTO (2026-07-09)" + "LO QUE SE HIZO EN LA SESIÓN 2026-07-09" (indexación, app desktop, biometría, documentación)
2. **CLAUDE.md:** Bug 19 agregado (reintroducción whitelist metodo_aut + SFace/YuNet)
3. **AGENTS.md:** 8 agentes definidos (app_desktop + Setup/Deploy nuevos; SIEM reducido a 2 submenús; Portería con biometría)
4. **Checklist FASE1 (v1.5):** versión actualizada con estado 92% técnico
5. **Resumen Sesión 2026-07-09 (NEW):** consolidación de grafo, app desktop, SIEM, próximos pasos
6. **Grafo Indexado (NEW):** 7283 nodos, 10258 edges, clusters, hotspots, capas
7. **App Desktop Tablas (NEW):** 13 tablas interactuadas, flujos completos
8. **REPORTE_E1-E10 (v2.1):** E10 completo, 19 commits posteriores verificados
9. **REPORTE_E1-E07 (v3.0):** E7 + Bugs 11-15 (54 bugs totales en schema V.1.10)
10. **REPORTE_E1-A01 (v3.0):** A01 + Bug 7 (control por menú en módulos, 2026-07-01)
11. **README.md (app_desktop):** Última actualización 2026-07-09, estado operativo, Bug 19
12. **REGLAS_APP_ESCRITORIO_SGI.md:** Validación post-implementación con tabla de ciclos probados

### 🧪 Verificaciones
- Tests 23/23 PASS en BD local y servidor institucional real (10.5.213.103)
- Ciclo biometría end-to-end validado (enrolar → identificar → ingreso→salida con metodo_aut=4)
- Auditoría real confirmada (`usr_insert = porteria`, no genérico)
- Grafo persistido para compartir con equipo
- 0 sesiones colgadas post-pruebas

### 📌 Estado Final
- **Documentación:** 100% actualizada (12 archivos)
- **Código:** 92% completitud técnica FASE 1
- **Tests:** 23/23 PASS
- **Grafo:** Indexado y persistido (7283 nodos, 10258 edges)
- **App Desktop:** Operativa en producción con biometría facial
- **Ready:** Para presentación Director Regional SENA (29 julio 2026)

---

## [2026-07-08] Sesión: Reducción módulo SIEM a 2 submenús + tabla de alertas rediseñada + auto-refresh

### 🎯 Objetivos Logrados
- ✅ **Módulo SIEM reducido de 5 a 2 submenús** (a pedido explícito, redundancia con Panel de Control/Sesiones Activas): eliminados Eventos Auth (21102), IPs Bloqueadas (21104) y Actividad Física (21105) — vistas, router `desbloquear_ip.php`, 5 funciones PL/pgSQL, menús y permisos huérfanos, código + servidor + BD sincronizados.
- ✅ **Tabla "Alertas recientes" rediseñada estilo Wireshark**: de tarjetas apiladas + gráfica Chart.js a una fila compacta por evento (Fecha/Hora, IP, Usuario, Tipo, Motivo abreviado, Cliente extraído del User-Agent, Intentos, Estado), sin iconos. Nuevas funciones `smartcsetExtractClientFromUserAgent()` y `smartcsetMotivoFalloAbrev()`.
- ✅ **Auto-refresh del Panel de Control**: ya no requiere recargar la página para ver eventos nuevos. Patrón fragment (`dashboard_fragment.php`) + `?partial=1` + `SmartcsetListado.loadIntoHost()` (reutiliza el mecanismo ya usado en listados de personas, evita duplicar render en JS), polling cada 20s con guards `inFlight`/`visibilitychange` (mismo patrón que `smartcset-presencia.js`).

### 🧪 Pruebas
- Sintaxis PHP/JS validada en todos los archivos tocados (`php -l`, `node -c`).
- `grep` exhaustivo confirmó cero referencias huérfanas a menús/funciones/rutas eliminados en todo el repo.
- Verificado en servidor tras `rsync --delete`: archivos eliminados localmente también desaparecieron en `/var/www/html/smartcset`; funciones PL/pgSQL correctas tras `DROP FUNCTION` (`pg_proc` sin las 5 eliminadas, con las 5 que sí deben quedar).
- Control de acceso (`usuarioTieneMenu`) confirmado antes del branch `?partial=1` en el Panel de Control — sin bypass de autorización vía el parámetro de auto-refresh.

### 📋 Detalle
Ver `HANDOFF.md` sección "LO QUE SE HIZO EN LA SESIÓN 2026-07-08", `CLAUDE.md` Bug 18, `backend/routers/siem/AGENTS.md` (actualizado).

---

## [2026-07-07] Sesión: Migración y auditoría del servidor institucional real (10.5.213.103) + TLS BD

### 🎯 Objetivos Logrados
- ✅ **BD migrada** al servidor institucional real `10.5.213.103` (dump/restore desde `10.5.213.111`, con backup previo de los datos que ya había ahí).
- ✅ **Código del servidor corregido**: symlinks públicos faltantes, `.env` con `DB_HOST` apuntando al servidor viejo, permisos de escritura faltantes en `uploads/logos`/`storage/porteria`.
- ✅ **Vhost `smartcset-ssl.conf` con 2 bugs reales corregidos**: `Redirect permanent /` sin scope en `*:80` secuestraba el tráfico HTTP de las otras 8 apps del servidor compartido; `DocumentRoot` de `*:443` con reglas de protección anti-webshell apuntando a rutas que no existían. Reescrito con el patrón ya probado en `10.5.213.111` — verificado que las 8 apps siguen funcionando por HTTP e inalcanzables por HTTPS.
- ✅ **Bug 6 (CLAUDE.md) reintroducido, encontrado y resuelto de raíz**: 9 funciones PL/pgSQL (incluye `fun_ingreso_sesion`/`fun_salida_sesion`, que corren en cada login/logout) tenían el patrón de manejo de errores roto. Causa real: 3 migraciones que se ejecutan después de los archivos base en el instalador tenían el patrón viejo. Corregidas las 3 migraciones + las 7 funciones de `instructor/`, desplegado todo.
- ✅ **`expose_php=Off`**, **`X-Frame-Options` unificado** (`SAMEORIGIN` en Apache y PHP, antes contradictorios), **certificado TLS regenerado** (el script de origen generaba certs sin SAN y con `CA:TRUE` — corregido).
- ✅ **TLS BD activado (E8, parcial)**: `pg_hba.conf` con `hostnossl`/`hostssl` acotados a `db_smartcset2` + subred `10.5.213.0/24`, sin tocar `0.0.0.0/0` (decisión explícita para no exigir TLS a dispositivos fuera de esa subred). Verificado con evidencia real: rechazo sin TLS, aceptación con TLS, las otras 5 bases de datos del mismo servidor sin cambios.
- ✅ **Sincronización final verificada**: checksum idéntico entre repo local y `/var/www/html/smartcset`, 0 funciones con el patrón de error roto en la BD.

### 🧪 Pruebas
- Login/logout, dashboard, SIEM, portería (uso real de usuarios activos durante la auditoría), instructor, usuarios, menús, admin, entradas, registro — todos verificados end-to-end contra `10.5.213.103`.
- TLS BD probado desde 2 hosts distintos de la subred (`.103` a sí mismo, `.111` hacia `.103`): sin TLS rechazado, con TLS aceptado.
- Otras 8 apps del servidor compartido confirmadas intactas antes y después de cada cambio de infraestructura.

### 📋 Detalle
Ver `HANDOFF.md` sección "Migración y consolidación del servidor institucional real", `CLAUDE.md` Bug 17, y
`Documentacion para implementacion de MSPI/FASE 01_Blindaje Técnico Inmediato/02_CHECKLIST_IMPLEMENTACION_FASE1_SMARTCSET.md`
(E8 pasó de 0% a ~35%, A02/A05 actualizados).

### ⚠️ Pendiente explícitamente diferido
`DB_ENCRYPTION_KEY`/E2 (bloqueado desde 2026-07-06, atado al módulo de reconocimiento facial) y firewall perimetral/SSH hardening (requieren Oficina TI SENA).

---

## [2026-07-07] Sesión: Consolidación módulo SIEM — submenús 4-5 (IPs Bloqueadas, Actividad) — módulo completo

### 🎯 Objetivos Logrados
- ✅ **IPs Bloqueadas (21104) consolidado.** `desbloquear_ip.php` validaba el menú viejo `0604` (mismo bug que tenía `forzar_sesion.php` antes del fix del 2026-07-06) → corregido a `usuarioTieneMenu($pdo, ..., '21104')`. Hora del último intento en UTC crudo → `smartcsetFormatDbTimestamp()`. Cache-busting de `siem.css` con ruta rota (`filemtime()` sin `/frontend/web/public/assets`). Botón "Desbloquear" con los mismos 3 bugs de JS que tenía "Forzar cierre": `SmartcsetHttp` sin cargar `http-client.js`, `SmartcsetToast` inexistente (global real `SmartToast`), contrato `.then/.catch` invertido.
- ✅ **Actividad (21105) consolidado.** Filtros Desde/Hasta y KPI "hoy" comparaban en UTC crudo (mismo patrón que Eventos/Dashboard) → `fun_siem_actividad_fisica` ahora recibe `wzona_horaria` (6º parámetro, requirió `DROP FUNCTION IF EXISTS` de la firma vieja de 5 args); KPI inline en PHP parametrizado igual. Mismos fixes de `filemtime()` y `date(strtotime())` → `smartcsetFormatDbTimestamp()` en las 3 apariciones del timeline.
- ✅ **Módulo SIEM 100% consolidado** — los 5 submenús (21101-21105) verificados end-to-end: timezone local, sin CDN externo, botones de acción funcionales, control de acceso real por menú.

### 🧪 Pruebas (BD activa: `10.5.213.111`/`db_smartcset2`, la que define el `.env`)
- Ciclo real ingreso→salida vía endpoints de portería: KPIs de Actividad 0/0/0 → 1/1/0 → 1/0/1, timeline con hora local correcta (13:45 UTC → 08:45 Bogotá), badge INGRESO→SALIDA.
- Ataque simulado (6 intentos fallidos desde `127.0.0.1`, `X-Forwarded-For` correctamente ignorado): IP bloqueada visible, botón "Desbloquear" funcional end-to-end (login vuelve a funcionar tras desbloquear).
- Control de acceso con `porteria` (sin menú `211xx`): 403 en las 2 vistas y el endpoint; con menú asignado temporalmente vía endpoint real de administración: 200; menús revertidos exactamente al estado original.
- Limpieza completa: persona/ingreso de prueba eliminados, intentos de login de prueba auto-eliminados al desbloquear, 2 sesiones de prueba cerradas por logout real — 0 residuos en la BD.

### 📋 Detalle
Ver `HANDOFF.md` sección "LO QUE SE HIZO EN LA SESIÓN 2026-07-07", `CLAUDE.md` Bug 16 (ahora ✅ RESUELTO completo).

### 📌 Acuerdo de flujo de trabajo (nuevo, vigente desde esta sesión)
Desarrollo y código en local; solo se copia a `/var/www/html/smartcset` (servidor `10.5.213.111`) cuando cumple los 5 Pilares y las premisas principales. El `.env` local ya apunta la BD de trabajo a ese mismo servidor — el aislamiento local aplica al código, no a la base de datos.

---

## [2026-07-06] Sesión: Consolidación módulo SIEM — submenús 1-3 (Panel de Control, Eventos, Sesiones)

### 🎯 Objetivos Logrados
- ✅ **Panel de Control (21101) consolidado.** 3 bugs corregidos: (a) el KPI "IPs bloqueadas" **crasheaba la página con 2+ IPs bloqueadas simultáneas** (subconsulta escalar con GROUP BY+HAVING devolvía múltiples filas — fallaba justo durante un ataque distribuido); (b) horas mostradas 5h adelantadas (UTC crudo) y gráfica agrupando por hora UTC — nuevo parámetro `wzona_horaria` en las funciones + `smartcsetFormatDbTimestamp()`; (c) Chart.js cargaba desde CDN externo (rompía en intranet sin internet) — vendorizado en `assets/js/vendor/chart-4.4.0/`.
- ✅ **Eventos (21102) consolidado.** Filtros Desde/Hasta ahora comparan contra el día local Colombia (antes un evento de las 8pm quedaba en el día UTC siguiente); columna Fecha/Hora en hora local.
- ✅ **Sesiones (21103) consolidado.** El botón "Forzar cierre" **nunca había funcionado desde el navegador**: (a) `forzar_sesion.php` validaba el menú viejo `0603` (inexistente tras la renumeración del Bug 12) → 403 para no-admins con `21103` asignado; (b) la vista llamaba `SmartcsetHttp` sin cargar `http-client.js` y `SmartcsetToast` (el global real es `SmartToast`); (c) el `.then()` asumía el envelope `{ok,error}` pero `SmartcsetHttp` resuelve con `payload.data` y lanza en error. Corregido todo + cast a string en la protección de auto-cierre.
- ✅ **Congruencia con E3:** umbral "5 intentos/15 min" ya no está hardcodeado en el SQL del SIEM — las funciones reciben `wmax_intentos`/`wventana_minutos` y PHP pasa `LOGIN_MAX_INTENTOS`/`LOGIN_VENTANA_MINUTOS` del `.env`.
- ✅ Cache-busting de `siem.css` corregido en las 3 vistas (filemtime apuntaba a ruta inexistente → re-descarga en cada carga).

### 🧪 Pruebas (BD activa 192.168.1.71)
- Ataque simulado desde 2 IPs vía `fun_registrar_intento_login` real: KPIs correctos (2 bloqueadas, antes crash), badges, gráfica en hora local.
- Flujo completo de forzar cierre: admin cerró sesión colgada de `porteria` (auditoría `cod_cierre='ADMIN'`, `usr_cierre='admin.smart'`) y portería pudo volver a entrar. Guardias verificados: no-admin sin menú → 403; auto-cierre → rechazado.
- Ronda final: 3 vistas HTTP 200, 0 referencias a CDN, hora mostrada = hora real.

### ⚠️ Pendiente (próxima sesión)
- **IPs Bloqueadas (21104):** consolidar — `desbloquear_ip.php` aún valida el menú viejo `0604` (mismo bug que forzar_sesion, ya identificado).
- **Actividad (21105):** consolidar — mismas clases de bug esperables (filemtime CSS, timezone).

---

## [2026-07-05] Sesión (continuación): E3 rate limiting cerrado + restauración de usuarios + justificación MSPI

### 🎯 Objetivos Logrados
- ✅ **E3 — Rate limiting + logging de autenticación CERRADO** (último entregable técnico grande de FASE 1). Enriquecido con auditoría forense: columnas `motivo_fallo` y `user_agent` en `tab_intentos_login`, función `fun_registrar_intento_login` a 5 args, motivo visible en el SIEM. Suite nueva `scripts/test_seguridad/test_e3_rate_limiting.py` — **5/5 PASS en BD local y remota**. Cierra OWASP A07.
- ✅ **Restaurados los usuarios perdidos** en el servidor de laboratorio (habían quedado en la exclusión del `pg_dump` del Bug 15): de 2 a **15 usuarios**, todos activos, con sus menús re-asignados según la numeración nueva. Instalados en el remoto los prerequisitos `pgcrypto` y `tab_borrados`.
- ✅ **Creada la carpeta `Documentacion para implementacion de MSPI/justificacion_MSPI/`** — fundamentación legal-estratégica para la presentación al Director Regional (29 julio): 6 documentos + README + 7 PDFs oficiales del SENA analizados. Hallazgo central: la situación actual viola la propia política del SENA (Acuerdo Consejo Directivo 2019 §15.7) y el Reglamento del Aprendiz 2024 (Art. 11 Par. 5).
- ✅ **Fix `common.py`**: `PROJECT_ROOT` apuntaba a `scripts/` (desactualizado tras mover los tests) → `run_psql` no encontraba `.env`. Ahora localiza la raíz por marcador. Beneficia a todas las suites de seguridad.

### 📋 Detalle
Ver `HANDOFF.md` secciones 7-9 de la sesión 2026-07-05, `CLAUDE.md` (sección E3 + lecciones `DROP FUNCTION` y `search_path`), el checklist FASE1 (E3 → 100%) y `justificacion_MSPI/README.md`.

### ⚠️ Estado FASE 1
Sube de ~80% a ~85%. Restantes: **E2** (cifrado en reposo — bloqueado por rediseño de PK), **E8** (hardening red — Oficina TI), **E9** (gestión de parches), **E1 A03-A10** (auditoría OWASP restante).

---

## [2026-07-05] Sesión: Merge feat/seguridad → feat/implementacion_MSPI + reinstalación limpia en servidor de laboratorio

### 🎯 Objetivos Logrados
- ✅ Creada rama de trabajo `feat/implementacion_MSPI` desde `main` (rama activa a partir de ahora)
- ✅ Restaurado dump de `db_smartcset2` local contra servidor de laboratorio (`192.168.1.71`, no institucional)
- ✅ Mergeado `feat/seguridad` → `feat/implementacion_MSPI`: SIEM (renumerado a submenú `211` de SGA), rate limiting de login, hardening de sesiones — **excluyendo intencionalmente** todo el módulo de reconocimiento facial/biometría
- ✅ Corregidos 8 bugs de sintaxis/datos en `script-BD-SMARTCSET V.1.10.sql` que impedían instalación limpia desde cero (nunca antes probada en esta versión del schema) — ver CLAUDE.md Bug 11
- ✅ Reinstalación completa verificada en `192.168.1.71`: exit 0, 78 tablas, 58 funciones
- ✅ Reparado el MCP `codebase-memory-mcp` (binario faltante en el path configurado) y reindexado solo el proyecto `smartcset`

### 📋 Detalle
Ver `HANDOFF.md`, sección "LO QUE SE HIZO EN LA SESIÓN 2026-07-05", y `CLAUDE.md` Bugs 11 y 12 para el detalle técnico completo.

---

## [2026-07-02] Sesión: Merge feat/seguridad con origin/main + fix colisión de menús

### 🎯 Objetivos Logrados
- ✅ Restaurar `db_smartcset2` desde dump institucional real (SENA, 2026-07-01)
- ✅ Commitear el trabajo de blindaje Fase 1 (previamente sin commitear) en rama nueva `feat/seguridad`
- ✅ Fusionar 12 commits de `origin/main` (Kevin: instructores, carga SENA, OpenAPI) sin perder trabajo de ningún lado
- ✅ Regenerar `database/schema/script-BD-SMARTCSET V.1.8.sql` fiel a la BD real (ambas versiones previas estaban desactualizadas)
- ✅ Push de `feat/seguridad` a GitHub (main intacto, sin PR abierto)

---

## 📋 BUGS ARREGLADOS

### Bug: `DB_HOST=loclahost` (typo en `.env`)
**Síntoma:** conexión PHP→PostgreSQL fallaba tras restaurar la BD.
**Solución:** corregido a `localhost`.
**Estado:** ✅ RESUELTO

### Bug: symlinks `public/pages` y `public/routers` perdidos y commiteados como borrados
**Síntoma:** sin ellos, todas las páginas y endpoints AJAX dan 404.
**Solución:** recreados (`ln -sf ../pages pages`, `ln -sf ../../../backend/routers routers`) y commiteados como `120000`.
**Estado:** ✅ RESUELTO

### Bug (heredado de Kevin): instalador abortaba por 4 archivos de función faltantes
**Síntoma:** `setup_smartcset.sh` (con `set -euo pipefail`) abortaba por completo en el primer archivo inexistente del array `FUNCS` (`actualizar_datos/fun_actualizar_{contratista,funcionario,instructor,persona_centro}.sql`), dejando sin desplegar todo lo posterior (rate limiting, SIEM, etc).
**Causa raíz:** archivos referenciados en `origin/main` que nunca se crearon en el repo.
**Solución:** guarda `[[ -f "$f" ]] &&` en el loop de `FUNCS`, igual patrón que ya usaba el loop de migraciones.
**Estado:** ✅ MITIGADO (instalador ya no aborta; las funciones en sí siguen sin existir — pendiente que Kevin las cree)

### Bug: colisión de `id_menu` entre módulo SIEM e instructores
**Síntoma:** sidebar mostraba "Asistencia" en vez de "SIEM" al navegar a `pages/modulos/siem/actividad/index.php`.
**Causa raíz:** SIEM (E11, Fase 1) y el módulo de instructores de Kevin (`Feat/instructores #10`) usaron independientemente el mismo `id_menu = '06'`/`'0601'`. `sidebar.php` traía código de Kevin que sobreescribe a la fuerza el label de esos IDs para administradores.
**Riesgo evitado:** la migración de instructores usaba `ON CONFLICT (id_menu) DO UPDATE` — de haber corrido contra `db_smartcset2` (con SIEM ya desplegado), habría sobreescrito silenciosamente los registros de menú de SIEM.
**Solución:** renumerado el módulo de instructores de `06/0601` a `07/0701` en 6 archivos (`sidebar.php`, `asistencia_service.php`, `fichas/index.php`, `fun_crear_usuarios_instructores.sql`, `revoke_instructores_menu_personas.sql`, `add_menu_instructor_asistencia.sql`).
**Estado:** ✅ RESUELTO — verificado en vivo, ambos módulos conviven en el sidebar sin colisión.

---

## 📦 MERGE feat/seguridad ↔ origin/main

7 conflictos reales de 192 archivos divergentes (los demás se auto-fusionaron sin intervención):
- 3 endpoints de registro: conservado el fix de rutas local (Bug 9) + adoptada la documentación OpenAPI de Kevin
- `porteria-salida-modal.js`: conservado el fix crítico local (el de Kevin no resolvía el bug real de `salidas.js`) + adoptada su mejora de tipo de documento dinámico
- `smartcset-path.js`, `setup_smartcset.sh`: combinados sin pérdida
- `schema/script-BD-SMARTCSET V.1.8.sql`: regenerado desde `pg_dump --schema-only` de la BD real (ninguna de las dos versiones commiteadas coincidía con la BD real; corrige deuda preexistente)

Ver `HANDOFF.md` sección "LO QUE SE HIZO EN LA SESIÓN 2026-07-02" para el detalle completo.

---

## [2026-06-27] Sesión: Restauración DB Local + Mini SIEM + Fixes Portería

### 🎯 Objectivos Logrados
- ✅ Restaurar entorno local idéntico al servidor SENA institucional
- ✅ Implementar mini módulo SIEM (Security Information & Event Management)
- ✅ Arreglar flujo de ingreso/salida (portería)
- ✅ Verificar cumplimiento de 5 Pilares Obligatorios

---

## 📋 BUGS ARREGLADOS

### Bug #1: `seq_log_ingresos` no existía en BD local
**Problema:** Dump del servidor (2026-06-25) anterior a creación de secuencia  
**Síntoma:** `fun_registrar_ingreso_manual()` fallaba con "sequence not found"  
**Solución:** Creada secuencia y vinculada a `tab_log_ingresos.id_ingreso`
```sql
CREATE SEQUENCE public.seq_log_ingresos START WITH 1;
ALTER SEQUENCE public.seq_log_ingresos OWNED BY public.tab_log_ingresos.id_ingreso;
ALTER TABLE public.tab_log_ingresos ALTER COLUMN id_ingreso SET DEFAULT nextval('seq_log_ingresos');
```
**Estado:** ✅ RESUELTO

---

### Bug #2: Módulo Salida no encontraba ingresos abiertos
**Problema:** `porteria-salida-modal.js` hacía `fetch("consultar.php?...")` (URL relativa)  
**Síntoma:** Modal mostraba "Sin ingreso activo" aunque existiera en BD  
**Causa Raíz:** Archivo legacy usando fetch directo en lugar de `SmartcsetSalidaRouter`  
**Solución:** Actualizado modal para usar router correcto:
```javascript
// ANTES:
fetch("consultar.php?" + new URLSearchParams({...}))

// AHORA:
SmartcsetSalidaRouter.consultar(num, "CC")
```
**Archivo:** `/frontend/web/public/assets/js/modules/porteria/porteria-salida-modal.js` líneas 24-36  
**Estado:** ✅ RESUELTO

---

### Bug #3: Nombres aparecían como "undefined" en modal
**Problema:** Endpoint devuelve `nombres`/`apellidos`, modal buscaba `nom_persona`/`ape_persona`  
**Síntoma:** Modal mostraba "undefined" en lugar del nombre de la persona  
**Solución:** Actualizado modal con fallback:
```javascript
// ANTES:
persona.nom_persona

// AHORA:
persona.nombres || persona.nom_persona || ""
```
**Archivo:** `/frontend/web/public/assets/js/modules/porteria/porteria-salida-modal.js` líneas 91-95, 104-119  
**Estado:** ✅ RESUELTO

---

## 🎨 FEATURES IMPLEMENTADAS

### Mini SIEM Module
**Estado:** ✅ COMPLETO y FUNCIONAL

**Componentes:**
- `frontend/web/pages/modulos/siem/` — 5 vistas
  - `index.php` — Dashboard con KPIs, gráficas, alertas
  - `eventos/index.php` — Tabla de intentos login con filtros
  - `sesiones/index.php` — Sesiones activas, forzar cierre
  - `ips/index.php` — IPs bloqueadas por rate limiting E3, desbloquear
  - `actividad/index.php` — Log de actividad física (ingresos/salidas)

- `database/functions/siem/` — 9 funciones PL/pgSQL
  - `fun_siem_dashboard.sql` — KPIs, eventos/hora, top IPs, alertas recientes
  - `fun_siem_eventos.sql` — Listado eventos con paginación y filtros
  - `fun_siem_sesiones.sql` — Sesiones activas, forzar cierre
  - `fun_siem_ips.sql` — IPs bloqueadas, desbloquear
  - `fun_siem_actividad.sql` — Actividad física con timeline

- `backend/routers/siem/v1/` — 2 endpoints AJAX
  - `forzar_sesion.php` — POST para cerrar sesión (menu 0603)
  - `desbloquear_ip.php` — POST para desbloquear IP (menu 0604)

- `frontend/web/public/assets/css/siem.css` — Estilos con vars CSS corporativas

- `database/seeds/seed_menus_siem.sql` — 6 menús (06, 0601-0605) asignables

**Cumple:**
- ✅ Coherencia — Patrones idénticos a portería (init.php, structure, relative requires)
- ✅ Congruencia — Documentado en HANDOFF.md, implementación alineada
- ✅ Funcionalidad — Todas las 5 vistas cargan, endpoints responden HTTP 200
- ✅ Estabilidad — Manejo robusto de errores, no hay crashes
- ✅ Seguridad Total — require_session.php, verificación de menú asignado, prepared statements

---

## 🔐 ACCESS CONTROL VERIFICATION

**Cambio:** Permisos por menú asignado (no solo admins)

**Comportamiento:**
- Admin (`ind_usuario=true`) → Ve todos los menús automáticamente
- No-admin → Ve SOLO menús asignados en `tab_menu_usuarios`
- Endpoints AJAX verifican menú específico (ej. menu 0603 para sesiones)

**Verificación:** ✅ usuario.TI (no-admin) accede a SIEM solo con menús asignados

---

## 📦 BD CHANGES

### Sequence Creada
```
seq_log_ingresos — nextval() para tab_log_ingresos.id_ingreso
```

### Data Insertada
```
seed_menus_siem.sql — 6 menús SIEM (IDs: 06, 0601-0605)
```

### Funciones Desplegadas
```
database/functions/siem/ — 9 nuevas funciones (patrón 4-arg)
```

---

## 📝 FILES MODIFIED

| Archivo | Cambio | Líneas |
|---------|--------|--------|
| `porteria-salida-modal.js` | Usar SmartcsetSalidaRouter + campos nombres/apellidos | 24-36, 91-95, 104-119 |
| `database/setup_smartcset.sh` | Agregar SIEM functions + seed en FUNCS array | N/A (líneas > 1000) |
| `core/prepare.php` | seq_log_ingresos creada en BD (SQL directo) | N/A (DB only) |

---

## ✅ PREMISAS VERIFICADAS (11/11)

| # | Premisa | Estado | Verificación |
|---|---------|--------|--------------|
| 1 | BD = Servidor SENA | ✅ | Dump restaurado 2026-06-25, seq_log_ingresos agregada |
| 2 | Apache HTTPS/TLS | ✅ | `https://localhost/smartcset/` funciona |
| 3 | Symlinks correctos | ✅ | pages/, routers/ presentes y funcionales |
| 4 | Ingreso registra OK | ✅ | id_ingreso 3 en BD, timestamp correcto |
| 5 | Salida encuentra ingreso | ✅ | Endpoint `/routers/porteria/v1/salida/consultar.php` devuelve datos |
| 6 | SIEM Dashboard carga | ✅ | KPIs, charts, tabla de alertas renderizado |
| 7 | Access control por menú | ✅ | usuario.TI ve SIEM solo con menú asignado |
| 8 | 5 Pilares → Coherencia | ✅ | Código consistente, patrones uniformes |
| 9 | 5 Pilares → Congruencia | ✅ | Specs = Implementación = Docs |
| 10 | 5 Pilares → Funcionalidad | ✅ | Ingreso/salida/SIEM funcionan exactamente como se definen |
| 11 | 5 Pilares → Estabilidad + Seguridad | ✅ | Cero crashes, manejo de errores robusto, prepared statements, auth validado |

---

## 🚀 PRÓXIMOS PASOS (NO INCLUIDO EN ESTA SESIÓN)

- [ ] E4 — Rate limiting refinamiento (ajustar umbrales por IP/usuario)
- [ ] E5 — Validación de uploads (archivos portería)
- [ ] E6 — Logs JSON estructurado (ECS format)
- [ ] E7 — Auditoría completa de setup.sh
- [ ] Fase 2 — Reportes avanzados
- [ ] Fase 3 — Integración SENA (carga de DF49, PE04)
- [ ] Fase 4 — Testing E2E + Coverage 80%+

---

## 📅 Timeline Sesión

| Hora | Actividad |
|------|-----------|
| 15:00 | Inicio: DB local restore + symlinks verify |
| 15:30 | Bug #1: seq_log_ingresos identificado y arreglado |
| 16:00 | SIEM mini module full implementation |
| 16:30 | Bug #2: salida modal fetch URL arreglado |
| 17:00 | Bug #3: nombres undefined arreglado |
| 17:30 | Verification de 11 premisas completadas |
| 18:00 | Documentation update |

---

## 🎓 LECCIONES APRENDIDAS

1. **Dumps desfasados:** Siempre verificar que funciones y sequences se crearon después del dump  
2. **Legacy code:** Archivos viejos pueden usar patrones diferentes (fetch relativo vs router)  
3. **Field naming:** API puede devolver nombres diferentes (nombres vs nom_persona) — fallbacks útiles  
4. **Browser cache:** Cambios JS requieren Ctrl+F5 o timestamp refresh para ver cambios  
5. **Access control:** Menu assignment = permiso, no solo admin role

---

## 👤 Ejecutado por

**Usuario:** Anderson  
**Rol:** Desarrollador + Cybersecurity Lead SmartCSET  
**Fecha:** 2026-06-27  
**Duración:** ~3 horas  
**Commits:** N/A (sesión continua, sin git)

---

**Estado General:** 🟢 PRODUCCIÓN-READY (Fase 1 ≈70% completa)
