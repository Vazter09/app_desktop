# AGENTS.md — src/modulos/

## Propósito

Directorio contenedor de los tres módulos funcionales de negocio del sistema: Portería (control de acceso), Registro (registro de personas), y Entradas (configuración de puertas).

---

## Estructura general

```
modulos/
├── porteria/            ← Control de acceso físico (ingreso + salida)
│   ├── ingreso/
│   ├── salida/
│   └── lib/
├── registro/            ← Registro de personas (módulo standalone)
│   ├── forms/
│   ├── lib/
│   ├── login.php
│   └── index.php
└── entradas/            ← CRUD de puertas del centro
```

---

## Patrón de cada módulo

**Cada módulo tiene:**
- `init.php` — Bootstrap del módulo que carga `prepare.php` con la profundidad correcta
- `index.php` — Vista principal del módulo
- Opcionalmente `lib/` — Lógica compartida del módulo
- Opcionalmente `forms/` — Formularios específicos del módulo

**Patrón de include en módulos:**
```php
<?php
// En src/modulos/porteria/ingreso/index.php:
require_once __DIR__ . '/../lib/init.php';  // Sube 2 niveles hasta porteria/lib/

// En src/modulos/porteria/lib/init.php:
require_once dirname(__DIR__, 3) . '/core/prepare.php';  // Sube 3 niveles hasta src/core/
?>
```

**Razón del patrón:** Cada módulo necesita cargar `prepare.php` desde la profundidad correcta para calcular paths relativos. `init.php` del módulo hace ese cálculo una sola vez y los scripts internos lo incluyen.

---

## Módulos principales

### Portería (`porteria/`)

Control de acceso físico al centro. Permite:
- Registro de ingresos de personas
- Registro de salidas de personas
- Consulta de estado de ingreso abierto
- Soporte para lectura manual o por código de barras

**Acceso:** Usuario con perfil portería

**Flujo:** Ver `porteria/AGENTS.md`

### Registro (`registro/`)

Módulo de registro de personas con autenticación standalone. Permite:
- Login independiente (no usa sesión principal)
- Registro de 4 tipos de persona: aprendiz, instructor, funcionario, contratista
- Búsqueda y edición de personas existentes

**Acceso:** Usuarios con credenciales configurables en `tab_config_sistema`

**Característica especial:** Sesión propia (`$_SESSION['registro_authenticated']`), completamente independiente del login principal

**Flujo:** Ver `registro/AGENTS.md`

### Entradas (`entradas/`)

CRUD de las puertas/entradas del centro (códigos 1-9). Define dónde pueden ingresar/salir las personas.

**Acceso:** Usuario administrador

**Depende de:** Cadena institucional SENA (centro, sede)

---

## Convenciones específicas

- Cada módulo tiene su propio `init.php` que es el "punto de entrada" interno del módulo
- Los scripts internos del módulo incluyen el `init.php` del módulo, no directamente `prepare.php`
- La variable `$smartcset_asset_href` se calcula en cada `init.php` y está disponible para templates
- Los módulos pueden tener sesión propia (como `registro/`) que es independiente de la sesión principal

---

## Dependencias entre módulos

- `porteria/` depende de `tab_log_ingresos`, `tab_personas`, `tab_entradas_centro`, `tab_metodos_aut` en BD
- `registro/` depende de `tab_personas`, `tab_tipos_persona`, `tab_ciudades` en BD; tiene sesión propia
- `entradas/` depende de `tab_entradas_centro` en BD; requiere configuración de centro/sede

---

## Qué NO tocar sin entender primero

- No incluir `prepare.php` directamente desde scripts dentro de módulos — siempre incluir el `init.php` del módulo
- No mezclar sesiones — `registro/` tiene `$_SESSION['registro_authenticated']` que es independiente de `$_SESSION['id_usuario']`
- No asumir que `$_SESSION['id_usuario']` existe en `registro/` — validar siempre
- No crear ciclos de include entre `init.php` de módulos diferentes
- No cambiar la estructura de directorios (ingreso/salida/lib dentro de porteria) sin actualizar todos los `dirname(__DIR__, N)` en rutas
