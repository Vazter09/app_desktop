# SistNomina v1.2 - Guía de Seguridad y Deployment

## 📋 Cambios de Seguridad Implementados

### ✅ Correcciones Realizadas

1. **Recuperar.php** - Eliminado código duplicado que causaba conflicto de encriptación
2. **Login.js** - Validación consistente de 8 caracteres mínimo
3. **Cambiar_clave.php** - Algoritmo consistente PASSWORD_BCRYPT
4. **Index.php** - Validación de ind_usuario + headers de seguridad
5. **Logout.php** - Logging de errores para auditoría
6. **Variables de Entorno** - Credenciales en .env en lugar de hardcodeadas
7. **Middleware de Seguridad** - Headers, CSRF, validación de entrada

### 🔐 Medidas Implementadas

#### 1. **Variables de Entorno (.env)**
- Archivo `.env` con configuración sensible
- Cargador automático `EnvLoader.php`
- Fallback a valores por defecto
- **Acción:** Nunca commitear `.env` a Git, solo `.env.example`

```bash
# Crear archivo .env desde template
cp .env.example .env
# Editar con credenciales reales
nano .env
```

#### 2. **Middleware de Seguridad**
Incluye:
- Headers HTTP de seguridad (X-Frame-Options, CSP, etc.)
- Protección CSRF con tokens
- Validación de métodos HTTP
- Prevención de Directory Traversal
- Configuración segura de sesiones

#### 3. **Encriptación de Contraseñas**
- Algoritmo: **PASSWORD_BCRYPT** (uniforme en todos los módulos)
- Longitud mínima: **8 caracteres**
- Validación de lado cliente (HTML5) y servidor (PHP)

#### 4. **Migrador de Contraseñas**
- Archivo movido a: `scripts/migrations/password_migrator.php`
- Protección de acceso local solamente
- Validación de longitud mínima: 8 caracteres
- **Eliminar después de usar en producción**

---

## 🚀 Configuración para Producción

### 1. Preparar Servidor

```bash
# 1. Crear archivo .env con valores reales
cp .env.example .env
# Editar credenciales de BD, etc.

# 2. Establecer permisos
chmod 600 .env                          # Solo lectura para propietario
chmod 755 src/ js/ css/ img/
chmod 640 src/*.php                     # Lectura para servidor web

# 3. Crear directorio de logs
mkdir -p logs
chmod 777 logs
```

### 2. Habilitar HTTPS Obligatorio

En `src/config.php`, descomenta la línea de forzar HTTPS:

```php
if (APP_ENV === 'production' && empty($_SERVER['HTTPS'])) {
    header("Location: https://" . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI']);
    exit();
}
```

Luego en `index.php`, cambia `APP_ENV` a `production`:

```env
APP_ENV=production
```

### 3. Configuración Apache/PHP

**php.ini (recomendado para producción):**
```ini
display_errors = Off
log_errors = On
error_log = /path/to/logs/php_errors.log
session.cookie_secure = On          # HTTPS solo
session.cookie_httponly = On        # No accesible desde JS
session.use_strict_mode = On
max_execution_time = 30
upload_max_filesize = 10M
post_max_size = 10M
```

**Apache .htaccess (en raíz del proyecto):**
```apache
# Forzar HTTPS
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]

# Ocultar archivos sensibles
<FilesMatch "^\.(env|git|htaccess)$">
    Order allow,deny
    Deny from all
</FilesMatch>

# Bloquear acceso a scripts/migrations/
<Directory "/var/www/html/pronom/scripts/migrations">
    Deny from all
</Directory>
```

---

## 🛡️ Checklist de Seguridad Pre-Producción

- [ ] Archivo `.env` creado y configurado con credenciales reales
- [ ] `debug_auth.php` eliminado (o movido a carpeta privada)
- [ ] HTTPS habilitado y APP_ENV = production
- [ ] Logs configurados: `logs/` directorio creado y permisos 777
- [ ] BD respalda (backup antes de migración)
- [ ] Pruebas de login con usuarios reales
- [ ] Validar cambio de contraseña
- [ ] Pruebas de recuperación de contraseña
- [ ] Revisar logs de errores PHP
- [ ] CORS configurado si se accede desde múltiples dominios

---

## 📝 Estructura de Directorios Segura

```
pronom/
├── .env                    ← Credenciales (NO en Git)
├── .env.example           ← Template (en Git)
├── .gitignore             ← Incluir .env, logs/
├── index.php
├── debug_auth.php         ← ELIMINAR o mover a privado
├── src/
│   ├── config.php         ← Carga .env
│   ├── EnvLoader.php      ← Cargador de variables
│   ├── SecurityMiddleware.php
│   ├── prepare.php
│   ├── menu_principal.php
│   ├── usuarios.php
│   └── ...
├── scripts/
│   ├── *.sql              ← Scripts de BD
│   └── migrations/
│       └── password_migrator.php  ← Protegido/privado
├── logs/                  ← Errores y auditoría
├── css/
└── js/
```

---

## 🔍 Validación de Seguridad

### Test de Login
```bash
curl -X POST https://tu-servidor.com \
  -d "txt_usuario=admin&txt_clave=tucontraseña"
```

### Revisar Headers
```bash
curl -I https://tu-servidor.com
# Debe incluir: X-Frame-Options, X-Content-Type-Options, etc.
```

### Validar HTTPS
```bash
curl -I http://tu-servidor.com
# Debe redirigir a https://
```

---

## 📞 Soporte y Mantenimiento

- **Rotación de logs:** Implementar logrotate
- **Respaldo de BD:** Programar dumps diarios
- **Monitoreo:** Revisar `logs/php_errors.log` regularmente
- **Actualizaciones:** Mantener PostgreSQL y PHP actualizados

---

**Versión:** SistNomina v1.2  
**Última actualización:** 21 de febrero de 2026  
**Estado de seguridad:** ✅ Mejorado
