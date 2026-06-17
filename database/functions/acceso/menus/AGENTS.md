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
6. `fun_delete_perfil_usuarios` — borrar UN menú de TODOS los usuarios (ausente del instalador, pendiente — ver nota E7)
7. `fun_trigger_desasignar_menu` — trigger automático: al eliminar menú, desasigna de usuarios
8. `fun_trigger_menu` — trigger: asigna menú '9' a nuevos usuarios
9. `fun_trigger_menu_admin` — trigger: asigna todos los menús a administradores
10. `fun_tab_menu_usuarios` — archivo legacy, NO desplegable (ver nota E7)

---

## Estado de despliegue

**Incluidas en setup.sh:**
- fun_insert_tab_menus
- fun_update_tab_menus
- fun_delete_tab_menus
- fun_insert_menu_usuarios
- fun_delete_perfil_usuario
- fun_trigger_desasignar_menu
- fun_trigger_menu
- fun_trigger_menu_admin

**AUSENTE del setup.sh (pendiente):**
- fun_delete_perfil_usuarios — su descripción no coincide claramente con su implementación real;
  requiere análisis propio antes de decidir si se agrega a `FUNCS` (fuera del alcance de E7)

> **Nota (E7, 2026-06-13):** `fun_tab_menu_usuarios.sql` **NO debe agregarse a `FUNCS`**. Contiene
> versiones legacy de `fun_insert_menu_usuarios` y `fun_delete_perfil_usuario` (parámetros `wid_usuario`/
> `wid_menu`, sin validación de existencia, `RAISE EXCEPTION` con texto plano en vez del patrón estándar).
> Si se incluyera, su `CREATE OR REPLACE FUNCTION` sobreescribiría silenciosamente las versiones seguras
> ya desplegadas (regresión de seguridad). El archivo permanece en el repo como referencia histórica.
> `fun_trigger_menu` y `fun_trigger_menu_admin` **ya estaban presentes** en `FUNCS` — la mención previa de
> "AUSENTES" para estos dos era una inexactitud de documentación preexistente, no relacionada con E7.
> Ver `Documentacion para implementacion de MSPI/FASE 01_Blindaje Técnico Inmediato/REPORTE_E1-E07_CORRECCION_SETUP_SMARTCSET.md`.

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
