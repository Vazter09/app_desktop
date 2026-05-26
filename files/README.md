# CSET SYSTEM — Sistema de Gestión de Personas
## Instrucciones de Despliegue

### Estructura de Archivos
```
cset_app/
├── login.php                  ← Página de inicio de sesión
├── index.php                  ← Panel principal (tipos de persona)
├── assets/
│   └── style.css              ← Estilos futuristas globales
├── includes/
│   ├── auth.php               ← Gestión de sesión y autenticación
│   ├── db.php                 ← Conexión PDO y funciones de BD
│   └── ajax_ciudades.php      ← Endpoint AJAX para ciudades
└── forms/
    ├── aprendiz.php           ← Formulario de registro de aprendiz
    ├── instructor.php         ← Formulario de registro de instructor
    ├── funcionario.php        ← Formulario de registro de funcionario
    └── contratista.php        ← Formulario de registro de contratista
```

### Credenciales de Acceso
- **Usuario:** `usuariocset`
- **Contraseña:** `usuariocset`

### Configuración de Base de Datos
Edite el archivo `includes/db.php` y ajuste las constantes:
```php
define('DB_HOST', 'localhost');      // Host PostgreSQL
define('DB_PORT', '5432');           // Puerto
define('DB_NAME', 'cset_db');        // Nombre de la base de datos
define('DB_USER', 'postgres');       // Usuario de BD
define('DB_PASS', 'tu_password');    // Contraseña de BD
define('DB_SCHEMA', 'public');       // Esquema
```

### Requisitos del Servidor
- PHP 8.0 o superior
- Extensión `pdo_pgsql` habilitada en PHP
- PostgreSQL 13 o superior
- Servidor web: Apache (con mod_rewrite) o Nginx
- Las tablas del esquema deben estar creadas previamente

### Verificar extensión PDO PostgreSQL
```bash
php -m | grep pdo_pgsql
# Si no aparece, habilitar en php.ini:
# extension=pdo_pgsql
```

### Tablas de catálogo requeridas (deben existir)
- `tab_tipos_docum`
- `tab_tipos_persona`
- `tab_niveles_estudio`
- `tab_profesiones`
- `tab_dptos`
- `tab_ciudades`
- `tab_centros`
- `tab_redes`
- `tab_fichas`

### Notas de Seguridad
- Cambiar las credenciales de acceso en `includes/auth.php`
- En producción, mover `includes/` fuera del document root
- Configurar HTTPS en el servidor web
- Revisar permisos de archivos (644 para .php, 755 para directorios)
