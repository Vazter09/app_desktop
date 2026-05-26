# 📢 Mejora: Errores de Integridad Referencial Claros

**Fecha:** 3 de marzo de 2026  
**Tipo:** Mejora de UX / Manejo de Errores  
**Impacto:** Usuarios entienden qué hacer cuando algo está relacionado

---

## 🔴 Problema Original

Cuando intentas eliminar un menú que está asignado a usuarios:

```
❌ ERR: update o delete en «tab_menus» viola la llave foránea 
   «tab_menu_usuarios_id_menu_fkey» en la tabla «tab_menu_usuarios»
```

**Usuario piensa:**
- ¿Qué es SQLSTATE?
- ¿Qué es una llave foránea?
- ¿Qué debo hacer?
- **Confused. Cierra el navegador.**

---

## ✅ Solución Implementada

Ahora ve:

```
❌ No se puede eliminar este menú.

Motivo: Está asignado a usuarios.

Acción: Primero debe desasignarlo en la sección 
'Gestión de Accesos de Usuarios'.
```

**Usuario piensa:**
- ✓ Entiendo el problema
- ✓ Sé por qué no puedo eliminar
- ✓ Sé exactamente qué hacer
- **Satisfecho. Resuelve el problema.**

---

## 🔧 Cambios Realizados

### 1. ErrorHandler.php - Nuevo Método

```php
public static function handleForeignKeyViolation(
    PDOException $e, 
    $operation = 'DELETE', 
    $context = []
)
```

**Características:**
- Detecta SQLSTATE 23503 (violación FK)
- Analiza el mensaje nativo de PostgreSQL
- Identifica la tabla involucrada
- Genera mensaje contextualizado según tabla
- Registra en logs para auditoría

**Ejemplo:**
```php
ErrorHandler::handleForeignKeyViolation($e, 'DELETE', ['tabla' => 'tab_menus']);
// Retorna: "❌ No se puede eliminar este menú. Está asignado a usuarios..."
```

### 2. menus.php - Detección de FK

```php
try {
    $stmt_del_menu->execute([$id]);
} catch (PDOException $e) {
    if ($e->errorInfo[0] === '23503') {
        // Es error de clave foránea
        $respuesta = ErrorHandler::handleForeignKeyViolation(
            $e, 
            'DELETE',
            ['tabla' => 'tab_menus']
        );
        $w_mensaje = $respuesta['message'];
    }
}
```

### 3. Visualización Mejorada

```html
<div class="alert alert-danger" style="white-space: pre-wrap;">
    ❌ No se puede eliminar este menú.
    
    Motivo: Está asignado a usuarios.
    
    Acción: Primero debe desasignarlo...
</div>
```

**Nota:** `white-space: pre-wrap` preserva saltos de línea (`\n`)

---

## 📊 Mapeo de Contextos

El sistema detecta automáticamente qué tabla causó el error y personaliza el mensaje:

| Contexto Detectado | Mensaje |
|-------------------|---------|
| menú en tab_menu_usuarios | "Está asignado a usuarios. Desasignarlo en Gestión de Accesos." |
| usuario en tab_* | "Tiene registros relacionados. Resolver relaciones primero." |
| INSERT/UPDATE a FK inválida | "Referencia inválida. Verificar IDs existan." |

---

## 🚀 Cómo Aplicar a Otros Archivos

### usuarios.php, dptos.php, cargos.php, etc.

1. **Importar ErrorHandler:**
   ```php
   require_once('ErrorHandler.php');
   ```

2. **Envolver DELETE:**
   ```php
   try {
       $stmt_del->execute([$id]);
   } catch (PDOException $e) {
       if ($e->errorInfo[0] === '23503') {
           $respuesta = ErrorHandler::handleForeignKeyViolation(
               $e, 'DELETE', ['tabla' => 'tu_tabla']
           );
       }
   }
   ```

3. **Mostrar con white-space:**
   ```html
   <div style="white-space: pre-wrap;">
       <?= htmlspecialchars($mensaje) ?>
   </div>
   ```

**Ver plantilla completa:** `src/INTEGRIDAD_REFERENCIAL_PLANTILLA.php`

---

## 📁 Archivos Modificados

### ✏️ Actualizado
- **src/menus.php** - Usa ErrorHandler ahora
- **src/ErrorHandler.php** - Agregó método `handleForeignKeyViolation()`

### ✨ Nuevo
- **src/INTEGRIDAD_REFERENCIAL_PLANTILLA.php** - Plantilla lista para copiar
- **MANEJO_INTEGRIDAD_REFERENCIAL.md** - Documentación completa

---

## 💡 Beneficios

| Antes | Después |
|-------|---------|
| Mensaje técnico confuso | Mensaje claro en español |
| Usuario no sabe qué hacer | Usuario sabe exactamente qué hacer |
| Sin contexto | Identifica tabla y operación |
| Sin logging especial | Se registra en logs |
| Único para BD | Contextualizado por tabla |

---

## 🔍 Ejemplos de Mensajes por Tabla

### Menú con usuarios asignados
```
❌ No se puede eliminar este menú.

Motivo: Está asignado a usuarios.

Acción: Primero debe desasignarlo a todos los usuarios 
en la sección 'Gestión de Accesos de Usuarios'.
```

### Usuario con datos relacionados
```
❌ No se puede eliminar este usuario.

Motivo: Tiene registros relacionados en el sistema.

Acción: Primero debe resolver estas relaciones.
```

### Guardar con FK inválida
```
❌ No se puede guardar. Referencia inválida.

Motivo: Uno de los datos referenciados no existe.

Acción: Verifique que todos los IDs referenciados existan.
```

---

## 🧪 Testing

Ahora prueba:

1. **Ir a Menús** → `menu_usuarios.php`
2. **Seleccionar un menú** con usuarios asignados
3. **Click Eliminar**
4. **Confirmar eliminación**
5. **Resultado:** Ves mensaje claro ✅

---

## 📚 Documentación Relacionada

- **[MANEJO_INTEGRIDAD_REFERENCIAL.md](MANEJO_INTEGRIDAD_REFERENCIAL.md)** - Guía completa
- **[src/INTEGRIDAD_REFERENCIAL_PLANTILLA.php](src/INTEGRIDAD_REFERENCIAL_PLANTILLA.php)** - Plantilla lista
- **[INDICE_DOCUMENTACION.md](INDICE_DOCUMENTACION.md)** - Mapa de docs

---

## 🎯 Próximos Pasos

- [ ] Aplicar mismo patrón a usuarios.php
- [ ] Aplicar mismo patrón a dptos.php  
- [ ] Aplicar mismo patrón a cargos.php
- [ ] Crear más mensajes contextualizados
- [ ] Agregar sugerencias de "Ir a sección X"

---

## 📞 Referencia Rápida

**Para agregar este manejo a un archivo:**

```php
<?php
require_once('ErrorHandler.php');

try {
    $stmt_del->execute($params);
} catch (PDOException $e) {
    if ($e->errorInfo[0] === '23503') {
        // FK violation
        $respuesta = ErrorHandler::handleForeignKeyViolation(
            $e, 'DELETE', ['tabla' => 'tu_tabla']
        );
        $mensaje = $respuesta['message'];
    }
}
?>

<!-- HTML -->
<div style="white-space: pre-wrap;">
    <?= htmlspecialchars($mensaje) ?>
</div>
```

---

## ✅ Status

- [x] ErrorHandler mejorado
- [x] menus.php actualizado e funcionando
- [x] Documentación completa
- [x] Plantilla lista para otros archivos
- [ ] Aplicar a usuarios.php
- [ ] Aplicar a dptos.php
- [ ] Aplicar a cargos.php

**Versión:** 1.1 (Mejora de Integridad Referencial)

