# ⚡ QUICK START - Sistema de Manejo de Errores

**Tiempo de lectura: 5 minutos**

---

## 🎯 En Una Frase

Los **errores de la BD ahora se traduce n al español** y se **categorizan** (🔴 BD, ⚠️ Validación, 📡 Red) para que el usuario entienda exactamente qué pasó.

---

## ✅ Lo Que Ya Funciona

- ✅ `menu_usuarios.php` muestra errores claros
- ✅ Alertas categorizadas con iconos
- ✅ Logs automáticos en `logs/error_handler.log`
- ✅ 30+ códigos SQLSTATE traducidos

---

## 🚀 Testear Ahora (2 min)

1. Abre: `http://localhost/pronom/src/menu_usuarios.php`
2. Selecciona un usuario
3. Marca algunos menús
4. Click "Guardar"
5. **Esperado:** Ves `✅ OPERACIÓN EXITOSA` (o error categor izado)

---

## 📊 Ejemplos de Errores

### ✅ Éxito
```
✅ OPERACIÓN EXITOSA
5 menús asignados correctamente
(5 menús)
```

### 🔴 Error de BD
```
🔴 ERROR DE BASE DE DATOS
Violación de clave única. Este registro ya existe.
(Código: 23505)
```

### ⚠️ Error de Validación
```
⚠️ ERROR DE VALIDACIÓN
ID Usuario es requerido y no puede estar vacío.
```

### 📡 Error de Red
```
📡 ERROR DE RED
Error crítico de comunicación con el servidor.
Verifique su conexión.
```

### 🔓 Error de Integridad Referencial (NUEVO)
```
❌ No se puede eliminar este menú.

Motivo: Está asignado a usuarios.

Acción: Primero debe desasignarlo en la sección 
'Gestión de Accesos de Usuarios'.
```

---

## 📁 Archivos Principales

| Archivo | Qué es | Impacto |
|---------|--------|--------|
| `src/ErrorHandler.php` | Clase central | Traduce y categoriza errores |
| `src/obtener_menus_usuario.php` | AJAX GET | Carga menús asignados |
| `src/procesar_perfil.php` | AJAX POST | Guarda menús del usuario |
| `js/menu_usuarios.js` | Frontend logic | Muestra alertas categorizadas |
| `logs/error_handler.log` | Auditoría | Registro de todos los errores |

---

## 🔍 Ver Logs

### En Terminal:
```bash
type logs/error_handler.log
```

### Ejemplo de contenido:
```
[2026-03-03 14:30:45] DATABASE_ERROR | Code: 23505 | Message: duplicate key... | IP: 192.168.1.100
[2026-03-03 14:31:20] VALIDATION_ERROR | Code: N/A | Message: ID Usuario requerido... | IP: 192.168.1.101
```

---

## 💻 Usar en Mis Propios Archivos

### Paso 1: Incluir
```php
<?php
require_once('ErrorHandler.php');
```

### Paso 2: Try-Catch
```php
try {
    // tu código SQL
    $stmt->execute([$param]);
    
    echo json_encode(
        ErrorHandler::createResponse('success', 'Éxito', 'DATABASE')
    );
    
} catch (PDOException $e) {
    ErrorHandler::sendJSON(
        ErrorHandler::handleDatabaseException($e)
    );
} catch (Exception $e) {
    ErrorHandler::sendJSON(
        ErrorHandler::handleValidationException($e)
    );
}
```

Ver plantilla completa: `src/ErrorHandler_PLANTILLA.php`

---

## 🧪 Hacer Tests (30 min)

Ver: `TESTING_ERRORES.md`

Tests clave:
- [ ] Test 1: Carga normal sin errores
- [ ] Test 2: Error de parámetro vacío
- [ ] Test 3: Error de BD (clave duplicada)
- [ ] Test 5: Guardar menús correctamente
- [ ] Test 9: Ver consola (F12)
- [ ] Test 8: Verificar logs

---

## 🎓 Documentación Completa

```
RESUMEN (2 min)      → RESUMEN_MANEJO_ERRORES.md
EJEMPLOS (5 min)     → EJEMPLOS_ERRORES_VISUALES.md
DETALLES (20 min)    → MANEJO_ERRORES.md
CÓDIGO (10 min)      → src/ErrorHandler.php
TESTING (30 min)     → TESTING_ERRORES.md
ARQUITECTURA (15 min)→ ARQUITECTURA_ERRORES.md
PLANTILLA (5 min)    → src/ErrorHandler_PLANTILLA.php
ÍNDICE (2 min)       → INDICE_DOCUMENTACION.md
```

---

## ❓ Preguntas Frecuentes

**P: ¿Qué pasa si la BD no responde?**  
R: Error 📡 NETWORK. Usuario ve "Error de Red. Verifique conexión."

**P: ¿Dónde veo los errores del servidor?**  
R: `logs/error_handler.log` contiene TODO.

**P: ¿Cómo veo detalles técnicos?**  
R: Abre F12 en navegador → Console → Verás logs detallados.

**P: ¿Se exponen datos sensibles?**  
R: No. Usuario ve mensaje amigable. Detalles solo en log privado.

**P: ¿Puedo agregar más códigos SQLSTATE?**  
R: Sí. Edita `src/ErrorHandler.php` línea 15-40.

**P: ¿Funciona con otros archivos PHP?**  
R: Sí. Usa `src/ErrorHandler_PLANTILLA.php` como guía.

---

## 🚦 Estado Actual

```
Implementación: ✅ COMPLETADO (100%)
Testing:        ⏳ PENDIENTE (ejecutar 14 tests)
Documentación: ✅ COMPLETADO (6 documentos)
Producción:    🟢 LISTO cuando tests pasen
```

---

## 📋 Próximos Pasos

### Hoy:
1. Leer este archivo (5 min) ✅
2. Ir a `menu_usuarios.php` y hacer un test (2 min)
3. Abrir F12 y ver consola (1 min)
4. Revisar `logs/error_handler.log` (1 min)
5. **Total: 9 minutos** → Ya sabes cómo funciona

### Esta Semana:
1. Ejecutar tests de `TESTING_ERRORES.md` (30 min)
2. Aplicar ErrorHandler a 1-2 archivos más (20 min)
3. Monitorear logs en ambiente de test (continuamente)

### Próximas Semanas:
1. Aplicar a resto de endpoints
2. Crear dashboard de errores (opcional)
3. Analizar patrones de SQLSTATE

---

## 🎯 Verificación Rápida

Ejecutar estos comandos para verificar:

```bash
# ¿ErrorHandler.php existe?
ls src/ErrorHandler.php

# ¿Logs directory existe?
ls -d logs/

# ¿Archivos PHP actualizados?
grep -l "ErrorHandler" src/obtener_menus_usuario.php
grep -l "ErrorHandler" src/procesar_perfil.php

# ¿JavaScript tiene nuevas funciones?
grep "mostrarErrorCategorizado" js/menu_usuarios.js
grep "mostrarExito" js/menu_usuarios.js
```

**Si TODO tiene ✅, el sistema está listo.**

---

## 📞 Referencia Rápida de Iconos

| Icono | Significado | Qué hacer |
|-------|-------------|-----------|
| ✅ | Éxito | Continuar |
| 🔴 | Error BD | Reintentar o contactar admin |
| ⚠️ | Validación | Revisar datos ingresados |
| 📡 | Red | Revisar conexión a internet |

---

## 🎉 ¡Listo!

Ya tienes:
- ✅ Sistema funcional de manejo de errores
- ✅ Documentación completa
- ✅ Tests definidos
- ✅ Ejemplos para usar en otros archivos

**Siguiente: Ejecuta los tests. Ver `TESTING_ERRORES.md`**

---

**¿Preguntas? Ver `INDICE_DOCUMENTACION.md` para buscar tema específico.**

