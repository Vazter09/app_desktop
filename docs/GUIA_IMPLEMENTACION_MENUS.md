# 🚀 GUÍA RÁPIDA DE IMPLEMENTACIÓN

## Funciones y Menús por Usuario - SistNomina V.1.3+

---

## ⚡ Paso 1: Registro de Funciones en PostgreSQL

Ejecutar en psql o herramienta de administración de PostgreSQL:

```bash
# Opción 1: Usando psql desde línea de comandos
psql -U postgres -d db_proynom -f "C:\Apache24\htdocs\pronom\scripts\fun_insert_menu_usuarios.sql"
psql -U postgres -d db_proynom -f "C:\Apache24\htdocs\pronom\scripts\fun_delete_perfil_usuarios.sql"

# Opción 2: Copiar y pegar en pgAdmin
# Copiar el contenido de fun_insert_menu_usuarios.sql en la ventana SQL y ejecutar
# Repetir con fun_delete_perfil_usuarios.sql
```

---

## ✅ Validación Inmediata

Una vez registradas las funciones, ejecutar en PostgreSQL:

```sql
-- Verificar que las funciones existen
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('fun_insert_menu_usuarios', 'fun_delete_perfil_usuarios');

-- Resultado esperado: 2 filas (ambas funciones)

-- Probar la función insert (ejemplo)
SELECT fun_insert_menu_usuarios('admin', '1');

-- Si no hay error, está OK ✅

-- Probar la función delete (ejemplo) 
SELECT fun_delete_perfil_usuarios('admin');

-- Si no hay error, está OK ✅
```

---

## 📁 Archivos Nuevos

Verificar que existan en el directorio `c:\Apache24\htdocs\pronom\`:

```
scripts/
├── fun_insert_menu_usuarios.sql          ✓ Creado
├── fun_delete_perfil_usuarios.sql        ✓ Creado
└── (otros archivos existentes)

src/
├── obtener_menus_usuario.php             ✓ Creado
├── menu_usuarios.php                     ✓ Modificado
├── procesar_perfil.php                   ✓ Sin cambios requeridos
├── prepare.php                           ✓ Sin cambios requeridos
└── (otros archivos)

js/
├── menu_usuarios.js                      ✓ Modificado
└── (otros archivos)

CAMBIOS_MENUS_USUARIOS_V1.3.md           ✓ Creado (documentación)
```

---

## 🧪 Prueba Funcional Completa

### Prueba 1: Cargar usuario y ver menús asignados

1. Abrir navegador → `http://localhost/pronom/src/menu_usuarios.php`
2. Seleccionar usuario del dropdown (ej: "admin")
3. **Resultado esperado:**
   - Panel derecho se desbloquea
   - Ciertos checkboxes aparecen marcados (menús del admin)
   - Consola de navegador (F12) sin errores

### Prueba 2: Cambiar menús y guardar

1. Desmarcar un menú que el usuario tiene
2. Marcar un menú que no tiene
3. Hacer clic en "EJECUTAR PROCESO"
4. **Resultado esperado:**
   - Mensaje ✅ "¡Grabado exitoso en tab_menu_usuarios!"
   - Si cambias de usuario y vuelves, verás los cambios guardados

### Prueba 3: Botón Limpiar/Nuevo

1. Con usuario seleccionado, haz clic en "Limpiar / Nuevo"
2. **Resultado esperado:**
   - Se limpia la selección del usuario
   - Se desmarcan todos los checkboxes
   - Panel vuelve a estar bloqueado (gris)

---

## 🔍 Solución de Problemas

### ❌ Error: "Función no encontrada"

**Síntoma:** Al hacer clic en usuario aparece error en consola  
**Causa:** Las funciones SQL no se registraron en PostgreSQL  
**Solución:**
```bash
# Ejecutar nuevamente:
psql -U postgres -d db_proynom -f scripts/fun_insert_menu_usuarios.sql
psql -U postgres -d db_proynom -f scripts/fun_delete_perfil_usuarios.sql

# Verificar con:
SELECT routine_name FROM information_schema.routines 
WHERE routine_name LIKE 'fun_%menu%';
```

---

### ❌ Error: "obtener_menus_usuario.php not found (404)"

**Síntoma:** Al seleccionar usuario, aparece error 404 en consola  
**Causa:** El archivo `obtener_menus_usuario.php` no existe en `src/`  
**Solución:**
```bash
# Verificar que exista el archivo:
dir C:\Apache24\htdocs\pronom\src\obtener_menus_usuario.php

# Si no existe, crear el archivo nuevamente con el contenido proporcionado
```

---

### ❌ Checkboxes no se marcan

**Síntoma:** Selecciono usuario pero los checkboxes no aparecen marcados  
**Causa:** El JavaScript no está funcionando o hay error en la BD  
**Solución:**
```javascript
// Abrir consola (F12) y revisar:
// 1. Error en fetch?
// 2. Respuesta JSON válida?

// Probar AJAX manualmente:
fetch('obtener_menus_usuario.php?usuario=admin')
    .then(r => r.json())
    .then(d => console.log(d));

// Si devuelve error, revisar: php -l obtener_menus_usuario.php
```

---

### ❌ Al guardar, dice "¡Grabado!" pero no se guarda

**Síntoma:** Click en EJECUTAR PROCESO → mensaje OK pero cambios no se persisten  
**Causa:** Las funciones SQL existen pero no ejecutan inserciones  
**Solución:**
```sql
-- Verificar que la función insert realmente funciona:
BEGIN;
  SELECT fun_insert_menu_usuarios('admin', '1');
  SELECT COUNT(*) FROM tab_menu_usuarios WHERE id_usuario='admin' AND id_menu='1';
ROLLBACK;

-- Si no inserta, revisar la función SQL por errores
```

---

## 📞 Logs Recomendados

### Activar logging en PHP (para debugging)

En `prepare.php` o en los archivos PHP, agregar:

```php
// Al inicio del script
error_log("DEBUG: Valor de variable = " . var_export($variable, true));

// Para ver logs:
// Linux: tail -f /var/log/apache2/error.log
// Windows: Ver evento en Registro de eventos de Windows
```

### Revisar query log de PostgreSQL

```sql
-- En postgres
SET log_statement = 'all';
-- Revisar archivo de log de PostgreSQL
```

---

## 📊 Flujo Resumido

```
Usuario accede a menu_usuarios.php
    ↓
[Selecciona usuario del dropdown]
    ↓
JavaScript dispara evento 'change'
    ↓
Llama AJAX a obtener_menus_usuario.php?usuario=ID
    ↓
PHP valida usuario y consulta tab_menu_usuarios
    ↓
Devuelve JSON con array de id_menus
    ↓
JavaScript marca los checkboxes correspondientes
    ↓
[Usuario ve sus menús ya marcados]
    ↓
[Usuario modifica si desea]
    ↓
[Click EJECUTAR PROCESO]
    ↓
Form POST a procesar_perfil.php
    ↓
PHP inicia transacción:
  1. fun_delete_perfil_usuarios(id_usuario)  ← Limpia
  2. fun_insert_menu_usuarios(id_usuario, id_menu) ← Inserta nuevos
    ↓
COMMIT o ROLLBACK
    ↓
[Mensaje de éxito o error]
    ↓
FIN
```

---

## ✨ Características Nuevas Resumidas

| Característica | Antes | Ahora |
|---|---|---|
| **Ver menús asignados** | No | ✅ Cargan automáticamente |
| **Visualización rápida** | No | ✅ Checkboxes pre-marcados |
| **Limpiar formulario** | No | ✅ Botón "Limpiar/Nuevo" |
| **AJAX asincrónico** | No | ✅ No bloquea interfaz |
| **Información clara** | No | ✅ Nota descriptiva al usuario |

---

**Implementación completada: ✅**  
Versión: **v1.3+**  
Fecha: **2 de marzo de 2026**
