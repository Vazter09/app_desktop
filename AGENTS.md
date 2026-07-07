# AGENTS.md — SmartCSET

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

### Agente: Módulo Portería (SGI)

**Responsable de:** `frontend/web/pages/modulos/porteria/`, `backend/routers/porteria/`, `backend/services/porteria/`, funciones `database/functions/porteria/`

**Entradas:** cambios en flujo de ingreso/salida, soporte de nuevos métodos de lectura

**Salidas:** vistas de portería, lógica de registro, parsers de documento

**Cuidado:** no romper el constraint de ingreso único por día

### Agente: Módulo Registro

**Responsable de:** `frontend/web/pages/modulos/registro/`, `backend/routers/registro/`, `backend/services/registro/`

**Entradas:** nuevos formularios de tipo de persona, cambios en catálogo de personas

**Salidas:** formularios de registro de personas

**Cuidado:** el login standalone del módulo está **INACTIVO desde 2026-07-01** (`registroUsaLoginStandalone()` retorna `false`). El módulo usa la sesión principal (`$_SESSION['id_usuario']`) + control por menú `0300`/`20701` como el resto del sistema. Ver Bug 8 en CLAUDE.md.

### Agente: Módulo SIEM

**Responsable de:** `frontend/web/pages/modulos/siem/`, `backend/routers/siem/`, `database/functions/siem/`

**Entradas:** cambios en las 5 vistas (dashboard, eventos, sesiones, IPs bloqueadas, actividad), nuevos KPIs o filtros

**Salidas:** vistas de auditoría/monitoreo, endpoints AJAX de acción administrativa (forzar cierre de sesión, desbloquear IP)

**Cuidado:** menú `211xx` (submenú de SGA `20`), no menú raíz `06` (ver Bug 12 en CLAUDE.md). Patrones obligatorios de timezone, control de acceso, cache-busting y contrato JS documentados en `backend/routers/siem/AGENTS.md` — leer antes de tocar cualquier vista o función nueva de este módulo. Módulo consolidado end-to-end 2026-07-06/07 (ver Bug 16 en CLAUDE.md).

### Agente: Administración y Menú (SGA)

**Responsable de:** `frontend/web/pages/menu/`, `frontend/web/pages/usuarios/`, `frontend/web/pages/admin/`, `frontend/web/layout/`

**Entradas:** cambios en estructura de menús, permisos, configuración visual

**Salidas:** dashboard, sidebar, CRUD de menús y usuarios, panel de configuración

**Cuidado:** `nom_programa` en `tab_menus` es la ruta física al archivo PHP desde la raíz del proyecto

### Agente: Setup / Deploy

**Responsable de:** `database/setup_smartcset.sh`, `scripts/`, `SETUP_AUDIT.md`

**Entradas:** nuevas funciones o migraciones a integrar al instalador

**Salidas:** script de instalación corregido y actualizado

**Cuidado:** conocer los bugs documentados en `CLAUDE.md` (sección "Bugs conocidos", Bugs 1-15) antes de modificar el script; `SETUP_AUDIT.md` es la auditoría histórica original

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
# localhost o el servidor de laboratorio 192.168.1.71). Usar las
# credenciales de .env vía PGPASSWORD.

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
