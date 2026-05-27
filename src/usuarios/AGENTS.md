# AGENTS.md — src/usuarios/

## Propósito

Módulo de administración de usuarios del sistema SmartCSET. CRUD completo: crear, editar, listar, habilitar/deshabilitar usuarios. Solo accesible a administradores.

---

## Archivos y su función

### usuarios.php

Único archivo. CRUD completo de usuarios: lista todos los usuarios, permite crear nuevos, editar existentes, toggle de estado activo/inactivo, toggle de rol administrador.

**Acciones (via GET parameter `action`):**
- `action=view` — lista todos los usuarios en tabla
- `action=edit&id=XXX` — muestra formulario de edición/alta
- POST — procesa formulario (inserción o actualización)

**Depende de:**
- Funciones PL/pgSQL: `fun_insert_tab_usuarios()`, `fun_update_tab_usuarios()`
- Prepared statements: `$stmt_fun_ins_user`, `$stmt_fun_upd_user`, `$stmt_list_users`

**Campos de usuario:**
- `id_usuario` — identificador único (VARCHAR, no puede cambiar tras crear)
- `nom_usuario` — nombre completo
- `mail_usuario` — correo corporativo
- `pass_usuario` — hash bcrypt (nunca mostrar)
- `ind_usuario` — booleano, es administrador
- `ind_estado` — booleano, está activo

---

## Flujo de creación de usuario

1. Usuario admin abre `usuarios.php?action=edit` (sin ID)
2. Formulario vacío para crear nuevo
3. Admin ingresa: id, nombre, correo, contraseña inicial
4. POST a `usuarios.php`
5. PHP valida: id único, nombre 3-50 chars, correo con @, password 12+ chars
6. PHP hashea contraseña: `password_hash($pass, PASSWORD_BCRYPT)`
7. PHP llama `fun_insert_tab_usuarios(id, nom, mail, hash_bcrypt, ind_estado=true, ind_usuario=false)`
8. PostgreSQL inserta fila con `usr_insert` = ID del admin logueado
9. Flash message: "Usuario creado"
10. Redirige a listado

---

## Flujo de edición

1. Admin abre `usuarios.php?action=edit&id=usuario123`
2. Formulario con datos actuales (password vacío)
3. Admin puede cambiar: nombre, correo, estado, rol
4. Si el campo password está vacío, se conserva el hash anterior
5. Si el campo password tiene valor, se hashea y se actualiza
6. POST a `usuarios.php`
7. PHP llama `fun_update_tab_usuarios(id, nom, mail, hash_o_null, ind_estado, ind_usuario)`
8. PostgreSQL actualiza fila (si hash_o_null es NULL, conserva hash anterior)
9. Flash message: "Usuario actualizado"

---

## Convenciones específicas

- **Las contraseñas siempre se hashean en PHP con `password_hash($pass, PASSWORD_BCRYPT)`** — PostgreSQL nunca valida contraseñas, solo las almacena
- **Si el campo password está vacío en edición, el prepared statement recibe NULL** — la función PL/pgSQL interpreta NULL como "no cambiar"
- **La validación de longitud mínima (12 chars) es obligatoria antes de hashear**
- **El `id_usuario` es inmutable tras creación** — no permitir su edición
- **Al crear admin, validar que no sea la última persona con `ind_usuario=true`** — prevenir que se bloquee el sistema

---

## Dependencias

- Depende de `prepare.php` (crea `$pdo` y prepared statements)
- Depende de funciones PL/pgSQL: `fun_insert_tab_usuarios()`, `fun_update_tab_usuarios()`
- Depende de `validarLongitudPassword()` de `helpers.php`

---

## Qué NO tocar sin entender primero

- No permitir que el último usuario administrador desactualice su propio `ind_usuario` — agregar validación que previene lockout
- No asumir que `$_SESSION['ind_usuario'] === true` garantiza permisos — validar siempre antes de permitir acceso a este script
- No cambiar el tipo de `ind_usuario` de BOOLEAN a INTEGER o similar — `tab_usuarios` espera BOOLEAN
- No pasar la contraseña sin hashear a la función PL/pgSQL — siempre hashear en PHP primero con `password_hash()`
- No reutilizar el mismo salt o hash en varios usuarios — `password_hash()` genera un salt nuevo cada vez
- No permitir cambiar `id_usuario` de un usuario existente — la PK es inmutable, crear uno nuevo si se necesita cambiar
