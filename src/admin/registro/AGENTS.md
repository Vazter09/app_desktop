# AGENTS.md — src/admin/registro/

## Propósito

Listado administrativo de personas registradas en el sistema. Permite filtrar por tipo (aprendiz, instructor, funcionario, contratista) y ver detalles/editar registros.

---

## Archivos y su función

### listado.php

Vista principal del listado de personas registradas. Interfaz con:
- Tabs o menú para seleccionar tipo de persona (aprendiz, instructor, funcionario, contratista)
- Tabla de personas del tipo seleccionado
- Links para editar/ver detalles
- Paginación opcional

**Espera:**
- Sesión activa con `$_SESSION['ind_usuario'] === true` (solo admin)
- Variables `$pdo` y prepared statements de `prepare.php`

**Parámetros GET:**
- `tipo=X` — tipo de persona (aprendiz, instructor, funcionario, contratista)
- `page=N` — página de paginación

**Emite:**
- Tabla HTML con lista de personas
- Links a formularios de edición

### listado_fragment.php

Fragmento HTML de la tabla de personas para carga AJAX parcial. Devuelve solo `<tbody>` con filas de personas, sin `<table>` ni estructura externa. Se usa cuando el usuario cambia de tipo sin recargar página completa.

**Parámetro POST:**
- `tipo` — tipo de persona a listar
- `page` (opcional) — página de paginación

**Retorna:**
- HTML de `<tr>` elementos con datos de personas

### config.php

Configuración específica del submódulo registro administrativo:
- Constantes de cantidad por página
- Mapeos de tipo a etiqueta/ícono
- Rutas a formularios de edición

---

## Flujo de uso

1. Admin abre `src/admin/registro/listado.php`
2. Por defecto muestra aprendices del listado
3. Admin hace click en tab "Instructores"
4. AJAX carga `listado_fragment.php?tipo=instructor`
5. `listado_fragment.php` consulta `tab_personas WHERE tipo='instructor'`
6. Devuelve HTML de tabla
7. JS reemplaza `<tbody>` con el nuevo contenido
8. Admin hace click en "Editar" de una persona
9. Redirige a `src/modulos/registro/forms/instructor.php?edit=id` o similar

---

## Dependencias

- Depende de `prepare.php` (crea `$pdo`)
- Depende de funciones de `lib/personas_list.php` para consultas
- Depende de formularios en `src/modulos/registro/forms/` para edición

---

## Convenciones específicas

- El fragmento `listado_fragment.php` devuelve solo `<tbody>` HTML, no JSON ni estructura completa
- La paginación es opcional; si no se implementa, mostrar todas las personas de un tipo
- Los links de edición deben apuntar a los formularios del módulo registro (`src/modulos/registro/forms/`)

---

## Qué NO tocar sin entender primero

- No cambiar el nombre de `listado_fragment.php` — JavaScript en `registro-listado-admin.js` lo busca por nombre exacto
- No retornar JSON desde `listado_fragment.php` — debe ser HTML puro, sin wrapper
- No hacer paginación server-side solo en AJAX — el GET inicial también necesita paginación
