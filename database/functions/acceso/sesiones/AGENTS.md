# AGENTS.md — database/functions/acceso/sesiones/

## Propósito

Gestión de sesiones activas. Una única función para registrar/actualizar sesiones de usuarios.

---

## Función

`fun_registrar_sesion(id_usuario VARCHAR, token_sesion TEXT, duracion_segundos INT)` — UPSERT de sesión activa

- Si sesión existe para usuario: actualiza `ult_actividad` y `token_sesion`
- Si sesión NO existe: inserta nueva fila
- `ult_actividad` se usa para limpiar sesiones viejas

---

## Convenciones

- `tab_sesiones` tiene constraint UNIQUE en `id_usuario` — imposible 2 sesiones simultáneas
- `token_sesion` es el `session_id` de PHP
- `ult_actividad` se actualiza en cada request del usuario activo

---

## Dependencias

- Depende de `_helpers/smartcset_raise.sql`
- Operan sobre `tab_sesiones`

---

## Qué NO tocar sin entender primero

- El UPSERT (INSERT ... ON CONFLICT) es el patrón correcto para sesiones
- Una sesión por usuario máximo — el constraint lo fuerza
