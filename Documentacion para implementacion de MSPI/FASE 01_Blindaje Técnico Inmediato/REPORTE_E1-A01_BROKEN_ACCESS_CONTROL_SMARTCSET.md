# Reporte de remediación — E1-A01: Broken Access Control

**Documento N°:** FASE1-REP-A01
**Versión:** 1.1
**Fecha de elaboración:** 2026-06-10
**Última actualización:** 2026-06-11 — agregada sección 6.2 (procedimiento detallado de pruebas manuales) y 6.3 (criterios de cierre)
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

### 6.2 Procedimiento detallado de ejecución

> **Requisitos previos:** servidor de desarrollo levantado (`.\tools\start_dev.ps1` o `php -S localhost:8080`), BD `db_smartcset` con datos de seed (usuarios `admin.smart` / `porteria` existentes), y `curl` disponible. Todos los comandos asumen `http://localhost:8080` como base — ajustar el host/puerto si es distinto.
>
> Usar un *cookie jar* por usuario para no mezclar sesiones: `cookies_porteria.txt` y `cookies_admin.txt`.

---

#### Prueba 1 — Usuario no-admin (`porteria`) accede directo a CRUDs de administración

**Objetivo:** confirmar que `usuarioEsAdministrador()` bloquea con 403 a un usuario autenticado sin privilegio admin.

**Paso 1.1 — Login como `porteria`:**
```bash
curl -i -c cookies_porteria.txt -X POST http://localhost:8080/index.php \
  --data-urlencode "txt_usuario=porteria" \
  --data-urlencode "txt_clave=Porteria2026!"
```
- **Resultado esperado:** `HTTP/1.1 302 Found` con `Location` apuntando a `src/menu/menu_principal.php`. El archivo `cookies_porteria.txt` debe contener una cookie `PHPSESSID`.
- **Resultado que NO debe ocurrir:** `200 OK` mostrando de nuevo el formulario de login (= credenciales rechazadas) o ausencia de cookie `PHPSESSID`.

**Paso 1.2 — Intentar abrir `menus.php` con la sesión de `porteria`:**
```bash
curl -i -b cookies_porteria.txt http://localhost:8080/src/menu/menus.php
```
- **Resultado esperado:** `HTTP/1.1 403 Forbidden` con cuerpo de texto plano `Acceso denegado. Esta sección es exclusiva para administradores.` (proviene del `die()` en la guardia §4.1).
- **Resultado que NO debe ocurrir:** `200 OK` con el HTML del CRUD de menús, o cualquier tabla/listado de `tab_menus`.

**Paso 1.3 — Intentar abrir `usuarios.php` con la misma sesión:**
```bash
curl -i -b cookies_porteria.txt http://localhost:8080/src/usuarios/usuarios.php
```
- **Resultado esperado:** igual que 1.2 — `403 Forbidden` + mensaje "Acceso denegado. Esta sección es exclusiva para administradores."
- **Resultado que NO debe ocurrir:** `200 OK` con el listado/formulario de usuarios del sistema.

**(Opcional) Paso 1.4 — Repetir 1.2 y 1.3 contra los otros 2 endpoints HTML restantes** (`src/menu/menu_usuarios.php` y `src/menu/copiar_menu_usuarios.php`) para cobertura completa de los 4 archivos HTML del hallazgo:
```bash
curl -i -b cookies_porteria.txt http://localhost:8080/src/menu/menu_usuarios.php
curl -i -b cookies_porteria.txt http://localhost:8080/src/menu/copiar_menu_usuarios.php
```
- **Resultado esperado:** `403 Forbidden` en ambos, mismo mensaje.

---

#### Prueba 2 — `POST` directo sin sesión a los endpoints JSON críticos

**Objetivo:** confirmar que `procesar_perfil.php` y `procesar_permiso.php` —que antes de la corrección no exigían ni siquiera sesión— ahora responden 403 sin necesidad de estar autenticado.

**Paso 2.1 — `POST` sin cookies a `procesar_perfil.php`:**
```bash
curl -i -X POST http://localhost:8080/src/menu/procesar_perfil.php \
  --data-urlencode "hid_usuario=1" \
  --data-urlencode "chk_menu[]=1"
```
- **Resultado esperado:** `HTTP/1.1 403 Forbidden`, `Content-Type: application/json`, cuerpo JSON con `"status":"error"` y mensaje `"Acceso denegado. Esta operación requiere privilegios de administrador."` (formato de `ErrorHandler::createResponse`).
- **Resultado que NO debe ocurrir:** `200 OK` con `"status":"success"`, o cualquier modificación en `tab_menu_usuarios` para `id_usuario=1`.

**Paso 2.2 — `POST` sin cookies a `procesar_permiso.php`:**
```bash
curl -i -X POST http://localhost:8080/src/menu/procesar_permiso.php \
  --data-urlencode "id_usuario=1" \
  --data-urlencode "id_menu=1" \
  --data-urlencode "permitido=1"
```
- **Resultado esperado:** igual que 2.1 — `403 Forbidden` + JSON de error con privilegios de administrador requeridos.
- **Resultado que NO debe ocurrir:** `200 OK` con `"status":"success"` o cambio del permiso del menú 1 para el usuario 1.

**Paso 2.3 — Verificación negativa en BD (confirma que no hubo escritura):**
```sql
-- Antes y después de 2.1/2.2, el resultado debe ser idéntico (sin filas nuevas/modificadas)
SELECT id_usuario, id_menu, fec_update FROM tab_menu_usuarios
WHERE id_usuario = 1 ORDER BY fec_update DESC LIMIT 5;
```
- **Resultado esperado:** ninguna fila con `fec_update` posterior al momento de ejecución de 2.1/2.2.

**(Opcional) Paso 2.4 — Repetir 2.1 con sesión de `porteria` (no admin), reutilizando `cookies_porteria.txt`:**
```bash
curl -i -b cookies_porteria.txt -X POST http://localhost:8080/src/menu/procesar_perfil.php \
  --data-urlencode "hid_usuario=1" \
  --data-urlencode "chk_menu[]=1"
```
- **Resultado esperado:** `403 Forbidden` igual que sin sesión — la guardia exige `usuarioEsAdministrador()`, no solo "tener sesión".

---

#### Prueba 3 — Usuario admin (`admin.smart`) sin falsos positivos

**Objetivo:** confirmar que la guardia añadida no rompe el flujo legítimo del administrador (regresión cero).

**Paso 3.1 — Login como `admin.smart`:**
```bash
curl -i -c cookies_admin.txt -X POST http://localhost:8080/index.php \
  --data-urlencode "txt_usuario=admin.smart" \
  --data-urlencode "txt_clave=AdminSmart2026!"
```
- **Resultado esperado:** `302 Found` → `src/menu/menu_principal.php`, cookie `PHPSESSID` en `cookies_admin.txt`.

**Paso 3.2 — Acceder a los 4 CRUDs HTML con sesión admin:**
```bash
curl -s -o /dev/null -w "%{http_code} menus.php\n"             -b cookies_admin.txt http://localhost:8080/src/menu/menus.php
curl -s -o /dev/null -w "%{http_code} usuarios.php\n"          -b cookies_admin.txt http://localhost:8080/src/usuarios/usuarios.php
curl -s -o /dev/null -w "%{http_code} menu_usuarios.php\n"     -b cookies_admin.txt http://localhost:8080/src/menu/menu_usuarios.php
curl -s -o /dev/null -w "%{http_code} copiar_menu_usuarios.php\n" -b cookies_admin.txt http://localhost:8080/src/menu/copiar_menu_usuarios.php
```
- **Resultado esperado:** `200` en las 4 líneas.
- **Resultado que NO debe ocurrir:** cualquier `403` — indicaría que `usuarioEsAdministrador()` no reconoce a `admin.smart` como administrador (`tab_usuarios.ind_usuario` mal seteado) o que la guardia se insertó en un lugar incorrecto.

**Paso 3.3 — `POST` real a `procesar_permiso.php` con sesión admin (operación de negocio legítima):**
```bash
curl -i -b cookies_admin.txt -X POST http://localhost:8080/src/menu/procesar_permiso.php \
  --data-urlencode "id_usuario=<ID_USUARIO_PORTERIA>" \
  --data-urlencode "id_menu=<ID_MENU_VALIDO>" \
  --data-urlencode "permitido=1"
```
> Sustituir `<ID_USUARIO_PORTERIA>` y `<ID_MENU_VALIDO>` por valores reales de `tab_usuarios` / `tab_menus` (consultar con `SELECT id_usuario FROM tab_usuarios WHERE usr_usuario = 'porteria';` y `SELECT id_menu, str_nombre FROM tab_menus;`).

- **Resultado esperado:** `200 OK`, JSON con `"status":"success"`, y el cambio reflejado en `tab_menu_usuarios` (verificar con la misma query del Paso 2.3).
- **Resultado que NO debe ocurrir:** `403 Forbidden` (falso positivo de la guardia) ni error 500.

**Paso 3.4 — `POST` a `procesar_perfil.php` (asignación de perfil completo) con sesión admin:**
```bash
curl -i -b cookies_admin.txt -X POST http://localhost:8080/src/menu/procesar_perfil.php \
  --data-urlencode "hid_usuario=<ID_USUARIO_PORTERIA>" \
  --data-urlencode "chk_menu[]=<ID_MENU_1>" \
  --data-urlencode "chk_menu[]=<ID_MENU_2>"
```
- **Resultado esperado:** `200 OK`, JSON `"status":"success"`, transacción aplicada (los menús listados quedan asignados, los no listados se desasignan).
- **Resultado que NO debe ocurrir:** `403 Forbidden` ni rollback con mensaje de error.

**Paso 3.5 — Cierre de sesión y limpieza:**
```bash
curl -i -b cookies_admin.txt http://localhost:8080/src/auth/logout.php
rm -f cookies_porteria.txt cookies_admin.txt
```

---

### 6.3 Criterios de cierre de la verificación

| # | Prueba | Aprobado si | Falla si |
|---|---|---|---|
| 1.2 / 1.3 / 1.4 | `porteria` accede a CRUDs admin | `403` + "Acceso denegado..." en los 4 archivos HTML | Cualquier `200` con contenido del CRUD |
| 2.1 / 2.2 | `POST` sin sesión a endpoints JSON | `403` + JSON `status:error` en ambos, sin cambios en BD | `200` con `status:success` o fila modificada en `tab_menu_usuarios` |
| 2.4 | `POST` con sesión `porteria` (no admin) | `403` igual que sin sesión | `200` (la guardia solo validaría sesión, no rol) |
| 3.2 | `admin.smart` accede a los 4 CRUDs | `200` en los 4 | Cualquier `403` (falso positivo) |
| 3.3 / 3.4 | `admin.smart` ejecuta operaciones reales | `200` + `status:success` + cambio persistido en BD | `403`, `500`, o `status:error` |

Si **todas** las filas de la tabla anterior cumplen "Aprobado si", la prueba manual del subcontrol 1 de A01 queda cerrada y el ítem pendiente de §6.1 puede marcarse `[x]` en `02_CHECKLIST_IMPLEMENTACION_FASE1_SMARTCSET.md`.

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
