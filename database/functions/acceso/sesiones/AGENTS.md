# AGENTS.md — database/functions/acceso/sesiones/

## Propósito

Gestión de sesiones activas en `tab_sesiones`. Una fila por usuario = sesión abierta; bloquea segundo login hasta logout o cierre por administrador.

---

## Funciones

1. `fun_ingreso_sesion(p_user)` — INSERT si no hay fila activa; error de negocio si ya existe sesión
2. `fun_salida_sesion(p_user)` — DELETE idempotente de la fila
3. `fun_actualizar_sesion_actividad(p_user)` — UPDATE `ult_actividad` (informativo; llamado desde `prepare.php`)

Todas retornan `TEXT` con `'OK'` en éxito. Errores de negocio vía `smartcset_raise_*` (P0001).

---

## Convenciones

- `tab_sesiones`: PK en `id_usuario` — máximo una sesión activa por usuario
- Sin `token_sesion`; la sesión PHP (`$_SESSION`) es independiente de la fila BD
- `ult_actividad` no expira sesiones automáticamente; solo auditoría para el menú admin
- Liberación: logout (`fun_salida_sesion`) o admin (`src/admin/sesiones/index.php`)

---

## Dependencias

- Depende de `_helpers/smartcset_raise.sql`
- Operan sobre `tab_sesiones` y `tab_usuarios`

---

## Qué NO tocar sin entender primero

- No reintroducir UPSERT en ingreso — debe bloquear si ya hay fila
- No auto-borrar por timeout en estas funciones — política definida con el negocio
- Mantener `RETURNS TEXT` coherente con el resto del módulo acceso
