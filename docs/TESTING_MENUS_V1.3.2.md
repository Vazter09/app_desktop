# ✅ TESTING RÁPIDO - Mejoras Jerárquicas V.1.3.2

## Pruebas Iniciales (5 minutos)

### Test 1️⃣: Carga de Página
**¿Qué esperar?**
- Menús nivel 1 visibles (Configuración, Liquidación, Fin)
- Botones ▸ junto a menús que tienen submenús
- Panel derecho gris (bloqueado)

**Cómo verificar:**
```
1. Abrir: http://localhost/pronom/src/menu_usuarios.php
2. Ver tabla con menús
3. ¿Ves solo ~3-5 filas de menús? ✓
4. ¿Los submenús NO están visibles? ✓
5. ¿Hay pequeños botones ▸ en algunas filas? ✓
```

**Si falla:**
- Revisar que `style` esté en `<head>` de menu_usuarios.php
- Verificar que `.menu-row.nivel-2` tiene `display: none` en CSS

---

### Test 2️⃣: Expandir/Contraer
**¿Qué esperar?**
- Click en ▸ expande el menú → ▼
- Click en ▼ contrae el menú → ▸
- Submenús aparecen/desaparecen suavemente

**Cómo verificar:**
```
1. Con página cargada
2. Buscar menú "1 - Configuración" (debe tener ▸)
3. Click en ▸
4. ¿Se expande? ¿Ves "11 - Parámetros", "12 - Acceso", etc.? ✓
5. ¿El símbolo cambió a ▼? ✓
6. Click en ▼ nuevamente
7. ¿Se contrae? ¿Desaparecen los submenús? ✓
```

**Si falla:**
- Revisar console (F12) para errores
- Verificar función `expandirMenu()` en menu_usuarios.js

---

### Test 3️⃣: Cargar Usuario Existente
**Precondición:** Debe haber usuario "admin" en la BD con menús asignados

**¿Qué esperar?**
- Seleccionar admin
- Carga rápida (AJAX)
- Se expanden automáticamente los menús que tienen asignados
- Se marcan los checkboxes de menús asignados
- Resumen muestra la cantidad

**Cómo verificar:**
```
1. Clic en selector "ID Usuario"
2. Seleccionar "Administrador del Sistema" (es admin)
3. Esperar ~1 segundo
4. ¿Se expanden automáticamente algunos menús? ✓
5. ¿Se marcan algunos checkboxes? ✓
6. Ejemplo - deberías ver:
   ▼ 1 - Configuración
     ▼ 12 - Acceso
       ☑ 121 - Usuarios
       ☑ 122 - Cambiar Clave
   ▼ 2 - Liquidación
     ☑ 21 - Conceptos
7. ¿El resumen dice "Menús Seleccionados (n)"? ✓
```

**Si falla:**
- Abrir console (F12)
- Buscar errores de fetch
- Verificar que `obtener_menus_usuario.php` existe
- Probar AJAX manualmente:
  ```javascript
  fetch('obtener_menus_usuario.php?usuario=admin')
      .then(r => r.json())
      .then(d => console.log(d));
  ```

---

### Test 4️⃣: Auto-Marcar Padres al Seleccionar Menú con Programa
**¿Qué esperar?**
- Menú con programa (tiene valor en columna 3, no es "no_aplica")
- Al marcarlo, todos sus padres se marcan automáticamente hacia arriba

**Cómo verificar:**
```
1. Expandir "1 - Configuración"
2. Expandir "12 - Acceso"
3. VER menús:
   ☐ 121 - Usuarios (tiene programa: usuarios.php)
   ☐ 122 - Cambiar Clave (tiene programa: cambiar_clave.php)
4. Desmarcar "admin" del selector (reset)
5. Seleccionar otro usuario (o usuario vacío)
6. Marcar manualmente "121 - Usuarios"
7. ¿Se marcó automáticamente "12 - Acceso"? ✓
8. ¿Se marcó automáticamente "1 - Configuración"? ✓
9. ¿El resumen ahora muestra 3 menús? ✓
```

**Si falla:**
- Verificar que el atributo `data-tiene-programa` está en los checkboxes del HTML
- Revisar párametro `data-tiene-programa` en PHP:
  ```php
  data-tiene-programa="<?= ($m['nom_programa'] !== 'no_aplica' && !empty($m['nom_programa'])) ? 'true' : 'false' ?>"
  ```
- Verificar función `marcarMenusPadres()` en JavaScript

---

### Test 5️⃣: Resumen Visual en Tiempo Real
**¿Qué esperar?**
- Panel azul que dice "📋 Menús Seleccionados (n):"
- Lista con checkmarks ✓ de todos los menús marcados
- Se actualiza inmediatamente al marcar/desmarcar

**Cómo verificar:**
```
1. Seleccionar usuario con menús
2. ¿Aparece el panel azul con lista? ✓
3. ¿Muestra cantidad correcta? ✓
4. Desmarcar un checkbox
5. ¿La lista se actualiza inmediatamente? ✓
6. ¿La cantidad disminuye? ✓
7. Marcar otro checkbox
8. ¿Se suma a la lista? ✓
```

**Si falla:**
- Revisar función `actualizarResumenMenus()` en JavaScript
- Verificar que el contenedor con id `resumen_menus_seleccionados` no existe en el HTML (se crea dinámicamente)

---

### Test 6️⃣: Guardar y Auto-Limpieza
**¿Qué esperar?**
- Al hacer submit exitosamente, mostrar mensaje
- Después de 0.5 segundos, todo se limpia automáticamente
- Panel vuelve a gris (bloqueado)
- Selector vacío
- Todos los checkboxes desmarcados

**Cómo verificar:**
```
1. Seleccionar usuario
2. Marcar/desmarcar algunos checkboxes
3. Clic "EJECUTAR PROCESO"
4. ¿Aparece mensaje "✅ ¡Grabado exitoso..."? ✓
5. Contar: 1, 2, 3, 4, 5...
6. ¿Después se limpia todo automáticamente? ✓
7. ¿Selector está vacío? ✓
8. ¿Todos sin marcar? ✓
9. ¿Panel de nuevo gris? ✓
```

**Si falla:**
- Revisar console de errores
- Verificar que `procesar_perfil.php` existe y responde
- Comprobar timeout de 500ms en función `cargarMenusAsignados()`

---

### Test 7️⃣: Botón "Limpiar/Nuevo"
**¿Qué esperar?**
- Click inmediato en limpiar/nuevo (sin esperar 500ms como en guardado)
- Limpia todo igual al guardar

**Cómo verificar:**
```
1. Seleccionar usuario
2. Marcar checkboxes
3. Clic "Limpiar/Nuevo"
4. ¿Se limpia inmediatamente? ✓ (sin mensaje)
5. ¿Selector vacío? ✓
6. ¿Checkboxes desmarcados? ✓
7. ¿Panel gris? ✓
```

---

## 🐛 Troubleshooting Rápido

| Problema | Síntoma | Solución |
|---|---|---|
| **Menús no se expanden** | Click en ▸ no hace nada | Revisar `expandirMenu()` en JS |
| **No se cargan menús al seleccionar** | Error 404 en console | Verificar `obtener_menus_usuario.php` existe |
| **Menús no se expanden automáticamente** | Usuario seleccionado pero todo contraído | Revisar `expandirMenusSeleccionados()` en JS |
| **No se auto-marcan padres** | Marcas menú, padres no se marcan | Verificar `data-tiene-programa` en HTML |
| **Resumen no aparece** | No ve el panel azul | Revisar `actualizarResumenMenus()` en JS |
| **No se limpia después de guardar** | Datos persisten después de click | Revisar timeout de 500ms |
| **Símbolos ▸ no aparecen** | No ves botones de expansión | Verificar CSS `.menu-toggle` |

---

## 📋 Checklist de Validación

```
ANTES DE MARCAR COMO COMPLETADO:

Funcionalidad Base:
☐ Página carga sin errores
☐ Selector de usuario carga usuario
☐ Panel de menús se desbloquea

Expansión/Colapso:
☐ Botones ▸ visibles en menús adecuados
☐ Click en ▸ expande/contrae
☐ Símbolo cambia (▸ ↔ ▼)
☐ Submenús aparecen/desaparecen

Auto-Carga de Menús:
☐ AJAX obtiene menús del usuario
☐ Menús se marcan correctamente
☐ Padres se expanden automáticamente
☐ Resumen muestra cantidad correcta

Auto-Marcado de Padres:
☐ Menú con programa se detecta
☐ Al marcar, se marcan todos los padres
☐ Encadenamiento hacia arriba correcto

Guardado:
☐ Submit va a procesar_perfil.php
☐ Mensaje de éxito aparece
☐ Auto-limpieza después de 500ms

Global:
☐ No hay errores en console (F12)
☐ No hay warnings en console
☐ Flujo completo sin problemas
☐ Performance aceptable (< 2s en cargas)
```

---

## 🎯 Pasos Exactos Test Completo (10 minutos)

```
1. Abre menu_usuarios.php
2. Verifica estado inicial: ✓ solo menús nivel 1, ▸ visibles
3. Click ▸ Configuración: ✓ expande
4. Selecciona "admin": ✓ carga, expande, marca, resumen
5. Click ▸ Configuración: ✓ contrae
6. Expande "12 - Acceso" manualmente
7. Marca manualmente "121 - Usuarios": ✓ marca 12 y 1 automáticamente
8. Ve resumen actualizado: ✓ 3 menús
9. Guarda: ✓ mensaje, auto-limpia
10. Verifica estado final = estado inicial
```

**Tiempo esperado:** 10 minutos  
**Resultado esperado:** TODOS LOS TESTS PASAN ✓

---

**Documento de Pruebas:** v1.3.2  
**Fecha:** 2 de marzo de 2026
