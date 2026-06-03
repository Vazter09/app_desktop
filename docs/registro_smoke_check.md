# Checklist de validación — Módulo Registro

## 1) Precondiciones (admin)

- En el login principal (`index.php`) entrar como admin.
- Ir a **Admin → Config. sistema**.
- Activar **Habilitar registro de personas**.
- Definir **usuario** y (si aplica) **clave** del login de registro.
- Guardar configuración.
- Ejecutar migración de menús si aplica: `database/migrations/update_menu_registro_listado_admin.sql`.

## 2) Acceso registrantes/operadores

- Abrir `src/modulos/registro/login.php`.
- Validar que si el módulo está deshabilitado, aparece el mensaje “Módulo de registro deshabilitado” (503).
- Con el módulo habilitado:
  - Probar credenciales incorrectas → debe mostrar error y no dejar entrar.
  - Probar credenciales correctas → debe redirigir al panel `src/modulos/registro/index.php`.

## 3) Panel público `src/modulos/registro/index.php`

- Debe mostrar cuatro tarjetas con íconos emoji (🎓, 👨🏻‍🏫, 🏛️, 🛠️).
- Cada tarjeta enlaza al formulario correspondiente en `forms/*.php`.
- No debe mostrar tabla ni registro inline en este panel.

## 4) Listados en admin (0301–0304)

- Desde el login principal, abrir **Registro personas → Aprendiz** (y los demás tipos).
- Debe cargar `src/admin/personas/aprendices/index.php` (y rutas hermanas) con tabla (Tipo, Documento, Nombres, Correo, Dirección, F. Nac., Estado).
- El botón **+ Registrar nuevo** enlaza al formulario del módulo público (requiere sesión de registro si se usa directamente).

## 5) Formularios `forms/*.php`

- Completar datos obligatorios y enviar (POST al mismo formulario).
- Debe guardar en BD o mostrar error de validación/BD.
- **Volver** regresa al panel público `index.php`.

## 6) Logout (módulo registro)

- Desde el panel público, usar “Salir”.
- Debe limpiar sesión del módulo y volver a `src/modulos/registro/login.php`.
