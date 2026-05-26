# Funciones PostgreSQL (SmartCSET)

Funciones fuera del esquema principal `script_BD_SMARTCSET V.1.5.sql`. Se despliegan con `psql -f` en el orden indicado en cada carpeta bajo `database/functions/`.

## Excepciones

Desplegar primero `_helpers/smartcset_raise.sql`. Convenciones alineadas con `fun_*` (parámetros `w*`, variables `v*`, `AS $$` / `$$ LANGUAGE plpgsql`):

- `smartcset_raise_core` — núcleo P0001 (uso interno)
- `smartcset_raise_validacion` — datos inválidos o faltantes
- `smartcset_raise_negocio` — reglas de negocio (ingreso activo, menú con hijos, etc.)
- `smartcset_raise_no_encontrado` — registro inexistente
- `smartcset_handle_sql_error` — traduce `23505`, `23503`, etc. a mensajes en español

Todas usan `ERRCODE P0001` para que PHP (`ErrorHandler`) muestre el mensaje al usuario sin prefijos `fun_*`.

## Estructura en disco

| Carpeta | Contenido |
|---------|-----------|
| `_helpers/` | Helpers de excepciones (obligatorio antes del resto) |
| `acceso/usuarios/` | CRUD usuarios, validación login/correo, contraseña |
| `acceso/menus/` | CRUD menús, perfiles (`tab_menu_usuarios`), triggers |
| `acceso/sesiones/` | Sesión en BD (`tab_sesiones`) |
| `porteria/` | Ingreso/egreso: visitantes, `tab_log_ingresos` |
| `carga/` | Procesos masivos (PE04, DF49, juicios) — uso futuro |

Si actualiza desde funciones que devolvían `TEXT` con `'ERROR: ...'`, ejecute una vez:

`database/migrations/drop_functions_void_return.sql` (incluido en `setup_smartcset.sh`).

## Despliegue

**Instalación completa (recomendado):**

```bash
./database/setup_smartcset.sh
```

**Solo portería (ingreso/salida):**

```powershell
.\tools\deploy_funciones_acceso.ps1
```

**Solo funciones de acceso (usuarios + menús + sesión):** ver orden en `setup_smartcset.sh` o `tools/setup_db.ps1`.

## Orden en `porteria/` (dependencias)

1. `fun_upsert_persona_visitante.sql`
2. `fun_insert_log_ingreso.sql`
3. `fun_update_persona_tras_ingreso.sql`
4. `fun_registrar_ingreso_manual.sql`
5. `fun_update_log_salida.sql`
6. `fun_update_persona_tras_salida.sql`
7. `fun_registrar_salida_manual.sql`

Luego: `CREATE SEQUENCE seq_log_ingresos` y migraciones en `database/migrations/`.

## Ver también

- [database.md](database.md) — instalación, seeds y migraciones
- [modulos.md](modulos.md) — pantallas PHP de portería
