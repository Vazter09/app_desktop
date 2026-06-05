# AGENTS.md — src/menu/

## Propósito

Módulo de gestión de menús del sistema y asignación de permisos por usuario. Incluye el dashboard principal post-login que muestra los módulos disponibles para el usuario.

---

## Archivos y su función

### menu_principal.php

Dashboard operativo post-login: KPIs de portería (ingresos/salidas/personas dentro), actividad reciente, acciones rápidas según menús asignados, y avisos admin (sesiones activas, módulo registro). La navegación completa sigue en el sidebar (`obtenerMenusUsuario()`).

**Espera:**
- Sesión activa (`$_SESSION['id_usuario']`)
- Variables `$pdo` y statements `$stmt_list_ingresos_hoy`, `$stmt_list_salidas_hoy`, `$stmt_list_sesiones_activas`

**Emite:**
- Página completa con head/sidebar/topbar/footer
- Sección `.dashboard-*` en `css/layout.css` (sin duplicar cards de módulos)

### menus.php

CRUD del catálogo de menús (`tab_menus`): alta, edición y eliminación de items del menú del sistema. Solo accesible a administradores. Usa prepared statements `$stmt_ins_menu`, `$stmt_upd_menu`, `$stmt_del_menu`.

**Parámetros:**
- GET `action=view` — lista todos los menús
- GET `action=edit&id=XXX` — muestra formulario de edición
- POST `action=save` — procesa inserción/actualización

**Depende de:**
- Funciones PL/pgSQL: `fun_insert_tab_menus`, `fun_update_tab_menus`, `fun_delete_tab_menus`

### menu_usuarios.php

Asignación/desasignación de accesos: matriz de menús por usuario. Vista con tabla de usuarios vs menús, checkboxes para indicar asignación. Envía cambios via AJAX a `procesar_perfil.php`.

**Interacción:**
- GET: muestra matriz
- Clicks en checkbox envían AJAX a `procesar_perfil.php`

### copiar_menu_usuarios.php

Vista para copiar el perfil de accesos de un usuario a otro. Formularios desplegables para seleccionar usuario origen y destino. Procesa via AJAX a `procesar_copiar_perfil.php`.

### obtener_menus_usuario.php

Endpoint AJAX que devuelve los menús asignados a un usuario en JSON. Usado por `menu_usuarios.js` para actualizaciones parciales sin recargar página.

**Parámetro:**
- POST `id_usuario=XXX`

**Retorna:**
- JSON: `{ "menus": [ { "id_menu": "...", "nom_menu": "...", "asignado": true/false }, ... ] }`

### procesar_permiso.php

Procesa el toggle de un permiso individual (asignar/desasignar un menú a un usuario). Endpoint AJAX que retorna JSON con status.

**Parámetros POST:**
- `id_usuario` — usuario objetivo
- `id_menu` — menú a asignar/desasignar
- `asignar` — true/false

**Retorna:**
- JSON: `{ "status": "ok", "message": "..." }` o error

### procesar_perfil.php

Procesa la asignación masiva de menús (perfil completo) a un usuario. Endpoint AJAX que borra todos los menús del usuario y luego asigna los nuevos.

**Parámetros POST:**
- `id_usuario` — usuario objetivo
- `menus[]` — array de IDs de menú a asignar

**Retorna:**
- JSON: `{ "status": "ok" }` o error

### procesar_copiar_perfil.php

Procesa la copia del perfil de accesos entre dos usuarios. Lee todos los menús del usuario origen y los asigna al usuario destino.

**Parámetros POST:**
- `usuario_origen` — usuario del cual copiar
- `usuario_destino` — usuario al cual pegar

**Retorna:**
- JSON: `{ "status": "ok", "menus_copiados": N }` o error

---

## Convenciones específicas

- `nom_programa` en `tab_menus` es la ruta física del archivo PHP desde la raíz del proyecto: `src/modulos/porteria/ingreso/index.php`
- `'no_aplica'` en `nom_programa` indica que el menú es padre (no tiene página propia)
- `'Exit'` es valor especial que el sidebar convierte en enlace de logout
- Los procesadores AJAX (`procesar_*.php`) retornan JSON, nunca HTML
- Los `$stmt_*` son variables globales de `prepare.php`; no crear nuevos statements

---

## Dependencias

- Todos los scripts dependen de `prepare.php` (crea `$pdo` y statements)
- `menu_principal.php` depende de `obtenerMenusUsuario()` de `helpers.php`
- `menus.php` depende de funciones PL/pgSQL: `fun_insert_tab_menus`, `fun_update_tab_menus`, `fun_delete_tab_menus`
- Los procesadores dependen de funciones PL/pgSQL: `fun_insert_menu_usuarios`, `fun_delete_perfil_usuario`, etc.
- `menu_usuarios.js` en cliente depende de `procesar_permiso.php` y `obtener_menus_usuario.php` existentes

---

## Qué NO tocar sin entender primero

- No cambiar `'no_aplica'` a NULL en `nom_programa` para menús padre — el sidebar y helpers.php usan `strcasecmp($prog, 'no_aplica')` para detectar menús padre
- No permitir que un usuario no-admin vea o edite menús — agregar validación `if (!$_SESSION['ind_usuario']) exit;` en todas las vistas
- No crear ciclos en la jerarquía de menús (padre A → B → A) — agregar validación en `fun_insert_tab_menus` en PostgreSQL
- No confundir `fun_delete_perfil_usuario.php` (singular, borra menús de UN usuario) con `fun_delete_perfil_usuarios.sql` (plural, borra UN menú de TODOS los usuarios) — son funciones diferentes
- No olvidar que la tabla `tab_menu_usuarios` tiene constraint UNIQUE(id_usuario, id_menu) — las inserciones duplicadas fallan silenciosamente con `ON CONFLICT DO NOTHING` en PostgreSQL
