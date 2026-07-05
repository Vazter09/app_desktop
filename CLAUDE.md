# CLAUDE.md — SmartCSET

## Qué es SmartCSET

SmartCSET es un sistema de control de acceso y registro de personas para el SENA (Servicio Nacional de Aprendizaje de Colombia). Permite a la portería de un centro de formación SENA registrar el ingreso y la salida de visitantes, aprendices, instructores, funcionarios y contratistas. Además administra usuarios del sistema, menús de navegación con permisos por usuario, configuración visual corporativa y un módulo de registro de personas standalone.

El proyecto está escrito en PHP 8+ puro (sin Composer, sin autoloading PSR-4, sin framework) con PostgreSQL 14+ como único motor de base de datos. Toda la lógica de integridad y negocio crítica vive en funciones PL/pgSQL. PHP se encarga de la presentación, el enrutamiento y la autenticación de contraseñas (bcrypt via `password_verify`).

---

## 5 Pilares Obligatorios + Estándares de Código

**Cada línea de código debe cumplir:**

1. **Coherencia** — Código consistente, patrones uniformes en todo el proyecto
2. **Congruencia** — Todo alineado: especificaciones, implementación, documentación
3. **Funcionalidad** — Features funcionan exactamente como se definen
4. **Estabilidad** — Cero crashes, manejo robusto de errores
5. **Seguridad Total** — Cero vulnerabilidades conocidas, defensa en profundidad

**Estándar de código (A partir de 2026-06-25):**

- **PHP**: PSR-12 (indentación 4 espacios, llaves en línea propia para clases/métodos, `camelCase` para métodos, `PascalCase` para clases)
- **Python** (scripts, tooling): **PEP8 estricto** (línea ≤79 caracteres, `snake_case` para funciones, imports ordenados, espaciado estándar). Validar con `ruff check` antes de commit.
- **SQL/PostgreSQL**: Convenciones documentadas abajo (prefijos `tab_`, `fun_`, `seq_`, etc.)
- **JavaScript**: Vanilla JS, camelCase, semicolons opcionales (Bootstrap 5 compatible)

**Aplicación:**
- Todo código nuevo en `backend/`, `frontend/`, `scripts/`, `database/functions/` debe cumplir estos estándares
- Refactorings deben alinear código antiguo a los estándares
- CI/pre-commit puede incluir validación automática (`ruff`, `phpcs`, `sqlformat`)

---

## Setup rápido de desarrollo

### Requisitos

- PHP 8.1+ con extensión `pdo_pgsql` habilitada
- PostgreSQL 14+ con usuario con permisos para crear bases de datos
- PowerShell (Windows) o bash (Linux/macOS)

### 1. Variables de entorno

Copiar `.env.example` a `.env` y ajustar credenciales:

```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=db_smartcset
DB_USER=postgres
DB_PASS=tu_password

COLOR_VERDE_OSCURO=#004d40
COLOR_VERDE_OLIVA=#808000

PATH_LOGO=img/logo_empresa.png
```

### 2. Instalar la base de datos

```bash
# Desde la raíz del proyecto (requiere psql en PATH)
bash database/setup_smartcset.sh
```

**ADVERTENCIA**: El script BORRA y RECREA todas las tablas. Usarlo solo en instalación nueva.

**ADVERTENCIA CRÍTICA**: El script en su estado actual tiene 4 bugs documentados en `SETUP_AUDIT.md`. Ver sección "Bugs conocidos" más abajo antes de ejecutarlo.

Credenciales de desarrollo tras el setup:
- `admin.smart` / `AdminSmart2026!` (administrador)
- `porteria` / `Porteria2026!` (usuario portería)

### 3. Levantar servidor de desarrollo

El entorno local usa **Apache con HTTPS** (no el servidor PHP built-in).

- **URL**: `https://localhost/smartcset/`
- `http://localhost/` redirige automáticamente a HTTPS
- Certificado autofirmado — el navegador pide confirmación la primera vez ("Configuración avanzada" → "Acceder a localhost")
- Configuración Apache: `/etc/apache2/sites-available/smartcset-ssl-local.conf`
- Copia en el repo: `docs/infraestructura/smartcset-ssl-local.conf`
- `APP_BASE_PATH=smartcset` en `.env` es obligatorio para que las URLs funcionen bajo `/smartcset/`

Si Apache no está corriendo: `sudo systemctl start apache2`

El servidor PHP built-in (`php -S`) es una alternativa sin HTTPS (dejar `APP_BASE_PATH` vacío):
```bash
bash scripts/dev/start_dev.sh
# http://localhost:8080/  (sin HTTPS, sin /smartcset/)
```

---

## Arquitectura del proyecto

```
smartcset/
├── .env                    ← Variables de entorno (no commitear)
├── .env.example            ← Plantilla de variables de entorno
├── CLAUDE.md               ← Este archivo
├── AGENTS.md               ← Guía de agentes IA
├── SETUP_AUDIT.md          ← Auditoría de bugs en setup_smartcset.sh
│
├── backend/                ← API y lógica de negocio (PHP)
│   ├── core/               ← Bootstrap central del sistema
│   │   ├── prepare.php     ← Conexión PDO + TODOS los prepared statements globales
│   │   ├── prepare_login.php ← Prepared statements para autenticación
│   │   ├── config.php      ← Define constantes DB_*, APP_ENV, etc. desde .env
│   │   ├── EnvLoader.php   ← Lector de .env a $_ENV y constantes
│   │   ├── AppConfig.php   ← Clase singleton: configuración de BD (tab_config_sistema)
│   │   ├── ErrorHandler.php ← Traductor SQLSTATE -> mensajes de usuario
│   │   ├── SecurityMiddleware.php ← Headers HTTP, prevención ataques básicos
│   │   ├── LogoUpload.php  ← Subida de logo a frontend/web/public/uploads/logos/
│   │   ├── ConfigSistemaDefaults.php ← Valores por defecto de tab_config_sistema
│   │   ├── helpers.php     ← Funciones globales: getIcon, renderPageFlash, etc.
│   │   ├── Db.php          ← Clase wrapper de base de datos
│   │   ├── RouterResponse.php ← Manejo de respuestas HTTP
│   │   └── lib/
│   │       └── acceso_sesion.php ← Lógica de sesiones
│   │
│   ├── middleware/         ← Guardias de autenticación
│   │   ├── require_session.php     ← Requiere sesión autenticada
│   │   ├── require_admin.php       ← Requiere rol administrador
│   │   ├── require_registro_session.php ← Requiere sesión del módulo registro
│   │   └── require_session_or_device.php ← Sesión O dispositivo móvil
│   │
│   ├── routers/            ← Endpoints/controllers organizados por dominio
│   │   ├── auth/v1/        ← Login, logout, recuperar contraseña
│   │   ├── usuarios/v1/    ← CRUD de usuarios
│   │   ├── menus/v1/       ← CRUD de menús y permisos
│   │   ├── admin/v1/       ← Panel administrativo
│   │   ├── porteria/v1/    ← Ingreso y salida de personas
│   │   │   ├── _lib/       ← Lógica compartida de portería
│   │   │   └── prepare.php ← Prepared statements de portería
│   │   ├── registro/v1/    ← Módulo de registro standalone
│   │   ├── entradas/v1/    ← CRUD de entradas/puertas
│   │   └── sesion/v1/      ← Gestión de sesiones
│   │
│   └── services/           ← Lógica de negocio reutilizable
│       ├── porteria/       ← Servicios de portería (ingreso, salida, etc.)
│       ├── registro/       ← Servicios de registro de personas
│       ├── admin/          ← Servicios administrativos
│       ├── menus/          ← Servicios de menús y permisos
│       ├── entradas/       ← Servicios de entradas/puertas
│       └── reportes/       ← Generación de reportes
│
├── frontend/               ← UI y presentación (PHP + HTML + CSS + JS)
│   └── web/
│       ├── init.php        ← Bootstrap del frontend
│       │
│       ├── layout/         ← Partials HTML compartidos
│       │   ├── head.php    ← <head> con Bootstrap, CSS globales, theme_vars.php
│       │   ├── sidebar.php ← Sidebar de navegación dinámico
│       │   ├── topbar.php  ← Barra superior con usuario activo
│       │   ├── footer.php  ← Cierre HTML + JS globales
│       │   ├── theme_vars.php ← Inyecta CSS custom properties desde AppConfig
│       │   ├── ui_kit.php  ← Kit UI utilitario
│       │   ├── components/ ← Componentes HTML reutilizables
│       │   └── partials/   ← Subpartials (ej. modal de confirmación)
│       │
│       ├── pages/          ← Vistas/páginas por sección
│       │   ├── auth/       ← Login, logout, recuperar contraseña
│       │   ├── menu/       ← Dashboard, menús
│       │   ├── usuarios/   ← CRUD de usuarios (vista)
│       │   ├── admin/      ← Panel administrativo
│       │   ├── alertas/    ← Alertas y notificaciones
│       │   └── modulos/    ← Módulos funcionales (portería, registro, etc.)
│       │
│       └── public/         ← Document root del servidor web
│           ├── index.php   ← Punto de entrada (router principal)
│           ├── router.php  ← Enrutador de requests
│           ├── assets/     ← CSS, JS, imágenes
│           │   ├── css/    ← Estilos (layout.css, modulos_*, etc.)
│           │   └── js/     ← Scripts (vanilla JS, sin bundler)
│           ├── uploads/    ← Directorios de uploads por módulo
│           │   └── logos/  ← Logos subidos via configuración
│           ├── tools/      ← Herramientas internas (diagnóstico, etc.)
│           ├── pages -> ../pages  ← Symlink a páginas
│           └── routers -> ../../../backend/routers ← Symlink a routers
│
├── database/
│   ├── setup_smartcset.sh  ← Instalador completo
│   ├── bootstrap_modulo_acceso.sql ← Script de bootstrap
│   ├── schema/             ← Scripts de schema
│   │   ├── script-BD-SMARTCSET V.1.10.sql   ← ACTIVO (esquema completo SENA)
│   │   ├── script-BD-SMARTCSET V.1.9.sql    ← Versión anterior, aún presente
│   │   └── history/        ← Versiones históricas
│   ├── functions/          ← Funciones PL/pgSQL organizadas por dominio
│   │   ├── _helpers/       ← Helpers de excepciones (desplegar PRIMERO)
│   │   ├── acceso/         ← Menús, usuarios, sesiones
│   │   ├── porteria/       ← Ingreso y salida de personas
│   │   ├── config/         ← Configuración del sistema
│   │   └── carga/          ← Carga de reportes SENA
│   ├── migrations/         ← Migraciones SQL numeradas
│   └── seeds/              ← Datos iniciales de desarrollo
│
├── scripts/                ← Scripts de desarrollo y deploy
│   ├── dev/                ← Scripts de desarrollo
│   │   └── start_dev.sh    ← Inicia servidor PHP dev en frontend/web/public
│   ├── deploy/             ← Scripts de deploy
│   ├── db/                 ← Scripts de BD
│   ├── infra/              ← Scripts de infraestructura
│   ├── tools/              ← Herramientas auxiliares
│   └── test_seguridad/     ← Suite de tests automatizados (Python + unittest)
│
├── test_seguridad/         ← Tests de seguridad (E1-E07)
│   ├── common.py           ← Helpers compartidos
│   ├── test_e1_a01_broken_access_control.py
│   ├── test_e1_a02_cryptographic_failures.py
│   ├── test_e4_hardening_sesiones.py
│   ├── test_e6_verificacion_uploads.py
│   ├── test_e7_correccion_setup.py
│   └── README.md
│
├── mobile/                 ← Apps móviles
│   └── porteria-app/       ← App portería (React Native, Flutter, etc.)
│
├── storage/                ← Almacenamiento de datos
│   └── porteria/           ← Fotos de portería
│
├── docs/                   ← Documentación interna
│   └── infraestructura/    ← Documentación de infraestructura
│
└── Documentacion para implementacion de MSPI/  ← Documentación de seguridad SENA
    ├── PHASE 0_documentos politicas de tratamiento de datos/
    ├── FASE 01_Blindaje Técnico Inmediato/
    ├── MSPI_liniamientos/
    └── plantillas_gov/
```

---

## Patrones y convenciones de código

### PHP

**Nombrado de archivos:**
- Clases PHP: `PascalCase.php` — `AppConfig.php`, `ErrorHandler.php`, `LogoUpload.php`
- Vistas/scripts: `snake_case_descriptivo.php` — `menu_principal.php`, `cambiar_clave.php`
- Procesadores de POST: prefijo `procesar_` — `procesar_perfil.php`
- Endpoints AJAX (respuesta JSON o fragmento): prefijo `ajax_` — `ajax_ciudades.php`
- Librerías de lógica de módulo: en directorio `lib/`

**Nombrado de funciones:**
- Funciones globales (helpers.php): camelCase descriptivo — `getIcon()`, `renderPageFlash()`, `smartcsetProjectAssetHref()`
- Funciones de módulo: prefijo del módulo — `ingresoRegistrarManual()`, `salidaBuscarIngresoAbierto()`, `registroGetTiposDocumento()`
- Funciones de acceso: prefijo `acceso` — `accesoNormalizarDocumento()`, `accesoParseCaptura()`
- Funciones de portería: prefijo `porteria` — `porteriaBuscarPersona()`, `porteriaConsultarAcceso()`

**Clases:**
- `AppConfig`: singleton estático. Se inicializa con `AppConfig::boot($pdo)` en `prepare.php`. Provee acceso a `tab_config_sistema` (colores, logo, nombre del sistema, flags de módulos).
- `ErrorHandler`: clase de utilidad estática. Método principal: `ErrorHandler::userMessageFromException($e)` — convierte cualquier `Throwable` en mensaje legible para el usuario sin exponer SQL.
- `EnvLoader`: carga `.env` a `$_ENV` y `putenv`. Se llama desde `config.php`.
- `SecurityMiddleware`: se auto-invoca al ser incluido (`SecurityMiddleware::initialize()`). Setea headers HTTP de seguridad.

**Inclusiones (require_once):**
```php
// Patrón desde frontend/web/pages/auth/ (vista):
require_once __DIR__ . '/../../../backend/core/prepare.php';   // relativo al archivo actual

// Patrón desde backend/routers/porteria/v1/ (endpoint):
require_once __DIR__ . '/../../../../backend/core/prepare.php';  // cuenta directorios hacia arriba

// Patrón desde backend/services/porteria/ (servicio):
require_once __DIR__ . '/../../core/prepare.php';

// Patrón desde frontend/web/layout/ (partial):
require_once __DIR__ . '/../../../backend/core/prepare.php';

// NUNCA usar paths absolutos del sistema de archivos
// NUNCA usar require_once('backend/core/prepare.php') — siempre relativo
```

**Gestión de sesión:**
- `$_SESSION['id_usuario']` — ID del usuario logueado (string, TEXT en BD)
- `$_SESSION['nom_usuario']` — Nombre completo
- `$_SESSION['ind_usuario']` — booleano: es administrador
- `$_SESSION['flash_msg']` + `$_SESSION['flash_tipo']` — mensajes flash entre redirects
- `$_SESSION['registro_authenticated']` — sesión standalone del módulo registro. **Inactiva desde 2026-07-01**: `registroUsaLoginStandalone()` retorna `false`, el módulo usa la sesión principal + menú `0300` como todo lo demás. El código standalone (`registroAuthenticateStandalone()`, `registroLogout()`, `login.php`) sigue en el repo pero inerte — reactivable poniendo ese toggle en `true` si hiciera falta.

**Control de acceso por menú (páginas de módulos):**
```php
// Patrón obligatorio para toda página nueva bajo pages/modulos/<algo>/:
if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . smartcsetLoginUrl());
    exit();
}
if (!usuarioTieneMenu($pdo, (string) $_SESSION['id_usuario'], '0XXX')) {
    http_response_code(403);
    die('Acceso denegado. No tiene el módulo asignado.');
}
```
`usuarioTieneMenu()` (en `backend/core/helpers.php`) es la única función que valida contra `tab_menu_usuarios` a nivel de página — los administradores pasan siempre (bypass). **No basta con `isset($_SESSION['id_usuario'])`**: eso solo verifica que hay sesión, no que el usuario tenga ese menú específico asignado. `obtenerMenusUsuario()` es solo para pintar el sidebar, no es control de acceso — ver Bug 7 más abajo.

**Flujo de autenticación:**
1. `index.php` ejecuta POST → `prepare.php` ya tiene `$stmt_login` preparado
2. `password_verify($pass, $hash)` valida la contraseña bcrypt
3. PostgreSQL solo almacena el hash; nunca valida contraseñas
4. Tras login exitoso: redirect a `src/menu/menu_principal.php`

**Flash messages:**
```php
// Escribir (en procesadores que redirigen):
$_SESSION['flash_msg'] = 'Ingreso registrado correctamente.';
$_SESSION['flash_tipo'] = 'success';  // success | danger | warning | info

// Leer (en vistas):
renderPageFlash($w_mensaje, $w_tipo_alerta);
// Renderiza <div id="page-flash-data" ...> que smartcset-toast.js convierte en toast Bootstrap
```

**Consultas a base de datos:**
- TODOS los prepared statements globales viven en `src/core/prepare.php`
- Las vistas consumen los `$stmt_*` preparados como variables globales
- Para consultas propias de un módulo: usar `$pdo->prepare()` directamente en la lógica del módulo
- SIEMPRE usar casting explícito en PostgreSQL: `?::TEXT`, `?::NUMERIC`, `?::BOOLEAN`
- NUNCA concatenar strings en SQL — siempre prepared statements con parámetros posicionales `?` o nombrados `:nombre`

**Rutas de assets (CSS/JS):**
```php
// Desde cualquier página PHP, calcular el prefijo correcto hacia frontend/web/public/assets/:
$smartcset_asset_href = smartcsetProjectAssetHref();
// Resultado: depende de la profundidad del archivo actual
// - Desde frontend/web/pages/: '../../public/assets/'
// - Desde backend/routers/: '../../../frontend/web/public/assets/'

// Uso en HTML/PHP:
echo '<link rel="stylesheet" href="' . $smartcset_asset_href . 'css/layout.css">';
echo '<script src="' . $smartcset_asset_href . 'js/common.js"></script>';
echo '<img src="' . $smartcset_asset_href . 'img/logo.png">';

// O directamente desde vistas frontend/web/:
echo '<link rel="stylesheet" href="public/assets/css/layout.css">';
```

### SQL / PostgreSQL

**Nomenclatura:**
- Tablas: `tab_` + nombre — `tab_usuarios`, `tab_log_ingresos`, `tab_personas`
- Tablas temporales (carga SENA): `tab_temp_` + nombre — `tab_temp_df49`
- Funciones PL/pgSQL: `fun_` + verbo + objeto — `fun_validar_login`, `fun_insert_log_ingreso`
- Helpers de excepciones: `smartcset_raise_*` — `smartcset_raise_validacion`, `smartcset_raise_negocio`
- Sequences: `seq_` + nombre — `seq_log_ingresos`
- Triggers: `fun_trigger_` + nombre — `fun_trigger_menu`, `fun_trigger_desasignar_menu`

**Patrón de funciones PL/pgSQL:**
```sql
CREATE OR REPLACE FUNCTION fun_nombre_accion(
    wparam1  tab_tabla.columna%TYPE,
    wparam2  TEXT DEFAULT NULL
) RETURNS TEXT AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    -- 1. Validaciones con smartcset_raise_validacion()
    -- 2. Reglas de negocio con smartcset_raise_negocio()
    -- 3. Operación DML
    RETURN 'OK';  -- o RETURN id_nuevo;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN RAISE;
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;
```
> **IMPORTANTE:** `GET STACKED DIAGNOSTICS` solo es válido dentro del bloque `EXCEPTION` del mismo
> subprograma donde ocurrió el error. Nunca llamar `smartcset_handle_sql_error()` sin argumentos —
> la función necesita recibir los diagnósticos capturados por el bloque EXCEPTION llamante.

**Errores de negocio desde PL/pgSQL:**
- Usar `PERFORM smartcset_raise_validacion('Mensaje al usuario.')` para datos inválidos
- Usar `PERFORM smartcset_raise_negocio('Mensaje al usuario.')` para reglas de negocio
- El ERRCODE es siempre `P0001`; PHP lo captura via `ErrorHandler::userMessageFromException()`
- El mensaje del `RAISE` es el que ve el usuario final — debe ser en español y sin jerga técnica

**Auditoría:**
Todas las tablas operativas tienen columnas `usr_insert`, `fec_insert`, `usr_update`, `fec_update`. Las funciones reciben el ID del usuario como último parámetro y lo propagan.

### CSS

- Un archivo por módulo: `modulo_seccion.css` — `modulos_ingresos.css`, `registro.css`
- CSS globales: `layout.css` (estructura), `style_crud.css` (tablas CRUD), `components.css` (componentes reutilizables), `style.css` (estilos base)
- Variables CSS inyectadas dinámicamente desde `AppConfig` via `theme_vars.php` — nunca codear colores corporativos directamente; usar `var(--v-oscuro)`, `var(--v-oliva)`, `var(--cyan)`, etc.
- Bootstrap 5.3 via CDN — no hay build step

### JavaScript

- Vanilla JS — sin npm, sin webpack, sin bundler
- Un archivo por módulo: `ingresos.js`, `salidas.js`, `menus.js`, etc.
- Librerías globales en `js/`:
  - `smartcset-toast.js` — lee `#page-flash-data` y muestra toast Bootstrap
  - `smartcset-forms.js` — utilidades de formularios
  - `smartcset-confirm.js` — modal de confirmación antes de DELETE
  - `layout.js` — toggle sidebar, comportamiento responsive
  - `common.js` — funciones compartidas de bajo nivel

---

## Base de datos: guía de trabajo

### Conectar desde PHP

La conexión PDO se crea en `backend/core/prepare.php` y está disponible como variable global `$pdo` en cualquier script que incluya ese archivo. No crear conexiones adicionales.

```php
// Desde frontend/web/pages/auth/login.php:
require_once __DIR__ . '/../../../backend/core/prepare.php';

// Ahora $pdo está disponible:
$stmt = $pdo->prepare("SELECT * FROM tab_personas WHERE id_persona = ?::NUMERIC");
$stmt->execute([$id]);
$row = $stmt->fetch();
```

### Cómo añadir una nueva función PL/pgSQL

1. Crear el archivo en la carpeta correcta de `database/functions/`:
   - Lógica de acceso/usuarios: `database/functions/acceso/usuarios/`
   - Lógica de menús: `database/functions/acceso/menus/`
   - Lógica de portería: `database/functions/porteria/`
   - Configuración: `database/functions/config/`
   - Carga reportes SENA: `database/functions/carga/`

2. Nombrar el archivo: `fun_verbo_objeto.sql` — todo lowercase, guiones bajos

3. Usar el patrón estándar con `smartcset_raise_*` y `smartcset_handle_sql_error()`

4. Desplegar a la BD:
```powershell
# Windows:
.\tools\deploy_funciones_acceso.ps1   # para funciones de acceso
.\tools\deploy_funciones_ingresos.ps1 # para funciones de portería

# O directamente con psql:
psql -h localhost -U postgres -d db_smartcset -f database/functions/porteria/fun_nueva.sql
```

5. Agregar el archivo al array `FUNCS` en `database/setup_smartcset.sh` para que próximas instalaciones lo incluyan

6. Si la función es llamada desde PHP, agregar el prepared statement a `backend/core/prepare.php`

### Cómo crear una migración

1. Crear archivo en `database/migrations/` con nombre descriptivo del cambio: `add_columna_x.sql`, `update_tabla_y.sql`
2. Hacerlo idempotente: usar `IF NOT EXISTS`, `ON CONFLICT DO NOTHING`, o `DO $$ BEGIN ... EXCEPTION WHEN ... END $$`
3. Agregar la migración al bloque correspondiente en `database/setup_smartcset.sh`
4. Ejecutar contra la BD de desarrollo antes de commitear

### Tablas principales

| Tabla | Propósito |
|---|---|
| `tab_usuarios` | Usuarios del sistema SmartCSET |
| `tab_personas` | Personas registradas (visitantes, aprendices, instructores, etc.) |
| `tab_menus` | Catálogo de opciones de menú |
| `tab_menu_usuarios` | Permisos de menú por usuario |
| `tab_log_ingresos` | Log de ingresos y salidas del centro |
| `tab_sesiones` | Sesiones activas de usuarios |
| `tab_config_sistema` | Configuración del sistema (fila única, id_config=1) |
| `tab_entradas_centro` | Puertas/entradas del centro (1-9) |
| `tab_metodos_aut` | Métodos de autenticación (1=manual, 2=QR, 3=barras) |
| `tab_tipos_persona` | Tipos de persona (1=Visitante, 2=Aprendiz, 3=Instructor...) |
| `tab_tipos_docum` | Tipos de documento (CC, CE, TI, PA, Sin) |
| `tab_dptos` | Departamentos de Colombia |
| `tab_ciudades` | Ciudades de Colombia |

### Relaciones críticas

- `tab_log_ingresos.id_visitante` → `tab_personas.id_persona`
- `tab_log_ingresos.id_entrada_centro` → `tab_entradas_centro.id_entrada_centro`
- `tab_log_ingresos.id_metodo_aut` → `tab_metodos_aut.id_metodo_aut`
- `tab_menu_usuarios.id_usuario` → `tab_usuarios.id_usuario`
- `tab_menu_usuarios.id_menu` → `tab_menus.id_menu`
- `tab_entradas_centro.(id_centro, id_sede)` → `tab_sedes.(id_centro, id_sede)` (cadena institucional SENA)

### Lógica de "ingreso abierto"

Un ingreso está "abierto" cuando `fec_salida = fec_ingreso` en `tab_log_ingresos`. Al registrar la salida, se actualiza `fec_salida` a `CURRENT_TIMESTAMP`. Hay un constraint único que impide dos ingresos activos del mismo día para la misma persona.

---

## Bugs conocidos / deuda técnica

Ver `SETUP_AUDIT.md` para el análisis histórico original (V.1.5/V.1.6). Estado actualizado al 2026-06-26:

### Bug 1: schema desactualizado en setup.sh — ✅ RESUELTO
El instalador usa `script-BD-SMARTCSET V.1.10.sql` (esquema activo actual, desde el merge de `feat/seguridad` en 2026-07-05).

### Bug 2: funciones PL/pgSQL ausentes del instalador — ✅ Resuelto en su mayoría (E7)
- ✅ `acceso/usuarios/fun_validar_login.sql` — agregada a `FUNCS` (E7)
- ✅ `acceso/usuarios/fun_validar_correo.sql` — agregada a `FUNCS` (E7)
- ✅ `acceso/usuarios/fun_validar_usuario.sql` — agregada a `FUNCS` (E7)
- ✅ `acceso/menus/fun_trigger_menu.sql` — ya estaba presente en `FUNCS` (la marca de "ausente" era una
  inexactitud de documentación previa, no un bug real)
- ✅ `acceso/menus/fun_trigger_menu_admin.sql` — idem, ya estaba presente en `FUNCS`
- ❌ `acceso/menus/fun_tab_menu_usuarios.sql` — **NO se agrega**: contiene versiones legacy que
  sobreescribirían `fun_insert_menu_usuarios`/`fun_delete_perfil_usuario` ya desplegadas con
  validaciones de seguridad. Permanece en el repo solo como referencia histórica.
- 🔲 `acceso/menus/fun_delete_perfil_usuarios.sql` (plural) — pendiente; su descripción no coincide con
  su implementación real, requiere análisis propio (fuera del alcance de E7)

**Nota sobre el impacto real:** `fun_validar_correo`, `fun_validar_login` y `fun_validar_usuario` **no
son llamadas desde PHP actualmente** — el login (`prepare.php`) y la recuperación de contraseña
(`recuperar.php`) usan SQL directo. Su ausencia previa era una brecha documental, no una falla
funcional. Ver
`Documentacion para implementacion de MSPI/FASE 01_Blindaje Técnico Inmediato/REPORTE_E1-E07_CORRECCION_SETUP_SMARTCSET.md`.

### Bug 3: migraciones no ejecutadas — parcialmente resuelto
- ✅ `update_modulos_rutas_organizadas.sql` — ya incluida en `setup.sh`
- ✅ `update_menu_registro_listado_admin.sql` — ya incluida en `setup.sh`
- 🔲 `add_unique_ingreso_persona_dia.sql` — aún no incluida en `setup.sh`

### Bug 4: Funciones de carga Excel SENA no incluidas
`fun_proceso_df49.sql`, `fun_proceso_pe04.sql`, `fun_proceso_juicios.sql` — probablemente omisión intencional; desplegar manualmente si el módulo de carga está activo.

### Bug 5: `seq_log_ingresos` ausente del schema — ✅ RESUELTO (2026-06-26)
La secuencia no estaba en `script-BD-SMARTCSET V.1.8.sql`. Se agregaron los 3 bloques necesarios al schema (`CREATE SEQUENCE`, `ALTER SEQUENCE OWNED BY`, `ALTER TABLE DEFAULT`) y se desplegó en el servidor remoto (10.5.213.111). El instalador `setup_smartcset.sh` ya tenía la línea de creación.

### Bug 6: `smartcset_handle_sql_error()` — patrón viejo — ✅ RESUELTO (2026-06-26)
La versión original (sin argumentos) usaba `GET STACKED DIAGNOSTICS` directamente en su cuerpo, lo que PostgreSQL prohíbe fuera del bloque `EXCEPTION` del mismo subprograma. Causaba crash al registrar ingresos.

**Todas las funciones migradas al patrón 4-arg y desplegadas en remoto (34 total):**
- `_helpers/smartcset_raise.sql` — versión 4-arg activa, zero-arg eliminada
- `porteria/` — 7 funciones (incluye `fun_insert_log_ingreso`, `fun_registrar_ingreso_manual`, `fun_upsert_persona_visitante`)
- `acceso/usuarios/` — 8 funciones
- `acceso/sesiones/` — 5 funciones
- `acceso/menus/` — 3 funciones
- `acceso/entradas/` — 2 funciones
- `config/` — 3 funciones
- `registro/` — 5 funciones
- `actualizar_datos/` — 1 función

Verificación: `SELECT proname FROM pg_proc WHERE prosrc LIKE '%smartcset_handle_sql_error()%'` devuelve 0 filas.

### Bug 7: Control de acceso solo verificaba sesión, no menú asignado — ✅ RESUELTO (2026-07-01)
Las páginas de SIEM (`pages/modulos/siem/*/index.php`) y del módulo registro solo comprobaban `isset($_SESSION['id_usuario'])` — cualquier usuario logueado (sin importar sus menús) podía acceder a cualquier módulo por URL directa. El sistema de menús (`tab_menu_usuarios`) solo controlaba qué aparecía en el sidebar, no el acceso real a la página. Verificado con datos reales antes del fix: `porteria` (sin menú SIEM asignado) obtenía HTTP 200 en `siem/index.php`.

**Fix:** nueva función `usuarioTieneMenu($pdo, $idUsuario, $idMenu)` en `backend/core/helpers.php` (admin = bypass, resto = valida `tab_menu_usuarios`), aplicada a las 5 páginas de SIEM (`0601`-`0605`) y al módulo registro (`0300`). Ver también Bug 8.

### Bug 8: Módulo registro con login standalone compartido — ✅ RESUELTO (2026-07-01)
El módulo registro (`frontend/web/pages/modulos/registro/`) tenía su propio login separado de la sesión principal, con **una sola credencial compartida** para todo el módulo (`tab_config_sistema.usr_registro`/`pass_registro_hash`) — no había forma de saber qué persona específica usó el módulo. Además, aunque el código intentaba grabar `usr_insert = wusr` explícitamente en 6 funciones PL/pgSQL (`fun_registrar_persona`, `fun_registrar_aprendiz`, `fun_registrar_instructor`, `fun_registrar_funcionario`, `fun_registrar_contratista`, `fun_actualizar_aprendiz`), el trigger `tri_act_tabla` (ver el fix de auditoría `app.usuario` más arriba) lo sobreescribía siempre con `CURRENT_USER = postgres` — ese `wusr` nunca llegaba a guardarse. Confirmado con datos: 7,381 filas en `tab_personas` con `usr_insert = 'postgres'`, 0 con algún usuario de registro.

**Fix:** `registroUsaLoginStandalone()` (en `backend/services/registro/access.php`, ya existía como toggle a medio implementar) ahora retorna `false`. El módulo usa `$_SESSION['id_usuario']` + `usuarioTieneMenu(..., '0300')` como el resto de la app, y `registroDisplayUsername()` devuelve el usuario real de la sesión — que junto con el `SET app.usuario` agregado a `backend/middleware/require_registro_session.php` hace que la auditoría (`usr_insert`/`usr_update`) muestre a la persona real, no `postgres` ni el usuario compartido. Verificado con escritura real: `usr_insert = dora.castro`. El parámetro `wusr` en las 6 funciones PL/pgSQL queda como código muerto (inofensivo, no se limpió).

### Bug 9: Rutas rotas en 3 endpoints del módulo registro — ✅ RESUELTO (2026-07-01)
`backend/routers/registro/v1/forms/guardar.php`, `aprendiz/buscar.php` y `personas/listar.php` usaban `dirname(__DIR__, 3)` para llegar a `backend/core/prepare.php`, pero estos 3 archivos están un nivel más anidados que `ciudades.php`/`login.php` (que sí están a la profundidad correcta con 3). Los 3 endpoints devolvían HTTP 500 en cualquier request — nunca funcionaron. Encontrado al probar el fix del Bug 8 (antes quedaba enmascarado porque el login standalone bloqueaba el acceso antes de llegar a este bug). Corregido a `dirname(__DIR__, 4)` en los 3 archivos.

### Bug 10: Colisión de `id_menu` entre SIEM (06/0601) y módulo de instructores — ✅ RESUELTO (2026-07-02)
Al fusionar la rama `feat/seguridad` (blindaje Fase 1, incluye SIEM E11) con `origin/main` (incluye `Feat/instructores #10` de Kevin), ambos módulos habían usado independientemente `id_menu = '06'` como top-level y `'0601'` como hijo — colisión semántica que un merge de texto no puede detectar porque ambos archivos SQL son válidos por separado. `frontend/web/layout/sidebar.php` traía código del módulo de instructores que sobreescribe a la fuerza el label de `06`/`0601` a "Asistencia"/"Por carrera" para administradores, haciendo que las páginas de SIEM (dueño real de esos IDs en `tab_menus`) aparecieran mal etiquetadas. La migración `add_menu_instructor_asistencia.sql` usaba `ON CONFLICT (id_menu) DO UPDATE` — de haber corrido contra una BD con SIEM ya desplegado, habría sobreescrito silenciosamente los registros de menú de SIEM.

**Fix:** renumerado el módulo de instructores de `06/0601` a `07/0701` (IDs verificados libres) en `sidebar.php`, `backend/services/instructor/asistencia_service.php`, `frontend/web/pages/modulos/instructor/fichas/index.php`, `fun_crear_usuarios_instructores.sql`, `revoke_instructores_menu_personas.sql` y `add_menu_instructor_asistencia.sql`. SIEM conserva `06/0601` sin cambios.

**Lección para nuevos módulos con menú propio:** antes de elegir un `id_menu` top-level, verificar contra `SELECT id_menu FROM tab_menus WHERE ind_id_padre='00'` en la BD real — no asumir que un ID de 2 dígitos está libre solo porque no aparece en el propio branch de trabajo.

### Bug 11: schema V.1.10 con múltiples errores de sintaxis que impedían instalación limpia — ✅ RESUELTO (2026-07-05)
Nunca se había corrido `setup_smartcset.sh` contra una BD completamente vacía desde que el schema activo pasó a ser V.1.10 — los bugs quedaron enmascarados porque las BD reales (local y remota) venían de `pg_restore` de dumps, no del script. Al recrear desde cero la BD del servidor de laboratorio (`192.168.1.71`, no institucional SENA), aparecieron 8 errores en cadena, corregidos en orden:
1. `CREATE EXTENSION IF NOT EXISTS PG_VECTOR;` — extensión inexistente, duplicaba la línea anterior (`vector`). Eliminada.
2. `tab_festivos` sin `;` de cierre — rompía el parseo del siguiente `CREATE TABLE`.
3. FK de `tab_aprendices` referenciaba columna inexistente `id_ficha` (la columna real es `id_ficha_vigente`).
4. `tab_novedades_academicas`: coma sobrante antes del `)` + FK de `id_causa_novedad` apuntaba a `tab_causas_novedad(id_tipo_novedad)` (columna inexistente en esa tabla; corregido a `id_causa_novedad`).
5. Tabla `tab_borrados` nunca se creaba pero `fun_act_tabla()` la usa como bitácora de DELETE — agregada.
6. `INSERT INTO tab_vehiculos VALUES('AAA000',1,77777777)` (dato de prueba de placa genérica) violaba la FK porque `tab_personas` está vacía en instalación limpia — convertido a `INSERT ... SELECT ... WHERE EXISTS (...)` para no bloquear el instalador; se mantiene el dato porque sí se va a implementar más adelante.
7. 45 `INSERT` de datos semilla (motivos de llamado, tipos/causas de novedad, opciones de productiva, jornadas, tipos de permiso) no incluían `usr_insert`/`fec_insert`, columnas `NOT NULL` — agregados `'seed'` y `CURRENT_TIMESTAMP` a los 45.
8. Columna `val_datos_origen JSONB` en `tab_log_ingresos` estaba comentada por error (`--    val_datos_origen`); `fun_insert_log_ingreso` la usa — descomentada.

**Verificado end-to-end:** instalador corrido contra `db_smartcset2` en `192.168.1.71` desde cero, exit code 0, 78 tablas, 58 funciones, menú SIEM en `211` (ver Bug 12).

### Bug 12 (evolución del Bug 10): SIEM se trae de `feat/seguridad` como submenú de SGA, no como menú raíz — 2026-07-05
Al mergear `feat/seguridad` a la rama de trabajo actual `feat/implementacion_MSPI` (que ya tenía el árbol de menús reorganizado en 3 abuelos SGI/SGA/SAA — ver `reorganizacion_menus_tres_abuelos.sql`, posterior a cuando se escribió el Bug 10), SIEM se renumeró de `06`/`0601-0605` (menú raíz) a `211`/`21101-21105` (submenú de SGA, `20`). Nueva migración `database/migrations/add_menu_siem_sga.sql`, agregada al `setup_smartcset.sh` **después** de `reorganizacion_menus_tres_abuelos.sql` (que borra y recrea todo `tab_menus`) y **antes** de `ensure_admin_acceso_total.sql`. El seed viejo `database/seeds/seed_menus_siem.sql` (numeración `06`) fue eliminado — quedaba huérfano y nunca se ejecutaba en el orden correcto.

**Reconocimiento facial excluido intencionalmente:** `feat/seguridad` también traía un módulo de biometría facial (`fun_guardar_biometria_facial`, `fun_identificar_persona_por_rostro`, tabla `tab_biometria_facial`, app desktop Python en `reconocimientio_facial/`, catálogo `tab_metodos_aut` con `id_metodo_aut=4`). Se excluyó por completo a pedido de Anderson — no está en el alcance de esta fase. Ver commit de merge en `feat/implementacion_MSPI` para el detalle completo de qué se trajo y qué no.

### Deuda técnica adicional

- Modal de ingreso (`porteria-ingreso-modal.js`): auto-apertura en desktop agregada (2026-06-26); antes solo aparecía en salida, no en ingreso
- Modal de salida (`porteria-salida-modal.js`): el botón final usaba `form.submit()` (no dispara el evento `submit`, nunca llamaba al AJAX real) — ✅ RESUELTO (2026-07-01), ahora llama directo a `SmartcsetSalidaRouter.registrar()`
- ~~Módulo registro hace SQL directo~~ — **nota desactualizada, ya no aplica.** El módulo usa prepared statements + funciones PL/pgSQL (`fun_registrar_*`) centralizadas en `backend/core/prepare.php`, igual que el resto del sistema. Ver Bug 8 y 9 para lo que sí se arregló ahí.

---

## Lo que NO hacer

- **No introducir Composer ni autoloading PSR-4.** Todo se carga con `require_once`. Si se necesita una nueva clase, agregarla al directorio correspondiente y cargarla explícitamente.
- **No usar ninguna función de autoload personalizada.** No hay `spl_autoload_register`.
- **No mockear la base de datos en tests.** No existe capa de abstracción para mocking; la BD de test debe ser PostgreSQL real.
- **No crear conexiones PDO adicionales.** Usar la conexión `$pdo` de `prepare.php`.
- **No usar variables superglobales sin sanear.** Siempre `htmlspecialchars()` al hacer echo, y prepared statements para SQL.
- **No saltarse el patrón de prepared statements.** Nunca concatenar input de usuario en SQL, ni siquiera con `intval()`.
- **No agregar lógica de negocio en las vistas (frontend/web/pages/).** Las vistas deben leer variables ya preparadas; la lógica va en `backend/routers/` o en `backend/services/`.
- **No codear colores corporativos directamente en CSS/HTML.** Usar las variables CSS `var(--v-oscuro)`, `var(--v-oliva)`, o las variables del sistema de temas desde `frontend/web/layout/theme_vars.php`.
- **No crear nuevas tablas sin migración SQL.** Cualquier cambio de schema va en `database/migrations/` o en `database/schema/`.
- **No desplegar funciones PL/pgSQL sin actualizar el array FUNCS de `database/setup_smartcset.sh`.**
- **No olvidar el EXCEPTION block** en funciones PL/pgSQL nuevas: siempre re-lanzar P0001 y llamar `smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint)` para OTHERS — nunca sin argumentos. Los 4 valores se capturan con `GET STACKED DIAGNOSTICS` dentro del mismo bloque EXCEPTION.
- **No commitear `.env`.** Está en `.gitignore`; usar `.env.example` para documentar variables.
- **No usar `exit` dentro de funciones de librería** salvo en middleware y guardianes de acceso que son parte del contrato de la función.
- **No confundir `fecha_insert` con `fec_insert`.** El proyecto usa `fec_` como prefijo consistentemente.
- **No cambiar el tipo de retorno de funciones PL/pgSQL sin actualizar los statements de `backend/core/prepare.php`.** Si una función retornaba `TEXT` y ahora retorna `VOID`, el `fetchColumn()` fallará.
- **No usar `$pdo->lastInsertId()` para sequences.** PostgreSQL no lo soporta; usar el `RETURNING` de la función PL/pgSQL.

---

## Cómo correr el proyecto localmente (paso a paso completo)

### 1. Configurar variables de entorno
```bash
cp .env.example .env
# Editar .env con las credenciales de PostgreSQL locales
# DB_NAME=db_smartcset2
# DB_USER=postgres
# DB_PASS=ander123
```

### 2. Instalar la base de datos
```bash
# PostgreSQL debe estar corriendo
bash database/setup_smartcset.sh
# O usar directamente el schema V.1.10:
psql -U postgres -d db_smartcset2 -f database/schema/script-BD-SMARTCSET\ V.1.10.sql
```

### 3. Levantar servidor de desarrollo

Apache debe estar corriendo (en Linux ya inicia con el sistema):
```bash
sudo systemctl start apache2
```

### 4. Acceder al sistema
- **URL**: `https://localhost/smartcset/`
- **Usuario admin**: `admin.smart` / `AdminSmart2026!`
- **Usuario portería**: `porteria` / `Porteria2026!`

### Notas importantes
- El document root es `frontend/web/public/` (servido vía `Alias /smartcset` en Apache)
- El punto de entrada es `frontend/web/public/index.php`
- Los symlinks `frontend/web/public/pages` → `../pages` y `frontend/web/public/routers` → `../../../backend/routers` son obligatorios — sin ellos las páginas y los endpoints dan 404
- `APP_BASE_PATH=smartcset` en `.env` es obligatorio con Apache bajo `/smartcset/`
- Todos los includes/requires deben ser relativos (nunca paths absolutos)

Tras el login exitoso, la sesión redirige a `/smartcset/pages/menu/menu_principal.php`.
