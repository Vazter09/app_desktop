# AGENTS.md — src/modulos/registro/

## Propósito

Módulo de registro de personas con autenticación standalone. Permite registrar 4 tipos de persona (aprendiz, instructor, funcionario, contratista) sin necesidad de usuario del sistema principal.

---

## Características especiales

- **Autenticación propia:** usa `$_SESSION['registro_authenticated']` (NO `$_SESSION['id_usuario']`)
- **Independencia:** funciona completamente separado del login principal
- **Credenciales configurables:** usuario/contraseña almacenados en `tab_config_sistema`

---

## Archivos y su función

### login.php

Login standalone del módulo. Valida `usr_registro` y `pass_registro_hash` contra valores en `tab_config_sistema`. Si es correcto, setea `$_SESSION['registro_authenticated'] = true` y redirige a `index.php`.

**Parámetros POST:**
- `usuario` — usuario del módulo registro
- `clave` — contraseña (validada con `password_verify()` contra hash bcrypt)

### index.php

Panel de control principal del módulo. Muestra 4 tarjetas (aprendiz, instructor, funcionario, contratista) con descripción, ícono y botón para ir a formulario de registro.

**Espera:**
- Sesión `$_SESSION['registro_authenticated'] === true`

### init.php

Bootstrap del módulo. Incluye `prepare.php`, helpers, valida que sesión registrada existe.

**Efecto:**
- Variables globales `$pdo`, `$stmt_*` disponibles
- Variable `$smartcset_asset_href` calculada
- Redirige a `login.php` si no hay sesión registrada

### ajax_ciudades.php

Endpoint AJAX: retorna ciudades filtradas por departamento. Usado por formularios de registro para populate dropdown de ciudades.

**Parámetro POST:**
- `id_dpto` — ID del departamento

**Retorna:**
- JSON: `[ { "id_ciudad": ..., "nom_ciudad": ... }, ... ]`

### ajax_personas.php

Endpoint AJAX: busca personas existentes por fragmento de nombre o documento. Usado en formularios de búsqueda de persona preexistente.

**Parámetro POST:**
- `busqueda` — fragmento de nombre o documento

**Retorna:**
- JSON: `[ { "id_persona": ..., "nom_persona": ..., "tipo": ... }, ... ]`

---

## Flujo típico

1. Usuario abre `http://localhost:8080/src/modulos/registro/`
2. Sin sesión, redirige a `login.php`
3. Ingresa credenciales del módulo registro (no usuario del sistema)
4. POST a `login.php`, setea `$_SESSION['registro_authenticated']`
5. Redirige a `index.php`
6. Muestra 4 tarjetas de tipos de persona
7. Abre formulario de tipo seleccionado (ej. `forms/aprendiz.php`)
8. Completa datos y envía
9. Formulario procesa directamente (no hay procesador separado) — inserta en `tab_personas`

---

## Dependencias

- Depende de `prepare.php` incluido via `init.php`
- Depende de `tab_config_sistema` para credenciales
- Depende de funciones de `lib/` para búsquedas y catalogos
- Depende de formularios en `forms/` para captura de datos

---

## Convenciones específicas

- **Sesión independiente:** `$_SESSION['registro_authenticated']` NO está relacionada con `$_SESSION['id_usuario']` del login principal
- **Directorio lib/:** contiene funciones de acceso `registroGet*()`, `registroRequireAccess()`, etc.
- **Directorio forms/:** cada archivo es un formulario de un tipo de persona; heredan estructura común de `forms/persona.php`

---

## Qué NO tocar sin entender primero

- No confundir `$_SESSION['registro_authenticated']` con `$_SESSION['id_usuario']` — son independientes
- No asumir que existe `$_SESSION['id_usuario']` dentro del módulo registro — validar siempre
- No cambiar el nombre de `login.php` — es el punto de entrada del módulo
- No permitir acceso a `index.php` sin `$_SESSION['registro_authenticated']` seteada
- No mezclar el login del módulo registro con el login principal (`index.php` en raíz)
