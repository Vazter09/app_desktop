# AGENTS — Funciones de sesiones (`acceso/sesiones`)

## Convención de parámetros

Todos los argumentos que mapean a columnas usan `%TYPE` (ej. `tab_sesiones.id_sesion%TYPE`, `tab_usuarios.id_usuario%TYPE`), igual que portería y `fun_ingreso_sesion`.

## Convención de retorno

Igual que el resto del proyecto (`fun_ingreso_sesion`, `fun_salida_sesion`): **`RETURNS TEXT`**, no `TABLE`.

| Función | Retorno TEXT |
|---------|----------------|
| `fun_ingreso_sesion` | `id_sesion` |
| `fun_salida_sesion` | `'OK'` |
| `fun_actualizar_sesion_actividad` | `'OK'` |
| `fun_validar_sesion_activa` | `ult_actividad` o `NULL` si no hay sesión activa |

**Listados** (admin conectados): `SELECT` en `prepare.php`, no función PL/pgSQL (mismo criterio que portería / `stmt_list_ingresos_hoy`).

## Capa PHP — [`src/core/lib/acceso_sesion.php`](../../../src/core/lib/acceso_sesion.php)

- `accesoIngresoSesion()` → `fun_ingreso_sesion`
- `accesoSalidaSesion()` → `fun_salida_sesion`
- `accesoTouchSesion()` → `fun_actualizar_sesion_actividad`
- `accesoValidarSesionActiva()` → `fun_validar_sesion_activa` (devuelve `?string` ult_actividad)

## Presencia lite (PHP, sin función PL/pgSQL)

- `accesoEstadoPresencia($sesionActiva, $ultActividad)` → `ACTIVO` | `AUSENTE` | `DESCONECTADO` según `SESION_PRESENCIA_ACTIVO_MIN` (`.env`)
- `accesoPresenciaEtiqueta()` / `accesoPresenciaClaseCss()` — badges en `src/admin/sesiones/index.php`
- Heartbeat: `src/core/ajax_sesion_heartbeat.php` + `js/smartcset-presencia.js` (intervalo `SESION_HEARTBEAT_SEG`); alinea el throttle de `Db::touchSesionSiCorresponde`
