# AGENTS.md — database/functions/

## Propósito

Funciones PL/pgSQL organizadas por dominio funcional. Encapsulan toda la lógica crítica de integridad y negocio de la base de datos.

---

## Estructura

```
functions/
├── _helpers/            ← Excepciones (DESPLEGAR PRIMERO)
├── acceso/              ← Usuarios, menús, sesiones
│   ├── menus/
│   ├── usuarios/
│   └── sesiones/
├── porteria/            ← Ingreso y salida
├── config/              ← Configuración del sistema
└── carga/               ← Carga de reportes SENA (opcional)
```

---

## Orden de despliegue OBLIGATORIO

1. **`_helpers/`** — Primero SIEMPRE. Define excepciones que el resto de funciones usa.
2. **`acceso/usuarios/`** — Usuarios del sistema
3. **`acceso/menus/`** — Menús y permisos
4. **`acceso/sesiones/`** — Sesiones
5. **`porteria/`** — Portería (ingreso/salida)
6. **`config/`** — Configuración
7. **`carga/`** — Carga SENA (opcional, solo si módulo está activo)

**NUNCA cambiar este orden.** Las funciones posteriores llaman las anteriores.

---

## Convenciones generales

**Nomenclatura:** `fun_` + verbo + objeto
- `fun_insert_tab_usuarios.sql`
- `fun_validar_login.sql`
- `fun_registrar_ingreso_manual.sql`

**Parámetros:** uso de tipos con `%TYPE` para inmunidad a cambios de schema
```sql
CREATE FUNCTION fun_nombre(wparam1 tab_tabla.columna%TYPE, wparam2 TEXT) ...
```

**Manejo de errores:** SEMPRE bloque EXCEPTION con P0001 y `smartcset_handle_sql_error()`
```sql
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN RAISE;
    WHEN OTHERS THEN PERFORM smartcset_handle_sql_error();
END;
```

**Mensajes de usuario:** en español, sin jerga técnica, mediante `smartcset_raise_validacion()` o `smartcset_raise_negocio()`

---

## Subdirectorios

### _helpers/
Helpers de excepciones. Funciones:
- `smartcset_raise_validacion(msg)` — lanza error de validación
- `smartcset_raise_negocio(msg)` — lanza error de negocio
- `smartcset_raise_no_encontrado(msg)` — recurso no encontrado
- `smartcset_raise_core(msg)` — error de sistema
- `smartcset_handle_sql_error()` — maneja otros errores SQL

### acceso/
Funciones de acceso del sistema (usuarios, menús, sesiones).

### acceso/usuarios/
- `fun_insert_tab_usuarios` — crear usuario
- `fun_update_tab_usuarios` — actualizar usuario
- `fun_actualizar_password` — cambiar contraseña
- `fun_validar_login` — validar login
- `fun_validar_correo` — validar correo (AUSENTE del instalador)
- `fun_validar_usuario` — validar usuario (AUSENTE del instalador)

### acceso/menus/
- `fun_insert_tab_menus` — crear menú
- `fun_update_tab_menus` — actualizar menú
- `fun_delete_tab_menus` — eliminar menú
- `fun_insert_menu_usuarios` — asignar menú a usuario
- `fun_delete_perfil_usuario` — borrar todos los menús de un usuario
- `fun_delete_perfil_usuarios` — borrar un menú de todos los usuarios (AUSENTE del instalador)
- `fun_trigger_desasignar_menu` — trigger al eliminar menú
- `fun_trigger_menu` — trigger al crear usuario (AUSENTE del instalador)
- `fun_trigger_menu_admin` — trigger admin (AUSENTE del instalador)
- `fun_tab_menu_usuarios` — query de menús por usuario (AUSENTE del instalador)

### acceso/sesiones/
- `fun_registrar_sesion` — UPSERT de sesión activa

### porteria/
- `fun_upsert_persona_visitante` — crear o actualizar persona
- `fun_insert_log_ingreso` — registrar ingreso
- `fun_update_persona_tras_ingreso` — actualizar estadísticas tras ingreso
- `fun_registrar_ingreso_manual` — proceso atómico de ingreso (orquesta las 3 anteriores)
- `fun_update_log_salida` — registrar salida
- `fun_update_persona_tras_salida` — actualizar estadísticas tras salida
- `fun_registrar_salida_manual` — proceso atómico de salida

### config/
- `fun_update_tab_config_sistema` — actualizar toda la configuración (29 parámetros)

### carga/
- `fun_proceso_df49` — procesar carga DF-49 SENA
- `fun_proceso_pe04` — procesar carga PE-04 SENA
- `fun_proceso_juicios` — procesar juicios de evaluación

---

## Dependencias entre funciones

Las funciones posterior dependen de las anteriores:
- Todas dependen de `_helpers/*`
- `fun_registrar_ingreso_manual` llama: `fun_upsert_persona_visitante`, `fun_insert_log_ingreso`, `fun_update_persona_tras_ingreso`
- `fun_registrar_salida_manual` llama: `fun_update_log_salida`, `fun_update_persona_tras_salida`

---

## Qué NO tocar sin entender primero

- No cambiar el orden de despliegue
- No eliminar `_helpers/*` sin revisar todas las otras funciones que lo usan
- No cambiar la firma de una función sin actualizar el prepared statement correspondiente en `prepare.php`
- No cambiar el tipo de retorno de una función (ej. de TEXT a VOID) — rompe `fetchColumn()` en PHP
