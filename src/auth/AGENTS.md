# AGENTS.md — src/auth/

## Propósito

Módulo de autenticación secundaria. Los scripts aquí manejan logout, recuperación de contraseña y cambio de contraseña — todas operaciones que ocurren después del login inicial en `index.php`.

---

## Archivos y su función

### logout.php

Destruye la sesión PHP y redirige a `index.php`. Script simple, no toma parámetros.

**Flujo:**
1. GET o POST a `logout.php`
2. `session_destroy()`
3. `header('Location: index.php')`

### recuperar.php

Formulario y procesador de recuperación de contraseña. Dos modos:
1. **Modo correo:** usuario ingresa ID + correo registrado
2. **Modo pantalla:** usuario ingresa solo ID y recibe clave temporal

Genera clave aleatoria de 12 caracteres, la hashea con bcrypt y actualiza `tab_usuarios.pass_usuario`.

**Variables de sesión usadas:**
- Lee flash messages para mostrar en vista
- Escribe flash_msg al procesar

**Depende de:**
- SQL directo en `prepare.php`: `$stmt_valida_mail` (valida ID_usuario + correo) y `$stmt_upd_pass`
  (actualiza el hash). **No llama** a `fun_validar_correo()` ni a `fun_actualizar_password()` — esas
  funciones PL/pgSQL existen y están incluidas en `setup.sh` (desde E7), pero el flujo de recuperación
  actual usa consultas directas, no estas funciones.

### cambiar_clave.php

Formulario de cambio de contraseña para el usuario logueado. Requiere sesión activa.

**Flujo:**
1. GET a `cambiar_clave.php` — muestra formulario
2. POST con `clave_actual`, `clave_nueva`, `clave_nueva_confirm`
3. PHP valida `clave_actual` con `password_verify()` contra hash en BD
4. PHP valida `clave_nueva` con `validarLongitudPassword()` (mínimo 12 chars)
5. PHP hashea `clave_nueva` con `password_hash($pass, PASSWORD_BCRYPT)`
6. PHP llama función PL/pgSQL `fun_actualizar_password()`

**Depende de:**
- `validarLongitudPassword()` de `helpers.php`
- `fun_actualizar_password()` de PL/pgSQL
- Sesión activa (`$_SESSION['id_usuario']`)

---

## Convenciones específicas

- `logout.php` no debe mostrar ningún HTML; solo destruir sesión y redirigir
- `recuperar.php` genera claves con `bin2hex(random_bytes(6))` (12 caracteres hex)
- `cambiar_clave.php` nunca muestra la contraseña actual en HTML; valida solo en servidor
- Los formularios usan `<input type="password">` para ocultar entrada

---

## Dependencias

- `logout.php` depende de: sesión PHP (puede destruir incluso si está vacía)
- `recuperar.php` depende de: `$stmt_valida_mail` y `$stmt_upd_pass` (SQL directo en `prepare.php`),
  no de las funciones PL/pgSQL `fun_validar_correo()`/`fun_actualizar_password()`
- `cambiar_clave.php` depende de: `validarLongitudPassword()`, `fun_actualizar_password()`, sesión activa

---

## Qué NO tocar sin entender primero

- No agregar lógica de "cambiar contraseña de otro usuario" desde `cambiar_clave.php` — siempre es del usuario logueado
- No generar claves temporales con algoritmos débiles; usar `bin2hex(random_bytes(N))`
- No pasar la contraseña nueva sin hashear a PostgreSQL; hashear siempre en PHP primero
- No mostrar un mensaje "contraseña anterior incorrecta" muy diferente del "contraseña nueva no válida" — ambos deben ser genéricos para no revelar si el usuario existe
- No olvidar validar longitud mínima de `clave_nueva`; la validación es obligatoria en `cambiar_clave.php`
