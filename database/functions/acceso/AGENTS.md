# AGENTS.md — database/functions/acceso/

## Propósito

Funciones de gestión de acceso del sistema: autenticación de usuarios, gestión de menús (permisos), y sesiones activas.

---

## Subdirectories

### menus/
10 funciones para CRUD de menús y asignación de permisos a usuarios. Ver `menus/AGENTS.md`.

### usuarios/
6 funciones para CRUD de usuarios del sistema y validaciones. Ver `usuarios/AGENTS.md`.

### sesiones/
1 función para registrar/actualizar sesiones activas. Ver `sesiones/AGENTS.md`.

---

## Dependencias de despliegue

Deben desplegarse DESPUÉS de `_helpers/` pero ANTES de las funciones de portería.

---

## Convenciones compartidas

Todas las funciones de acceso:
- Operan sobre tablas `tab_usuarios`, `tab_menus`, `tab_menu_usuarios`, `tab_sesiones`
- Usan excepciones de `_helpers/` para errores
- Requieren auditoría (`usr_insert`, `fec_insert`, etc.) en operaciones de modificación
- Retornan TEXT (nunca VOID) para compatibilidad con `fetchColumn()` de PHP

---

## Qué NO tocar sin entender primero

- El orden de despliegue: `_helpers` → `acceso/*` → resto
- Las relaciones FK entre `tab_usuarios` → `tab_menu_usuarios` ← `tab_menus`
