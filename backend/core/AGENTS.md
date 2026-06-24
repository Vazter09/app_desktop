# AGENTS.md — src/core/

## Propósito

Este directorio es el núcleo del sistema. Todo lo que se carga aquí está disponible globalmente en todos los módulos PHP. Es el único lugar donde se crea la conexión PDO y se definen los prepared statements globales. Modulos cambios aquí impactan TODO el proyecto.

---

## Archivos y su función

### prepare.php

El archivo más crítico del sistema. Hace cuatro cosas en orden:
1. Incluye `config.php` (constantes de BD) y `AppConfig.php`
2. Crea la conexión PDO con `PDO::ATTR_ERRMODE => ERRMODE_EXCEPTION`
3. Llama `AppConfig::boot($pdo)` para cargar la configuración desde BD
4. Prepara TODOS los prepared statements globales agrupados por sección

Cualquier script que necesite BD incluye `prepare.php` (directamente o via `init.php` de su módulo). Los `$stmt_*` creados aquí son variables en el scope del archivo que lo incluyó, no variables globales PHP.

**ATENCIÓN:** Agregar statements a `prepare.php` siempre al final de la sección correspondiente, nunca en medio de una sección existente. El orden importa porque algunos statements dependen de tablas que deben existir.

### config.php

Incluye `EnvLoader.php`, lo invoca, y define constantes PHP (`DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASS`, `COLOR_VERDE_OSCURO`, `COLOR_VERDE_OLIVA`, `PATH_LOGO`, `SESSION_TIMEOUT`, `APP_ENV`). También inicia configuración de sesión (`gc_maxlifetime`).

### EnvLoader.php

Lee el archivo `.env` de la raíz del proyecto y carga las variables a `$_ENV` y `putenv`. Tiene valores por defecto para cuando `.env` no existe (útil en CI). No llamar directamente; `config.php` lo invoca.

### AppConfig.php

Clase estática singleton que lee `tab_config_sistema WHERE id_config = 1`. Se inicializa con `AppConfig::boot($pdo)`. Proporciona:

**Métodos de datos del sistema:**
- `AppConfig::nomSistema()` — nombre del sistema
- `AppConfig::pathLogo()` — ruta relativa al logo
- `AppConfig::colorPrimario()` — color verde oscuro corporativo
- `AppConfig::colorSecundario()` — color verde oliva corporativo

**Métodos de tema CSS:**
- `AppConfig::themeTokensDark()` — array de tokens CSS para tema oscuro
- `AppConfig::themeTokensLight()` — array de tokens CSS para tema claro
- `AppConfig::sidebarThemeTokens()` — tokens específicos del sidebar

**Métodos de módulos:**
- `AppConfig::moduloRegistroHabilitado()` — flag booleano
- `AppConfig::loginRegistroStandalone()` — flag booleano

**Métodos de credenciales de registro:**
- `AppConfig::usrRegistro()` — usuario del módulo registro
- `AppConfig::passRegistroHash()` — hash bcrypt de contraseña

**Métodos de utilidad de color:**
- `AppConfig::hexToRgba(string $hex, float $alpha)` — convierte #RRGGBB a rgba()
- `AppConfig::darkenHex(string $hex, float $percent)` — oscurece un color hex

**Control de ciclo de vida:**
- `AppConfig::boot(PDO $pdo)` — inicializa desde BD; se llama desde `prepare.php`
- `AppConfig::reset()` — fuerza recarga; se usa en `configuracion.php` tras actualizar config

Si la tabla `tab_config_sistema` no existe (instalación incompleta o sin migraciones), `AppConfig` cae a valores del `.env` o hardcoded. Nunca lanza excepción.

### ErrorHandler.php

Clase estática de traducción de errores. El método principal es `ErrorHandler::userMessageFromException(Throwable $e)`:
- Si es `PDOException`: extrae SQLSTATE, busca en mapa de mensajes, o extrae mensaje de negocio del RAISE de PostgreSQL
- Si es `Exception` general: extrae el mensaje si no parece técnico, sino usa mensaje genérico
- Nunca expone SQLSTATE, nombres de tablas ni detalles de stack al usuario final

**Métodos de respuesta JSON para endpoints AJAX:**
- `ErrorHandler::handleDatabaseException(PDOException $e)` → array con `status`, `message`, `source`
- `ErrorHandler::handleValidationException(Exception $e)` → idem
- `ErrorHandler::sendJSON(array $response)` → hace header JSON y echo, llama exit

**Manejo de errores especializados:**
- `ErrorHandler::handleForeignKeyViolation($e, 'DELETE', $context)` — para cuando DELETE viola FK

Los errores se loguean a `src/logs/error_handler.log` (directorio creado si no existe).

### SecurityMiddleware.php

Se auto-invoca al ser incluido (`SecurityMiddleware::initialize()` al final del archivo). Establece headers HTTP de seguridad (X-Content-Type-Options, X-Frame-Options, X-XSS-Protection, CSP). Incluye lógica para forzar HTTPS (comentada, activar en producción).

**ATENCIÓN:** `configureSessionSecurity()` tiene `session.cookie_secure = 1` que rompe en HTTP local. Si la sesión no funciona en desarrollo, comentar esa línea o agregar condición `APP_ENV === 'production'`.

### helpers.php

Funciones PHP globales disponibles en todo el sistema tras incluir este archivo:

**Funciones de icono y presentación:**
- `getIcon(string $nombre)` — mapea nombre de menú a clase Bootstrap Icons

**Funciones de sesión y usuario:**
- `usuarioEsAdministrador(PDO $pdo, string $id)` — verifica `ind_usuario` con cache estático
- `obtenerMenusUsuario(PDO $pdo, string $id)` — devuelve menús asignados (o todos si es admin)

**Funciones de presentación:**
- `renderPageFlash(?string $mensaje, string $tipo, ?string $título)` — emite `#page-flash-data` que `smartcset-toast.js` convierte en toast
- `validarLongitudPassword(string $password, bool $esObligatoria)` — lanza `Exception` si no cumple mínimo de 12 caracteres

**Funciones de rutas de assets:**
- `smartcsetProjectAssetHref()` — calcula `../../` relativo desde la página actual a la raíz
- `smartcsetModulosAssetHref()` — alias deprecado de la anterior
- `smartcsetUrlNomPrograma(string $nomPrograma)` — construye URL de un item de menú desde `nom_programa`
- `smartcsetLogoUrl(string $assetHref)` — URL del logo para `<img src>`

### LogoUpload.php

Clase estática para subida del logo institucional a `public/uploads/logos/`. Solo acepta PNG, JPEG, GIF, WEBP. Límite 5MB. Retorna ruta relativa desde la raíz del proyecto (compatible con `tab_config_sistema.path_logo`).

### ConfigSistemaDefaults.php

Clase de datos con los valores por defecto de `tab_config_sistema`. Se usa en `admin/configuracion.php` para la función "Restaurar sección". Define secciones: `SECTION_GENERAL`, `SECTION_THEME_DARK`, `SECTION_THEME_LIGHT`.

---

## Flujo de inicialización

1. Cualquier script incluye `require_once 'src/core/prepare.php'`
2. `prepare.php` incluye `config.php` (que incluye `EnvLoader.php` y ejecuta `session_start()`)
3. `prepare.php` incluye `AppConfig.php` y llama `AppConfig::boot($pdo)`
4. `prepare.php` crea `$pdo` con PDO::ERRMODE_EXCEPTION
5. `prepare.php` prepara todos los `$stmt_*` y los deja en el scope local
6. El script que incluyó `prepare.php` ahora tiene acceso a `$pdo`, `$stmt_*`, y clase `AppConfig`

---

## Convenciones específicas

- El orden de inclusión en cualquier script de módulo es: `prepare.php` → `ErrorHandler.php` → `helpers.php` (en ese orden)
- `prepare.php` incluye `config.php` y `AppConfig.php` internamente; no incluirlos por separado
- Los `$stmt_*` de `prepare.php` son variables en el scope del archivo que lo incluyó, no variables globales PHP — si se necesitan en una función, pasarlos como parámetro
- No llamar `session_start()` si ya fue llamado; usar `session_status() === PHP_SESSION_NONE` como guardia
- `AppConfig::reset()` existe solo para que `admin/configuracion.php` refresque la configuración sin reiniciar el servidor; no llamarlo desde otros lugares sin cuidado

---

## Dependencias

- `prepare.php` depende de: `config.php`, `AppConfig.php`, la BD PostgreSQL activa, archivo `.env` en la raíz
- `config.php` depende de: `EnvLoader.php`, archivo `.env` en la raíz del proyecto
- `helpers.php` depende de: `AppConfig` (clase ya cargada)
- `sidebar.php` en layout depende de: `$pdo` y `obtenerMenusUsuario()` de `helpers.php`
- Todas las excepciones esperadas vienen de `PDOException` lanzadas por PostgreSQL

---

## Qué NO tocar sin entender primero

- No reordenar los `$stmt_*` en `prepare.php`; el orden actual minimiza dependencias entre statements
- No cambiar la firma de `AppConfig::boot()` — es llamado desde `prepare.php` siempre con un argumento `$pdo`
- No agregar lógica de negocio a `ErrorHandler`; su único rol es traducir excepciones a mensajes
- No eliminar el método `AppConfig::reset()` — es necesario para que `configuracion.php` refresque la configuración sin reiniciar
- No crear funciones globales en `helpers.php` que hagan `require` o `include` — puede causar problemas de include múltiples
- No cambiar `PDO::ATTR_ERRMODE` a `ERRMODE_SILENT` — necesita ser `ERRMODE_EXCEPTION` para que las excepciones se lancen
