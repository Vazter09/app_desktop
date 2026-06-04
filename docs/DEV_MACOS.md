# Desarrollo local en macOS (smartcset.local:8080)

## URL

- `http://smartcset.local:8080/` requiere en `/etc/hosts`:
  ```
  127.0.0.1 smartcset.local
  ```

## Opción A — Apache + PHP-FPM (puerto 8080)

Homebrew suele usar Apache en 8080 y PHP-FPM en 9000.

1. Servicios activos:
   ```bash
   brew services start php
   brew services start httpd
   ```

2. Virtual host: `DocumentRoot` = raíz del proyecto (`httpd-vhosts.conf`).

3. **No usar `mod_php`** en Apache 2.4 + PHP 8.5 si provoca respuesta vacía/segfault; usar en `httpd.conf`:
   ```apache
   <FilesMatch \.php$>
       SetHandler "proxy:fcgi://127.0.0.1:9000"
   </FilesMatch>
   ```

4. Logs:
   ```bash
   tail -f /opt/homebrew/var/log/httpd/smartcset-error.log
   ```

## Opción B — Servidor PHP integrado (sin Apache)

```bash
brew services stop httpd   # liberar 8080
bash tools/start_dev.sh
# http://127.0.0.1:8080/
```

## Base de datos

Si ves `Error crítico en prepare_login.php` con `pg_hba.conf` o IP `10.5.x.x`, tu `.env` apunta a un PostgreSQL remoto que no acepta tu máquina.

Para desarrollo local en la Mac:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=db_smartcset
DB_USER=postgres
DB_PASS=tu_password_local
```

Luego instalar/actualizar BD:

```bash
bash database/setup_smartcset.sh   # solo si puedes recrear la BD
# o
bash tools/setup_db.sh             # funciones + seeds sobre BD existente
```

Diagnóstico: `http://localhost:8080/tools/diagnose_bd.php`

### Menús Personas (desarrollo)

Tras cambiar rutas o permisos del módulo Personas, sincronizar sin tocar la BD a mano:

```bash
bash tools/sync_menus_personas.sh
```

Asigna menús Personas (`03`, `0300`–`0304`) y Configuración (`04`, `0401`, `0402`) a `admin.smart`. Otros usuarios:

```bash
bash tools/sync_menus_personas.sh admin.smart porteria
```

Lee credenciales de `.env` y aplica `database/seeds/seed_menus_personas_dev.sql` (idempotente).
