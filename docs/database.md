# Base de datos SmartCSET (PostgreSQL)

## Configuración de la aplicación

En `.env`:

```env
DB_NAME=db_smartcset
```

## Instalación desde cero

### 1. Crear la base de datos

Conéctese a PostgreSQL como superusuario y cree la BD (solo una vez):

```sql
CREATE DATABASE db_smartcset
    WITH ENCODING 'UTF8'
    LC_COLLATE = 'Spanish_Colombia.1252'
    LC_CTYPE = 'Spanish_Colombia.1252'
    TEMPLATE template0;
```

Desde la raíz del proyecto:

```bash
./database/setup_smartcset.sh
```

Windows (PowerShell):

```powershell
.\database\setup_smartcset.ps1
```

### 2. Esquema principal (obligatorio)

Ejecutar **una sola vez** sobre `db_smartcset`:

```text
database/schema/script_BD_SMARTCSET V.1.5.sql
```

Ese script crea tablas, tipos, triggers de auditoría y datos maestros del sistema CSET.

**V.1.5:** `tab_entradas_centro` exige `id_centro` e `id_sede` (FK a `tab_sedes`). Las funciones CRUD de usuarios/menús/ingreso **no** van en el esquema; despliéguelas después (pasos 4–5).

### 3. Tabla de sesiones y datos de desarrollo

1. `database/migrations/add_tab_sesiones.sql` — tabla `tab_sesiones` (usada por `prepare.php` / logout)
2. Seeds y migraciones (orden en lista siguiente)

### 4. Datos de desarrollo (opcional)

Orden sugerido:

1. `database/seeds/seed_acceso_dev.sql` — usuario `admin.smart`
2. `database/seeds/seed_menus_admin.sql` — menús de administración
3. `database/migrations/add_menu_accesos_0203_0204.sql` — Accesos / Copiar perfil (si no están en el seed)
4. `database/migrations/sync_admin_menu_access.sql` — permisos admin
5. `database/migrations/update_nom_programa_subfolders.sql` — rutas de menús (`src/menu/...`)
6. `database/migrations/add_menu_registro_ingreso_0102.sql` — menú **Registro ingreso** y accesos usuario `porteria`
7. `database/migrations/add_menu_registro_salida_0103.sql` — menú **Registro salida** y accesos `porteria` (0102 + 0103)
8. `database/migrations/refactor_ingreso_abierto_salida.sql` — índice ingreso abierto (`fec_salida = fec_ingreso`)
9. `database/migrations/update_modulos_rutas_organizadas.sql` — rutas `src/modulos/...` tras reorganización de carpetas

### 5. Funciones de acceso (obligatorio para usuarios y menús)

El esquema V.1.5 **no** incluye `fun_insert_tab_usuarios` ni `fun_update_tab_usuarios`. Sin ellas, crear/editar usuarios falla con error 42883.

Despliegue completo (macOS/Linux):

```bash
./database/setup_smartcset.sh
```

Las funciones viven en `database/functions/` por módulo (`acceso/`, `porteria/`, `carga/`). Ver [database-functions.md](database-functions.md).

Desde la raíz del proyecto:

```powershell
.\tools\deploy_funciones_acceso.ps1
```

`database\setup_smartcset.ps1`, `database/setup_smartcset.sh` y `tools\setup_db.ps1` ejecutan el despliegue automáticamente.

### 6. Funciones de registro de ingreso y salida (portería)

Tras las migraciones de menú `0102` / `0103`, desplegar funciones (no van en el esquema V.1.5 principal):

```powershell
.\tools\deploy_funciones_acceso.ps1
```

Incluye `fun_registrar_ingreso_manual`, `fun_registrar_salida_manual`, índice de ingreso abierto y `seq_log_ingresos`.

Reglas en BD:

- **Ingreso:** solo si no hay visita abierta (`fec_salida = fec_ingreso`).
- **Salida:** actualiza `fec_salida` con `CURRENT_TIMESTAMP` en el ingreso activo del día.
- **Reingreso mismo día:** permitido después de registrar salida.

## Migrar desde `db_proynom`

Si ya tenía datos en la base antigua:

```powershell
pg_dump -U postgres -d db_proynom -Fc -f backup_proynom.dump
pg_restore -U postgres -d db_smartcset --no-owner backup_proynom.dump
```

O renombrar la base (con nadie conectado):

```sql
-- Desde otra BD, p. ej. postgres
ALTER DATABASE db_proynom RENAME TO db_smartcset;
```

Luego actualice `.env` con `DB_NAME=db_smartcset`.
