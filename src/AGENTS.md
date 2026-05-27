# AGENTS.md — src/

## Propósito

Este directorio contiene todo el código PHP de presentación, lógica de aplicación y módulos funcionales del sistema SmartCSET. No contiene base de datos (eso está en `../database/`) ni assets estáticos (eso está en `../css/` y `../js/`). El punto de entrada es `index.php` en la raíz del proyecto.

---

## Estructura general

```
src/
├── core/                ← Bootstrap central (prepare.php, AppConfig, ErrorHandler)
├── layout/              ← Partials HTML compartidos (head, sidebar, topbar, footer)
├── auth/                ← Autenticación secundaria (logout, recuperar, cambiar clave)
├── menu/                ← CRUD de menús y asignación de permisos por usuario
├── usuarios/            ← CRUD de usuarios del sistema
├── admin/               ← Administración (configuración, listados administrativos)
└── modulos/             ← Módulos funcionales de negocio
    ├── porteria/        ← Control de acceso físico (ingreso + salida)
    ├── registro/        ← Registro de personas (módulo standalone)
    └── entradas/        ← CRUD de puertas del centro
```

---

## Patrón de inicialización

Cada script PHP en `src/` sigue este patrón:

```php
<?php
// 1. Include del core (o include de init.php del módulo que a su vez incluye core)
require_once 'src/core/prepare.php';  // si está en la raíz
// O:
require_once __DIR__ . '/../../core/prepare.php';  // si está en subdirectorio

// 2. Include de ErrorHandler si va a capturar excepciones
require_once 'src/core/ErrorHandler.php';

// 3. Include de helpers
require_once 'src/core/helpers.php';

// 4. La sesión ya está iniciada en prepare.php

// 5. Validar que existe sesión activa (si la página requiere autenticación)
if (!isset($_SESSION['id_usuario'])) {
    header('Location: index.php');
    exit;
}

// 6. Resto del código
?>
```

---

## Variables disponibles tras incluir prepare.php

```php
$pdo                    // Conexión PDO a PostgreSQL
$stmt_*                 // Decenas de prepared statements
AppConfig::*            // Clase singleton de configuración
ErrorHandler::*         // Clase de traducción de errores
```

## Convenciones por subdirectorio

### src/core/
- Bootstrap central
- `prepare.php` es el archivo más crítico — incluir siempre primero
- `AppConfig::boot($pdo)` se llama automáticamente en `prepare.php`
- No agregar lógica de negocio aquí; solo bootstrap y configuración

### src/layout/
- Partials HTML incluibles desde cualquier página interna
- Cada partial espera variables PHP específicas seteadas
- El orden de inclusión es: `head.php` → `sidebar.php` → `topbar.php` → `footer.php`
- No incluir `prepare.php` desde aquí; asumirlo ya incluido

### src/auth/
- Páginas que no requieren sesión activa (logout la destruye)
- `recuperar.php` genera clave temporal
- `cambiar_clave.php` requiere sesión activa

### src/menu/
- CRUD de menús (`tab_menus`)
- Asignación de permisos a usuarios (`tab_menu_usuarios`)
- Procesadores AJAX que retornan JSON
- El dashboard `menu_principal.php` es la primera página post-login

### src/usuarios/
- CRUD de usuarios (`tab_usuarios`)
- Solo accesible a administradores
- Las contraseñas se hashean con `password_hash($pass, PASSWORD_BCRYPT)`

### src/admin/
- Configuración del sistema (`tab_config_sistema`)
- Listados administrativos de datos
- Solo accesible a administradores

### src/modulos/
- Módulos autónomos con su propio `init.php`
- Cada módulo puede tener su propia sesión (como `registro/`)
- Portería, Registro y Entradas son los tres módulos principales

---

## Dependencias críticas

- Todos los scripts dependen de `src/core/prepare.php` (directa o indirectamente)
- El sidebar depende de `obtenerMenusUsuario()` que usa `$pdo`
- Los formularios dependen de prepared statements en `prepare.php`
- Los módulos `porteria/` y `registro/` tienen sus propios `init.php` con bootstraps anidados

---

## Qué NO tocar sin entender primero

- No cambiar la estructura de inclusiones en `prepare.php`; el orden de inicialización es crítico
- No crear `require` circulares (A incluye B, B incluye A)
- No asumir que `$pdo` existe si no se incluyo `prepare.php`
- No asumir que `$_SESSION['id_usuario']` existe en páginas públicas
- No crear funciones en helpers.php que devuelvan HTML; eso va en partials de `layout/`
