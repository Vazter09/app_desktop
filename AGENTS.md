# AGENTS.md — SmartCSET

---

## 🔐 PREMISAS PRINCIPALES & CONSIGNA OBLIGATORIA (DESDE 2026-07-09)

### Premisas Fundamentales
- **Sistema:** Control de acceso y registro de personas en centros de formación SENA
- **Datos sensibles:** Identidad (cédula, foto), patrones de asistencia de aprendices/instructores/visitantes
- **Amenaza principal:** Fuga de identificación + análisis de patrones de movimiento
- **Principio rector:** **Seguridad Total** — Coherencia + Congruencia + Funcionalidad + Estabilidad + Seguridad en CADA línea de código
- **Stack:** PHP 8+ (sin framework) + PostgreSQL 14+ + React web + Tkinter desktop (app_desktop)

### ⚠️ CONSIGNA OBLIGATORIA: MSPI + FASE 0 + FASE 1 (GATE DE ENTRADA A TODO DESARROLLO)
**A partir del 2026-07-09, CUALQUIER código nuevo DEBE:**

| Requisito | Prueba | Owner |
|-----------|--------|-------|
| ✅ **Cumplir MSPI (MinTIC)** | Mapeo explícito a Ejes 3, 5, 6, 7, 8 | Agente que implementa |
| ✅ **Aprobar FASE 0** | Alineado con FASE0-POL-001, FASE0-RIE-003 | Documentación previa |
| ✅ **Aprobar FASE 1** | Cumple E1-E10 relevantes (E-tasks) | Tests de seguridad suite |
| ✅ **5 Pilares** | Coherencia/Congruencia/Funcionalidad/Estabilidad/Seguridad | Code review pre-commit |

**COROLARIO:** Una funcionalidad que no pueda certificarse contra MSPI + Fase 0-1 **NO se implementa**. No es "deuda diferida" — es scope mal definido.

### Checklist Obligatorio (TODO DESARROLLO)
Antes de **cualquier** `git commit` que incluya código nuevo:

- [ ] **MSPI:** ¿A qué eje(s)? Documentado en PR/ADR/comment
- [ ] **Vulnerabilidades OWASP:** ¿Cuáles podría introducir? Mitigadas explícitamente
- [ ] **Tests:** ¿Pasa `scripts/test_seguridad/`? Tests nuevos si feature nueva
- [ ] **Fase 1 E-tasks:** ¿Qué entregables aplican? (ej. "E1 + E3 + E6" → validado)
- [ ] **Datos sensibles:** Si toca personas → Cifrado reposo (E2) + TLS tránsito (E8)
- [ ] **Autenticación/Sesión:** Sesión (E4) + rate limiting (E3) si toca login
- [ ] **Formularios:** CSRF tokens (E5) si hay POST; validación de input (OWASP A03)
- [ ] **Auditoría de 5 Pilares:** Coherencia con CLAUDE.md, congruencia con política, funciona, estable, seguro

**SIN ESTE CHECKLIST CUMPLIDO: RECHAZO DE PR. No es sugerencia — es gate.**

### APP_DESKTOP (Desde 2026-07-09)
**Regla crítica:** Toda funcionalidad nueva en `app_desktop/` sigue las MISMAS reglas que backend/frontend. **No hay excepción por ser desktop.**
- Biometría facial: E1 (validación), E2 (vectores cifrados), E3 (rate limit si aplica), E8 (TLS a backend)
- Nuevos endpoints: E1 (acceso), E6 (validación upload si aplica), E10 (tests automatizados)
- Cliente HTTP: E8 (TLS validation `verify_tls=True` siempre), E3 (rate limit respetado del servidor)

**Ejemplo:** Feature "enrolar rostro" → requiere E1 (¿quién puede?) + E2 (vector cifrado) + E6 (foto validada) + E8 (TLS al backend). Si alguno falta, el feature no se implementa hasta cumplir.

---

## Propósito de este archivo

Este archivo describe cómo los agentes de IA (Claude Code y similares) deben operar dentro del proyecto SmartCSET. Define zonas de responsabilidad, contratos entre subsistemas, y lineamientos de colaboración entre múltiples agentes concurrentes.

---

## Estructura de agentes recomendada

El proyecto puede ser trabajado por agentes especializados según el dominio. Se recomienda no mezclar responsabilidades: un agente que trabaja en funciones PL/pgSQL no debe tocar al mismo tiempo la capa de vistas PHP.

> **Nota de rutas (actualizado 2026-07-05):** el proyecto ya no usa `src/`. La estructura real es
> `backend/` (core, routers, services, middleware) + `frontend/web/` (layout, pages, public). El
> document root servido por Apache es `frontend/web/public/` bajo `https://localhost/smartcset/`.
> Las rutas de abajo se dan con la estructura actual.

### Agente: Core / Bootstrap

**Responsable de:** `backend/core/`, `frontend/web/public/index.php`, `.env`, `backend/routers/auth/`

**Entradas:** cambios en conexión BD, configuración del sistema, autenticación

**Salidas:** variables globales `$pdo`, `$stmt_*`, `AppConfig`, constantes de configuración

**Cuidado:** cambios en `prepare.php`/`prepare_login.php` afectan TODOS los módulos; siempre verificar que los statements existentes no se rompan

### Agente: Base de datos / Schema

**Responsable de:** `database/schema/`, `database/functions/`, `database/migrations/`, `database/seeds/`

**Entradas:** nuevas tablas, cambios de schema, nuevas funciones PL/pgSQL

**Salidas:** schema SQL actualizado, funciones desplegadas, migraciones documentadas

**Cuidado:** orden de despliegue crítico — `_helpers` antes que el resto

### Agente: Módulo Portería (SGI) — Incluye Biometría con Foto (2026-07-09)

**Responsable de:** `frontend/web/pages/modulos/porteria/`, `backend/routers/porteria/`, `backend/services/porteria/`, funciones `database/functions/porteria/`

**Responsabilidad completa:**
- Ingreso/salida manual por documento
- Parseo de QR/códigos de barras
- **Biometría facial:** enrolar + identificar, con foto de enrolamiento (2026-07-09, tarde — Opción A)
- Soporte de múltiples métodos de autenticación (`id_metodo_aut`: 1=manual, 2=QR, 3=barras, 4=facial)

**Entradas:** cambios en flujo de ingreso/salida, nuevos métodos de lectura, cambios en biometría

**Salidas:** vistas de portería, lógica de registro, parsers de documento, endpoints de biometría

**Cuidado:** 
- No romper el constraint de ingreso único por día
- Whitelist de `id_metodo_aut` en `parse_captura_service.php` debe incluir `ACCESO_METODO_BIOMETRICO = 4` (ver Bug 19)
- Biometría: vector pgvector 128 dims (SFace), índice HNSW, búsqueda por similitud cosine
- Funciones 4-arg exception handling: `fun_guardar_enrolamiento_facial` (ahora 4 params: +`ruta_foto_enrolamiento`), `fun_identificar_persona_por_rostro`
- **Fotos de enrolamiento (Opción A, 2026-07-09):** NO se guardan como `BYTEA`. `backend/services/porteria/biometria_photo_service.php` las guarda en filesystem (`frontend/web/public/uploads/biometria/{id_persona}/{id_persona}_{primer_nombre}.jpg`, valida MIME real con `finfo`); la ruta relativa vive en `tab_enrolamiento_facial.ruta_foto_enrolamiento`. `identificar.php` siempre debe devolver la foto real guardada, nunca una nueva — el cliente no debe sustituirla por una captura en vivo salvo fallback explícito. Cifrado en reposo de estas fotos (E2) queda diferido por decisión de Anderson (resolución del lado del SENA), no confundir con "cumplido".
- **Cambiar la aridad de estas funciones SIEMPRE requiere `DROP FUNCTION IF EXISTS` de la firma vieja** en el propio `.sql` — ver Bug 20 en CLAUDE.md (mismo error que Bug 6/E3, tercera vez que ocurre en el proyecto).

### Agente: Módulo Registro

**Responsable de:** `frontend/web/pages/modulos/registro/`, `backend/routers/registro/`, `backend/services/registro/`

**Entradas:** nuevos formularios de tipo de persona, cambios en catálogo de personas

**Salidas:** formularios de registro de personas

**Cuidado:** el login standalone del módulo está **INACTIVO desde 2026-07-01** (`registroUsaLoginStandalone()` retorna `false`). El módulo usa la sesión principal (`$_SESSION['id_usuario']`) + control por menú `0300`/`20701` como el resto del sistema. Ver Bug 8 en CLAUDE.md.

### Agente: Módulo SIEM (Reducido — 2026-07-08)

**Responsable de:** `frontend/web/pages/modulos/siem/`, `backend/routers/siem/`, `database/functions/siem/`

**Responsabilidad actual (post-reducción):**
- `21101` — Panel de Control (KPIs, alertas tabla Wireshark, auto-refresh 20s)
- `21103` — Sesiones Activas (forzar cierre operativo)
- **Eliminados 2026-07-08:** Eventos (21102), IPs Bloqueadas (21104), Actividad (21105)

**Entradas:** cambios en las 2 vistas (panel, sesiones), nuevos KPIs o filtros

**Salidas:** vistas de auditoría/monitoreo, endpoints AJAX de acción administrativa (forzar cierre de sesión)

**Cuidado:** menú `211xx` (submenú de SGA `20`), no menú raíz `06` (ver Bug 12 en CLAUDE.md). Patrones obligatorios de timezone (`AT TIME ZONE`), control de acceso (`usuarioTieneMenu`), cache-busting (`filemtime`), y contrato JS documentados en `backend/routers/siem/AGENTS.md` — leer antes de tocar cualquier vista o función nueva de este módulo. Módulo consolidado 2026-07-06/07, reducido 2026-07-08 (ver Bugs 16-18 en CLAUDE.md).

### Agente: Administración y Menú (SGA)

**Responsable de:** `frontend/web/pages/menu/`, `frontend/web/pages/usuarios/`, `frontend/web/pages/admin/`, `frontend/web/layout/`

**Entradas:** cambios en estructura de menús, permisos, configuración visual

**Salidas:** dashboard, sidebar, CRUD de menús y usuarios, panel de configuración

**Cuidado:** `nom_programa` en `tab_menus` es la ruta física al archivo PHP desde la raíz del proyecto

### Agente: App Desktop (SGI — Escritorio Portería)

**Responsable de:** `app_desktop/app/`, `app_desktop/app/smartcset_client.py`, `app_desktop/app/ui/`

**Responsabilidad:**
- Cliente HTTP puro (urllib, sin `requests`)
- Login con sesión PHP real (misma autenticación que web)
- Módulos: dashboard, ingreso/salida, entradas (admin), biometría con foto + modal de confirmación (2026-07-09)

**Entradas:** cambios en endpoints portería, cambios en autenticación

**Salidas:** ejecutable Python + Tkinter, `SmartcsetClient` (contrato HTTP)

**Cuidado:** 
- No agregar deps externas sin necesidad real — solo 3 permitidas hoy: `opencv-python-headless`, `numpy` (cámara/motor), `Pillow` (conversión frame↔base64, agregada 2026-07-09). `bootstrap.py` detecta cambios en `requirements.txt` por hash y reinstala solo — no basta con editar el archivo si `.venv/` ya existe y el hash no cambió realmente.
- TLS validation `verify_tls=True` en producción (ver `smartcset_client.py` §construcción); sesión PHP es stateful — re-usar cookies entre requests
- **Modal de confirmación (`ui/identification_confirmation_modal.py`, nuevo 2026-07-09):** se abre automáticamente al identificar con éxito, antes de registrar. La foto que muestra debe ser la que devuelve el servidor (real, de enrolamiento) — nunca el frame en vivo salvo que el servidor no haya devuelto ninguna (fallback explícito, no comportamiento por defecto). Columna de huella dactilar es placeholder — no implementar sin que se pida explícitamente.
- **Cache local de fotos:** `app_desktop/app/images/{id}_{nombre}.jpg`, no versionado (`.gitignore` propio de esa carpeta) — es cache, no fuente de verdad; la fuente de verdad es siempre el servidor.
- Toda feature nueva de esta app requiere tests reales (sin mocks) en `app_desktop/app/tests/` antes de darse por terminada — ver checklist obligatorio de la sección "PREMISAS PRINCIPALES" arriba. No es opcional; se auditó explícitamente y se encontraron 3 violaciones propias en la sesión del 2026-07-09 (ver Bug 20 en CLAUDE.md).
- Integración completa con biometría (enrolar/identificar) — ver tabla de 13 tablas interactuadas en `app_desktop_tablas.md` (nota: esa tabla no incluye todavía la columna `ruta_foto_enrolamiento`, actualizar si se vuelve a generar el documento).

### Agente: Setup / Deploy / Infraestructura

**Responsable de:** `database/setup_smartcset.sh`, `scripts/`, `.env.example`, migraciones de schema

**Responsabilidad:**
- Instalador limpio que corre sin errores
- Despliegue seguro a producción (10.5.213.103)
- Variables de configuración documentadas en `.env.example`
- Todas las 23/23 tests de seguridad deben pasar post-instalación

**Entradas:** nuevas funciones o migraciones a integrar al instalador, nuevas variables de configuración

**Salidas:** script de instalación actualizado, .env.example documentado

**Cuidado:**
- Schema V.1.10 es el activo — nunca revert a versiones anteriores
- Orden despliegue crítico: `_helpers/smartcset_raise.sql` → dominio específico → migraciones
- Al agregar función PL/pgSQL: actualizar array `FUNCS` en `setup_smartcset.sh` E INCLUIR la migración si existe
- **Nuevas variables .env (E3):** `LOGIN_MAX_INTENTOS=5`, `LOGIN_VENTANA_MINUTOS=15` (configurables)
- **Nuevas variables .env (SIEM):** `DB_TIMEZONE=America/Bogota` (crítico para timezone local)
- Conocer Bugs 1-19 documentados en `CLAUDE.md` antes de modificar el script
- Instalación limpia debe pasar todas las tests (test_seguridad/test_*.py)
- Certificado TLS: con `subjectAltName`, `basicConstraints=CA:FALSE`, `extendedKeyUsage=serverAuth`

---

## Contratos entre subsistemas

### prepare.php → vistas

`prepare.php` expone las siguientes variables como contrato público:

- `$pdo` — objeto PDO
- `$stmt_login`, `$stmt_fun_ins_user`, `$stmt_fun_upd_user`, `$stmt_list_users` — usuarios
- `$stmt_menu`, `$stmt_list_todos_menus`, `$stmt_ins_menu`, `$stmt_upd_menu`, `$stmt_del_menu` — menús
- `$stmt_ins_perfil`, `$stmt_del_perfil`, `$stmt_list_usuarios`, `$stmt_list_menus` — perfiles
- `$stmt_list_entradas` — entradas del centro
- `$stmt_list_tipos_doc`, `$stmt_list_tipos_persona`, `$stmt_list_ingresos_hoy` — portería ingreso
- `$stmt_buscar_persona_doc`, `$stmt_fun_registrar_ingreso` — portería registro
- `$stmt_list_salidas_hoy`, `$stmt_buscar_ingreso_abierto`, `$stmt_fun_registrar_salida` — portería salida
- `$stmt_fun_ingreso_sesion`, `$stmt_fun_salida_sesion`, `$stmt_fun_touch_sesion`, `$stmt_fun_validar_sesion_activa`, `$stmt_list_sesiones_activas` — sesiones (usar `acceso_sesion.php` para funciones; listado vía `$stmt_list_sesiones_activas`)
- `$stmt_valida_mail`, `$stmt_upd_pass` — recuperación de contraseña
- `$stmt_get_config`, `$stmt_fun_upd_config` — configuración del sistema

### AppConfig → layout/tema

`AppConfig` expone configuración visual a todo el sistema:

- `AppConfig::nomSistema()` — nombre del sistema
- `AppConfig::pathLogo()` — ruta relativa al logo
- `AppConfig::colorPrimario()` / `colorSecundario()` — colores corporativos
- `AppConfig::themeTokensDark()` / `themeTokensLight()` — tokens CSS
- `AppConfig::moduloRegistroHabilitado()` — flag de módulo registro
- `AppConfig::usrRegistro()` / `passRegistroHash()` — credenciales del login standalone de registro (**inactivo desde 2026-07-01**; el módulo usa la sesión principal)

### PL/pgSQL → PHP (ErrorHandler)

Las funciones PL/pgSQL lanzan excepciones `P0001` con mensajes en español legibles por el usuario. `ErrorHandler::userMessageFromException($e)` extrae ese mensaje de la cadena de error de PostgreSQL y lo devuelve sin exponer detalles técnicos. Si el SQLSTATE no es P0001, se traduce usando el mapa de `$sqlErrorMap`.

---

## Reglas de colaboración entre agentes

1. **Un agente a la vez por archivo.** No editar el mismo archivo simultáneamente.

2. **Cambios en prepare.php requieren revisión de todos los módulos.** Si se agrega o modifica un statement, verificar que ningún módulo asuma el statement anterior.

3. **Cambios en schema siempre van acompañados de migración.** El schema activo es `script-BD-SMARTCSET V.1.10.sql`; para cambios estructurales crear una migración idempotente en `database/migrations/` en vez de editar el schema directamente. **Criterio ante divergencia schema-vs-datos reales: priorizar el diseño real de producción** (ver Bug 15 en CLAUDE.md).

4. **Las funciones PL/pgSQL van a `database/functions/` Y al array FUNCS de `setup_smartcset.sh`.** Ambos cambios van juntos.

5. **Los mensajes al usuario son responsabilidad de PL/pgSQL (RAISE) o de PHP (Exception).** No duplicar mensajes de error en ambas capas.

6. **El control de acceso a páginas de módulos es por menú, no solo por sesión.** Usar `usuarioTieneMenu($pdo, $idUsuario, '0XXX')` en cada página bajo `pages/modulos/` (admin pasa siempre; el resto valida `tab_menu_usuarios`). `isset($_SESSION['id_usuario'])` solo verifica que hay sesión, no el permiso. El login standalone del módulo registro está inactivo (usa la sesión principal). Ver Bugs 7 y 8 en CLAUDE.md.

7. **El sidebar siempre se renderiza con `$pdo` disponible.** Cualquier página que incluya `sidebar.php` debe haber cargado `prepare.php` antes.

---

## Verificación de estado del sistema

Antes de trabajar en cualquier área, verificar:

```bash
# La BD activa la define .env (DB_NAME=db_smartcset2, DB_HOST puede ser
# localhost, el servidor de laboratorio (192.168.1.71 / 10.5.213.111) o el
# servidor institucional real (10.5.213.103, donde smartcset opera de
# verdad — código y BD sincronizados desde 2026-07-07). Usar las
# credenciales de .env vía PGPASSWORD. DB_SSLMODE=require es obligatorio
# para conectar a la BD del servidor institucional desde su propia subred
# (10.5.213.0/24) — ver Bug 17/E8 en CLAUDE.md.

# Estado del schema en BD:
psql -h "$DB_HOST" -U postgres -d db_smartcset2 -c "\dt tab_*"

# Funciones desplegadas:
psql -h "$DB_HOST" -U postgres -d db_smartcset2 -c "\df fun_*"

# Usuarios del sistema:
psql -h "$DB_HOST" -U postgres -d db_smartcset2 -c "SELECT id_usuario, nom_usuario, ind_usuario, ind_estado FROM tab_usuarios"
```

Aplicación servida por Apache con HTTPS en `https://localhost/smartcset/`.

---

## Convenciones de nombres de dominio

Los agentes se mapean a dominios específicos del código. Cuando un agente trabaja en un área, debe revisar el `AGENTS.md` más cercano a ese directorio para entender:
- Qué archivos están en la carpeta
- Cuál es el flujo principal de negocio
- Qué depende el código de áreas externas
- Qué NO tocar sin entender primero

Por ejemplo, si trabajas en `frontend/web/pages/modulos/porteria/ingreso/`, debes consultar (en orden) el `AGENTS.md` más cercano subiendo por el árbol hasta la raíz, y finalmente `CLAUDE.md` para patrones generales. Hay `AGENTS.md` distribuidos en `backend/`, `frontend/web/layout/`, `database/functions/` y sus subcarpetas.

---

## Variables y funciones críticas

**Variables globales que se asumen en el scope:**

Cualquier script que incluya `prepare.php` tiene acceso a:
```php
$pdo                    // Conexión PDO
$stmt_*                 // Decenas de prepared statements
$w_mensaje              // Mensaje flash (si está setead)
$w_tipo_alerta          // Tipo de alert flash (si está seteado)
```

**Funciones globales disponibles:**

Cualquier script que incluya `helpers.php` tiene acceso a:
```php
getIcon($nombre)        // Mapea nombre menu a clase Bootstrap Icons
obtenerMenusUsuario()   // Retorna menús del usuario
renderPageFlash()       // Emite HTML del flash
validarLongitudPassword() // Valida que tenga 12+ chars
smartcsetProjectAssetHref() // Calcula prefijo ../../ hacia raíz
smartcsetUrlNomPrograma()  // Construye URL de menú
smartcsetLogoUrl()      // URL del logo para <img>
```

---

## Flujo de solicitud típico

1. Usuario accede a `https://localhost/smartcset/pages/menu/menu_principal.php`
2. PHP incluye `backend/core/prepare.php` (crea `$pdo`, prepara statements, inicializa `AppConfig`)
3. PHP incluye `frontend/web/layout/head.php` (emite `<head>` con Bootstrap, CSS, theme_vars)
4. PHP incluye `frontend/web/layout/sidebar.php` (renderiza menú lateral dinámico via `obtenerMenusUsuario()`)
5. PHP renderiza contenido principal
6. PHP incluye `frontend/web/layout/footer.php` (cierra HTML, carga JS global)
7. En el navegador, `smartcset-toast.js` lee `#page-flash-data` y muestra notificación

---

## Prevención de errores comunes

**Circular dependencies:**
- No incluir vistas desde `helpers.php`
- No incluir `core/prepare.php` desde `core/ErrorHandler.php`
- Las funciones de `lib/` pueden incluir `init.php`, que incluye `prepare.php`

**Sesión no inicializada:**
- Siempre asumir que `$_SESSION` existe si se llegó a una vista interna (post-login)
- Si una página puede ser pública, validar `$_SESSION['id_usuario']` antes de usarla
- `backend/middleware/` (`require_session.php`, `require_admin.php`, etc.) y `backend/routers/auth/` pueden redirigir al login si la sesión no existe

**Variables no inicializadas:**
- `$w_mensaje` y `$w_tipo_alerta` pueden no estar seteadas; usar `isset()` antes de leerlas
- Los `$stmt_*` siempre existen en `prepare.php`; usar `$stmt` como referencia en el código

**Charset y encoding:**
- Todo debe ser UTF-8 (tablas PostgreSQL, headers PHP, archivos HTML)
- Las contraseñas bcrypt son ASCII safe, así que no hay problemas ahí
