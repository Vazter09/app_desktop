# AGENTS.md — src/admin/

## Propósito

Módulo de administración del sistema. Incluye configuración global del sistema (colores, logo, nombre, módulos habilitados) y listados administrativos de datos (personas registradas, etc.). Solo accesible a administradores.

---

## Archivos y su función

### configuracion.php

Panel de configuración del sistema (solo admin). Permite cambiar:
- Nombre del sistema
- Colores corporativos (verde oscuro, verde oliva)
- Logo institucional (subida drag-and-drop)
- Tema oscuro/claro (tokens CSS)
- Módulos habilitados (flags)
- Credenciales del módulo de registro standalone (usuario/contraseña)

**Depende de:**
- Clase `AppConfig` con métodos de lectura/escritura
- Función PL/pgSQL `fun_update_tab_config_sistema()`
- Clase `LogoUpload` para procesar subidas

**Comportamiento:**
1. GET: muestra formulario con valores actuales
2. POST con `action=save`: actualiza todos los parámetros
3. POST con `action=restaurar_seccion&seccion=GENERAL`: restaura una sección a valores por defecto
4. Tras actualización, llama `AppConfig::reset()` y `AppConfig::boot($pdo)` para que el tema se recalcule en la misma request

**Variables de sesión:**
- Lee flash messages
- Escribe flash_msg al procesar

### registro/

Subdirectorio con listado administrativo de personas registradas. Ver `AGENTS.md` de subdirectorio para detalles.

---

## Flujo de actualización de configuración

1. Admin GET a `configuracion.php`
2. Página carga valores actuales de `AppConfig::nomSistema()`, etc.
3. Admin modifica campos y hace POST
4. PHP valida: nombre 3-50 chars, colores con formato hex, contraseña 8+ chars si se cambia
5. PHP procesa archivo de logo si se subió (via `LogoUpload::processUpload()`)
6. PHP llama `fun_update_tab_config_sistema(nom, col_oscuro, col_oliva, path_logo, tokens_oscuro, tokens_claro, ...)`
7. PostgreSQL actualiza fila única de `tab_config_sistema` (id_config=1)
8. PHP llama `AppConfig::reset()` para limpiar cache
9. PHP llama `AppConfig::boot($pdo)` para recargar desde BD
10. Flash message: "Configuración actualizada"
11. Página refresca con nuevos valores

---

## Convenciones específicas

- `tab_config_sistema` tiene exactamente UNA fila con `id_config = 1` — nunca crear más filas
- `AppConfig::reset()` es necesario porque la clase es singleton con cache estático — sin reset, los cambios no se reflejan
- Los colores se almacenan como strings hex (#RRGGBB) en BD pero se convierten a rgba() en CSS via `AppConfig::hexToRgba()`
- Los tokens CSS (oscuro/claro) se almacenan como JSON en `tab_config_sistema` — `AppConfig::themeTokensDark()` devuelve array asociativo

---

## Dependencias

- Depende de `prepare.php` (crea `$pdo`)
- Depende de clase `AppConfig` con métodos: `nomSistema()`, `colorPrimario()`, `pathLogo()`, `usrRegistro()`, etc.
- Depende de función PL/pgSQL `fun_update_tab_config_sistema()` con 29 parámetros
- Depende de clase `LogoUpload` para procesar archivos
- Depende de clase `ConfigSistemaDefaults` para valores por defecto al restaurar

---

## Qué NO tocar sin entender primero

- No olvidar llamar `AppConfig::reset()` tras actualizar config — sin esto, los cambios no se ven hasta recargar página o reiniciar servidor
- No cambiar el formato de almacenamiento de colores (hex) sin actualizar `AppConfig::hexToRgba()` — otros lugares asumen hex
- No permitir crear más filas en `tab_config_sistema` — la tabla es diseño singular (id_config es siempre 1)
- No asumir que todos los tokens CSS están presentes en la BD — usar `array_merge(defaults, bd_values)` al leer
- No validar que un color sea válido hex solo con regex — usar `AppConfig::hexToRgba()` que lanza si es inválido
