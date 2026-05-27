# AGENTS.md — src/modulos/entradas/

## Propósito

CRUD de las puertas/entradas del centro SENA. Define dónde pueden ingresar/salir las personas (códigos 1-9). Solo accesible a administradores.

---

## Archivos y su función

### index.php

CRUD completo de entradas:
- GET `action=view` — lista todas las entradas (1-9) en tabla
- GET `action=edit&id=X` — formulario para editar entrada
- POST — procesa inserción/actualización

**Campos:**
- `id_entrada_centro` — código de puerta (1-9)
- `nom_entrada_centro` — nombre descriptivo (ej. "Puerta Principal")
- `descripcion` — descripción adicional (opcional)
- `ind_estado` — estado activo/inactivo

**Depende de:**
- Prepared statements para operaciones CRUD en `tab_entradas_centro`
- Cadena institucional: `id_centro` y `id_sede` seteados en constantes del proyecto

### init.php

Bootstrap del módulo. Carga `prepare.php` y define constantes de centro/sede.

**Constantes:**
```php
define('CSET_ID_CENTRO_DEV', 1);  // Centro para desarrollo
define('CSET_ID_SEDE_DEV', 1);    // Sede para desarrollo
```

---

## Validaciones

- Los códigos de puerta van de 1 a 9 (constraint en BD)
- El nombre debe ser 3-50 caracteres
- Mínimo una puerta debe estar activa (no permitir desactivar la última)
- Las entradas pertenecen a un centro/sede específico (relación con `tab_sedes`)

---

## Dependencias

- Depende de `prepare.php` incluido via `init.php`
- Depende de tabla `tab_entradas_centro` en BD
- Depende de relación con `tab_sedes.(id_centro, id_sede)` — las entradas requieren centro/sede existente

---

## Convenciones específicas

- Los códigos 1-9 son fijos — no son IDs asignados automáticamente
- Las constantes `CSET_ID_CENTRO_DEV` y `CSET_ID_SEDE_DEV` definen el contexto institucional para desarrollo

---

## Qué NO tocar sin entender primero

- No permitir crear puerta con código 0 o >9 — rango 1-9 es obligatorio
- No permitir desactivar la última entrada activa — validar siempre
- No cambiar los valores de `CSET_ID_CENTRO_DEV` y `CSET_ID_SEDE_DEV` sin actualizar BD también
- No asumir que `id_centro` y `id_sede` siempre existen — validar en `tab_sedes`
