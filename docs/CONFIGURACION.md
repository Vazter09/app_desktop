# 🛠️ Guía de Configuración Post-Auditoría - PRONOM v1.2

## Cambios Realizados y Cómo Utilizarlos

---

## 1️⃣ **Configurar Variables de Entorno (.env)**

### ¿Qué es?
El archivo `.env` contiene todas las configuraciones sensibles (contraseñas, URLs de BD, etc.) SIN incluirlas en el código.

### Pasos:

```bash
# Paso 1: Copiar template
cp .env.example .env

# Paso 2: Editar con tus valores reales
nano .env
# O en Windows:
# notepad .env
```

### Contenido a Completar:
```env
# BASE DE DATOS
DB_HOST=localhost              # O tu servidor PostgreSQL
DB_PORT=5432
DB_NAME=db_smartcset
DB_USER=postgres
DB_PASS=TU_PASSWORD_AQUI       # 🔐 CAMBIAR ESTO

# COLORES (opcional — respaldo si aún no existe tab_config_sistema)
COLOR_VERDE_OSCURO=#004d40
COLOR_VERDE_OLIVA=#808000
PATH_LOGO=img/logo_empresa.png

# ENTORNO
APP_ENV=production             # Cambiar a "production"
SESSION_TIMEOUT=1800
```

⚠️ **IMPORTANTE:** `.env` NO debe subirse a Git. Ya está en `.gitignore`

### Apariencia y módulo registro (base de datos)

En instalaciones con PostgreSQL ya creado, ejecute:

```bash
chmod +x database/migrations/run_config_sistema.sh
./database/migrations/run_config_sistema.sh
```

Eso crea `tab_config_sistema`, la función `fun_update_tab_config_sistema` y los menús **Config. sistema** (`0205`) y **Registro personas** (`03xx`).

La configuración visual (colores, fuentes, logo) y los interruptores del módulo de registro se editan en **Administración → Config. sistema**. La base de datos es la fuente de verdad; `.env` solo se usa como respaldo si la tabla no existe.

---

## 2️⃣ **Crear Directorio de Logs**

El sistema necesita una carpeta para guardar registros de errores.

```bash
# Crear carpeta
mkdir logs

# Windows (PowerShell):
# New-Item -ItemType Directory -Name logs -Force
```

---

## 3️⃣ **Nuevos Archivos de Seguridad**

Se han agregado 3 nuevos archivos para mejorar la seguridad:

### `src/EnvLoader.php` ✅
- **Qué es:** Lee el archivo `.env` automáticamente
- **Uso:** Ya está integrado en `config.php`
- **No requiere cambios**

### `src/SecurityMiddleware.php` ✅
- **Qué es:** Protección contra ataques comunes (CSRF, XSS, Directory Traversal)
- **Uso:** Opcional, pero recomendado activar
- **Para activar:** Agregar en `src/prepare.php`:
```php
require_once('SecurityMiddleware.php');
SecurityMiddleware::initialize();
```

---

## 4️⃣ **Cambios en Archivos Existentes**

### `index.php` 🔐
- ✅ Agregados headers de seguridad
- ✅ Validación de campo `ind_usuario`
- ✅ Campo de contraseña ahora requiere mínimo 8 caracteres
- **No requiere cambios manuales**

### `src/config.php` 📝
- ✅ Ahora lee desde `.env` automáticamente
- ✅ Fallback a valores por defecto si `.env` no existe
- **No requiere cambios manuales**

### `src/cambiar_clave.php` 🔐
- ✅ Cambio de PASSWORD_DEFAULT a PASSWORD_BCRYPT
- **Mejora:** Consistencia en encriptación de todas las contraseñas
- **No requiere cambios manuales**

### `src/recuperar.php` 🛠️
- ✅ Eliminado código duplicado que causaba conflictos
- **Mejora:** Ahora funciona correctamente con una sola encriptación
- **No requiere cambios manuales**

### `js/login.js` 🎯
- ✅ Validación corregida: 8 caracteres (no 12)
- ✅ Nombre de campo correcto: `txt_clave`
- **No requiere cambios manuales**

---

## 5️⃣ **Migrador de Contraseñas (Si lo Necesitas)**

### Situación:
Si tienes contraseñas antiguas en BD con otro formato, necesitas migrarlas.

### Ubicación:
`scripts/migrations/password_migrator.php`

### Cómo usar:
```bash
# En navegador local (solo acceso local):
# http://localhost/pronom/scripts/migrations/password_migrator.php
```

### Pasos:
1. Abre el archivo en el navegador
2. Verás lista de usuarios con tipo de hash actual
3. Para cada usuario con hash ❌ incompatible:
   - Ingresa nueva contraseña
   - Haz clic en "Resetear"
4. **Cuando termines:** Elimina el archivo del servidor

---

## 6️⃣ **Checklist Pre-Producción**

```bash
# ✅ Verificar .env existe
ls -la .env

# ✅ Verificar permisos
ls -l src/config.php     # Debe ser -rw-r----- (640)
ls -l .env               # Debe ser -rw------- (600)

# ✅ Verificar logs/
mkdir -p logs
chmod 777 logs

# ✅ Test de conexión a BD (desde terminal)
php -r "require 'src/prepare.php'; echo 'BD OK';"

# ✅ Verificar HTTPS (editar .env)
# APP_ENV=production

# ✅ Revisar logs de errores
tail -f logs/error.log   # Si existe
```

---

## 7️⃣ **Habilitar HTTPS (Producción)**

### En el archivo `.env`:
```env
APP_ENV=production
```

Esto forzará redirección automática de HTTP → HTTPS

### En Apache:
Crear archivo `.htaccess` en raíz:

```apache
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
```

---

## 8️⃣ **Proteger Archivos Sensibles**

### Bloquear acceso a carpeta de migraciones:
En `.htaccess`:
```apache
<Directory "scripts/migrations">
    Deny from all
</Directory>
```

---

## 📝 **Documentación Disponible**

| Archivo | Propósito |
|---------|-----------|
| [SECURITY.md](SECURITY.md) | Guía completa de seguridad |
| [AUDIT_REPORT.md](AUDIT_REPORT.md) | Informe detallado de cambios |
| [.env.example](.env.example) | Template de variables |

---

## 🧪 **Pruebas Rápidas**

### Test 1: Login funciona
```bash
curl -X POST http://localhost/pronom/index.php \
  -d "txt_usuario=admin&txt_clave=password"
```

### Test 2: Headers de seguridad
```bash
curl -I http://localhost/pronom/
# Debe mostrar: X-Frame-Options, X-Content-Type-Options, etc.
```

### Test 3: Redirección HTTPS (producción)
```bash
curl -I http://tu-servidor.com/
# Debe redirigir a https://
```

---

## ❌ Problemas Comunes

### "No se puede conectar a la BD"
```bash
# Verificar credenciales en .env
nano .env
# Comprobar: DB_HOST, DB_USER, DB_PASS, DB_NAME
```

### "Archivo .env no encontrado"
```bash
# Crear desde template
cp .env.example .env
```

### "Permisos de logs/error"
```bash
# Crear directorio con permisos correctos
mkdir -p logs
chmod 777 logs
```

### "Contraseña no funciona después de cambios"
```bash
# Asegúrate que:
# 1. Encriptación sea PASSWORD_BCRYPT (no PASSWORD_DEFAULT)
# 2. Mínimo 8 caracteres
# 3. BD actualizada correctamente (revisar función SQL)
```

---

## 🎓 **Resumen de Mejoras**

| Aspecto | Antes | Ahora |
|--------|-------|-------|
| **Credenciales** | Hardcodeadas en PHP | Variables en .env |
| **Contraseñas** | Inconsistente (algunos PASSWORD_DEFAULT) | Uniforme PASSWORD_BCRYPT |
| **Headers HTTP** | Ninguno | 7+ headers de seguridad |
| **CSRF** | No implementado | Disponible en middleware |
| **Logs** | Errores silenciados | Registrados en logs/ |
| **Validación** | Solo ind_estado | ind_usuario + ind_estado |

---

## 📞 Soporte

Si tienes dudas:
1. Revisa [SECURITY.md](SECURITY.md)
2. Revisa [AUDIT_REPORT.md](AUDIT_REPORT.md)
3. Revisa `php -l archivo.php` para sintaxis
4. Revisa `logs/` para errores

---

**¡Sistema actualizado y listo para usar con seguridad mejorada!** ✅
