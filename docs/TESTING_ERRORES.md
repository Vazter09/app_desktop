# 🧪 GUÍA DE TESTING - Sistema de Manejo de Errores

**Fecha:** 3 de marzo de 2026  
**Objetivo:** Validar que todos los tipos de error se manejan correctamente

---

## ✅ Pre-requisitos

- [ ] ErrorHandler.php existe en `src/`
- [ ] obtener_menus_usuario.php actualizado con ErrorHandler
- [ ] procesar_perfil.php actualizado con ErrorHandler  
- [ ] menu_usuarios.js actualizado con nuevas funciones
- [ ] Directorio `logs/` existe y es escribible
- [ ] PostgreSQL funcionando y conectad

---

## 🧪 Test 1: Carga Normal sin Errores

**Objetivo:** Verificar que la carga normal funciona

### Pasos:
1. Ir a `menu_usuarios.php`
2. Seleccionar un usuario que tiene menús asignados
3. **Esperado:**
   - [ ] Menús se cargan automáticamente
   - [ ] Los menús asignados aparecen marcados (☑️)
   - [ ] Alert muestra: ✅ OPERACIÓN EXITOSA
   - [ ] Consola muestra: `╔════ OPERACIÓN EXITOSA...`
   - [ ] No hay errores en consola

**Método DEBUG:**
```javascript
// En consola (F12):
// Deberías ver:
✓ RESPUESTA JSON COMPLETA
{
  status: "success",
  message: "Menús cargados correctamente",
  source: "DATABASE",
  menusAsignados: [1, 12, 121],
  cantidad: 3,
  sqlstate: null
}
```

---

## 🧪 Test 2: Error de Validación - Parámetro Vacío

**Objetivo:** Verificar que se validen parámetros requeridos

### Pasos:
1. Abrir navegador e ir a:
   ```
   http://localhost/pronom/src/obtener_menus_usuario.php
   ```
   (SIN parámetro ?usuario=...)
2. **Esperado:**
   - [ ] No hay respuesta HTML (error JSON)
   - [ ] Response JSON contiene:
     ```json
     {
       "status": "error",
       "source": "VALIDATION",
       "message": "Parámetro \"usuario\" es requerido..."
     }
     ```

**Método DEBUG:**
```bash
# Desde terminal/PowerShell:
curl "http://localhost/pronom/src/obtener_menus_usuario.php" | python -m json.tool

# Deberías ver:
{
  "status": "error",
  "message": "Parámetro \"usuario\" es requerido en la URL.",
  "source": "VALIDATION"
}
```

---

## 🧪 Test 3: Error de Validación - ID Vacío

**Objetivo:** Verificar validación de campo ID

### Pasos:
1. Ir a URL:
   ```
   http://localhost/pronom/src/obtener_menus_usuario.php?usuario=
   ```
2. **Esperado:**
   - [ ] Response JSON:
     ```json
     {
       "status": "error",
       "source": "VALIDATION",
       "message": "ID de Usuario es requerido y no puede estar vacío."
     }
     ```

**Nota:** El filtro de validación debe ser ANTES de ejecutar consultas.

---

## 🧪 Test 4: Carga de Menús de Usuario Inexistente

**Objetivo:** Verificar que no hay error si usuario no tiene menús (vacío vs error)

### Pasos:
1. Crear un usuario nuevo sin menús o ir a URL:
   ```
   http://localhost/pronom/src/obtener_menus_usuario.php?usuario=USUARIO_NUEVO
   ```
2. **Esperado:**
   - [ ] Status: `success` (NO es error)
   - [ ] menusAsignados: `[]` (array vacío)
   - [ ] cantidad: `0`
   - [ ] NO hay excepción thrown

**Ejemplo respuesta:**
```json
{
  "status": "success",
  "message": "Menús cargados correctamente",
  "source": "DATABASE",
  "menusAsignados": [],
  "cantidad": 0
}
```

---

## 🧪 Test 5: Guardar Menús sin Error

**Objetivo:** Verificar que guardar menús devuelve respuesta correcta

### Pasos:
1. En `menu_usuarios.php`
2. Seleccionar usuario
3. Marcar algunos menús (ej: 3-5 menús)
4. Click en "Guardar" o Submit del formulario
5. **Esperado:**
   - [ ] Alert muestra: ✅ OPERACIÓN EXITOSA + cantidad
   - [ ] Response JSON:
     ```json
     {
       "status": "success",
       "message": "3 menús asignados correctamente",
       "source": "DATABASE",
       "cantidadGuardada": 3
     }
     ```
   - [ ] Consola muestra: `╔════ OPERACIÓN EXITOSA...`
   - [ ] Formulario se limpia después de 500ms
   - [ ] No hay transacciones abiertas

---

## 🧪 Test 6: Guardar sin Seleccionar Usuario

**Objetivo:** Verificar validación en guardar

### Pasos:
1. En `menu_usuarios.php`
2. SIN seleccionar usuario
3. Marcar algunos menús
4. Click "Guardar"
5. **Esperado:**
   - [ ] Alert muestra: ⚠️ ERROR DE VALIDACIÓN
   - [ ] Mensaje dice algo como: "ID del Usuario es requerido..."
   - [ ] NO se modifica la BD

---

## 🧪 Test 7: Duplicado (Clave Única Violada)

**Objetivo:** Verificar traducción de SQLSTATE 23505

### Pasos:
1. Obtener un usuario CON menús asignados
2. Sin cambiar nada, click "Guardar" directamente
3. **Esperado:**
   - [ ] Alert muestra: 🔴 ERROR DE BASE DE DATOS
   - [ ] Mensaje contiene: "Violación de clave única"
   - [ ] Código: 23505
   - [ ] NO hay crash del servidor
   - [ ] Transacción fue rolada back (BD consistente)

**Nota:** La función `fun_insert_menu_usuarios` debería manejar esto (INSERT OR IGNORE)

---

## 🧪 Test 8: Archivo de Log

**Objetivo:** Verificar que los errores se registran

### Verificar Log del Servidor:
```bash
# Navegar a carpeta del proyecto
cd c:\Apache24\htdocs\pronom\logs\

# Ver último contenido del log
type error_handler.log
# O (PowerShell)
Get-Content error_handler.log -Tail 20
```

**Esperado:**
```
[2026-03-03 14:30:45] DATABASE_ERROR | Code: 23505 | Message: duplicate key... | IP: 192.168.1.100
[2026-03-03 14:31:20] VALIDATION_ERROR | Code: N/A | Message: ID Usuario es requerido... | IP: 192.168.1.101
```

- [ ] Cada error genera una línea en el log
- [ ] Incluye timestamp exacto
- [ ] Incluye código de error
- [ ] Incluye IP del cliente

---

## 🧪 Test 9: Consola del Navegador

**Objetivo:** Verificar logs en F12 Developer Tools

### Pasos:
1. Abrir DevTools (F12)
2. Ir a pestaña "Console"
3. Hacer una operación (cargar menú, guardar, etc.)
4. **Esperado:**
   - [ ] Ves logs con formato claro:
     ```
     ✓ menu_usuarios.js cargado correctamente
     ✓ DOMContentLoaded disparado
     === CARGAR MENÚS ASIGNADOS ===
     === RESPUESTA JSON COMPLETA ===
     ```
   - [ ] Para errores ves:
     ```
     ╔════ ERROR CATEGORIZADO ════╗
     Origen: DATABASE
     Mensaje: ...
     SQLSTATE: 23505
     ╚═══════════════════════════╝
     ```
   - [ ] NO hay errores en rojo (excepto los intencionales)

---

## 🧪 Test 10: Red (Simular Error de Conexión)

**Objetivo:** Verificar manejo de errores de red

### Método 1: Apagar Servidor
```bash
# Apagar Apache o hacer pausa del servicio
# Intentar guardar menú en menu_usuarios.php
```

**Esperado:**
- [ ] Alert muestra: 📡 ERROR DE RED
- [ ] Mensaje menciona: "comunicación con el servidor"
- [ ] Consola:
  ```
  ╔════ ERROR CATEGORIZADO ════╗
  Origen: NETWORK
  Mensaje: Error crítico al cargar menús
  ╚═══════════════════════════╝
  ```

### Método 2: Cambiar URL a servidor inexistente
```javascript
// En menu_usuarios.js (SOLO PARA TESTING):
const response = await fetch('http://SERVIDOR_INEXISTENTE/file.php');
```

---

## 🧪 Test 11: Transacción Rollback

**Objetivo:** Verificar que ROLLBACK funciona en errores

### Setup:
1. Obtener usuario CON menús asignados
2. En `procesar_perfil.php`, simular error durante transacción:
   ```php
   // Agregar después de atan Transaction:
   throw new Exception("Error simulado");
   ```

### Pasos:
1. Cambiar menú del usuario en formulario
2. Enviar
3. **Esperado:**
   - [ ] Alert muestra error
   - [ ] BD NO fue modificada (los menús sigen igual)
   - [ ] Transacción fue completamente rolada back
   - [ ] Usuario puede reintentar

**Verificar:**
```sql
-- En PostgreSQL:
SELECT * FROM tab_menu_usuarios WHERE id_usuario = 'TEST_USER';
-- Debería tener los menús originales, no cambios fallidos
```

---

## 🧪 Test 12: Mensajes de Éxito Variados

**Objetivo:** Verificar contador de menús en respuesta

### Pasos:
1. Guardar con 0 menús (desmarcar todos)
2. **Esperado:** "0 menús asignados correctamente"
3. Guardar con 1 menú
4. **Esperado:** "1 menú asignado correctamente" (singular)
5. Guardar con 5 menús
6. **Esperado:** "5 menús asignados correctamente" (plural)

---

## 🧪 Test 13: Marcar Padres Automáticamente

**Objetivo:** Verificar que padres se marcan cuando marcan hijos

### Setup:
- Menús con estructura: 1 (padre) → 12 (hijo) → 121 (nieto)

### Pasos:
1. Limpiar form (desmarcar todos)
2. Marcar checkbox de "121"
3. **Esperado:**
   - [ ] ✓ Se marca "121" automáticamente
   - [ ] ✓ Se marca "12" automáticamente (padre)
   - [ ] ✓ Se marca "1" automáticamente (abuelo)
   - [ ] Consola muestra:
     ```
     Menú marcado: 121, Padre: 12
     → Padre marcado automáticamente: 12
     → Padre marcado automáticamente: 1
     ```

---

## 🧪 Test 14: Diferentes SQLSTATE

**Objetivo:** Verificar que diferentes códigos se traducen correctamente

### Simular cada error (requiere scripts SQL específicos):

| SQLSTATE | Error | Cómo Simular |
|----------|-------|-------------|
| 23505 | Clave única | Insertar duplicado |
| 23503 | Clave foránea | ID usuario/menú inexistente |
| 42P01 | Tabla no existe | Borrar tabla temporalmente |
| 08000 | Conexión | Desconectar BD |

**Para cada uno:**
- [ ] Alert muestra traducción correcta
- [ ] SQLSTATE visible en mensaje
- [ ] Log registra correctamente
- [ ] Consola muestra detalles técnicos

---

## 📋 Checklist Final

### Antes de Producción:
- [ ] Todos los tests 1-14 pasaron
- [ ] No hay errores no manejados
- [ ] Logs escriben correctamente
- [ ] Usuario entiende cada mensaje
- [ ] ROLLBACK funciona en transacciones
- [ ] Validaciones previenen SQL injection
- [ ] Información sensible no se muestra
- [ ] SQLSTATE se traduce correctamente
- [ ] Iconos visuales coinciden con categoría
- [ ] Timestamps están correctos

### Archivos a Verificar:
- [ ] `src/ErrorHandler.php` - Existe y tiene 200+ líneas
- [ ] `src/obtener_menus_usuario.php` - Usa ErrorHandler
- [ ] `src/procesar_perfil.php` - Usa ErrorHandler
- [ ] `js/menu_usuarios.js` - Tiene funciones nuevas
- [ ] `logs/` - Directorio creado y con permisos
- [ ] `logs/error_handler.log` - Archivo creamos con logs

---

## 📞 Si Algo Falla

### Error: "Class ErrorHandler not found"
```
Solución: Verificar que prepare.php tenga:
require_once('ErrorHandler.php');
```

### Error: "Cannot write to logs directory"
```
Solución: Crear carpeta y asignar permisos:
mkdir c:\Apache24\htdocs\pronom\logs
cd logs
ICACLS . /grant:r "%USERNAME%":(OI)(CI)F
```

### Error: Alertas no aparecen con categorías
```
Solución: Verificar que menu_usuarios.js tenga las funciones:
- mostrarErrorCategorizado()
- mostrarExito()
```

### Error: SQLSTATE no se traduce
```
Solución: Verificar ErrorHandler::$sqlErrorMap tiene el código
Ejemplo: agrega a ErrorHandler.php:
'42P99' => 'Tu mensaje aquí',
```

---

## 🎓 Conclusión

Cuando todos estos tests pasen, el sistema de manejo de errores está:
- ✅ Funcionando correctamente
- ✅ Comunicando claramente
- ✅ Registrando para auditoría
- ✅ Listo para producción

**Mantenga este documento actualizado si agrega nuevos endpoints o errores.**

