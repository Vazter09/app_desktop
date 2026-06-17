# AGENTS.md — database/functions/acceso/usuarios/

## Propósito

6 funciones para CRUD de usuarios y validaciones de login/recuperación de contraseña.

---

## Funciones

1. `fun_insert_tab_usuarios` — crear usuario (valida ID único, nombre, correo)
2. `fun_update_tab_usuarios` — actualizar usuario (nombre, correo, flags)
3. `fun_actualizar_password` — cambiar contraseña (valida mínimo 12 chars)
4. `fun_validar_login` — búsqueda para login (retorna datos si usuario existe)
5. `fun_validar_correo` — valida par (ID_usuario, correo) para recuperación
6. `fun_validar_usuario` — retorna ID + nombre si usuario activo

---

## Estado de despliegue

**Incluidas en setup.sh (las 6):**
- fun_insert_tab_usuarios
- fun_update_tab_usuarios
- fun_actualizar_password
- fun_validar_login
- fun_validar_correo
- fun_validar_usuario

> **Nota (E7, 2026-06-13):** `fun_validar_login`, `fun_validar_correo` y `fun_validar_usuario` estaban
> ausentes del `FUNCS` de `setup_smartcset.sh`. Se revisaron, se alineó su manejo de errores al patrón
> estándar (`smartcset_handle_sql_error()`) y se agregaron a `FUNCS`. Ver
> `Documentacion para implementacion de MSPI/FASE 01_Blindaje Técnico Inmediato/REPORTE_E1-E07_CORRECCION_SETUP_SMARTCSET.md`.
> Estas 3 funciones **no son llamadas actualmente desde PHP** (login y recuperación usan SQL directo en
> `prepare.php`/`recuperar.php`) — su inclusión cierra una brecha documental, no corrige una falla activa.

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

- Las 6 funciones ya están incluidas en `setup.sh`; si se agrega una nueva, recordar añadirla a `FUNCS`
- La validación de longitud de contraseña (12+ chars) es obligatoria
- El hash es una cadena bcrypt, NO encriptable — solo comparable via `password_verify()`
