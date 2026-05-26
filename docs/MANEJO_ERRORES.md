# Sistema Centralizado de Manejo de Errores
**Fecha:** 3 de marzo de 2026  
**Versión:** 1.0

---

## 📋 Resumen

Se ha implementado un **sistema centralizado de manejo y traducción de errores** que:

1. **Captura errores** de BD (PDOException), validación (Exception) y red
2. **Traduce códigos SQLSTATE** de PostgreSQL a mensajes legibles en español
3. **Categoriza el origen** del error para claridad del usuario
4. **Registra en logs** todos los errores para auditoría
5. **Muestra mensajes claros** en interfaz y consola

---

## 🔧 Componentes

### 1. **ErrorHandler.php** - Clase centralizadora
Ubicación: `src/ErrorHandler.php`

**Funcionalidades:**
- `createResponse()` - Estructura unificada de respuestas
- `handleDatabaseException()` - Procesa errores de BD
- `handleValidationException()` - Procesa errores de validación
- `validateNotEmpty()` - Valida campos requeridos
- `validateArray()` - Valida arrays
- `logError()` - Registra en archivo de log
- `sendJSON()` - Envía respuesta y termina ejecución
- `getUserMessage()` - Formatea mensaje para usuario

**Mapa de Códigos SQLSTATE traducidos:**

| Código | Mensaje |
|--------|---------|
| 23505  | Violación de clave única |
| 23503  | Violación de clave foránea |
| 23502  | Restricción NOT NULL |
| 23514  | Restricción CHECK |
| 42601  | Error de sintaxis SQL |
| 42883  | Función no encontrada |
| 42P01  | Tabla no encontrada |
| 28P01  | Contraseña incorrecta |
| 08000  | Error de conexión |
| 40P01  | Deadlock detectado |
| 22007  | Formato de fecha inválido |

---

## 🌐 Archivos PHP Actualizados

### `obtener_menus_usuario.php`
**Cambios:**
- Ahora usa `ErrorHandler::validateNotEmpty()` para validar parámetros
- Respuesta JSON incluye campos: `status`, `source`, `message`, `timestamp`
- Errores PDO se procesan con `ErrorHandler::handleDatabaseException()`
- Errores generales con `ErrorHandler::handleValidationException()`

**Ejemplo de respuesta exitosa:**
```json
{
  "status": "success",
  "message": "Menús cargados correctamente",
  "source": "DATABASE",
  "menusAsignados": [1, 12, 121, 2],
  "cantidad": 4,
  "timestamp": "2026-03-03 14:30:45",
  "sqlstate": null
}
```

**Ejemplo de error:**
```json
{
  "status": "error",
  "message": "ID de Usuario es requerido y no puede estar vacío.",
  "source": "VALIDATION",
  "sqlstate": null,
  "timestamp": "2026-03-03 14:30:45",
  "debug": {
    "exception_msg": "ID de Usuario es requerido...",
    "file": "obtener_menus_usuario.php",
    "line": 15
  }
}
```

---

### `procesar_perfil.php`
**Cambios:**
- Transacción ACID completa con rollback en error
- Validación de parámetros con `ErrorHandler::validateNotEmpty()`
- Respuesta incluye `cantidadGuardada` en éxito
- Manejo de excepciones PDO separado con rollback garantizado

**Ejemplo de respuesta exitosa:**
```json
{
  "status": "success",
  "message": "5 menús asignados correctamente",
  "source": "DATABASE",
  "cantidadGuardada": 5,
  "timestamp": "2026-03-03 14:31:20"
}
```

**Ejemplo de error de BD:**
```json
{
  "status": "error",
  "message": "Violación de clave única. Este registro ya existe en la base de datos.",
  "source": "DATABASE",
  "sqlstate": "23505",
  "timestamp": "2026-03-03 14:31:20",
  "debug": {
    "native_code": 0,
    "native_message": "duplicate key value violates..."
  }
}
```

---

## 💻 Cambios en JavaScript

### `menu_usuarios.js`

**Nuevas funciones:**

#### `mostrarErrorCategorizado(errorData)`
Muestra error categorizado con origen claro:
```javascript
function mostrarErrorCategorizado(errorData) {
    // Extrae: source, message, sqlstate
    // Loguea en consola con formato legible
    // Muestra alert con icono según origen:
    // 🔴 DATABASE
    // ⚠️ VALIDATION
    // ⚙️ SYSTEM  
    // 📡 NETWORK
}
```

#### `mostrarExito(successData, nomUsuario)`
Muestra éxito con detalles:
```javascript
function mostrarExito(successData, nomUsuario) {
    // Extrae: cantidadGuardada, message
    // Loguea en consola
    // Muestra alert con ✅ y detalles
}
```

**Cambios en evento `submit` del formulario:**
- Llama a `mostrarExito()` en caso de éxito
- Llama a `mostrarErrorCategorizado()` en caso de error BD o validación
- Captura errores de red con status 'NETWORK'

**Cambios en carga de menús:**
- Llama a `mostrarErrorCategorizado()` si falla la carga
- Errores de red capturados con tipo 'NETWORK'

---

## 📊 Flujo de Usuario

### Escenario 1: Carga normal
```
1. Usuario selecciona --> AJAX a obtener_menus_usuario.php
2. Valida parámetro (ID usuario)
3. Consulta BD --> SELECT menús
4. Retorna JSON con source: 'DATABASE' + arreglo menús
5. JS marca checkboxes
6. Usuario ve menús asignados
```

### Escenario 2: Error de validación
```
1. Parámetro vacío o inválido
2. ErrorHandler::validateNotEmpty() lanza Exception
3. Catch captura --> handleValidationException()
4. Retorna JSON con source: 'VALIDATION'
5. JS muestra alert: ⚠️ ERROR DE VALIDACIÓN + mensaje
```

### Escenario 3: Error de BD (SQLSTATE)
```
1. Consulta SQL con error
2. PDO lanza PDOException
3. ErrorHandler::handleDatabaseException() procesa
4. Busca SQLSTATE en mapa de traducción
5. Si no existe: genera mensaje genérico por prefijo
6. Retorna JSON con source: 'DATABASE' + sqlstate + mensaje traducido
7. JS muestra alert: 🔴 ERROR DE BASE DE DATOS + (Código: SQLSTATE)
```

### Escenario 4: Error de red
```
1. Fetch falla (no hay respuesta, timeout, etc.)
2. JavaScript captura catch()
3. Crea errorData con source: 'NETWORK'
4. Llama mostrarErrorCategorizado()
5. Usuario ve: 📡 ERROR DE RED + detalle
```

---

## 📝 Archivo de Log

**Ubicación:** `logs/error_handler.log`

**Formato:**
```
[2026-03-03 14:30:45] DATABASE_ERROR | Code: 23505 | Message: duplicate key value... | IP: 192.168.1.100
[2026-03-03 14:31:20] VALIDATION_ERROR | Code: N/A | Message: ID Usuario es requerido... | IP: 192.168.1.101
[2026-03-03 15:00:00] DATABASE_ERROR | Code: 08000 | Message: connection refused | IP: 192.168.1.102
```

**Ventajas:**
- Auditoría completa de errores
- Identificación de IPs de usuarios
- Timestamps exactos
- Fácil debugging

---

## 🛡️ Seguridad

### Información expuesta al usuario
- ✅ Mensajes legibles y educativos
- ✅ Código SQLSTATE (solo técnico, sin detalles sensibles)
- ✅ Categoría de error (BD, validación, etc.)

### Información NO expuesta al usuario
- ❌ Detalles exactos de consultas SQL
- ❌ Estructuras de tabla
- ❌ Rutas de archivo del servidor
- ❌ Pilas completas de stack trace

### Información en modo desarrollo (debug)
- Solo en respuesta JSON dentro de campo `debug`
- No se muestra en alert al usuario
- Disponible en consola del navegador (F12)

---

## 🔍 Cómo Debugear

### Desde Consola del Navegador (F12)
```javascript
// Los logs muestran estructura clara:
╔════ ERROR CATEGORIZADO ════╗
Origen: DATABASE
Mensaje: Violación de clave única...
SQLSTATE: 23505
╚═══════════════════════════╝
```

### Desde Log del Servidor
```bash
tail -f logs/error_handler.log
```

### Desde Response JSON (DEV TOOLS)
1. Abrir Inspect → Network
2. Hacer click en request (obtener_menus_usuario.php o procesar_perfil.php)
3. Ver pestaña Response
4. Campo `debug` contiene detalles técnicos

---

## 📌 Próximas Mejoras

1. **Dashboard de errores** - Panel administrativo mostrando últimos errores
2. **Alertas automáticas** - Notificar admin si hay muches errores en corto tiempo
3. **Estadísticas de SQLSTATE** - Gráficos de tipos de error más comunes
4. **Rotación de logs** - Archivar logs antiguos automáticamente
5. **Envío de email** - Alertar admin de errores críticos inmediatamente

---

## 📚 Resumen de Cambios

| Archivo | Cambios |
|---------|---------|
| `src/ErrorHandler.php` | ✨ NUEVO - Clase centralizadora |
| `src/obtener_menus_usuario.php` | ✏️ Integra ErrorHandler |
| `src/procesar_perfil.php` | ✏️ Integra ErrorHandler |
| `js/menu_usuarios.js` | ✏️ Nuevas funciones de UI para errores |
| `logs/` | ✨ NUEVO - Directorio para logs |

---

**Nota:** El sistema está listo para producción. Los logs se guardan automáticamente y el usuario recibe mensajes claros sobre qué salió mal y dónde.
