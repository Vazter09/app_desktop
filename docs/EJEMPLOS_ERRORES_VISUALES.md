# EJEMPLOS VISUALES - Mensajes de Error por Tipo

## 🟢 Éxito

```
┌─────────────────────────────────────────┐
│ ✅ OPERACIÓN EXITOSA                     │
│                                          │
│ 5 menús asignados correctamente          │
│ (5 menús)                                │
│                                          │
│ Accesos actualizados para: Juan Pérez    │
│                                          │
│              [   Aceptar   ]             │
└─────────────────────────────────────────┘

CONSOLA:
╔════ OPERACIÓN EXITOSA ════╗
Mensaje: 5 menús asignados correctamente
Menús guardados: 5
Usuario: Juan Pérez
╚═════════════════════════╝
```

---

## 🔴 Error de Base de Datos

### Ejemplo 1: Clave Duplicada
```
┌──────────────────────────────────────────┐
│ 🔴 ERROR DE BASE DE DATOS                 │
│                                           │
│ Violación de clave única. Este registro   │
│ ya existe en la base de datos.            │
│                                           │
│ (Código: 23505)                           │
│                                           │
│              [   Aceptar   ]              │
└──────────────────────────────────────────┘

CONSOLA:
╔════ ERROR CATEGORIZADO ════╗
Origen: DATABASE
Mensaje: Violación de clave única...
SQLSTATE: 23505
Detalles técnicos: {
  native_code: 0,
  native_message: "duplicate key value violates..."
}
╚═══════════════════════════╝
```

### Ejemplo 2: Tabla No Encontrada
```
┌──────────────────────────────────────────┐
│ 🔴 ERROR DE BASE DE DATOS                 │
│                                           │
│ Error de estructura. Contacte al          │
│ administrador.                            │
│                                           │
│ (Código: 42P01)                           │
│                                           │
│              [   Aceptar   ]              │
└──────────────────────────────────────────┘

CONSOLA:
╔════ ERROR CATEGORIZADO ════╗
Origen: DATABASE
SQLSTATE: 42P01
(Sin acceso a tabla o tabla eliminada)
╚═══════════════════════════╝
```

### Ejemplo 3: Error de Conexión
```
┌──────────────────────────────────────────┐
│ 🔴 ERROR DE BASE DE DATOS                 │
│                                           │
│ Error de conexión a base de datos.        │
│ Revise su conexión o contacte al admin.   │
│                                           │
│ (Código: 08000)                           │
│                                           │
│              [   Aceptar   ]              │
└──────────────────────────────────────────┘

CONSOLA:
╔════ ERROR CATEGORIZADO ════╗
Origen: DATABASE
SQLSTATE: 08000
(Conexión perdida o BD no responde)
╚═══════════════════════════╝
```

---

## ⚠️ Error de Validación

### Ejemplo 1: Campo Requerido Vacío
```
┌──────────────────────────────────────────┐
│ ⚠️ ERROR DE VALIDACIÓN                    │
│                                           │
│ ID Usuario es requerido y no puede        │
│ estar vacío.                              │
│                                           │
│              [   Aceptar   ]              │
└──────────────────────────────────────────┘

CONSOLA:
╔════ ERROR CATEGORIZADO ════╗
Origen: VALIDATION
Mensaje: ID Usuario es requerido...
Detalles: {
  file: "obtener_menus_usuario.php",
  line: 14
}
╚═══════════════════════════╝
```

### Ejemplo 2: Array Vacío
```
┌──────────────────────────────────────────┐
│ ⚠️ ERROR DE VALIDACIÓN                    │
│                                           │
│ Lista de menús no puede estar vacía.      │
│                                           │
│              [   Aceptar   ]              │
└──────────────────────────────────────────┘

CONSOLA:
╔════ ERROR CATEGORIZADO ════╗
Origen: VALIDATION
Mensaje: Lista de menús no puede estar vacía
╚═══════════════════════════╝
```

### Ejemplo 3: Formato Inválido
```
┌──────────────────────────────────────────┐
│ ⚠️ ERROR DE VALIDACIÓN                    │
│                                           │
│ Formato de email inválido.                │
│                                           │
│              [   Aceptar   ]              │
└──────────────────────────────────────────┘

CONSOLA:
╔════ ERROR CATEGORIZADO ════╗
Origen: VALIDATION
Mensaje: Formato de email inválido
╚═══════════════════════════╝
```

---

## ⚙️ Error del Sistema

```
┌──────────────────────────────────────────┐
│ ⚙️ ERROR DEL SISTEMA                      │
│                                           │
│ No se pudo escribir en el directorio      │
│ de archivos. Contacte al administrador.   │
│                                           │
│              [   Aceptar   ]              │
└──────────────────────────────────────────┘

CONSOLA:
╔════ ERROR CATEGORIZADO ════╗
Origen: SYSTEM
Mensaje: Permiso denegado para escribir...
═══════════════════════════╝
```

---

## 📡 Error de Red

### Ejemplo 1: Servidor No Responde
```
┌──────────────────────────────────────────┐
│ 📡 ERROR DE RED                           │
│                                           │
│ Error crítico de red o comunicación con   │
│ el servidor. Verifique su conexión.       │
│                                           │
│              [   Aceptar   ]              │
└──────────────────────────────────────────┘

CONSOLA:
╔════ ERROR CATEGORIZADO ════╗
Origen: NETWORK
Mensaje: Error crítico al cargar menús
Debug: fetch failed - connection refused
╚═══════════════════════════╝
```

### Ejemplo 2: Timeout
```
┌──────────────────────────────────────────┐
│ 📡 ERROR DE RED                           │
│                                           │
│ El servidor tardó demasiado en responder.  │
│ Reintente la operación.                   │
│                                           │
│              [   Aceptar   ]              │
└──────────────────────────────────────────┘

CONSOLA:
╔════ ERROR CATEGORIZADO ════╗
Origen: NETWORK
Mensaje: Timeout en solicitud
╚═══════════════════════════╝
```

---

## 📊 Comparación: Antes vs Después

### ANTES (Sin ErrorHandler)
```
❌ Error: DB Error: SQLSTATE[23505]: Integrity 
constraint violation: 7 ERROR: duplicate key 
value violates unique constraint "tab_users_id_key"
```
→ Usuario confundido, no entiende qué pasó

---

### DESPUÉS (Con ErrorHandler)
```
🔴 ERROR DE BASE DE DATOS

Violación de clave única. Este registro ya 
existe en la base de datos.

(Código: 23505)
```
→ Usuario entiende claramente:
- 🔴 Qué tipo de error es (BD)
- Qué pasó exactamente (registro duplicado)
- Código técnico para referencia (23505)

---

## 🎯 Cómo Responde Cada Capa

### Flujo: Usuario intenta cargar menús de usuario inexistente

```
JavaScript (menu_usuarios.js)
    ↓
FETCH a obtener_menus_usuario.php?usuario=999
    ↓
PHP (obtener_menus_usuario.php)
ErrorHandler::validateNotEmpty() - SÍ, tiene parametro
    ↓
SELECT menú WHERE id_usuario = '999' - RETORNA VACÍO
PERO no hay error, es respuesta válida (0 menús)
    ↓
Respuesta JSON:
{
  "status": "success",
  "menusAsignados": [],
  "cantidad": 0
}
    ↓
JavaScript recibe éxito
Muestra tabla sin checkmarks (sin menús asignados)
```

---

### Flujo: Usuario intenta cargar menús sin parámetro

```
JavaScript (menu_usuarios.js)
    ↓
FETCH a obtener_menus_usuario.php?usuario=
    ↓
PHP (obtener_menus_usuario.php)
ErrorHandler::validateNotEmpty('', 'ID de Usuario')
    ↓
LANZA Exception: "ID de Usuario es requerido..."
    ↓
CATCH captura Exception
ErrorHandler::handleValidationException($e)
    ↓
Respuesta JSON:
{
  "status": "error",
  "message": "ID de Usuario es requerido...",
  "source": "VALIDATION",
  "debug": {...}
}
    ↓
JavaScript recibe error
Llama mostrarErrorCategorizado()
    ↓
Alert: ⚠️ ERROR DE VALIDACIÓN
      ID de Usuario es requerido...
```

---

### Flujo: Error de BD real

```
JavaScript (menu_usuarios.js)
    ↓
FETCH POST a procesar_perfil.php
{hid_usuario: '100', chk_menu: [1,2,3]}
    ↓
PHP: BEGIN TRANSACTION
Intenta: SELECT fun_insert_menu_usuarios('100', '1')
    ↓
PostgreSQL: ERROR 23505 - duplicate key
    ↓
PDO LANZA PDOException
    ↓
CATCH captura PDOException
ErrorHandler::handleDatabaseException($e)
    ├─ errorInfo[0] = '23505'
    ├─ Busca en ErrorHandler::$sqlErrorMap['23505']
    ├─ Encuentra: "Violación de clave única..."
    └─ Log: "DATABASE_ERROR | 23505 | ..."
    ↓
ROLLBACK automático de transacción
    ↓
Respuesta JSON:
{
  "status": "error",
  "message": "Violación de clave única...",
  "source": "DATABASE",
  "sqlstate": "23505"
}
    ↓
JavaScript recibe error
Llama mostrarErrorCategorizado()
    ↓
Alert: 🔴 ERROR DE BASE DE DATOS
       Violación de clave única...
       (Código: 23505)
```

---

## 🔐 Información Visible en Cada Context

### A: Usuario Final (Alert en pantalla)
- ✅ Categoría (BD, validación, red)
- ✅ Mensaje amigable en español
- ✅ Código SQLSTATE (solo si BD)
- ❌ Detalles técnicos complejos
- ❌ Rutas del servidor

### B: Consola del Navegador (F12)
- ✅ TODO de A +
- ✅ Stack trace completo
- ✅ Variables de debug
- ✅ Timestamps exactos
- ❌ Datos sensibles (contraseñas, tokens)

### C: Log del Servidor (logs/error_handler.log)
- ✅ IP del usuario
- ✅ Timestamp
- ✅ Tipo de error
- ✅ Código SQLSTATE
- ✅ Mensaje original
- ❌ Datos sensibles

---

## 📌 Resumen de Iconos

| Icono | Tipo | Acción Recomendada |
|-------|------|-------------------|
| ✅ | Éxito | Continuar |
| 🔴 | Error BD | Contactar admin o reintentar |
| ⚠️ | Validación | Revisar datos ingresados |
| ⚙️ | Sistema | Contactar admin |
| 📡 | Red | Revisar conexión, reintentar |

