# Informe: Corrección de Auditoría — Quién realmente hace los cambios en SmartCSET

**Fecha:** 2026-06-30
**Área afectada:** Base de datos PostgreSQL + capa de conexión PHP
**Archivos modificados:** 3
**Tablas cubiertas automáticamente:** 53

---

## 1. El problema — ¿Qué estaba pasando?

SmartCSET tiene varios usuarios registrados: `admin.smart`, `porteria`, y cualquier otro que se cree en el futuro. Cada vez que uno de estos usuarios hace algo en el sistema (crear un usuario, asignar un menú, registrar un ingreso, cambiar la configuración), ese cambio queda guardado en la base de datos.

La base de datos tiene columnas especiales llamadas **columnas de auditoría** en casi todas las tablas:

| Columna | Qué debería guardar |
|---|---|
| `usr_insert` | Quién creó el registro |
| `fec_insert` | Cuándo lo creó |
| `usr_update` | Quién lo modificó por última vez |
| `fec_update` | Cuándo fue esa modificación |

El problema era que **sin importar quién iniciara sesión**, estas columnas siempre mostraban el mismo valor: `postgres`.

### ¿Por qué pasaba eso?

PostgreSQL (el motor de base de datos) y SmartCSET (la aplicación web) son dos programas separados. SmartCSET se conecta a PostgreSQL usando un único usuario de base de datos llamado `postgres`, que está configurado en el archivo `.env`. Es como si toda la empresa entrara a la oficina usando una sola tarjeta de acceso compartida: el edificio (PostgreSQL) solo ve la tarjeta (`postgres`), no sabe quién la está usando realmente.

El mecanismo que llenaba las columnas de auditoría es una función llamada **trigger** (disparador): un pequeño programa que PostgreSQL ejecuta automáticamente cada vez que alguien guarda o modifica un dato. Ese trigger usaba `CURRENT_USER`, que en PostgreSQL significa "el usuario de la conexión de base de datos", que siempre es `postgres`.

### El resultado visible en pgAdmin

Un administrador abría pgAdmin, miraba la tabla `tab_usuarios`, y veía:

```
usr_insert = 'postgres'    ← debería decir 'admin.smart'
usr_update = 'postgres'    ← debería decir 'admin.smart'
```

Cualquier auditoría real era imposible: no se podía saber quién había hecho qué.

---

## 2. La solución — Cómo se resolvió

### La idea central

PostgreSQL tiene una característica que permite guardar **variables de sesión personalizadas**. Una "sesión" es la conexión activa entre SmartCSET y la base de datos durante un request del usuario. Es como si, al entrar a la oficina con la tarjeta compartida, la persona pudiera escribir su nombre en una pizarra interna que solo ese guard puede leer.

El mecanismo funciona así:

1. **PHP escribe en la pizarra**: al inicio de cada request, SmartCSET le dice a PostgreSQL "el usuario de la app que está conectado ahora es `admin.smart`" usando el comando `SET app.usuario = 'admin.smart'`.
2. **El trigger lee la pizarra**: cuando ocurre un INSERT o UPDATE en cualquier tabla, el trigger pregunta "¿qué dice la pizarra?" y guarda ese valor en `usr_insert` o `usr_update`.

Si nadie escribió en la pizarra (porque alguien se conectó directo desde pgAdmin sin pasar por la app), el trigger cae al comportamiento anterior y guarda `postgres`. Esto es intencionado: no se pierde nada.

### Analogía sin términos técnicos

Imagina que hay un vigilante en la puerta de cada sala de la base de datos (ese es el trigger). Antes, el vigilante solo anotaba "entró alguien con tarjeta `postgres`". Ahora, cuando alguien entra, primero lee un papel que la aplicación SmartCSET pegó en la puerta que dice "el usuario real es `admin.smart`", y anota eso. Si no hay papel, anota `postgres` como antes.

---

## 3. Los archivos que se modificaron

### Archivo 1: `database/migrations/fix_auditoria_app_usuario.sql` ← NUEVO

Este archivo contiene la nueva versión del trigger `fun_act_tabla()`. Es una migración SQL, lo que significa que es un script que se ejecuta una sola vez contra la base de datos para actualizarla.

**Qué cambia en el trigger:**

Antes:
```sql
IF TG_OP = 'INSERT' THEN
    NEW.usr_insert = CURRENT_USER;   -- siempre 'postgres'
```

Después:
```sql
-- Lee el usuario real de la sesión de la app
w_usuario := NULLIF(TRIM(current_setting('app.usuario', TRUE)), '');

-- Si no hay usuario de app, usa el de conexión como respaldo
IF w_usuario IS NULL THEN
    w_usuario := CURRENT_USER;
END IF;

IF TG_OP = 'INSERT' THEN
    NEW.usr_insert = w_usuario;   -- ahora 'admin.smart', 'porteria', etc.
```

**Explicación de `current_setting('app.usuario', TRUE)`:**
- `current_setting` es una función de PostgreSQL que lee variables de sesión personalizadas.
- `'app.usuario'` es el nombre de la variable (el espacio de nombres `app.` es convención para variables de aplicación).
- `TRUE` como segundo argumento indica "si la variable no existe, devuelve NULL en lugar de lanzar un error".

**¿Por qué `NULLIF(TRIM(...))`?**
- `TRIM` elimina espacios accidentales al inicio/fin del valor.
- `NULLIF(..., '')` convierte una cadena vacía en NULL, para que el fallback funcione si PHP seteó un string vacío.

### Archivo 2: `backend/core/prepare.php` ← MODIFICADO (1 línea añadida)

Este archivo es el corazón de la capa de conexión de SmartCSET. Se ejecuta en **cada request** de toda la aplicación, sin excepción. Es el lugar correcto para poner infraestructura que debe aplicar globalmente.

**Qué se añadió:**

```php
if (session_status() === PHP_SESSION_ACTIVE && !empty($_SESSION['id_usuario'])) {
    // LÍNEA NUEVA: informa a PostgreSQL quién es el usuario de la app
    $pdo->exec("SET app.usuario = " . $pdo->quote((string) $_SESSION['id_usuario']));

    require_once __DIR__ . '/helpers.php';
    // ... resto del código sin cambios
}
```

**Por qué aquí y no en otro lado:**
- Este bloque solo se ejecuta cuando hay una sesión activa con un usuario logueado.
- Si no hay sesión (un visitante no autenticado, un script de mantenimiento), no se setea la variable y el trigger usa `postgres` como antes.
- `$pdo->quote()` es una función de seguridad que sanitiza el valor antes de enviarlo a la base de datos, evitando cualquier inyección SQL.

**El `SET` en PostgreSQL:**
- `SET app.usuario = 'admin.smart'` es un comando estándar de PostgreSQL.
- El prefijo `app.` es el espacio de nombres para variables de aplicación personalizada; PostgreSQL lo permite sin configuración extra desde la versión 9.2.
- La variable dura exactamente lo que dura la conexión PHP (un request). Al siguiente request, PHP la setea de nuevo con el usuario correcto.

### Archivo 3: `database/setup_smartcset.sh` ← MODIFICADO (1 línea añadida)

Este es el script de instalación completa del sistema. Se ejecuta cuando se instala SmartCSET desde cero. Se agregó la nueva migración al final de la lista de migraciones para que instalaciones futuras ya incluyan este fix.

```bash
# Antes (última línea de la lista):
  "$ROOT/database/migrations/add_menu_reportes_sena.sql"

# Después:
  "$ROOT/database/migrations/add_menu_reportes_sena.sql" \
  "$ROOT/database/migrations/fix_auditoria_app_usuario.sql"
```

---

## 4. Cómo aplicar el cambio a la base de datos existente

Solo hay que ejecutar la migración SQL una vez contra la base de datos activa. Esto actualiza el trigger en el motor sin afectar ningún dato existente:

```bash
# Desde la raíz del proyecto
psql -h localhost -U postgres -d db_smartcset \
  -f database/migrations/fix_auditoria_app_usuario.sql
```

O si se usa el servidor remoto (10.5.213.111):
```bash
psql -h 10.5.213.111 -U postgres -d db_smartcset \
  -f database/migrations/fix_auditoria_app_usuario.sql
```

El comando `CREATE OR REPLACE FUNCTION` reemplaza el trigger en caliente, sin necesidad de reiniciar nada ni afectar conexiones activas.

---

## 5. Cómo verificar que funcionó

**Desde pgAdmin**, abrir el Query Tool y ejecutar:

```sql
-- Simula lo que hace PHP al inicio de cada request
SET app.usuario = 'admin.smart';

-- Hacer cualquier cambio en una tabla auditada, por ejemplo:
UPDATE tab_config_sistema SET nom_sistema = nom_sistema WHERE id_config = 1;

-- Verificar el resultado
SELECT usr_update, fec_update FROM tab_config_sistema WHERE id_config = 1;
-- Debería mostrar: usr_update = 'admin.smart'
```

**Para verificar el fallback** (sin setear la variable):
```sql
-- Sin SET app.usuario previo
UPDATE tab_config_sistema SET nom_sistema = nom_sistema WHERE id_config = 1;

SELECT usr_update FROM tab_config_sistema WHERE id_config = 1;
-- Debería mostrar: usr_update = 'postgres'
```

---

## 6. Qué cubre y qué no

### Sí cubre — automáticamente, sin más cambios

Todas las tablas que tienen el trigger `tri_act_tabla`. Son 53 tablas:

`tab_activ_proyecto`, `tab_adicion_contratos`, `tab_ambientes`, `tab_aprendices`,
`tab_aprendices_fichas`, `tab_areas`, `tab_asistencia_aprendiz`, `tab_ausencias_aprendiz`,
`tab_bitacora`, `tab_centros`, `tab_certificados`, `tab_ciudades`, `tab_compet_instructor`,
`tab_competencias`, `tab_competencias_ficha`, `tab_config_sistema`, `tab_contratos_instructor`,
`tab_dptos`, `tab_empresas`, `tab_entradas_centro`, `tab_evidencias`, `tab_evidenciasxrap`,
`tab_fichas`, `tab_horas_instructor`, `tab_instructores`, `tab_jornadas`, `tab_juicios_eval`,
`tab_llamados_atencion`, `tab_log_ingresos`, `tab_menu_usuarios`, `tab_menus`,
`tab_metodos_aut`, `tab_niveles_estudio`, `tab_ocupaciones`, `tab_ofertas`, `tab_personas`,
`tab_pmtros_grales`, `tab_profesiones`, `tab_prog_competencia`, `tab_prog_especiales`,
`tab_programacion`, `tab_programas`, `tab_proyectos`, `tab_raps`, `tab_redes`,
`tab_regionales`, `tab_rutas`, `tab_sectores`, `tab_sedes`, `tab_tipos_docum`,
`tab_tipos_permiso`, `tab_tipos_persona`, `tab_usuarios`, `tab_vehiculos`

Esto incluye las más importantes: `tab_usuarios`, `tab_log_ingresos`, `tab_personas`, `tab_menus`, `tab_menu_usuarios`, `tab_config_sistema`.

### Ya funcionaban bien — no necesitaban cambio

Las funciones que ya recibían el usuario de app como parámetro explícito:
- `fun_upsert_tab_entradas_centro` — entradas/puertas
- `fun_upsert_persona_visitante` — personas en portería
- `fun_update_log_salida` — salidas de portería
- `fun_update_tab_config_sistema` — configuración del sistema
- `fun_actualizar_aprendiz` — datos de aprendices

### Intencionalmente excluido — correcto dejarlo así

Las funciones de carga masiva de reportes SENA (`fun_proceso_df49`, `fun_proceso_matriculados`, etc.) hardcodean `'carga_automatica'` o `'SISTEMA'` porque son procesos batch automatizados, no acciones de un usuario interactivo.

### No aplica — conexiones directas a pgAdmin

Cuando un administrador de base de datos se conecta directo desde pgAdmin (sin pasar por SmartCSET), no hay sesión PHP que setee `app.usuario`. El trigger cae en `CURRENT_USER = 'postgres'`. Este es el comportamiento correcto: indica que el cambio fue hecho directamente en la base de datos, no a través de la aplicación.

---

## 7. Impacto en usuarios nuevos

Cualquier usuario que se cree en el futuro en SmartCSET será manejado automáticamente. No hay ninguna configuración adicional que hacer. El mecanismo funciona con `$_SESSION['id_usuario']`, que es el ID que tiene cualquier usuario logueado, existente o nuevo.

---

## 8. Resumen ejecutivo

| Qué | Resultado |
|---|---|
| Archivos modificados | 3 (1 nuevo, 2 editados con 1 línea cada uno) |
| Tablas cubiertas | 53 (automáticamente, sin tocar ninguna) |
| Cambios en routers/servicios/frontend | Ninguno |
| Usuarios nuevos que se agreguen | Cubiertos automáticamente |
| Conexiones directas desde pgAdmin | Siguen mostrando `postgres` (correcto) |
| Datos históricos (anteriores a este fix) | Seguirán mostrando `postgres` (no se puede cambiar el pasado) |
| Riesgo de la implementación | Mínimo — `CREATE OR REPLACE FUNCTION` es no destructivo |
