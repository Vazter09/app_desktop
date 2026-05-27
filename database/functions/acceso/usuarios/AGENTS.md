# AGENTS.md — database/functions/acceso/usuarios/

## Propósito

6 funciones para CRUD de usuarios y validaciones de login/recuperación de contraseña.

---

## Funciones

1. `fun_insert_tab_usuarios` — crear usuario (valida ID único, nombre, correo)
2. `fun_update_tab_usuarios` — actualizar usuario (nombre, correo, flags)
3. `fun_actualizar_password` — cambiar contraseña (valida mínimo 12 chars)
4. `fun_validar_login` — búsqueda para login (retorna datos si usuario existe)
5. `fun_validar_correo` — valida par (ID_usuario, correo) para recuperación (AUSENTE del instalador)
6. `fun_validar_usuario` — retorna ID + nombre si usuario activo (AUSENTE del instalador)

---

## Estado de despliegue

**Incluidas en setup.sh:**
- fun_insert_tab_usuarios
- fun_update_tab_usuarios
- fun_actualizar_password

**AUSENTES del setup.sh (BUG CRÍTICO):**
- fun_validar_correo — SIN ESTA, recuperación de contraseña falla inmediatamente
- fun_validar_login
- fun_validar_usuario

---

## Convenciones

- Las contraseñas se hashean en PHP antes de llegar a BD (bcrypt)
- La BD solo almacena y recupera el hash, nunca lo valida
- `password_verify()` se ejecuta en PHP post-login
- Las validaciones (mínimo 12 chars) ocurren en PHP ANTES de hashear

---

## Dependencias

- Dependen de `_helpers/smartcset_raise.sql`
- Operan sobre `tab_usuarios`

---

## Qué NO tocar sin entender primero

- Las 3 funciones ausentes son críticas — sin ellas, login y recuperación fallan
- La validación de longitud de contraseña (12+ chars) es obligatoria
- El hash es una cadena bcrypt, NO encriptable — solo comparable via `password_verify()`
