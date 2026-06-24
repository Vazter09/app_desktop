# CLAUDE.md — SmartCSET

## Qué es SmartCSET

SmartCSET es un sistema de control de acceso y registro de personas para el SENA (Servicio Nacional de Aprendizaje de Colombia). Permite a la portería de un centro de formación SENA registrar el ingreso y la salida de visitantes, aprendices, instructores, funcionarios y contratistas. Además administra usuarios del sistema, menús de navegación con permisos por usuario, configuración visual corporativa y un módulo de registro de personas standalone.

El proyecto está escrito en PHP 8+ puro (sin Composer, sin autoloading PSR-4, sin framework) con PostgreSQL 14+ como único motor de base de datos. Toda la lógica de integridad y negocio crítica vive en funciones PL/pgSQL. PHP se encarga de la presentación, el enrutamiento y la autenticación de contraseñas (bcrypt via `password_verify`).

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

**Windows (PowerShell):**
```powershell
.\tools\start_dev.ps1
# Abre: http://localhost:8080/
```

**Linux/macOS (bash):**
```bash
bash scripts/dev/start_dev.sh
# Document root: frontend/web/public — http://localhost:8080/
```

El servidor PHP built-in es suficiente para desarrollo. No se necesita Apache ni Nginx.

---

## Arquitectura del proyecto

```
smartcset/
├── index.php               ← Login principal. Único punto de entrada público.
├── .env                    ← Variables de entorno (no commitear)
├── .env.example            ← Plantilla de variables de entorno
├── CLAUDE.md               ← Este archivo
├── AGENTS.md               ← Guía de agentes IA
├── SETUP_AUDIT.md          ← Auditoría de bugs en setup_smartcset.sh
│
├── css/                    ← 11 archivos CSS por módulo (no usar preprocesadores)
├── js/                     ← 20 archivos JS por módulo (vanilla JS + Bootstrap 5)
├── img/                    ← Logo institucional estático (img/logo_empresa.png)
├── public/
│   └── uploads/logos/      ← Logos subidos via configuración del sistema
├── storage/                ← Directorio de almacenamiento general
├── files/                  ← Archivos subidos por módulos
│
├── src/
│   ├── core/               ← Bootstrap central del sistema
│   │   ├── prepare.php     ← Conexión PDO + TODOS los prepared statements globales
│   │   ├── config.php      ← Define constantes DB_*, APP_ENV, etc. desde .env
│   │   ├── EnvLoader.php   ← Lector de .env a $_ENV y constantes
│   │   ├── AppConfig.php   ← Clase singleton: configuración de BD (tab_config_sistema)
│   │   ├── ErrorHandler.php ← Traductor SQLSTATE -> mensajes de usuario
│   │   ├── SecurityMiddleware.php ← Headers HTTP, prevención ataques básicos
│   │   ├── LogoUpload.php  ← Subida de logo a public/uploads/logos/
│   │   ├── ConfigSistemaDefaults.php ← Valores por defecto de tab_config_sistema
│   │   └── helpers.php     ← Funciones globales: getIcon, renderPageFlash, smartcsetProjectAssetHref, etc.
│   │
│   ├── layout/             ← Partials HTML compartidos por todos los módulos
│   │   ├── head.php        ← <head> con Bootstrap, CSS globales, theme_vars.php
│   │   ├── sidebar.php     ← Sidebar de navegación dinámico (usa $pdo y $stmt_menu)
│   │   ├── topbar.php      ← Barra superior con usuario activo
│   │   ├── footer.php      ← Cierre HTML + JS globales (Bootstrap, smartcset-*.js)
│   │   ├── theme_vars.php  ← Inyecta CSS custom properties desde AppConfig
│   │   ├── ui_kit.php      ← Kit UI utilitario
│   │   └── partials/       ← Subpartials (ej. modal de confirmación)
│   │
│   ├── auth/               ← Autenticación fuera del login principal
│   │   ├── logout.php      ← Destruye sesión y redirige a index.php
│   │   ├── recuperar.php   ← Formulario de recuperación de contraseña
│   │   └── cambiar_clave.php ← Cambio de contraseña autenticado
│   │
│   ├── menu/               ← CRUD de menús y asignación de permisos
│   │   ├── menu_principal.php  ← Dashboard post-login (cards con módulos del usuario)
│   │   ├── menus.php       ← CRUD de tab_menus (solo admin)
│   │   ├── menu_usuarios.php   ← Asignación de menús por usuario
│   │   ├── copiar_menu_usuarios.php ← Copiar perfil de menús entre usuarios
│   │   ├── obtener_menus_usuario.php ← Endpoint AJAX menús de usuario
│   │   ├── procesar_copiar_perfil.php ← Procesa copia de perfil
│   │   ├── procesar_perfil.php ← Procesa asignación de menús
│   │   └── procesar_permiso.php ← Procesa toggle de permiso individual
│   │
│   ├── usuarios/           ← CRUD de usuarios del sistema
│   │   └── usuarios.php    ← CRUD completo (solo admin): lista, crea, edita usuarios
│   │
│   ├── admin/
│   │   ├── configuracion.php   ← Panel de configuración del sistema (colores, logo, módulos)
│   │   └── personas/           ← Listados admin por tipo + config del módulo registro
│   │       ├── config.php
│   │       ├── aprendices/, instructores/, funcionarios/, contratistas/
│   │       └── lib/            ← listado_index.php, fragmentos AJAX
│   │
│   └── modulos/            ← Módulos funcionales del sistema
│       ├── porteria/       ← Control de acceso físico al centro
│       │   ├── ingreso/    ← Registro de ingresos
│       │   │   ├── index.php   ← Vista: formulario + lista ingresos de hoy
│       │   │   ├── procesar.php ← Procesador POST: llama ingresoRegistrarManual()
│       │   │   └── consultar.php ← Endpoint AJAX: busca persona por documento
│       │   ├── salida/     ← Registro de salidas
│       │   │   ├── index.php   ← Vista: formulario + lista salidas de hoy
│       │   │   ├── procesar.php ← Procesador POST: llama salidaRegistrarManual()
│       │   │   └── consultar.php ← Endpoint AJAX: busca ingreso abierto
│       │   └── lib/        ← Lógica compartida de portería
│       │       ├── init.php    ← Bootstrap del módulo portería
│       │       ├── acceso_documento.php ← Normalización de documento (solo dígitos, max 10)
│       │       ├── acceso_parse_captura.php ← Parser PDF417 cédula colombiana
│       │       ├── porteria_consulta.php ← Búsqueda persona + ingreso abierto
│       │       ├── porteria_foto.php ← Guardado de foto en registro
│       │       ├── porteria_modos_ui.php ← Partial HTML: barra modos escáner/foto
│       │       ├── ingresos_registro.php ← Función ingresoRegistrarManual()
│       │       └── salidas_registro.php  ← Función salidaRegistrarManual()
│       │
│       ├── registro/       ← Módulo de registro standalone de personas
│       │   ├── index.php   ← Panel de selección de tipo de persona
│       │   ├── login.php   ← Login standalone (usr_registro / pass_registro_hash)
│       │   ├── init.php    ← Bootstrap del módulo registro (head, header, footer)
│       │   ├── ajax_ciudades.php ← AJAX: ciudades por departamento
│       │   ├── ajax_personas.php ← AJAX: búsqueda de personas
│       │   ├── forms/      ← Formularios por tipo de persona
│       │   │   ├── aprendiz.php
│       │   │   ├── instructor.php
│       │   │   ├── funcionario.php
│       │   │   ├── contratista.php
│       │   │   └── persona.php  ← Formulario genérico de persona
│       │   └── lib/
│       │       ├── access.php   ← Control de acceso standalone del módulo
│       │       ├── catalogos.php ← Funciones: registroGet* (tipos doc, dptos, fichas, etc.)
│       │       └── personas_list.php ← Funciones de listado de personas
│       │
│       └── entradas/       ← CRUD de puertas/entradas del centro
│           ├── index.php   ← CRUD de tab_entradas_centro
│           └── init.php    ← Bootstrap del módulo entradas
│
├── database/
│   ├── setup_smartcset.sh  ← Instalador completo (ver "Bugs conocidos" más abajo para pendientes)
│   ├── bootstrap_modulo_acceso.sql ← Script de bootstrap del módulo acceso
│   ├── schema/             ← Scripts de schema por versión
│   │   ├── script-BD-SMARTCSET V.1.7.sql   ← ACTIVO (usar este)
│   │   └── history/        ← Versiones históricas (V.1.0 a V.1.3)
│   ├── functions/          ← Funciones PL/pgSQL organizadas por dominio
│   │   ├── _helpers/       ← Helpers de excepciones (desplegar PRIMERO)
│   │   ├── acceso/         ← Menús, usuarios, sesiones
│   │   ├── porteria/       ← Ingreso y salida de personas
│   │   ├── config/         ← Configuración del sistema
│   │   └── carga/          ← Carga de reportes SENA (DF-49, PE-04, juicios)
│   ├── migrations/         ← 15 migraciones SQL numeradas por propósito
│   └── seeds/              ← Datos iniciales de desarrollo
│
├── tools/                  ← Scripts de deploy y diagnóstico
│   ├── start_dev.ps1       ← Servidor PHP desarrollo (Windows)
│   ├── setup_db.ps1        ← Setup BD desde PowerShell
│   ├── deploy_funciones_acceso.ps1  ← Deploy funciones acceso a BD
│   ├── deploy_funciones_ingresos.ps1 ← Deploy funciones portería a BD
│   ├── diagnose_bd.php     ← Diagnóstico de conectividad y estado BD
│   └── setup_production.sh ← Script de instalación en producción
│
└── docs/                   ← Documentación interna del proyecto
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
// Patrón desde src/core/
require_once('src/core/prepare.php');   // desde raíz del proyecto

// Patrón desde src/modulos/porteria/ingreso/
require_once __DIR__ . '/../lib/init.php';   // relativo al archivo actual

// Patrón desde src/modulos/porteria/lib/init.php:
require_once dirname(__DIR__, 3) . '/core/prepare.php';  // cuenta directorios hacia arriba

// NUNCA usar paths absolutos del sistema de archivos
```

**Gestión de sesión:**
- `$_SESSION['id_usuario']` — ID del usuario logueado (string, TEXT en BD)
- `$_SESSION['nom_usuario']` — Nombre completo
- `$_SESSION['ind_usuario']` — booleano: es administrador
- `$_SESSION['flash_msg']` + `$_SESSION['flash_tipo']` — mensajes flash entre redirects
- `$_SESSION['registro_authenticated']` — sesión standalone del módulo registro

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
// Desde cualquier página PHP, calcular el prefijo correcto hacia la raíz del proyecto:
$smartcset_asset_href = smartcsetProjectAssetHref();
// Resultado: '../../' para src/modulos/porteria/ingreso/, '../' para src/menu/, etc.

// Uso:
echo $smartcset_asset_href . 'css/modulos_ingresos.css';
echo $smartcset_asset_href . 'js/ingresos.js';
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
BEGIN
    -- 1. Validaciones con smartcset_raise_validacion()
    -- 2. Reglas de negocio con smartcset_raise_negocio()
    -- 3. Operación DML
    RETURN 'OK';  -- o RETURN id_nuevo;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN RAISE;
    WHEN OTHERS THEN PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
```

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

La conexión PDO se crea en `src/core/prepare.php` y está disponible como variable global `$pdo` en cualquier script que incluya ese archivo. No crear conexiones adicionales.

```php
// En cualquier módulo que ya hizo require_once de prepare.php o init.php:
$stmt = $pdo->prepare("SELECT ... FROM tab_personas WHERE id_persona = ?::NUMERIC");
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

6. Si la función es llamada desde PHP, agregar el prepared statement a `src/core/prepare.php`

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

Ver `SETUP_AUDIT.md` para el análisis histórico original (V.1.5/V.1.6). Estado actualizado al 2026-06-13:

### Bug 1: schema desactualizado en setup.sh — ✅ RESUELTO
El instalador usa `script-BD-SMARTCSET V.1.7.sql` (esquema activo actual).

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

### Deuda técnica adicional

- `src/modulos/registro/forms/` hace INSERTs SQL directos en lugar de llamar funciones PL/pgSQL — inconsistente con el patrón del resto del sistema
- El módulo de registro carece de statement preparado en `prepare.php` porque usa SQL directo en los formularios

---

## Lo que NO hacer

- **No introducir Composer ni autoloading PSR-4.** Todo se carga con `require_once`. Si se necesita una nueva clase, agregarla al directorio correspondiente y cargarla explícitamente.
- **No usar ninguna función de autoload personalizada.** No hay `spl_autoload_register`.
- **No mockear la base de datos en tests.** No existe capa de abstracción para mocking; la BD de test debe ser PostgreSQL real.
- **No crear conexiones PDO adicionales.** Usar la conexión `$pdo` de `prepare.php`.
- **No usar variables superglobales sin sanear.** Siempre `htmlspecialchars()` al hacer echo, y prepared statements para SQL.
- **No saltarse el patrón de prepared statements.** Nunca concatenar input de usuario en SQL, ni siquiera con `intval()`.
- **No agregar lógica de negocio en las vistas (index.php).** Las vistas deben leer variables ya preparadas; la lógica va en `procesar.php` o en `lib/`.
- **No codear colores corporativos directamente en CSS/HTML.** Usar las variables CSS `var(--v-oscuro)`, `var(--v-oliva)`, o las variables del sistema de temas.
- **No crear nuevas tablas sin migración SQL.** Cualquier cambio de schema va en `database/migrations/`.
- **No desplegar funciones PL/pgSQL sin actualizar el array FUNCS de setup_smartcset.sh.**
- **No olvidar el EXCEPTION block** en funciones PL/pgSQL nuevas: siempre re-lanzar P0001 y llamar `smartcset_handle_sql_error()` para OTHERS.
- **No commitear `.env`.** Está en `.gitignore`; usar `.env.example` para documentar variables.
- **No usar `exit` dentro de funciones de librería** salvo en `registroRequireAccess()` y similares guardianes de acceso que son parte del contrato de la función.
- **No confundir `fecha_insert` con `fec_insert`.** El proyecto usa `fec_` como prefijo consistentemente.
- **No cambiar el tipo de retorno de funciones PL/pgSQL sin actualizar los statements de PHP.** Si una función retornaba `TEXT` y ahora retorna `VOID`, el `fetchColumn()` fallará.
- **No usar `$pdo->lastInsertId()` para sequences.** PostgreSQL no lo soporta; usar el `RETURNING` de la función PL/pgSQL.

---

## Cómo correr el proyecto localmente (paso a paso completo)

```powershell
# 1. Ubicarse en el directorio del proyecto
cd C:\ruta\a\smartcset

# 2. Configurar variables de entorno
Copy-Item .env.example .env
# Editar .env con las credenciales de PostgreSQL locales

# 3. Instalar la BD (requiere psql en PATH y PostgreSQL corriendo)
bash scripts/dev/start_dev.sh
# Abre: http://localhost:8080/
# Login: admin.smart / AdminSmart2026!
```

Si PostgreSQL no tiene `psql` en PATH en Windows, agregar el bin de PostgreSQL:
```powershell
$env:PATH += ";C:\Program Files\PostgreSQL\14\bin"
```

Tras el login exitoso, la sesión redirige a `src/menu/menu_principal.php` que muestra un dashboard con las tarjetas de módulos asignados al usuario.
