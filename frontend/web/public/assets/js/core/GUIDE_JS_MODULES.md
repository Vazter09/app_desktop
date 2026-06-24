# 📖 Guía de Módulos JavaScript — SmartCSET

**Última actualización:** 2026-06-18  
**Responsable:** Equipo de Desarrollo - SmartCSET

---

## ¿Qué es este documento?

Esta guía permite al equipo de desarrollo entender:
1. **Qué hace cada archivo JS** y **qué archivo PHP lo llama**
2. **Por qué se separó el código JavaScript del PHP**
3. **Qué es un "wizard"** en contexto de SmartCSET

---

## 📋 Tabla de Referencia: JS ↔ PHP

| Archivo JS | Archivo PHP que lo llama | Propósito | Tipo |
|---|---|---|---|
| **porteria-ingreso-modal.js** | `src/modulos/porteria/ingreso/index.php` | Wizard para registrar ingreso de personas (escaneo de cédula, selección de puerta, modalidad de acceso) | **Wizard** |
| **porteria-salida-modal.js** | `src/modulos/porteria/salida/index.php` | Wizard para registrar salida de personas (búsqueda de ingreso abierto, confirmación de salida) | **Wizard** |
| **auth-cambiar-clave.js** | `src/auth/cambiar_clave.php` | Validación y manejo de formulario de cambio de contraseña | Formulario |
| **recuperar.js** | `src/auth/recuperar.php` | Validación y manejo de formulario de recuperación de contraseña | Formulario |
| **login-page.js** | `index.php` (login principal) | Validación de usuario/contraseña, manejo de errores en login | Formulario |
| **admin-personas-config.js** | `src/admin/personas/config.php` | Configuración visual del módulo de personas (colores, módulos activos) | Configuración |
| **theme-init.js** | `src/layout/head.php` (global) | Inicialización de tema visual corporativo (colores, CSS variables) | Global |
| **theme-init.js** | `src/modulos/registro/init.php` | Inicialización de tema en módulo de registro standalone | Global |
| **registro-aprendiz-buscar.js** | `src/modulos/registro/forms/aprendiz.php` | Búsqueda automática de aprendices por documento (autocompletado) | Búsqueda |
| **registro-cargar-ciudades.js** | `src/modulos/registro/forms/aprendiz.php`<br>`src/modulos/registro/forms/contratista.php`<br>`src/modulos/registro/forms/funcionario.php`<br>`src/modulos/registro/forms/persona.php` | Carga dinámica de ciudades según departamento seleccionado (AJAX) | Dropdown dinámico |
| **registro-form-accordion.js** | `src/modulos/registro/forms/aprendiz.php` | Comportamiento accordión en formulario de aprendiz (expandir/contraer secciones) | UI component |
| **registro-form-funcionario.js** | `src/modulos/registro/forms/funcionario.php` | Lógica específica del formulario de funcionario | Formulario |
| **registro-session-clock.js** | `src/modulos/registro/init.php` | Reloj de sesión (contador de minutos restantes en módulo registro) | UI component |
| **registro-theme-toggle.js** | `src/modulos/registro/login.php`<br>`src/modulos/registro/init.php` | Toggle de tema claro/oscuro en módulo registro standalone | UI component |

---

## ❓ ¿Por qué se separó el JavaScript del PHP?

### 1. **Content Security Policy (CSP) — Seguridad 🔒**

**Antes (prohibido desde E4):**
```php
<!-- index.php -->
<script>
    function login() { ... }  <!-- SCRIPT INLINE -->
</script>
```

**Problema:** Los scripts inline **violan la política CSP** (`Content-Security-Policy: script-src 'self'`), que es un estándar de seguridad que:
- Previene inyección de código malicioso (XSS)
- Fuerza que TODOS los scripts vengan de archivos `.js` externos, no embedidos en HTML
- Es obligatorio para cumplir OWASP A03:2021 (Injection)

**Después (correcto desde E4):**
```php
<!-- index.php -->
<script src="js/login-page.js"></script>  <!-- SCRIPT EXTERNO -->
```

El navegador verifica que `login-page.js` viene de `'self'` (el mismo servidor) — ✅ permitido por CSP.

---

### 2. **Mantenimiento y reutilización**

**Antes:** Si el mismo código JS estaba en 3 archivos PHP diferentes, había que modificarlo en 3 lugares.

**Después:** Un cambio en `registro-cargar-ciudades.js` se aplica automáticamente a los 4 archivos PHP que lo incluyen (`aprendiz.php`, `contratista.php`, `funcionario.php`, `persona.php`).

---

### 3. **Cacheo del navegador**

**Antes:** El HTML PHP entero se regenera en cada request → el navegador no puede cachear código repetido.

**Después:** El archivo `porteria-ingreso-modal.js` (11 KB) se cachea después del primer acceso → los siguientes requests de ingreso cargan **mucho más rápido** (no retransmiten esos 11 KB).

---

### 4. **Separación de responsabilidades**

| Responsabilidad | Archivo |
|---|---|
| Lógica de negocio, acceso a BD, decisiones | **PHP** |
| Interactividad del usuario, validación en cliente, transiciones visuales | **JavaScript** |

Esto hace el código más legible y mantenible.

---

## 🧙 ¿Qué es un "Wizard"?

Un **wizard** (del inglés "mago") es un **patrón de interfaz de usuario** que guía al usuario a través de una serie de pasos para completar una tarea compleja.

### Características de un wizard:
1. **Múltiples pasos** — No un formulario de una sola página, sino 2-5 pantallas secuenciales
2. **Validación entre pasos** — No avanzas al siguiente paso si los datos actuales son inválidos
3. **Navegación clara** — Botones "Siguiente", "Anterior", "Cancelar"
4. **Estado persistente** — Los datos que ingresaste en el paso 1 se mantienen cuando vuelves al paso 2
5. **Progreso visible** — El usuario ve en qué paso está (ej. "Paso 2 de 4")

### Ejemplos en SmartCSET:

**Wizard de Ingreso (porteria-ingreso-modal.js):**
```
Paso 1: Escanear cédula o número de documento
         ↓
Paso 2: Validar identidad en BD (¿está registrada la persona?)
         ↓
Paso 3: Seleccionar puerta de entrada (1-9)
         ↓
Paso 4: Seleccionar modalidad (normal, visitante, etc.)
         ↓
Paso 5: Confirmar y registrar ingreso
```

**Beneficios:**
- El usuario no se abruma con 20 campos en una pantalla
- Si algo falla en el paso 2 (documento no válido), el sistema le dice **específicamente dónde** sin perder lo que escribió
- La experiencia es más fluida, especialmente en tablets de portería

---

## 🛠️ Cómo trabajar con estos archivos

### Si necesitas **modificar el comportamiento de portería:**
1. Edita `js/porteria-ingreso-modal.js` o `js/porteria-salida-modal.js`
2. Prueba en `http://localhost:8080/smartcset/src/modulos/porteria/ingreso/` (dev)
3. Abre DevTools (F12) → Console → verifica que no hay errores
4. Después de commit, limpia el caché del navegador (Ctrl+Shift+Delete)

### Si necesitas **agregar un nuevo archivo JS:**
1. Crea el archivo en `/js/` con nombre descriptivo (ej. `modal-nuevafuncion.js`)
2. Sigue el patrón: `(function() { ... })()` para evitar contaminación global (ver `common.js` como referencia)
3. Inclúyelo en el PHP con: `<script src="../../js/modal-nuevafuncion.js?v=<?= (int) $_v_variable ?>"></script>`
4. Verifica que pase CSP (no debe tener `<script>` inline en el HTML)
5. Documenta aquí cuál PHP lo llama

### Si necesitas **debuggear un wizard:**
1. Abre DevTools (F12) → Elements → busca `<div id="modal-..." class="modal">`
2. Console → Ejecuta `console.log(document.querySelectorAll('[name=...]'))` para inspeccionar estados
3. Sources → establece breakpoints en el JS para pausar ejecución
4. Network → verifica que las llamadas AJAX (ej. `consultar.php`) retornan 200

---

## 📊 Estadísticas de la Separación (E4 — 2026-06-14)

| Métrica | Antes | Después | Impacto |
|---|---|---|---|
| Líneas PHP de `index.php` | N/A | ↓ reducción | No aplicable (login principal) |
| Líneas PHP de `porteria/ingreso/index.php` | 1017 | 764 | **↓ 25% menos** |
| Líneas PHP de `porteria/salida/index.php` | 914 | 683 | **↓ 25% menos** |
| Archivos JS nuevos | 0 | 12 | Inversión en claridad |
| Tamaño cacheable JS | 0 KB | ~55 KB total | Aceleración en siguientes accesos |
| Cumplimiento CSP | ❌ | ✅ | **Seguridad mejorada** |

---

## 🔗 Referencias

- **E4 — Hardening de Sesiones:** `Documentacion para implementacion de MSPI/FASE 01_Blindaje Técnico Inmediato/REPORTE_E1-E04_HARDENING_SESIONES_SMARTCSET.md`
- **OWASP A03:2021 — Injection:** https://owasp.org/Top10/A03_2021-Injection/
- **Content-Security-Policy:** https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
- **Patrón Wizard (UX):** https://www.nngroup.com/articles/wizards/ (Nielsen Norman Group)

---

## ✅ Checklist para el equipo

Antes de modificar cualquier archivo JS o agregar uno nuevo:

- [ ] ¿Necesita ser incluido en algún PHP? (Si sí, agrega `<script src="...">`  )
- [ ] ¿Contiene `<script>` inline embedido? (Si sí, ❌ viola CSP — extrae a `.js`)
- [ ] ¿Funciona en `http://localhost:8080` sin errores en Console?
- [ ] ¿Está documentado aquí en la tabla de referencia?
- [ ] ¿Pasó `php -l` en todos los PHPs modificados?
- [ ] ¿Limpiaste caché del navegador antes de prueba final?

---

**Preguntas o aclaraciones:** Consulta el archivo `CLAUDE.md` (patrones generales) o `AGENTS.md` de la carpeta MSPI (decisiones de seguridad).
