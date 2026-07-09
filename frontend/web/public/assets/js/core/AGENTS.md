# AGENTS.md — js/

## Propósito

20 archivos JavaScript que manejan interactividad del lado cliente. Vanilla JS sin npm, webpack ni bundler.

---

## Archivos globales (cargan todos los scripts internos)

| Archivo | Propósito |
|---|---|
| `smartcset-toast.js` | Lee `#page-flash-data` y muestra toast Bootstrap |
| `smartcset-forms.js` | Detección de cambios sin guardar en formularios |
| `smartcset-confirm.js` | Modal de confirmación universal (data-smart-confirm) |
| `layout.js` | Toggle sidebar, overlay mobile, persistencia de colapso |
| `common.js` | Funciones utilitarias compartidas |

---

## Archivos por módulo

| Archivo | Módulo | Propósito |
|---|---|---|
| `menus.js` | menu | CRUD de menús |
| `menu_usuarios.js` | menu | Asignación de menús a usuarios |
| `copiar_menu_usuarios.js` | menu | Copia de perfil |
| `menu_calculadora.js` | menu | Calculadora flotante del dashboard |
| `usuarios.js` | usuarios | CRUD de usuarios |
| `entradas.js` | entradas | CRUD de puertas |
| `ingresos.js` | porteria | Formulario ingreso + tabla ingresos hoy |
| `salidas.js` | porteria | Formulario salida + tabla salidas hoy |
| `porteria-captura.js` | porteria | Modo escáner: enfoque campo documento |
| `porteria-medios.js` | porteria | Modo foto: captura cámara |
| `smartcset-listado.js` | global | Filtros GET + paginación AJAX en listados (`SmartcsetListado`) |
| `siem_dashboard.js` | SIEM | Auto-refresh del Panel de Control (polling 20s vía `SmartcsetListado.loadIntoHost`) |
| `personas-listado-admin.js` | admin/personas | Navegación AJAX entre listados por tipo |
| `registro-listado-admin.js` | (legacy) | Sustituido por personas-listado-admin.js |
| `registro-theme-toggle.js` | registro | Cambio tema claro/oscuro |
| `logo-upload.js` | admin | Subida drag-and-drop de logo |
| `login.js` | index.php | Comportamiento pantalla login |
| `qbe_functions.js` | varios | Utilidades de búsqueda tipo QBE |

---

## Contrato entre frontend y backend

**Flash messages:** `<div id="page-flash-data" data-message="..." data-type="success|danger|warning|info">`
- Leído por `smartcset-toast.js`
- Convertido a toast Bootstrap

**Confirmación:** `<button data-smart-confirm="¿Estás seguro?">`
- Leído por `smartcset-confirm.js`
- Modal universal antes de DELETE

**AJAX endpoints:** POST a `procesar_*.php` o `ajax_*.php`
- Respuestas JSON con `{ status, message }`
- Errores JSON con `{ error, message }`

---

## Convenciones

- **Sin framework:** puro JavaScript, sin jQuery/Vue/React
- **Sin bundler:** importar archivos via `<script>` en `footer.php`
- **Sin dependencias npm:** todo está en el repositorio
- **Nombres por módulo:** `ingresos.js` para porteria/ingreso, `usuarios.js` para usuarios, etc.

---

## Dependencias

- Todos dependen de Bootstrap 5.3 via CDN (para clase tooltips, modal, etc.)
- Los módulos dependen de sus CSS correspondientes cargados en `head.php`

---

## Qué NO tocar sin entender primero

- No agregar dependencias npm — el proyecto no tiene build step
- No usar ES6 modules (import/export) — cargar todo via `<script>`
- No minificar — los archivos se sirven tal cual
- El contrato de `#page-flash-data` es crítico — `smartcset-toast.js` lo depende
