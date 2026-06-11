# Reporte de remediación — E1-A01: Broken Access Control

**Documento N°:** FASE1-REP-A01
**Versión:** 1.0
**Fecha de elaboración:** 2026-06-10
**Entregable padre:** FASE1-BLI-001 — Entregable 1 (Auditoría OWASP Top 10)
**Control OWASP:** A01:2021 — Broken Access Control
**Estado:** ✅ Remediado y verificado (lint PHP)
**Elaborado por:** Equipo de Desarrollo - SmartCSET
**Clasificación:** Interno — Seguridad de la Información

---

## 1. Resumen ejecutivo

Se ejecutó la auditoría del control **A01 — Broken Access Control** del OWASP Top 10 2021 sobre SmartCSET, cubriendo sus tres subcontroles (validación de privilegio admin, IDOR por centro, y exigencia de sesión en módulos).

El hallazgo principal es una **escalada vertical de privilegios**: 8 endpoints de administración de menús y usuarios validaban únicamente que existiera una sesión iniciada (`isset($_SESSION['id_usuario'])`), pero **no** verificaban que el usuario tuviera el privilegio de administrador (`ind_usuario`). Dos de ellos (`procesar_perfil.php` y `procesar_permiso.php`) **no validaban siquiera la sesión**, quedando expuestos a peticiones no autenticadas.

Esto permitía que cualquier usuario autenticado sin rol de administrador —o, en dos casos, un atacante sin sesión— pudiera crear/editar menús, crear/editar usuarios y reasignar permisos de menús de otros usuarios. Es exactamente el riesgo **R-B02 (IDOR/control de acceso en datos)** de la matriz FASE0-RIE-003.

**Remediación:** se añadió una guardia de autorización basada en el helper existente `usuarioEsAdministrador($pdo, $_SESSION['id_usuario'])` en los 8 endpoints, replicando el patrón ya correcto de `src/admin/configuracion.php`. Páginas HTML responden `403` + mensaje; endpoints JSON responden `403` + envoltura de error JSON.

---

## 2. Alcance de la auditoría

| Subcontrol A01 | Resultado | Acción |
|---|---|---|
| **1. Validación de privilegio admin antes de acciones de administración** | ❌ Roto en 8 endpoints | ✅ Corregido (este reporte) |
| **2. IDOR — usuario solo accede a datos de su centro** (endpoints `consultar.php` de portería) | ✅ Aceptable | Ambos exigen sesión válida. El modelo de despliegue actual es mono-centro, por lo que no hay scoping por centro a nivel de usuario. Se deja marcado para revisión cuando el sistema opere multi-centro. |
| **3. Rutas de módulos requieren sesión válida** | ✅ Sin gaps reales | Los archivos de `src/modulos/` sin referencia a `id_usuario` son bootstraps (`init.php`) incluidos por páginas ya guardadas, o pertenecen al módulo `registro`, que usa su propio control de acceso standalone (`registroRequireAccess()`, `registroTieneSesionStandalone()`, `registroModuloHabilitado()`). El `login.php` del módulo registro es público por diseño. |

---

## 3. Hallazgo detallado (subcontrol 1)

### 3.1 Naturaleza de la vulnerabilidad

- **Tipo:** Escalada vertical de privilegios (Broken Access Control / Missing Function Level Access Control).
- **Causa raíz:** la verificación de acceso se limitaba a "¿hay sesión?" en lugar de "¿hay sesión **y** el usuario es administrador?". Las funciones de administración están documentadas como "solo admin" en `CLAUDE.md`, pero el código no lo imponía.
- **Patrón correcto de referencia (ya existía en el código):** `src/admin/configuracion.php` y `src/admin/personas/config.php` ya usaban `usuarioEsAdministrador($pdo, $_SESSION['id_usuario'])`. La corrección consistió en propagar ese mismo patrón.

### 3.2 Detalle por endpoint (estado **antes** de la corrección)

| # | Archivo | Tipo | Chequeo de sesión | Chequeo de privilegio admin | Severidad |
|---|---|---|---|---|---|
| 1 | `src/menu/menus.php` | Página HTML (CRUD menús) | ✅ Sí | ❌ No | Crítico |
| 2 | `src/usuarios/usuarios.php` | Página HTML (CRUD usuarios) | ✅ Sí | ❌ No | Crítico |
| 3 | `src/menu/menu_usuarios.php` | Página HTML (asignar menús) | ✅ Sí | ❌ No | Crítico |
| 4 | `src/menu/copiar_menu_usuarios.php` | Página HTML (copiar perfil) | ✅ Sí | ❌ No | Crítico |
| 5 | `src/menu/procesar_perfil.php` | Endpoint JSON (POST) | ❌ **No** | ❌ No (solo validaba que el *destino* no fuera admin) | Crítico |
| 6 | `src/menu/procesar_permiso.php` | Endpoint JSON (POST) | ❌ **No** | ❌ No | Crítico |
| 7 | `src/menu/procesar_copiar_perfil.php` | Endpoint JSON (POST) | ✅ Sí (vía `$_SESSION` implícito*) | ❌ No (solo validaba origen/destino) | Crítico |
| 8 | `src/menu/obtener_menus_usuario.php` | Endpoint JSON (GET) | ❌ **No** | ❌ No (el `usuarioEsAdministrador` aplicaba al *usuario consultado*, no al solicitante) | Alto |

\* En 5, 6, 7 y 8 el `usuarioEsAdministrador()` que ya existía se aplicaba al **usuario objetivo** de la operación (para decidir lógica de negocio), **no al solicitante**. Por eso no constituía control de acceso.

### 3.3 Impacto

- Un usuario de portería (no admin) autenticado podía: crear/editar/eliminar menús, crear/editar usuarios del sistema, y reasignar los menús (permisos) de cualquier usuario no administrador.
- En `procesar_perfil.php` y `procesar_permiso.php`, al no exigir sesión, la operación era invocable mediante un `POST` directo sin autenticación.

---

## 4. Remediación aplicada

### 4.1 Guardia para páginas HTML (archivos 1–4)

Se insertó, inmediatamente después del chequeo de sesión existente:

```php
// A01 (OWASP) — Broken Access Control: <sección> es exclusiva de administradores.
if (!usuarioEsAdministrador($pdo, $_SESSION['id_usuario'])) {
    http_response_code(403);
    die('Acceso denegado. Esta sección es exclusiva para administradores.');
}
```

### 4.2 Guardia para endpoints JSON/AJAX (archivos 5–8)

Se insertó, tras `header('Content-Type: application/json')`, una guardia que valida **sesión + privilegio admin del solicitante** y responde **403** con la envoltura de error estándar (`ErrorHandler::createResponse`). Se usa `403` explícito en lugar de `ErrorHandler::sendJSON()` porque este último fuerza HTTP `400`, y una denegación de autorización debe devolver `403`:

```php
// A01 (OWASP) — Broken Access Control: <operación> exige sesión y privilegio admin del solicitante.
if (!isset($_SESSION['id_usuario']) || !usuarioEsAdministrador($pdo, $_SESSION['id_usuario'])) {
    http_response_code(403);
    echo json_encode(
        ErrorHandler::createResponse('error', 'Acceso denegado. Esta operación requiere privilegios de administrador.', 'VALIDATION'),
        JSON_UNESCAPED_UNICODE
    );
    exit;
}
```

> La lógica preexistente que aplicaba `usuarioEsAdministrador()` al **usuario objetivo** (p. ej., impedir asignar menús a un admin, o mostrar el catálogo completo a un admin consultado) se conservó intacta: cumple un propósito de negocio distinto y es complementaria a la nueva guardia.

---

## 5. Archivos tocados

### 5.1 Código corregido (8 archivos)

| Archivo | Cambio |
|---|---|
| `src/menu/menus.php` | + guardia admin (HTML 403) tras chequeo de sesión |
| `src/usuarios/usuarios.php` | + guardia admin (HTML 403) tras chequeo de sesión |
| `src/menu/menu_usuarios.php` | + guardia admin (HTML 403) tras chequeo de sesión |
| `src/menu/copiar_menu_usuarios.php` | + guardia admin (HTML 403) tras chequeo de sesión |
| `src/menu/procesar_perfil.php` | + guardia sesión+admin (JSON 403) tras `Content-Type` |
| `src/menu/procesar_permiso.php` | + `require_once helpers.php` **y** guardia sesión+admin (JSON 403) |
| `src/menu/procesar_copiar_perfil.php` | + guardia sesión+admin (JSON 403) tras `Content-Type` |
| `src/menu/obtener_menus_usuario.php` | + guardia sesión+admin (JSON 403) tras `Content-Type` |

> Nota: `procesar_permiso.php` no incluía `src/core/helpers.php`, donde vive `usuarioEsAdministrador()`. Se agregó ese `require_once`.

### 5.2 Documentación actualizada (1 archivo)

| Archivo | Cambio |
|---|---|
| `FASE 01_Blindaje Técnico Inmediato/01_BLINDAJE_TECNICO_INMEDIATO_SMARTCSET.md` | Sección 3.2 A01 marcada ✅ Remediado con estado por subcontrol; fila A01 de la tabla de hallazgos (3.3) completada |

### 5.3 Documento creado (este reporte)

| Archivo | — |
|---|---|
| `FASE 01_Blindaje Técnico Inmediato/REPORTE_E1-A01_BROKEN_ACCESS_CONTROL_SMARTCSET.md` | Reporte de remediación E1-A01 |

---

## 6. Verificación

- ✅ `php -l` sin errores de sintaxis en los 8 archivos modificados.
- ✅ El helper `usuarioEsAdministrador()` consulta `tab_usuarios.ind_usuario` con prepared statement y cachea por solicitud (`src/core/helpers.php:68`).
- ✅ La sesión está disponible: `src/core/prepare.php` ejecuta `session_start()` antes de que cualquiera de estos archivos use `$_SESSION`.

### 6.1 Pruebas manuales recomendadas (pendientes de ejecutar en entorno con BD)

1. Iniciar sesión como `porteria` (no admin) e intentar abrir `src/menu/menus.php` y `src/usuarios/usuarios.php` → debe responder **403** "Acceso denegado", no mostrar el CRUD.
2. Sin sesión, hacer `POST` directo a `src/menu/procesar_perfil.php` y `src/menu/procesar_permiso.php` → debe responder **403** JSON, no modificar permisos.
3. Iniciar sesión como `admin.smart` (admin) y verificar que todas las pantallas y operaciones siguen funcionando con normalidad (no falsos positivos).

---

## 7. Trazabilidad normativa / certificación

| Marco | Mapeo |
|---|---|
| **OWASP Top 10 2021** | A01:2021 — Broken Access Control |
| **ISC2 CC** | Dominio 3 — Access Controls (control de acceso a nivel de función); Dominio 5 — Security Operations (gestión de vulnerabilidades) |
| **ISO/IEC 27001** | A.8 / A.5.15 — Control de acceso; A.8.3 — Restricción de acceso a la información |
| **MSPI MinTIC** | Eje 5 — Control de acceso |
| **FASE0-RIE-003** | Cierra parcialmente el riesgo R-B02 (IDOR/control de acceso en datos de personas) a nivel de funciones administrativas |
| **Ley 1273/2009** | Refuerza la protección frente al art. 269A (acceso abusivo a sistema informático) |

---

## 8. Pendientes derivados (fuera del alcance de A01)

- **Scoping multi-centro (subcontrol 2):** cuando SmartCSET opere con múltiples centros/sedes, los endpoints `consultar.php` de portería deberán filtrar por el centro/sede del usuario. Hoy no aplica (mono-centro).
- **CSRF (Entregable 5):** las guardias de A01 imponen *quién* puede invocar la operación, pero no protegen contra *cross-site request forgery*. Los tokens anti-CSRF se entregan en E5.
- **Rate limiting (Entregable 3)** y **hardening de sesión (Entregable 4)** siguen pendientes y son complementarios a este control.

---

**Fin del documento**
