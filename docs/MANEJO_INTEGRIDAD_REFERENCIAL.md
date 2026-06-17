# 🔐 Manejo Mejorado de Errores de Integridad Referencial

**Fecha:** 3 de marzo de 2026  
**Versión:** 1.1  
**Cambio:** Mensajes claros para violaciones de clave foránea

---

## 📌 Problema Identificado

Cuando el usuario intenta eliminar un menú que está asignado a usuarios, aparece:

```
❌ ERR: update o delete en «tab_menus» viola la llave foránea 
   «tab_menu_usuarios_id_menu_fkey» en la tabla «tab_menu_usuarios»
```

**Resultado:** El usuario NO entiende qué hacer.

---

## ✅ Solución Implementada

El mensaje ahora dice:

```
❌ No se puede eliminar este menú.

Motivo: Está asignado a usuarios.

Acción: Primero debe desasignarlo a todos los usuarios 
en la sección 'Gestión de Accesos de Usuarios'.
```

**Resultado:** El usuario entiende EXACTAMENTE qué pasó y qué hacer.

---

## 🔄 Cómo Funciona

### 1. Captura del Error (PDOException)

Cuando PostgreSQL rechaza una operación por violación FK:
```php
try {
    $stmt_del_menu->execute([$id]);
} catch (PDOException $e) {
    // Error capturado aquí
}
```

### 2. Detección de SQLSTATE 23503

```php
$errorInfo = $e->errorInfo;
if ($errorInfo[0] === '23503') {
    // Es error de clave foránea
}
```

### 3. Manejo Contextualizado

```php
$w_respuesta_json = ErrorHandler::handleForeignKeyViolation(
    $e,
    'DELETE',  // Tipo de operación
    ['tabla' => 'tab_menus']  // Contexto
);
```

### 4. Mensaje Personalizado Según Tabla

```php
if (strpos($nativeMessage, 'tab_menu_usuarios') !== false) {
    // Menú está en tab_menu_usuarios
    $userMessage = "No se puede eliminar este menú porque está asignado a usuarios...";
} elseif (strpos($nativeMessage, 'tab_usuarios') !== false) {
    // Es problema con usuarios
    $userMessage = "No se puede eliminar este usuario porque...";
}
```

### 5. Visualización Clara

```html
<div class="alert alert-danger" style="white-space: pre-wrap;">
    ❌ No se puede eliminar este menú.
    
    Motivo: Está asignado a usuarios.
    
    Acción: Primero debe desasignarlo...
</div>
```

---

## 📊 Tabla de Mensajes por Tabla

| Tabla | Operación | Mensaje |
|-------|-----------|---------|
| tab_menus | DELETE | "Está asignado a usuarios. Desasignarlo en Gestión de Accesos." |
| tab_usuarios | DELETE | "Tiene registros relacionados en el sistema. Resolver relaciones." |
| tab_menus | INSERT/UPDATE | "Referencia inválida. Verificar IDs referenciados existan." |

---

## 🔧 Archivo Modificado

**`src/menus.php`**
- ✅ Importa ErrorHandler.php
- ✅ Detecta SQLSTATE 23503
- ✅ Usa `handleForeignKeyViolation()`
- ✅ Muestra mensaje claro con saltos de línea (`white-space: pre-wrap`)

**`src/ErrorHandler.php`**
- ✅ Nuevo método: `handleForeignKeyViolation()`
- ✅ Detecta tabla en mensaje nativo
- ✅ Personaliza mensaje según contexto

---

## 🚀 Aplicar a Otros Archivos CRUD

### Paso 1: Importar ErrorHandler
```php
<?php
require_once('ErrorHandler.php');
```

### Paso 2: Capturar excepción específica
```php
try {
    // tu DELETE/INSERT/UPDATE
    $stmt->execute($params);
} catch (PDOException $e) {
    $errorInfo = $e->errorInfo;
    
    // Si es FK
    if ($errorInfo[0] === '23503') {
        $respuesta = ErrorHandler::handleForeignKeyViolation(
            $e,
            'DELETE',  // O 'INSERT', 'UPDATE'
            ['tabla' => 'tu_tabla']
        );
        ErrorHandler::sendJSON($respuesta);
    } else {
        // Otro error BD
        ErrorHandler::sendJSON(
            ErrorHandler::handleDatabaseException($e)
        );
    }
}
```

### Paso 3: Mejora la visualización
```html
<div class="alert alert-danger" style="white-space: pre-wrap;">
    <?= htmlspecialchars($mensaje) ?>
</div>
```

---

## 📋 Ejemplos de Contextos

### Menú que tiene usuarios asignados
```
Error capturado:
  SQLSTATE: 23503
  Native: "...viola la llave foránea «tab_menu_usuarios_id_menu_fkey»..."

ErrorHandler detecta:
  - strpos(..., 'tab_menu_usuarios') = verdadero
  - operation = 'DELETE'

Mensaje mostrado:
  "❌ No se puede eliminar este menú.
  
   Motivo: Está asignado a usuarios.
   
   Acción: Primero debe desasignarlo en 'Gestión de Accesos de Usuarios'."
```

### Usuario con datos asociados
```
Error capturado:
  SQLSTATE: 23503
  Native: "...viola la llave foránea «tab_usuarios_*_fkey»..."

ErrorHandler detecta:
  - strpos(..., 'tab_usuarios') = verdadero
  - operation = 'DELETE'

Mensaje mostrado:
  "❌ No se puede eliminar este usuario.
  
   Motivo: Tiene registros relacionados en el sistema.
   
   Acción: Primero debe resolver estas relaciones."
```

### FK a tabla inexistente
```
Error capturado:
  SQLSTATE: 23503
  Native: "insert or update on table \"tab_menus\" violates FK..."

ErrorHandler detecta:
  - operation = 'INSERT' o 'UPDATE'
  - No encontrada tabla específica

Mensaje mostrado:
  "❌ No se puede guardar. Referencia inválida.
  
   Motivo: Uno de los datos referenciados no existe.
   
   Acción: Verifique que todos los IDs referenciados existan."
```

---

## 🎯 Métodos Nuevos en ErrorHandler

### `handleForeignKeyViolation($e, $operation, $context)`

**Parámetros:**
- `$e` (PDOException) - La excepción capturada
- `$operation` (string) - 'DELETE', 'INSERT', o 'UPDATE'
- `$context` (array) - Información adicional como `['tabla' => 'nombre']`

**Retorna:**
- Array con estructura estándar: `status`, `message`, `source`, `sqlstate`, `debug`

**Ejemplo:**
```php
$respuesta = ErrorHandler::handleForeignKeyViolation(
    $e,
    'DELETE',
    ['tabla' => 'tab_menus', 'id' => '123']
);

// Resultado:
// [
//   'status' => 'error',
//   'message' => "❌ No se puede eliminar...",
//   'source' => 'DATABASE',
//   'sqlstate' => '23503',
//   'debug' => [...]
// ]
```

---

## 🔍 Cómo Debugear

### En Navegador (F12 Console)

Si fuera AJAX, verías:
```javascript
{
  status: "error",
  message: "❌ No se puede eliminar este menú...",
  source: "DATABASE",
  sqlstate: "23503",
  debug: {
    operation: "DELETE",
    native_message: "...violates foreign key...",
    context: {tabla: "tab_menus"}
  }
}
```

### En Log del Servidor

```
[2026-03-03 14:45:30] REFERENTIAL_INTEGRITY_ERROR | 
Code: 23503 | 
Message: update o delete en «tab_menus» viola... | 
IP: 192.168.1.100
```

---

## ✨ Mejoras Futuras

1. **Detectar automáticamente tabla desde mensaje nativo**
   - En lugar de pasar `['tabla' => '...']`
   - ErrorHandler detecta regex: `«(.+?)_(.+?)_fkey»`

2. **Sugerencias específicas por contexto**
   - "Ve a [enlace a sección]" en lugar de "Primero debe..."

3. **Logging detallado de FK violadas**
   - Dashboard mostrando cuáles tablas son problemas

4. **Auto-limpieza de orfandad**
   - Button "Limpiar registros huérfanos" automático

---

## 📝 Notas Técnicas

### SQLSTATE 23503 vs Error Message

```
SQLSTATE: 23503  ← Código estándar PostgreSQL (clave foránea)

Native Message: 
  "update o delete en «tab_menus» viola la llave foránea 
   «tab_menu_usuarios_id_menu_fkey» en la tabla «tab_menu_usuarios»"
  ↑ Contiene información sobre:
    - Tabla que intenta cambiar: tab_menus
    - Restricción: tab_menu_usuarios_id_menu_fkey
    - Tabla que tiene referencias: tab_menu_usuarios
```

### Detección de Contexto

```php
// El mensaje nativo siempre contiene nombre de tabla referenciada
if (strpos($nativeMessage, 'tab_menu_usuarios') !== false) {
    // Sé que es problema de usuarios con menús
}
```

---

## ✅ Checklist de Implementación

- [x] Mejorado mensaje de 23503 en ErrorHandler
- [x] Agregado método `handleForeignKeyViolation()`
- [x] Actualizado menus.php para usarlo
- [x] Mejorada visualización del mensaje (pre-wrap)
- [x] Contexto detectable por tabla
- [x] Documentación de patrones
- [ ] Aplicar a usuarios.php (próximo)
- [ ] Aplicar a dptos.php (próximo)
- [ ] Aplicar a cargos.php (próximo)

---

## 🎓 Resumen

El usuario antes veía:
```
❌ ERR: update o delete en «tab_menus» viola la llave foránea 
   «tab_menu_usuarios_id_menu_fkey» en la tabla «tab_menu_usuarios»
```

Ahora ve:
```
❌ No se puede eliminar este menú.

Motivo: Está asignado a usuarios.

Acción: Primero debe desasignarlo en 'Gestión de Accesos de Usuarios'.
```

**Diferencia:** 200% más claro y actionable.

