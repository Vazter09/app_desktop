# Auditoría: setup_smartcset.sh

**Fecha:** 27 de Mayo 2026

Análisis completo del script `database/setup_smartcset.sh` comparado contra todos los archivos SQL del proyecto.

---

## Qué hace el script

1. Lee credenciales desde `.env`
2. Detecta `psql` (soporta macOS Homebrew, PostgreSQL 18, y PATH del sistema)
3. Crea la BD `db_smartcset` si no existe
4. Aplica el schema completo (DROP + CREATE todas las tablas)
5. Despliega funciones PL/pgSQL en orden de dependencias
6. Crea la secuencia `seq_log_ingresos`
7. Ejecuta seeds y migraciones
8. Genera hashes bcrypt con PHP para los usuarios dev

---

## Problemas encontrados

### ❌ 1. Schema desactualizado — usa V.1.5, el activo es V.1.6

```bash

# Línea 37 del script (INCORRECTO):
SCHEMA="$ROOT/database/schema/script_BD_SMARTCSET V.1.5.sql"

# Debería ser:
SCHEMA="$ROOT/database/schema/script-BD-SMARTCSET V.1.6.sql"
```

Toda instalación desde cero arranca con una versión atrás del schema.
El mensaje final también dice `"Esquema V.1.5"` cuando debería decir `V.1.6`.

---

### ❌ 2. Funciones PL/pgSQL ausentes (7 funciones en el repo que NO se despliegan)

| Función                           | Ubicación           | Impacto si falta                                          |
| ---------------------------------- | -------------------- | --------------------------------------------------------- |
| `fun_validar_correo.sql`         | `acceso/usuarios/` | Recuperación de contraseña falla con `SQLSTATE 42883` |
| `fun_validar_login.sql`          | `acceso/usuarios/` | Login alternativo falla                                   |
| `fun_validar_usuario.sql`        | `acceso/usuarios/` | Validación de usuario falla                              |
| `fun_delete_perfil_usuarios.sql` | `acceso/menus/`    | No puede borrar todos los menús de un usuario            |
| `fun_tab_menu_usuarios.sql`      | `acceso/menus/`    | Query de menús por usuario no disponible                 |
| `fun_trigger_menu.sql`           | `acceso/menus/`    | Trigger de sincronización de menús no activo            |
| `fun_trigger_menu_admin.sql`     | `acceso/menus/`    | Trigger admin de menús no activo                         |

> Las funciones de validación de usuario (`fun_validar_correo`, `fun_validar_login`, `fun_validar_usuario`) son las más críticas en el día a día — sin ellas la recuperación de contraseña falla inmediatamente.

---

### ❌ 3. Migraciones ausentes (4 migraciones que existen pero NO se ejecutan)

| Migración                                 | Impacto                                                                                                                                                                         |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `update_modulos_rutas_organizadas.sql`   | **CRÍTICA** — actualiza `nom_programa` en `tab_menus` a rutas `src/modulos/...`. Sin ella, los links del menú de portería apuntan a rutas antiguas y no navegan |
| `update_menu_registro_listado_admin.sql` | Los menús de listado admin (0301–0304) apuntan a rutas incorrectas                                                                                                            |
| `add_unique_ingreso_persona_dia.sql`     | Falta el constraint único ingreso/persona/día en `tab_log_ingresos`                                                                                                         |
| `clean_log_ingresos_salidas.sql`         | Limpieza de log histórico (puede ser omisión intencional)                                                                                                                     |

---

### ⚠️ 4. Funciones de carga Excel no incluidas (omisión probable intencional)

Estas funciones existen en el repo pero el script no las despliega:

- `fun_proceso_df49.sql`
- `fun_proceso_pe04.sql`
- `fun_proceso_juicios.sql`

Si el módulo de carga de archivos Excel SENA (DF-49, PE-04, juicios) está en uso, hay que desplegarlas manualmente o agregar un script separado.

---

## Estado actual por categoría

### Schema

| Archivo                           | Estado                                  |
| --------------------------------- | --------------------------------------- |
| `script-BD-SMARTCSET V.1.6.sql` | ❌ No usado (debería ser el principal) |
| `script_BD_SMARTCSET V.1.5.sql` | ✅ Usado (desactualizado)               |

### Funciones — `acceso/usuarios/`

| Función                        | Estado              |
| ------------------------------- | ------------------- |
| `fun_insert_tab_usuarios.sql` | ✅ Desplegada       |
| `fun_update_tab_usuarios.sql` | ✅ Desplegada       |
| `fun_actualizar_password.sql` | ✅ Desplegada       |
| `fun_validar_correo.sql`      | ❌**Ausente** |
| `fun_validar_login.sql`       | ❌**Ausente** |
| `fun_validar_usuario.sql`     | ❌**Ausente** |

### Funciones — `acceso/menus/`

| Función                            | Estado              |
| ----------------------------------- | ------------------- |
| `fun_insert_tab_menus.sql`        | ✅ Desplegada       |
| `fun_update_tab_menus.sql`        | ✅ Desplegada       |
| `fun_delete_tab_menus.sql`        | ✅ Desplegada       |
| `fun_insert_menu_usuarios.sql`    | ✅ Desplegada       |
| `fun_delete_perfil_usuario.sql`   | ✅ Desplegada       |
| `fun_trigger_desasignar_menu.sql` | ✅ Desplegada       |
| `fun_delete_perfil_usuarios.sql`  | ❌**Ausente** |
| `fun_tab_menu_usuarios.sql`       | ❌**Ausente** |
| `fun_trigger_menu.sql`            | ❌**Ausente** |
| `fun_trigger_menu_admin.sql`      | ❌**Ausente** |

### Funciones — `acceso/sesiones/`

| Función                     | Estado        |
| ---------------------------- | ------------- |
| `fun_registrar_sesion.sql` | ✅ Desplegada |

### Funciones — `porteria/`

| Función                                | Estado        |
| --------------------------------------- | ------------- |
| `fun_upsert_persona_visitante.sql`    | ✅ Desplegada |
| `fun_insert_log_ingreso.sql`          | ✅ Desplegada |
| `fun_update_persona_tras_ingreso.sql` | ✅ Desplegada |
| `fun_registrar_ingreso_manual.sql`    | ✅ Desplegada |
| `fun_update_log_salida.sql`           | ✅ Desplegada |
| `fun_update_persona_tras_salida.sql`  | ✅ Desplegada |
| `fun_registrar_salida_manual.sql`     | ✅ Desplegada |

### Funciones — `config/`

| Función                              | Estado        |
| ------------------------------------- | ------------- |
| `fun_update_tab_config_sistema.sql` | ✅ Desplegada |

### Funciones — `_helpers/`

| Función                | Estado        |
| ----------------------- | ------------- |
| `smartcset_raise.sql` | ✅ Desplegada |

### Funciones — `carga/` (Excel SENA)

| Función                    | Estado           |
| --------------------------- | ---------------- |
| `fun_proceso_df49.sql`    | ⚠️ No incluida |
| `fun_proceso_pe04.sql`    | ⚠️ No incluida |
| `fun_proceso_juicios.sql` | ⚠️ No incluida |

### Migraciones

| Migración                                 | Estado                             |
| ------------------------------------------ | ---------------------------------- |
| `add_tab_sesiones.sql`                   | ✅ Ejecutada                       |
| `add_tab_config_sistema.sql`             | ✅ Ejecutada                       |
| `drop_functions_void_return.sql`         | ✅ Ejecutada                       |
| `add_menu_accesos_0203_0204.sql`         | ✅ Ejecutada                       |
| `sync_admin_menu_access.sql`             | ✅ Ejecutada                       |
| `update_nom_programa_subfolders.sql`     | ✅ Ejecutada                       |
| `add_menu_registro_ingreso_0102.sql`     | ✅ Ejecutada                       |
| `refactor_ingreso_abierto_salida.sql`    | ✅ Ejecutada                       |
| `add_menu_registro_salida_0103.sql`      | ✅ Ejecutada                       |
| `add_menu_config_y_registro.sql`         | ✅ Ejecutada                       |
| `update_modulos_rutas_organizadas.sql`   | ❌**Ausente (CRÍTICA)**     |
| `update_menu_registro_listado_admin.sql` | ❌**Ausente**                |
| `add_unique_ingreso_persona_dia.sql`     | ❌**Ausente**                |
| `clean_log_ingresos_salidas.sql`         | ❌ Ausente (puede ser intencional) |

### Seeds

| Seed                              | Estado           |
| --------------------------------- | ---------------- |
| `seed_acceso_dev.sql`           | ✅ Ejecutado     |
| `seed_menus_admin.sql`          | ✅ Ejecutado     |
| `script_Inserts_cset V.1.0.sql` | ⚠️ No incluido |
| `inserts_cset_v1.0_alt.sql`     | ⚠️ No incluido |

---

## Pendiente: corregir el script

Los cambios necesarios en `database/setup_smartcset.sh`:

1. **Cambiar schema** de V.1.5 a V.1.6
2. **Agregar 7 funciones** ausentes al array `FUNCS`
3. **Agregar 3 migraciones** ausentes al bloque de migraciones (en orden correcto)
4. **Actualizar mensaje final** de `"Esquema V.1.5"` a `"Esquema V.1.6"`
5. **Decidir** si las funciones de carga Excel se incluyen o van en script separado
