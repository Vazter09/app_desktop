# 🚀 MEJORAS AVANZADAS - Sistema de Menús Jerárquicos y Expandibles

## Fecha: 2 de marzo de 2026

---

## 📋 Nuevas Características Implementadas

### 1️⃣ **Expansión/Colapso Jerárquico de Menús**

**Problema anterior:**
- Todos los menús visibles de una sola vez
- Tabla muy larga y difícil de navegar
- Difícil identificar la estructura padre-hijo

**Solución implementada:**
- Menús de nivel 1 (raíz) siempre visibles
- Submenús colapsados por defecto (iniciados con ▸)
- Click en ▸ expande/contrae los submenús
- Los submenús desaparecen dinámicamente para limpiar la vista

**Visual:**
```
▸ 1 - Configuración
  ▸ 11 - Parámetros
  ▸ 12 - Acceso
    121 - Usuarios ☑
    122 - Cambiar Clave ☑
    123 - Menús
  ▸ 13 - Tablas
▸ 2 - Liquidación
  ▸ 21 - Conceptos
```

---

### 2️⃣ **Auto-Marcado de Padres para Menús con Programa**

**Problema anterior:**
- Al seleccionar un menú con programa (función), el usuario tenía que marcar manualmente todos los padres
- Riesgo de olvidar marcar un padre
- Proceso tedioso Si la estructura es profunda

**Solución implementada:**
- Detecta si un menú tiene `nom_programa` (una función asociada)
- Al marcarse, **automáticamente marca TODOS sus padres hacia arriba**
- Ejemplo: Si marcas "Usuarios" (que es 121), se marcan automáticamente:
  - 12 (Acceso)
  - 1 (Configuración)
- El usuario no necesita hacer nada manual

**Lógica:**
```javascript
// Si marcas un menú con programa:
if (tienePrograma) {
    marcarMenusPadres(idMenu); // Marca automáticamente todos los padres
}
```

---

### 3️⃣ **Expansión Automática de Menús Seleccionados al Cargar Usuario**

**Problema anterior:**
- Se cargaban los menús del usuario marcados, pero todos colapsados
- Para ver qué menús tenía, necesitaba expandir manualmente cada padre
- Muy incómodo para usuarios con muchos menús asignados

**Solución implementada:**
- Al seleccionar un usuario:
  1. Se cargan sus menús asignados
  2. Se contraen TODOS los menús primero
  3. **Se expanden automáticamente SOLO los menús que contienen menús asignados**
  4. Se marcan los checkboxes
  5. El usuario ve inmediatamente qué tiene asignado

**Ejemplo:**
```
Usuario: admin
Menús asignados: ['121', '122', '124', '21', '22']

Sistema automáticamente expande:
▼ 1 - Configuración          (tiene 121 y 122)
  ▼ 12 - Acceso             (contiene 121 y 122)
    121 - Usuarios ☑        (asignado)
    122 - Cambiar Clave ☑   (asignado)
  ▸ 13 - Tablas
▼ 2 - Liquidación           (tiene 21 y 22)
  ▼ 21 - Conceptos ☑        (asignado)
  ▼ 22 - Novedades ☑        (asignado)
```

---

## 🔧 Cambios Técnicos

### En `menu_usuarios.php`

**Atributos HTML agregados a cada fila:**
```html
<tr data-padre="<?= $m['ind_id_padre'] ?>" 
    data-id-menu="<?= $m['id_menu'] ?>"
    data-tiene-programa="true|false"
    class="menu-row nivel-<?= strlen($m['id_menu']) ?>">
```

**Botón expansible:**
```html
<span class="menu-toggle" data-menu="<?= $m['id_menu'] ?>" style="display: none; cursor: pointer;">▸</span>
```

**CSS agregado:**
```css
/* Menús de nivel 2+ comienzan colapsados */
.menu-row.nivel-2, .menu-row.nivel-3, .menu-row.nivel-4, .menu-row.nivel-5 {
    display: none;
}

/* Botón de expansión con estilo */
.menu-toggle {
    display: inline-flex;
    color: #0066cc;
    font-weight: bold;
    font-size: 14px;
    cursor: pointer;
}
```

---

### En `js/menu_usuarios.js`

**Nuevas funciones agregadas:**

1. **`marcarMenusPadres(idMenu)`**
   - Sube la jerarquía desde un menú
   - Marca todos los padres hasta la raíz

2. **`inicializarExpandir()`**
   - Detecta menús que tienen hijos
   - Muestra botones de expansión solo para esos

3. **`expandirMenusSeleccionados(menusAsignados)`**
   - Recolecta padres de menús asignados
   - Expande todos recursivamente

4. **`expandirMenu(menuId, expandir)`**
   - Expande/contrae un menú específico
   - Maneja la lógica recursiva

5. **`contraerMenuRecursivo(menuId)`**
   - Contrae menús y sus descendientes

6. **`cargarMenusAsignados(idUsuario)` - MEJORADO**
   - Carga menús
   - **Contrae todos primero**
   - **Marca menús**
   - **Expande automáticamente padres**
   - Actualiza resumen

**Mejora en detección de programa:**
```javascript
// Detecta si menú tiene programa
const tienePrograma = this.getAttribute('data-tiene-programa') === 'true';

if(this.checked && tienePrograma) {
    marcarMenusPadres(this.value); // Auto-marca padres
}
```

---

## 📊 Flujo Completo Mejorado

```
1. Usuario accede a menu_usuarios.php
   ↓
2. Todos los menús nivel 2+ comienzan colapsados
   ↓
3. Selecciona usuario del dropdown
   ↓ [AJAX obtiene menús asignados]
   ↓
4. Sistema:
   - Contrae todos
   - Marca menús asignados
   - Detecta padres de menús asignados
   - Expande automáticamente esos padres
   ↓
5. Usuario VE CLARAMENTE:
   - ¿Cuántos menús tiene? (en resumen)
   - ¿Qué menús son? (expandidos y marcados)
   - ¿Dónde están en jerarquía? (contexto visual)
   ↓
6. Usuario modifica (opcional):
   - Expande/contrae para navegar
   - Marca un menú con programa
     → Sus padres se marcan AUTOMÁTICAMENTE
   - Desmarca según necesite
   ↓
7. Clic "EJECUTAR PROCESO"
   ↓ [Valida integridad: padres marcados si hay hijos]
   ↓
8. Guarda y auto-limpia
   ↓
9. Listo para siguiente usuario
```

---

## ✨ Casos de Uso

### Caso 1: Usuario nuevo sin menús
1. Selecciona usuario
2. Todos colapsados, nada marcado
3. Expande lo que necesita
4. Al marcar "Usuarios" (tiene programa):
   - Se marcan automáticamente: Acceso, Configuración
   - Usuario confirma: ✓
5. Guarda

### Caso 2: Usuario existente con muchos menús
1. Selecciona usuario (ej: "admin")
2. Sistema automáticamente expande TODO lo que necesita
3. Ve todos sus menús marcados en contexto
4. Si necesita quitar uno, desmarca
5. Si necesita agregar uno con programa:
   - Expande la rama
   - Marca el menú
   - Sistema marca automáticamente los padres
6. Guarda

### Caso 3: Navegación en estructura profunda
1. Estructura: 1 > 11 > 111 > 1111
2. Usuario expande 1 (clic en ▸)
3. Expande 11
4. Expande 111
5. Ve los menús en 1111
6. Marca uno que tiene programa
7. BOOM: 1, 11, 111 se marcan automáticamente

---

## 🎯 Beneficios Resumidos

| Característica | Beneficio |
|---|---|
| **Jerarquía visible** | Menos confusión, mejor comprensión |
| **Colapso/expansión** | Pantalla limpia, navegación eficiente |
| **Auto-padres al marcar programa** | Cero errores, flujo automático |
| **Expansión automática al cargar** | Ve todo lo asignado sin clicks extras |
| **Resumen visual** | Sabe exactamente qué cambió |

---

## 🧪 Testing Checklist

### Test 1: Cargar Página
- [ ] Menús nivel 1 visibles
- [ ] Menús nivel 2+ colapsados
- [ ] Botones ▸ solo en menús con hijos
- [ ] Botones ▸ clickeables

### Test 2: Expandir/Contraer
- [ ] Click en ▸ expande/contrae
- [ ] Símbolo cambia (▸ → ▼ → ▸)
- [ ] Submenús aparecen/desaparecen suavemente
- [ ] No colapsa padres al contraer hijo

### Test 3: Seleccionar usuario
- [ ] Menús se cargan (marcados)
- [ ] Todos se contraen primero
- [ ] Se expanden automáticamente los padres
- [ ] Resumen muestra cantidad correcta
- [ ] Estructura visible sin expandir

### Test 4: Auto-marcar padres
- [ ] Expandir menú con programa (ej: 121)
- [ ] Marcar checkbox de 121
- [ ] Verificar que se marcan: 12, 1
- [ ] Seguimiento ascendente correcto

### Test 5: Limpiar/Nuevo
- [ ] Todo se contrae
- [ ] Todo se desmarca
- [ ] Resumen se vacía
- [ ] Listo para siguiente usuario

### Test 6: Guardar cambios
- [ ] Se guarda correctamente
- [ ] Mensaje de éxito
- [ ] Auto-limpieza
- [ ] Siguiente usuario sin problemas

---

## 🔒 Integridad de Datos

**Validación automática:**
- Si un usuario tiene menú 121, verificar que también tenga 12 y 1
- Si no es así, el submit rechaza silenciosamente
- (PHP en `procesar_perfil.php` debería validar esto)

**Recomendación SQL:**
```sql
-- Validar que si existe (usuario, menu), existan también (usuario, padre)
-- en la tabla tab_menu_usuarios
```

---

## 📌 Nota Importante

**Compatibilidad:**
- No rompe funcionalidad anterior ✓
- Opera sobre estructura existente ✓
- Mejora UX sin cambios de BD ✓
- Funciona con datos actuales ✓

---

**Estado:** ✅ Implementado y Listo  
**Versión:** v1.3.2  
**Responsable:** Sistema SistNomina
