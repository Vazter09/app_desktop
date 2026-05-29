# AGENTS.md — database/functions/acceso/menus/

## Propósito

10 funciones para CRUD de menús del sistema y asignación de permisos a usuarios. Garantizan integridad referencial de la jerarquía de menús.

---

## Funciones

1. `fun_insert_tab_menus` — crear menú con validación de padre y nombre
2. `fun_update_tab_menus` — actualizar menú (nombre, padre, ruta)
3. `fun_delete_tab_menus` — eliminar menú (valida que no tenga hijos ni usuarios)
4. `fun_insert_menu_usuarios` — asignar menú a usuario (idempotente)
5. `fun_delete_perfil_usuario` — borrar TODOS los menús de UN usuario
6. `fun_delete_perfil_usuarios` — borrar UN menú de TODOS los usuarios (ausente del instalador)
7. `fun_trigger_desasignar_menu` — trigger automático: al eliminar menú, desasigna de usuarios
8. `fun_trigger_menu` — trigger: asigna menú '9' a nuevos usuarios
9. `fun_trigger_menu_admin` — trigger: asigna todos los menús a administradores
10. `fun_tab_menu_usuarios` — query: retorna menús asignados a un usuario (ausente del instalador)

---

## Estado de despliegue

**Incluidas en setup.sh:**
- fun_insert_tab_menus
- fun_update_tab_menus
- fun_delete_tab_menus
- fun_insert_menu_usuarios
- fun_delete_perfil_usuario
- fun_trigger_desasignar_menu

**AUSENTES del setup.sh (BUG):**
- fun_delete_perfil_usuarios
- fun_tab_menu_usuarios
- fun_trigger_menu
- fun_trigger_menu_admin

---

## Convenciones

- `nom_programa = 'no_aplica'` indica menú padre (no tiene página)
- `nom_programa = 'Exit'` es logout especial
- Jerárquía máximo 2 niveles (padre → hijo, no más)
- `ind_id_padre = '00'` indica menú raíz (legacy `'0'` se migra con `update_menu_padre_raiz_00.sql`)

---

## Dependencias

- Dependen de `_helpers/smartcset_raise.sql`
- Operan sobre `tab_menus` y `tab_menu_usuarios`

---

## Qué NO tocar sin entender primero

- Los 4 triggers son críticos — removerlos rompe sincronización automática
- La validación de padre es obligatoria — previene orfandades
