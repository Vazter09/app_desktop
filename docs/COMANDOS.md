# 🚀 Comandos Útiles - PRONOM v1.2

## Windows (PowerShell)

### Setup Inicial
```powershell
# Copiar template .env
Copy-Item .env.example .env

# Crear carpeta logs
New-Item -ItemType Directory -Name logs -Force

# Editar .env
notepad .env

# Verificar conexión a BD
php -r "require 'src/prepare.php'; echo 'BD OK';"
```

### Tests de Seguridad
```powershell
# Verificar sintaxis PHP
php -l src/config.php
php -l src/prepare.php

# Ver headers HTTP
curl -I http://localhost/pronom

# Test POST (login)
curl -X POST http://localhost/pronom/ -d "txt_usuario=admin&txt_clave=1234"
```

### Permisos (Windows)
```powershell
# Ver permisos (requiere admin)
icacls .env
icacls logs

# Restringir .env a usuario actual
icacls .env /grant:r "$env:USERNAME:(F)" /inheritance:r
```

---

## Linux / macOS

### Setup Inicial
```bash
# Copiar template
cp .env.example .env

# Crear carpeta logs
mkdir -p logs
chmod 777 logs

# Editar configuración
nano .env

# Verificar conexión
php -r "require 'src/prepare.php'; echo 'BD OK';"
```

### Tests de Seguridad
```bash
# Verificar sintaxis
php -l src/config.php
php -l src/prepare.php

# Headers HTTP
curl -I http://localhost/pronom

# Test login
curl -X POST http://localhost/pronom/ \
  -d "txt_usuario=admin&txt_clave=1234"

# Ver headers detalladados
curl -v http://localhost/pronom 2>&1 | grep ">"
```

### Permisos Correctos
```bash
# Archivo .env (solo lectura propietario)
chmod 600 .env

# Archivos PHP (lectura propietario + grupo web)
chmod 640 src/*.php
chmod 640 index.php

# Carpeta logs (lectura/escritura web)
chmod 777 logs

# Verificar
ls -la .env
ls -la src/config.php
ls -la logs/
```

---

## Verificación de BD

### Conectar a PostgreSQL
```bash
psql -h localhost -U postgres -d db_proynom

# Una vez dentro:
\dt                    # Listar tablas
SELECT * FROM tab_usuarios;  # Ver usuarios
\q                     # Salir
```

### Backup de BD
```bash
# Crear respaldo
pg_dump -U postgres db_proynom > backup.sql

# Restaurar
psql -U postgres db_proynom < backup.sql
```

---

## Diagnóstico de Problemas

### Revisar logs PHP
```bash
# Linux
tail -f /var/log/apache2/error.log

# macOS
tail -f /private/var/log/apache2/error.log

# Windows (si está configurado)
type logs\php_errors.log
```

### Verificar usuario HTTP
```bash
# ¿Qué usuario ejecuta PHP?
ps aux | grep apache
ps aux | grep php

# Permisos necesarios
# Apache user debe poder: leer PHP, escribir en logs/
```

### Probar .env se carga
```bash
php -r "require 'src/EnvLoader.php'; 
EnvLoader::load(); 
echo 'DB_HOST: ' . EnvLoader::get('DB_HOST');"
```

---

## Migraciones y Mantenimiento

### Migrar contraseñas antiguas
```bash
# Ver usuarios y hashes
php -r "require 'src/prepare.php'; 
\$users = \$pdo->query('SELECT id_usuario, pass_usuario FROM tab_usuarios')->fetchAll();
foreach(\$users as \$u) {
    \$type = (strpos(\$u['pass_usuario'], '\$2y\$') === 0) ? 'bcrypt' : 'otro';
    echo \$u['id_usuario'] . ' => ' . \$type . PHP_EOL;
}"
```

### Resetear contraseña de usuario (CLI)
```bash
php -r "
require 'src/prepare.php';
\$pass = password_hash('nueva_contraseña', PASSWORD_BCRYPT);
\$stmt = \$pdo->prepare('UPDATE tab_usuarios SET pass_usuario = ? WHERE id_usuario = ?');
\$stmt->execute([\$pass, 'nombre_usuario']);
echo 'Contraseña actualizada';
"
```

### Crear usuario nuevo (SQL)
```bash
psql -U postgres -d db_proynom << EOF
SELECT fun_insert_tab_usuarios('newuser', 'Nombre Usuario', 
  '\$2y\$10\$hash_bcrypt_aqui', 'email@example.com', false, true);
EOF
```

---

## Monitoreo y Seguridad

### Monitores de errores
```bash
# Actualizar log en tiempo real
tail -f logs/php_errors.log

# Contar errores recientes
grep -c "ERROR" logs/php_errors.log
```

### Búsqueda de intentos fallidos
```bash
# Login fallidos en logs
grep "ID de usuario o contraseña" logs/php_errors.log

# Accesos bloqueados
grep "ACCESO DENEGADO" logs/php_errors.log
```

### Validar HTTPS
```bash
# Forzar HTTPS
curl -I -L http://tu-dominio.com
# Debe redirigir a https://

# Verificar certificado
openssl s_client -connect tu-dominio.com:443 -tls1_2
```

---

## Docker (Opcional)

### Si usas Docker
```dockerfile
FROM php:8.2-apache

RUN docker-php-ext-install pdo pdo_pgsql

COPY . /var/www/html/pronom
WORKDIR /var/www/html/pronom

RUN mkdir -p logs && chmod 777 logs
RUN chmod 600 .env

EXPOSE 80 443
```

```bash
# Build
docker build -t pronom .

# Run
docker run -p 80:80 -p 443:443 -v $(pwd)/.env:/var/www/html/pronom/.env pronom
```

---

## Vim/Nano - Editar Archivos

### Nano
```bash
nano .env           # Abrir
# Ctrl+X para salir
# Y para confirmar cambios
# N para no guardar
```

### Vim
```bash
vim .env
# i     - Insertar
# Esc   - Salir de inserción
# :wq   - Guardar y salir
# :q!   - Salir sin guardar
```

---

## Troubleshooting Rápido

### "No puedo conectar a BD"
```bash
# Verificar que BD está corriendo
psql -h localhost -U postgres -d postgres -c "SELECT 1"

# Verificar credenciales .env
cat .env | grep DB_
```

### "Permiso denegado en logs/"
```bash
# Arreglar permisos
chmod 777 logs
ls -la logs/
```

### "500 Internal Server Error"
```bash
# Ver error detallado
tail -f /var/log/apache2/error.log
# O revisar logs/

# Validar sintaxis
php -l index.php
php -l src/prepare.php
```

### "Contaseña no funciona"
```bash
# Verificar hash en BD
psql -c "SELECT id_usuario, pass_usuario FROM tab_usuarios LIMIT 1"

# Debe empezar con: $2y$ (bcrypt)
```

---

## Limpieza y Mantenimiento

### Limpiar logs antiguos
```bash
# Borrar logs más viejos de 30 días
find logs/ -mtime +30 -delete

# O con tar
tar czf logs_backup.tar.gz logs/
rm -rf logs/*
```

### Actualizar dependencias (si hay)
```bash
# Si usas Composer
composer update

# Si usas npm
npm update
```

---

**✅ Con estos comandos deberías poder administrar PRONOM sin problemas**
