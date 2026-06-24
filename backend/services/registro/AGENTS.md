# AGENTS.md — src/modulos/registro/lib/

## Propósito

Librería de funciones y utilidades del módulo registro. Control de acceso, carga de catálogos, y funciones de listado.

---

## Archivos y su función

### access.php

Control de acceso del módulo. Función principal: `registroRequireAccess()`.

Funciones:
- `registroRequireAccess()` — valida que `$_SESSION['registro_authenticated']` existe; sino redirige a `login.php` y termina
- `registroAuthenticateStandalone(string $usr, string $pass): bool` — valida credenciales contra `AppConfig::usrRegistro()` y `AppConfig::passRegistroHash()`
- `registroLogout()` — destruye sesión de registro
- `registroDisplayUsername()` — retorna usuario logueado en módulo registro
- `registroModuloHabilitado(): bool` — verifica `AppConfig::moduloRegistroHabilitado()`

También define constantes de redirección:
- `REGISTRO_LOGIN_URL` — ruta a `login.php`
- `REGISTRO_INDEX_URL` — ruta a `index.php`

### catalogos.php

Carga de catálogos para dropdowns de formularios.

Funciones:
- `registroGetTiposDocumento(PDO $pdo): array` — retorna tipos de documento (CC, CE, TI, etc.)
- `registroGetDepartamentos(PDO $pdo): array` — retorna departamentos de Colombia
- `registroGetCiudades(PDO $pdo, string $id_dpto): array` — retorna ciudades de un departamento
- `registroGetTiposPersona(PDO $pdo): array` — retorna tipos de persona (aprendiz, instructor, etc.)
- `registroGetFichas(PDO $pdo): array` — fichas con `ind_abierta = TRUE`; incluye `nom_programa`, `nom_centro` y `etiqueta` (id + contexto)
- `registroGetAreas(PDO $pdo): array` — áreas con `nom_centro` y `etiqueta`
- `registroGetCargos(PDO $pdo): array` — cargos con `etiqueta`
- También: `registroGetCentros`, `registroGetRedes`, `registroGetNivelesEstudio`, `registroGetProfesiones`

### personas_list.php

Función de listado de personas registradas.

Funciones:
- `registroFetchPersonasPorTipo(PDO $pdo, string $tipo, int $limite = 50): array` — retorna personas filtradas por tipo

---

## Convenciones específicas

- Todas las funciones que consultan BD reciben `PDO $pdo` como parámetro
- Los catálogos devuelven array asociativo: `["id" => "nombre", ...]`
- Las funciones usan nombres de función con prefijo `registro` — nunca `porteria` u otros módulos

---

## Dependencias

- Todas dependen de `$pdo` que viene de `prepare.php` incluido via módulo `init.php`
- `access.php` depende de clase `AppConfig` para leer credenciales
- `catalogos.php` depende de tablas maestras en BD

---

## Qué NO tocar sin entender primero

- No cambiar `registroRequireAccess()` — todos los scripts del módulo lo llaman para validar sesión
- No asumir que `$_SESSION['id_usuario']` existe — dentro del módulo registro solo existe `$_SESSION['registro_authenticated']`
- No confundir funciones `registroGet*` con nombres de tabla — son funciones de utilidad, no directo a BD
