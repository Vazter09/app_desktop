# 📋 RESUMEN DE CAMBIOS - Gestión de Menús por Usuario (V.1.3+)

## Fecha: 2 de marzo de 2026

---

## 📝 Resumen Ejecutivo

Se han creado las funciones SQL `fun_insert_menu_usuarios.sql` y `fun_delete_perfil_usuarios.sql`, y se ha mejorado la interfaz de **Gestión de Accesos de Usuarios** para mostrar automáticamente los menús ya asignados cuando se selecciona un usuario.

---

## 📂 Archivos Creados

### 1. **scripts/fun_insert_menu_usuarios.sql**
- **Descripción:** Función SQL para insertar la relación usuario-menú en `tab_menu_usuarios`
- **Parámetros:**
  - `p_id_usuario` (VARCHAR): ID del usuario
  - `p_id_menu` (VARCHAR): ID del menú
- **Retorna:** VOID
- **Características:**
  - Valida que el usuario y menú existan
  - Maneja conflictos de duplicados silenciosamente
  - Incluye validación de integridad referencial

### 2. **scripts/fun_delete_perfil_usuarios.sql**
- **Descripción:** Función SQL para eliminar todos los menús de un usuario (borra su perfil de acceso)
- **Parámetros:**
  - `p_id_usuario` (VARCHAR): ID del usuario
- **Retorna:** VOID
- **Características:**
  - Valida que el usuario exista
  - Elimina todos los registros de `tab_menu_usuarios` asociados
  - Manejo robusto de excepciones
  - Registra el número de registros eliminados (comment)

### 3. **src/obtener_menus_usuario.php**
- **Descripción:** Endpoint AJAX que devuelve los menús asignados a un usuario específico
- **Método:** GET
- **Parámetro:** `?usuario=ID_USUARIO`
- **Respuesta:** JSON con estructura:
  ```json
  {
    "status": "success",
    "menusAsignados": ["1", "11", "12", "121", ...]
  }
  ```
- **Validaciones:**
  - Usuario debe existir y estar activo
  - Devuelve error 400 si el usuario no existe

---

## 🔧 Archivos Modificados

### 1. **js/menu_usuarios.js**
**Cambios principales:**

#### ✨ Nueva función: `cargarMenusAsignados(idUsuario)`
```javascript
async function cargarMenusAsignados(idUsuario) {
    // Llamada AJAX a obtener_menus_usuario.php
    // Descarga todos los menús del usuario
    // Marca los checkboxes correspondientes
}
```

#### ✨ Mejorada: Event listener del selector de usuario
- Cuando se selecciona un usuario, automáticamente:
  1. Desactiva el bloqueo del panel de permisos
  2. Llama a `cargarMenusAsignados()` para cargar sus menús
  3. Marca los checkboxes de los menús ya asignados

#### ✨ Nueva funcionalidad: Botón "Limpiar / Nuevo"
- Limpia la selección del usuario
- Desactiva el panel de permisos
- Desmarca todos los checkboxes
- Permite empezar de nuevo sin recargar la página

### 2. **src/menu_usuarios.php**
**Cambios:**
- Mejorado el texto descriptivo con una nota clara que explica:
  - Los menús se cargarán automáticamente al seleccionar un usuario
  - Los menús ya asignados aparecerán marcados
  - El usuario puede modificar la configuración desde esa pantalla

---

## 🔄 Flujo de Uso Actualizado

### Escenario: Asignar/Modificar menús a un usuario

1. **Usuario abre "Gestión de Accesos de Usuarios"** (`menu_usuarios.php`)
   - Ve la lista de usuarios disponibles
   - Lee la nota informativa sobre la carga automática

2. **Selecciona un usuario del dropdown**
   - El panel derecho se desbloquea
   - Se hace una llamada AJAX a `obtener_menus_usuario.php`
   - Se reciben los IDs de los menús asignados

3. **JavaScript marca automáticamente los menús**
   - Todos los menús del usuario aparecen já con ✓
   - Visualiza rápidamente qué accesos tiene

4. **Usuario realiza cambios (opcional)**
   - Marca/desmarca menús según sea necesario
   - La lógica de "marcado ascendente" sigue funcionando (padre-hijo)

5. **Presenta el formulario**
   - Llama `procesar_perfil.php` que:
     - Borra todos los menús actuales (`fun_delete_perfil_usuario` o `fun_delete_perfil_usuarios`)
     - Inserta los nuevos menús seleccionados (`fun_insert_menu_usuarios`)

6. **Sistema confirma éxito**
   - Muestra mensaje de confirmación ✅
   - Usuario puede seleccionar otro usuario para continuar

---

## 📊 Estructura de Base de Datos Usada

### Tablas implicadas:
- **tab_usuarios:** Contiene los usuarios del sistema
- **tab_menus:** Contiene la estructura de menús del sistema
- **tab_menu_usuarios:** Relación N:M entre usuarios y menús (PK compuesta)

### Restricciones:
- `tab_menu_usuarios.id_usuario` REFERENCES `tab_usuarios(id_usuario)`
- `tab_menu_usuarios.id_menu` REFERENCES `tab_menus(id_menu)`
- **Clave primaria:** `(id_usuario, id_menu)`

---

## 🚀 Instalación/Deployment

### 1. Crear las funciones en la BD
```bash
# En PostgreSQL:
psql -U db_user -d db_proynom -f scripts/fun_insert_menu_usuarios.sql
psql -U db_user -d db_proynom -f scripts/fun_delete_perfil_usuarios.sql
```

### 2. Verificar que existen las funciones
```sql
\df fun_insert_menu_usuarios
\df fun_delete_perfil_usuarios
```

### 3. Probar el flujo completo
- Abrir `menu_usuarios.php` en el navegador
- Seleccionar un usuario
- Verificar que se cargan los menús correctamente
- Hacer cambios y guardar
- Verificar que los cambios se persisten

---

## ✅ Checklist de Validación

- [ ] Funciones SQL creadas en la BD
- [ ] Archivo `obtener_menus_usuario.php` funciona (devuelve JSON válido)
- [ ] Al seleccionar usuario, se cargan los menús asignados
- [ ] Los checkboxes se marcan/desmarcan correctamente
- [ ] El botón "Limpiar/Nuevo" resetea el formulario
- [ ] Al guardar cambios, se persisten en la BD
- [ ] La lógica de ascendencia (padre-hijo) sigue funcionando
- [ ] No hay errores en la consola del navegador
- [ ] No hay errores en el log de PHP

---

## 🔗 Relaciones Entre Archivos

```
menu_usuarios.php (interfaz)
    ├─> menu_usuarios.js (lógica cliente)
    │   ├─> obtener_menus_usuario.php (carga menús del usuario)
    │   └─> procesar_perfil.php (guarda cambios)
    │       └─> BD (funciones SQL)
    └─> prepare.php (conexión y prepara sentencias)
```

---

## 📝 Notas Adicionales

1. **Sin nom_programa en inserción:** A diferencia de versiones anteriores, la función `fun_insert_menu_usuarios` NO requiere el campo `nom_programa`. Este campo está en `tab_menus` y se hereda de allí.

2. **Transaccionalidad:** El proceso de guardado es atómico:
   - Se inicia una transacción
   - Se borran todos los menús antiguos
   - Se insertan los nuevos
   - Si hay error en cualquier paso, se revierte todo (ROLLBACK)

3. **Seguridad:** El usuario solo puede modificar menús de usuarios (el campo `id_usuario` se valida en la BD)

4. **Rendimiento:** La carga de menús asignados es asincrónica (AJAX), no bloquea la interfaz

5. **Compatibilidad:** El sistema sigue siendo compatible con versiones anteriores que usan `fun_delete_perfil_usuario` (singular)

---

**Autor:** Sistema SistNomina V.1.3+  
**Responsable:** [Usuario/Equipo]  
**Estado:** ✅ Completado
