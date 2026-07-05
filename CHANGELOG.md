# CHANGELOG — SmartCSET

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
