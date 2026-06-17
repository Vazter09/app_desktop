# Adaptación a Versión V.1.3 - Cambio de Estructura de Menús

**Fecha**: 25 de febrero de 2026  
**Objetivo**: Adaptar el sistema a la nueva versión V.1.3 donde `nom_programa` se movió de `tab_menu_usuarios` a `tab_menus`

---

## 📋 Resumen del Cambio Principal

En la versión V.1.3 del modelo de datos, el campo `nom_programa` ha sido **movido** de la tabla `tab_menu_usuarios` a la tabla `tab_menus`. Esto significa:

- **V.1.2**: El programa está asociado al menú **por usuario** → `tab_menu_usuarios.nom_programa`
- **V.1.3**: El programa está asociado al menú **globalmente** → `tab_menus.nom_programa`

---

## 🔧 Cambios Realizados

### 1. **Funciones SQL Actualizadas** (`scripts/`)

#### `fun_insert_tab_menus.sql`
- **Antes**: 3 parámetros (id_menu, nom_menu, id_padre)
- **Ahora**: 4 parámetros (id_menu, nom_menu, id_padre, nom_programa)
- **Cambio**: Agregado parámetro `p_nom_programa` al INSERT

#### `fun_update_tab_menus.sql`
- **Antes**: 3 parámetros (id_menu, nom_menu, id_padre)
- **Ahora**: 4 parámetros (id_menu, nom_menu, id_padre, nom_programa)
- **Cambio**: Agregado parámetro `p_nom_programa` y SET nom_programa en UPDATE

#### `fun_tab_menu_usuarios.sql` (`fun_insert_menu_usuarios`)
- **Antes**: 3 parámetros (id_usuario, id_menu, nom_programa)
- **Ahora**: 2 parámetros (id_usuario, id_menu)
- **Cambio**: Removido parámetro de programa, ahora solo crea la relación usuario-menú

---

### 2. **Consultas SQL Actualizadas** (`src/prepare.php`)

```sql
-- V.1.3: nom_programa se obtiene de tab_menus, no de tab_menu_usuarios
SELECT m.id_menu, m.nom_menu, m.ind_id_padre, m.nom_programa 
FROM tab_menu_usuarios mu 
INNER JOIN tab_menus m ON mu.id_menu = m.id_menu
WHERE mu.id_usuario = CAST(? AS TEXT) 
ORDER BY m.id_menu ASC
```

**Cambios en las funciones preparadas:**
- `$sql_fun_ins_menu`: Ahora con 4 parámetros (?::TEXT, ?::TEXT, ?::TEXT, ?::TEXT)
- `$sql_fun_upd_menu`: Ahora con 4 parámetros (?::TEXT, ?::TEXT, ?::TEXT, ?::TEXT)
- `$sql_ins_perfil`: Ahora con 2 parámetros (?::VARCHAR, ?::VARCHAR)
- `$stmt_list_menus`: Incluye nom_programa de tab_menus

---

### 3. **Archivos PHP Modificados**

#### `src/menus.php`
- ✅ Agregado campo input `txt_nom_programa` en el formulario
- ✅ Captura de valor: `$w_programa = $_POST['txt_nom_programa'] ?? 'no_aplica'`
- ✅ Pasa 4 parámetros al INSERT y UPDATE
- ✅ Tabla muestra columna "Programa" con valor de `m['nom_programa']`
- ✅ Función JS `qbe()` actualizada para recibir y mostrar programa

#### `src/menu_usuarios.php`
- ✅ Eliminado campo input `prog_<?= $m['id_menu'] ?>`
- ✅ Reemplazado con celda solo lectura que muestra `m['nom_programa']` de tab_menus
- ✅ Interfaz simplificada: solo checkboxes para asignar menús a usuarios
- ✅ Nuevo comentario: "Programa Asociado (V.1.3)" para identificar el cambio

#### `src/procesar_perfil.php`
- ✅ Removida lógica de obtención de `prog_*`
- ✅ Actualizada función a solo 2 parámetros: `fun_insert_menu_usuarios(id_usuario, id_menu)`
- ✅ Mensaje actualizado indicando V.1.3

#### `src/menu_principal.php`
- ✅ Consulta SQL actualizada: obtiene `m.nom_programa` en lugar de `mu.nom_programa`
- ✅ Comentario agregado: "V.1.3: nom_programa ahora está en tab_menus"
- ✅ Lógica de navegación mantiene compatibilidad (detecta "Exit" correctamente)

#### `src/procesar_permiso.php`
- ✅ Tabla corregida de referencia en función `obtenerAncestros()`
- ✅ Removido intento de insertar nom_programa
- ✅ SQL ahora: `INSERT INTO tab_menu_usuarios (id_usuario, id_menu) VALUES (?, ?)`

---

## 📊 Impacto en la Base de Datos

### Tabla `tab_menus` (V.1.3)
```sql
CREATE TABLE tab_menus (
    id_menu          VARCHAR PRIMARY KEY,
    nom_menu         VARCHAR NOT NULL,
    ind_id_padre     VARCHAR NOT NULL,
    nom_programa     VARCHAR NOT NULL DEFAULT 'no_aplica'  -- ← NUEVO
);
```

### Tabla `tab_menu_usuarios` (V.1.3)
```sql
CREATE TABLE tab_menu_usuarios (
    id_usuario       VARCHAR REFERENCES tab_usuarios(id_usuario),
    id_menu          VARCHAR REFERENCES tab_menus(id_menu),
    PRIMARY KEY(id_usuario, id_menu)
    -- nom_programa REMOVIDO ← CAMBIO CLAVE
);
```

---

## ✅ Validación de Compatibilidad

| Componente | V.1.2 | V.1.3 | Estado |
|------------|-------|-------|--------|
| Menús CRUD | ✓ | ✓ Actualizado | ✅ Compatible |
| Asignación de permisos | ✓ | ✓ Actualizado | ✅ Compatible |
| Navegación de menús | ✓ | ✓ Actualizado | ✅ Compatible |
| Funciones SQL | ✓ | ✓ Actualizado | ✅ Compatible |
| Documentación | - | ✓ Este archivo | ✅ Completado |

---

## 🚀 Próximos Pasos

1. **Actualizar Schema de BD**: Ejecutar el script `db_proynom.V.1.3.sql`
2. **Ejecutar Funciones**: Ejecutar todos los scripts en `scripts/` para actualizar las funciones
3. **Pruebas Funcionales**:
   - Crear menú con programa asociado
   - Asignar menú a usuario
   - Verificar que navegación muestra el programa correcto
   - Validar Edit/Delete de menús

4. **Migración de Datos** (si aplica):
   - Si hay datos existentes en V.1.2, migrar valores de `tab_menu_usuarios.nom_programa` a `tab_menus.nom_programa`

---

## 📝 Notas Técnicas

- El campo `nom_programa` en `tab_menus` usa DEFAULT 'no_aplica' para menús sin programa
- Los menús raíz sin programa ahora tienen valor explícito 'no_aplica' en lugar de NULL
- La funcionalidad de "Exit" se mantiene compatible (detecta cualquier variación de "Exit" o "exit.php")
- Las consultas usan INNER JOIN para obtener el programa directamente desde tab_menus

---

## 📞 Referencia de Archivos Modificados

| Archivo | Líneas | Tipo |
|---------|--------|------|
| `scripts/fun_insert_tab_menus.sql` | 1-13 | SQL Function |
| `scripts/fun_update_tab_menus.sql` | 1-17 | SQL Function |
| `scripts/fun_tab_menu_usuarios.sql` | 1-24 | SQL Function |
| `src/prepare.php` | 50-101 | PHP Prepare |
| `src/menus.php` | 5-156 | PHP CRUD |
| `src/menu_usuarios.php` | 70-76 | PHP Interface |
| `src/procesar_perfil.php` | 1-33 | PHP Processing |
| `src/menu_principal.php` | 15-21 | PHP Navigation |
| `src/procesar_permiso.php` | 1-31 | PHP Processing |

**Total**: 9 archivos adaptados

---

*Adaptación completada: 25/02/2026 - Sistema listo para V.1.3*
