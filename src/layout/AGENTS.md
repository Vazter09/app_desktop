# AGENTS.md — src/layout/

## Propósito

Sistema de partials HTML compartidos por todas las páginas internas (post-login). Estos archivos forman el "esqueleto" visual de la aplicación: barra superior, menú lateral, pie de página, y variables CSS de tema. Ninguno de estos archivos debe ser visitado directamente; son incluidos desde las vistas.

---

## Archivos y su función

### head.php

Renderiza el `<!DOCTYPE html>`, `<head>` con metadatos, CSS globales (Bootstrap, estilos del proyecto), y variables CSS de tema. Abre `<body>` y `<div class="app-wrapper">`.

**Espera variables:**
- `$page_title` (opcional) — título de la página para `<title>` y breadcrumb
- `$extra_stylesheets` (opcional) — array de rutas CSS adicionales

**Emite:**
- `<meta>` tags (charset, viewport, X-UA-Compatible)
- Bootstrap 5.3 vía CDN
- Bootstrap Icons vía CDN
- CSS globales: `layout.css`, `style_crud.css`, `components.css`, `style.css`
- `theme_vars.php` (variables CSS inyectadas)
- `<body class="...">` y `<div class="app-wrapper">`

### sidebar.php

Barra lateral izquierda: logo SmartCSET, navegación dinámica construida desde `obtenerMenusUsuario()`, soporte de submenús jerárquicos, item de Inicio fijo y Salir dinámico.

**Espera variables:**
- `$pdo` — conexión a BD (ya disponible tras `prepare.php`)
- `$_SESSION['id_usuario']` — usuario logueado

**Depende de:**
- Función global `obtenerMenusUsuario(PDO $pdo, string $id_usuario)`
- Función global `getIcon(string $nombre)`

**Emite:**
- Logo y navegación dinámica en `<aside class="sidebar">`
- Menús jerárquicos con submenús

### topbar.php

Barra superior: toggle mobile sidebar, breadcrumb (Inicio > página actual), nombre de usuario e icono, botón de cierre de sesión. Abre `<div class="content-wrapper">` y `<main class="main-content">`.

**Espera variables:**
- `$page_title` (opcional) — última parte del breadcrumb
- `$_SESSION['id_usuario']`, `$_SESSION['nom_usuario']` — usuario logueado

**Emite:**
- `<header class="topbar">`
- Breadcrumb
- Nombre del usuario y logout link
- Abre `<div class="content-wrapper">` y `<main class="main-content">`

### footer.php

Cierre de `</main>`, `</div>`, `</div>`. Contenedor de toasts. Modal de confirmación. Carga de JS globales: `smartcset-forms.js`, `smartcset-toast.js`, `smartcset-confirm.js`, `layout.js`. Opcionalmente `menu_calculadora.js` y `$extra_js`.

**Espera variables:**
- `$include_calculator` (opcional, booleano) — si incluir la calculadora flotante
- `$extra_js` (opcional) — array de rutas JS adicionales

**Emite:**
- Cierre de HTML: `</main></div></div></body></html>`
- Contenedor `<div id="toast-container">` para notificaciones
- Modal `#smartcset-confirm-modal` para confirmaciones
- Script tags para JS globales
- Script tags para JS adicionales

### theme_vars.php

Emite una etiqueta `<style>` con variables CSS custom properties (--v-oscuro, --v-oliva, --cyan, etc.) leídas desde `AppConfig`. Debe ser incluido DENTRO de `<head>` para que los estilos globales puedan usar esas variables.

**Espera variables:**
- Clase `AppConfig` ya cargada (se llamó `AppConfig::boot()`)

**Emite:**
- `<style>:root { --v-oscuro: #...; --v-oliva: #...; --cyan: ...; ... }</style>`

### ui_kit.php

Kit UI utilitario con componentes Bootstrap comunes para páginas standalone (login, recuperar). Generalmente no se usa en vistas internas (que incluyen head/sidebar/topbar/footer).

### partials/ui_confirm_modal.php

HTML del modal de confirmación universal usado por `smartcset-confirm.js`. No se incluye directamente; se incluye desde `footer.php`.

---

## Flujo de una página interna típica

```php
<?php
require_once 'src/core/prepare.php';  // Crea $pdo, $stmt_*, AppConfig

// Validar sesión
if (!isset($_SESSION['id_usuario'])) {
    header('Location: index.php');
    exit;
}

$page_title = "Mi Página";
$extra_stylesheets = ['css/custom.css'];

include 'src/layout/head.php';         // HTML hasta <main>
include 'src/layout/sidebar.php';      // Sidebar izquierda
include 'src/layout/topbar.php';       // Topbar superior

// Contenido principal
echo "<div class='container'>";
echo "...";
echo "</div>";

$include_calculator = false;
$extra_js = ['js/custom.js'];
include 'src/layout/footer.php';       // Cierre HTML + JS
?>
```

---

## Convenciones específicas

- **Orden de inclusión es obligatorio:** head → sidebar → topbar → footer
- **No incluir `prepare.php` desde aquí.** Asumir que ya fue incluido por el script que incluye estos partials
- **Las variables CSS deben venir de `theme_vars.php`** — nunca codear colores corporativos directamente en HTML/CSS
- **No agregar lógica de negocio aquí.** Los partials solo renderizan HTML; la lógica va en el script que los incluye
- **Los assets deben ser rutas relativas.** Si el partial se incluye desde diferentes profundidades, recalcular el prefijo o pasar como parámetro

---

## Dependencias

- Todos los partials dependen de que `prepare.php` haya sido incluido antes (vía el script que los incluye)
- `sidebar.php` depende de `obtenerMenusUsuario()` de `helpers.php` y de variable global `$pdo`
- `theme_vars.php` depende de clase `AppConfig` ya inicializada
- `footer.php` depende de archivos JS: `smartcset-toast.js`, `smartcset-confirm.js`, `layout.js`

---

## Qué NO tocar sin entender primero

- No cambiar el orden de inclusión de partials; CSS y JS se cargan en orden y las dependencias importan
- No asumir que `$pdo` existe en `sidebar.php` si el script que lo incluyó no incluyó `prepare.php` primero
- No agregar lógica SQL a los partials; si necesitas datos, prepararlos en el script y pasar como variable
- No incluir `theme_vars.php` fuera de `<head>`; necesita ser antes de cualquier CSS que use las variables
- No cambiar `<div class="app-wrapper">` a algo más — JavaScript de `layout.js` espera esa estructura exacta
