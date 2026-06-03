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
- `id_entrada_centro` — código de puerta (1-9), **asignado automáticamente** al crear vía `fun_upsert_tab_entradas_centro`
- `nom_entrada_centro` — nombre descriptivo (ej. "Puerta Principal")
- `descripcion` — descripción adicional (opcional)
- `ind_estado` — estado activo/inactivo

**Depende de:**
- `$stmt_list_entradas` — listado con join a sede/centro
- `$stmt_fun_upsert_entrada` → `fun_upsert_tab_entradas_centro`
- `$stmt_fun_delete_entrada` → `fun_delete_tab_entradas_centro`
- Catálogo `tab_sedes` + `tab_centros`: el modal exige elegir sede (`sel_sede` = `id_centro:id_sede`)

### init.php

Bootstrap del módulo. Carga `prepare.php`.

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

- Los códigos 1-9 son fijos — no son IDs asignados automáticamente (PK global, no por sede)
- Al crear/editar se elige sede en UI; el listado muestra centro y sede

---

## Qué NO tocar sin entender primero

- No permitir crear puerta con código 0 o >9 — rango 1-9 es obligatorio
- No permitir desactivar la última entrada activa — validar siempre
- No asumir que `id_centro` y `id_sede` siempre existen — validar en `tab_sedes`
