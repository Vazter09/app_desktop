# AGENTS.md — SmartCSET

## Propósito de este archivo

Este archivo describe cómo los agentes de IA (Claude Code y similares) deben operar dentro del proyecto SmartCSET. Define zonas de responsabilidad, contratos entre subsistemas, y lineamientos de colaboración entre múltiples agentes concurrentes.

---

## Estructura de agentes recomendada

El proyecto puede ser trabajado por agentes especializados según el dominio. Se recomienda no mezclar responsabilidades: un agente que trabaja en funciones PL/pgSQL no debe tocar al mismo tiempo la capa de vistas PHP.

### Agente: Core / Bootstrap

**Responsable de:** `src/core/`, `index.php`, `.env`, `src/auth/`

**Entradas:** cambios en conexión BD, configuración del sistema, autenticación

**Salidas:** variables globales `$pdo`, `$stmt_*`, `AppConfig`, constantes de configuración

**Cuidado:** cambios en `prepare.php` afectan TODOS los módulos; siempre verificar que los statements existentes no se rompan

### Agente: Base de datos / Schema

**Responsable de:** `database/schema/`, `database/functions/`, `database/migrations/`, `database/seeds/`

**Entradas:** nuevas tablas, cambios de schema, nuevas funciones PL/pgSQL

**Salidas:** schema SQL actualizado, funciones desplegadas, migraciones documentadas

**Cuidado:** orden de despliegue crítico — `_helpers` antes que el resto

### Agente: Módulo Portería

**Responsable de:** `src/modulos/porteria/`, funciones `database/functions/porteria/`

**Entradas:** cambios en flujo de ingreso/salida, soporte de nuevos métodos de lectura

**Salidas:** vistas de portería, lógica de registro, parsers de documento

**Cuidado:** no romper el constraint de ingreso único por día

### Agente: Módulo Registro

**Responsable de:** `src/modulos/registro/`

**Entradas:** nuevos formularios de tipo de persona, cambios en catálogo de personas

**Salidas:** formularios de registro standalone

**Cuidado:** el módulo tiene autenticación propia (standalone); no mezclar con `$_SESSION['id_usuario']`

### Agente: Administración y Menú

**Responsable de:** `src/menu/`, `src/usuarios/`, `src/admin/`, `src/layout/`

**Entradas:** cambios en estructura de menús, permisos, configuración visual

**Salidas:** dashboard, sidebar, CRUD de menús y usuarios, panel de configuración

**Cuidado:** `nom_programa` en `tab_menus` es la ruta física al archivo PHP desde la raíz del proyecto

### Agente: Setup / Deploy

**Responsable de:** `database/setup_smartcset.sh`, `tools/`, `SETUP_AUDIT.md`

**Entradas:** nuevas funciones o migraciones a integrar al instalador

**Salidas:** script de instalación corregido y actualizado

**Cuidado:** conocer los 4 bugs documentados en `SETUP_AUDIT.md` antes de modificar el script

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
- `AppConfig::usrRegistro()` / `passRegistroHash()` — credenciales standalone registro

### PL/pgSQL → PHP (ErrorHandler)

Las funciones PL/pgSQL lanzan excepciones `P0001` con mensajes en español legibles por el usuario. `ErrorHandler::userMessageFromException($e)` extrae ese mensaje de la cadena de error de PostgreSQL y lo devuelve sin exponer detalles técnicos. Si el SQLSTATE no es P0001, se traduce usando el mapa de `$sqlErrorMap`.

---

## Reglas de colaboración entre agentes

1. **Un agente a la vez por archivo.** No editar el mismo archivo simultáneamente.

2. **Cambios en prepare.php requieren revisión de todos los módulos.** Si se agrega o modifica un statement, verificar que ningún módulo asuma el statement anterior.

3. **Cambios en schema siempre van acompañados de migración.** No modificar el schema V.1.6 directamente; crear una nueva migración.

4. **Las funciones PL/pgSQL van a `database/functions/` Y al array FUNCS de `setup_smartcset.sh`.** Ambos cambios van juntos.

5. **Los mensajes al usuario son responsabilidad de PL/pgSQL (RAISE) o de PHP (Exception).** No duplicar mensajes de error en ambas capas.

6. **El módulo de registro standalone tiene su propia sesión.** No asumir que `$_SESSION['id_usuario']` estará disponible en el módulo registro.

7. **El sidebar siempre se renderiza con `$pdo` disponible.** Cualquier página que incluya `sidebar.php` debe haber cargado `prepare.php` antes.

---

## Verificación de estado del sistema

Antes de trabajar en cualquier área, verificar:

```bash
# Estado del schema en BD:
psql -U postgres -d db_smartcset -c "\dt tab_*"

# Funciones desplegadas:
psql -U postgres -d db_smartcset -c "\df fun_*"

# Usuarios del sistema:
psql -U postgres -d db_smartcset -c "SELECT id_usuario, nom_usuario, ind_usuario, ind_estado FROM tab_usuarios"
```

Para diagnóstico rápido desde PHP:
```
http://localhost:8080/tools/diagnose_bd.php
```

---

## Convenciones de nombres de dominio

Los agentes se mapean a dominios específicos del código. Cuando un agente trabaja en un área, debe revisar el `AGENTS.md` más cercano a ese directorio para entender:
- Qué archivos están en la carpeta
- Cuál es el flujo principal de negocio
- Qué depende el código de áreas externas
- Qué NO tocar sin entender primero

Por ejemplo, si trabajas en `src/modulos/porteria/ingreso/`, debes consultar (en orden):
1. `src/modulos/porteria/ingreso/AGENTS.md`
2. `src/modulos/porteria/AGENTS.md`
3. `src/modulos/AGENTS.md`
4. `src/AGENTS.md`
5. `CLAUDE.md` (este documento) para patrones generales

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

1. Usuario accede a `http://localhost:8080/src/menu/menu_principal.php`
2. PHP incluye `src/core/prepare.php` (crea `$pdo`, prepara statements, inicializa `AppConfig`)
3. PHP incluye `src/layout/head.php` (emite `<head>` con Bootstrap, CSS, theme_vars)
4. PHP incluye `src/layout/sidebar.php` (renderiza menú lateral dinámico via `obtenerMenusUsuario()`)
5. PHP renderiza contenido principal
6. PHP incluye `src/layout/footer.php` (cierra HTML, carga JS global)
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
- `src/auth/` puede redirigir a `index.php` si la sesión no existe

**Variables no inicializadas:**
- `$w_mensaje` y `$w_tipo_alerta` pueden no estar seteadas; usar `isset()` antes de leerlas
- Los `$stmt_*` siempre existen en `prepare.php`; usar `$stmt` como referencia en el código

**Charset y encoding:**
- Todo debe ser UTF-8 (tablas PostgreSQL, headers PHP, archivos HTML)
- Las contraseñas bcrypt son ASCII safe, así que no hay problemas ahí
