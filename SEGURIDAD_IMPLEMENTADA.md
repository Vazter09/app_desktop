# Implementación de Seguridad — SmartCSET

**Última actualización:** 2026-06-18
**Responsable:** Equipo de Desarrollo - SmartCSET
**Estado:** 55% de Fase 1 + 100% de Fase 0

---

## Resumen Ejecutivo

| Métrica                      | Avance                                                    |
| ----------------------------- | --------------------------------------------------------- |
| **Fase 0 (Gobernanza)** | ✅ 100% Completa — 8 documentos legales                  |
| **Fase 1 (Código)**    | ⚠️ 55% — 5/10 entregables completados                  |
| **Cobertura OWASP**     | ~40% — A01, A02, A07 cerrados; A03-A10 pendientes        |
| **Cobertura ISC2 CC**   | ✅ Dominios D1-D5 con evidencia de Fase 0; D3 en progreso |
| **Tests de seguridad**  | ✅ 23/23 PASS (E1-A01, A02, E4, E6, E7)                   |

---

## FASE 0 — DOCUMENTACIÓN COMPLETA (Gobernanza y Políticas)

### 8 Documentos Legales Creados:

| Doc N°                 | Archivo                                     | Cubre                                        | Estado |
| ----------------------- | ------------------------------------------- | -------------------------------------------- | ------ |
| **FASE0-POL-001** | 01_POLITICA_Y_TRATAMIENTO_DATOS_PERSONALES  | Ley 1581/2012, D1, Ejes 1/11                 | ✅     |
| **FASE0-INV-002** | 02_INVENTARIO_ACTIVOS_INFORMACION_CID       | ISO 27001 A.8, D1/D5, Eje 3 (16 activos INF) | ✅     |
| **FASE0-RIE-003** | 03_MATRIZ_RIESGOS_INICIAL                   | ISO 27005, D1, Eje 2 (31 riesgos)            | ✅     |
| **FASE0-ROL-004** | 04_ROLES_Y_RESPONSABILIDADES_SEGURIDAD      | D1/D5, Ejes 1/4                              | ✅     |
| **FASE0-AUD-005** | 05_CRONOGRAMA_AUDITORIAS_PERIODICAS         | D5, Ejes 1/6                                 | ✅     |
| **FASE0-PSI-006** | 06_POLITICA_GENERAL_SEGURIDAD_INFORMACION   | D1 completo,**mapea 11 ejes MSPI**     | ✅     |
| **FASE0-ACC-007** | 07_POLITICA_CONTROL_ACCESO_SEGURIDAD_FISICA | D3 completo, Ejes 5/7                        | ✅     |
| **FASE0-INC-008** | 08_MARCO_GESTION_INCIDENTES_CONTINUIDAD     | D2 completo, Ejes 9/10 (RTO=4h, RPO=24h)     | ✅     |

**Ubicación:** `Documentacion para implementacion de MSPI/FASE 0_documentos politicas de tratamiento de datos/`

---

## FASE 1 — IMPLEMENTACIÓN EN CÓDIGO

### Resumen por Entregable:

| Entregable                            | Contenido                           | Status                            | %    |
| ------------------------------------- | ----------------------------------- | --------------------------------- | ---- |
| **E1 — OWASP Top 10**          | Auditoría A01-A10                  | ⚠️ 40% (A01 ✅, A02 ✅, A07 ✅) | 40%  |
| **E2 — Cifrado en reposo**     | pgcrypto para datos sensibles       | ⛔ Bloqueado                      | 0%   |
| **E3 — Rate limiting**         | tab_intentos_login + middleware PHP | 🔲 Pendiente                      | 0%   |
| **E4 — Hardening sesiones**    | SecurityMiddleware, CSP, cookies    | ✅**100%**                  | 100% |
| **E5 — Anti-CSRF**             | Tokens en formularios POST          | 🔲 Pendiente                      | 0%   |
| **E6 — Verificación uploads** | .htaccess en directorios            | ✅**100%**                  | 100% |
| **E7 — Corrección setup**     | 3/4 funciones PL/pgSQL en FUNCS     | ✅**100%**                  | 100% |
| **E8 — Hardening de red**      | TLS PostgreSQL, firewall            | ⚠️ 30%                          | 30%  |
| **E9 — Gestión de parches**   | Inventario + SLA por CVSS           | 🔲 Pendiente                      | 0%   |
| **E10 — SDLC seguro**          | Checklist pre-commit/deploy         | ✅**100%**                  | 100% |

**Total Fase 1:** 5/10 completados = **55%**

---

## DETALLE DE IMPLEMENTACIONES COMPLETADAS

### E1-A01: Broken Access Control ✅

**Vulnerabilidad:** Escalada vertical de privilegios — 8 endpoints sin verificación de admin

**Endpoints vulnerables identificados:**

- `src/menu/menus.php`
- `src/usuarios/usuarios.php`
- `src/menu/menu_usuarios.php`
- `src/menu/copiar_menu_usuarios.php`
- `src/menu/procesar_perfil.php`
- `src/menu/procesar_permiso.php`
- `src/menu/procesar_copiar_perfil.php`
- `src/menu/obtener_menus_usuario.php`

**Remediación implementada:**

```php
// Guardias admin agregadas a cada endpoint
if (!usuarioEsAdministrador($pdo, $_SESSION['id_usuario'])) {
    header('Location: index.php');
    exit;
}
```

**Validación:** 11 pruebas manuales con curl en producción → **TODAS PASS** (2026-06-11)

**Reporte:** `REPORTE_E1-A01_BROKEN_ACCESS_CONTROL_SMARTCSET.md` (v1.1)

---

### E1-A02: Cryptographic Failures (HTTPS) ✅

**Vulnerabilidad:** Sistema sin HTTPS en producción — tráfico en claro

**Remediación implementada (2026-06-17):**

#### Certificado TLS

```bash
# ECDSA P-256, válido 365 días, CN=smartcset.local
/etc/apache2/certs/smartcset.crt + .key
Algoritmo verificado: TLSv1.3
Cipher: TLS_AES_256_GCM_SHA384
```

#### VirtualHost HTTPS en Apache

```apache
DocumentRoot: /var/www/html
ServerName: 10.5.213.103
HTTP → HTTPS: 301 Moved Permanently
```

#### Forzado de HTTPS en código

```php
// index.php (líneas 11-15)
if (defined('APP_ENV') && APP_ENV === 'production' && empty($_SERVER['HTTPS'])) {
    header("Location: https://" . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI'], true, 301);
    exit;
}
```

#### Cookie flags verificados

```
Set-Cookie: PHPSESSID=...;
  Secure ✅        (HTTPS only)
  HttpOnly ✅      (no acceso desde JS)
  SameSite=Strict ✅ (máxima protección CSRF)
  Max-Age=1800 ✅  (30 min sesión)
```

**Validación:** Firefox aceptó certificado autofirmado, login exitoso, dashboard accesible

**Reporte:** `REPORTE_E1-A02_CRYPTOGRAPHIC_FAILURES_SMARTCSET.md` (v3.0)

---

### E1-A07: Session Fixation ✅ (implementado via E4)

**Vulnerabilidad:** No había regeneración de SID tras login exitoso

**Remediación implementada:**

```php
// index.php (línea 52)
session_regenerate_id(true);  // Destruye SID anterior, genera uno nuevo
$_SESSION['id_usuario'] = $w_reg['id_usuario'];
```

**Validación:**

- Pre-login: SID = `f8ep25l5lpsqve423ojdr9dvds`
- Post-login: SID = `aqnmlf6k0c228grl0f8p0jf0h2` (diferente ✅)

**Cierre de vector:** Un atacante no puede hijackear la sesión de login con un SID pre-generado.

---

### E4: Hardening de Sesiones ✅ (100% completado)

**Compuesto de 4 sub-implementaciones:**

#### 1. SecurityMiddleware Activo

```php
// prepare.php y prepare_login.php (antes código muerto, ahora activo)
require_once __DIR__ . '/SecurityMiddleware.php';
SecurityMiddleware::configureSessionSecurity();
SecurityMiddleware::setSecurityHeaders();
```

**Headers HTTP implementados:**

| Header                      | Valor                                        | Propósito                                     |
| --------------------------- | -------------------------------------------- | ---------------------------------------------- |
| `X-Content-Type-Options`  | `nosniff`                                  | Previene MIME sniffing                         |
| `X-Frame-Options`         | `DENY`                                     | Previene clickjacking                          |
| `X-XSS-Protection`        | `1; mode=block`                            | Protección XSS legacy                         |
| `Referrer-Policy`         | `strict-origin-when-cross-origin`          | Privacidad de referer                          |
| `Permissions-Policy`      | `geolocation=(), microphone=(), camera=()` | Deshabilita permisos de navegador              |
| `Content-Security-Policy` | `script-src 'self'`                        | **CSP activo — solo scripts de origen** |

#### 2. Externalización de Scripts Inline (Prerrequisito CSP)

**(9 scripts de bajo/medio riesgo, 2026-06-14):**

- `js/login-page.js` — desde `index.php`
- `js/recuperar.js` — desde `src/auth/recuperar.php`
- `js/admin-personas-config.js` — desde `src/admin/personas/config.php`
- `js/theme-init.js` — inicialización de tema visual
- `js/registro-aprendiz-buscar.js` — búsqueda automática de aprendices
- `js/registro-cargar-ciudades.js` — carga dinámica de ciudades por departamento
- `js/registro-form-accordion.js` — comportamiento accordión en formularios
- `js/registro-form-funcionario.js` — lógica específica formulario funcionario
- `js/registro-session-clock.js` — reloj de sesión en módulo registro

**(2 scripts de alto riesgo — wizards, 2026-06-14):**

- `js/porteria-ingreso-modal.js` — wizard de 5 pasos para ingreso de personas
  - Reducción: `porteria/ingreso/index.php` de 1017 → 764 líneas (**25% reducción**)
- `js/porteria-salida-modal.js` — wizard para salida de personas
  - Reducción: `porteria/salida/index.php` de 914 → 683 líneas (**25% reducción**)

**Hallazgo adicional y bug corregido:**

- `src/auth/cambiar_clave.php` tenía `session_start()` prematuro (antes de `SecurityMiddleware`)
- Arreglado: eliminado `session_start()` redundante y externalizado a `js/auth-cambiar-clave.js`

**Resultado:** 0 `<script>` inline restantes en el sistema

#### 3. Cookie Security Fix

**Antes:**

```php
ini_set('session.cookie_secure', '1');  // Siempre, sin condición ❌
// Rompía dev (HTTP) pero "forzaba" HTTPS
```

**Después:**

```php
$w_cookie_secure = (APP_ENV === 'production') ? '1' : '0';
ini_set('session.cookie_secure', $w_cookie_secure);  // Condicional ✅
// Seguro en producción, funciona en dev
```

**Impacto:** Las cookies ahora se envían únicamente por HTTPS en producción, sin romper flujo de desarrollo.

#### 4. CSP Activado

```php
// SecurityMiddleware.php
$w_csp = "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; "
       . "font-src 'self'; img-src 'self' data:;";
header("Content-Security-Policy: $w_csp");
```

- ✅ `script-src 'self'` — solo scripts de este servidor (bloquea inyecciones XSS)
- ⚠️ `style-src 'unsafe-inline'` — necesario para theming embebido, bajo riesgo
- ✅ `img-src 'self' data:` — imágenes del servidor + data URLs (para fotos capturadas)

**Verificación end-to-end:**

- Login → dashboard → porteria ingreso/salida → cambiar clave
- Header CSP presente en TODAS las respuestas
- DevTools Console: 0 violaciones de CSP

**Reporte:** `REPORTE_E1-E04_HARDENING_SESIONES_SMARTCSET.md` (v2.0, 2026-06-14)

---

### E6: Verificación de Uploads ✅

**Vulnerabilidad:** Directorios de uploads permitían ejecución de PHP y interpretación de HTML/JS

**Directorios protegidos:**

- `public/uploads/logos/` — logos corporativos subidos vía configuración
- `storage/porteria/` — fotos de personas capturadas en control de acceso

**Remediación implementada (2 archivos .htaccess idénticos):**

```apache
# 1. BLOQUEAR EJECUCIÓN PHP
<FilesMatch "\.(php|phtml|asp|jsp|cgi|sh|pl|py|phar)$">
    Deny from all
</FilesMatch>

# 2. FORZAR CONTENT-TYPE SEGURO
Header set Content-Type "image/jpeg"

# 3. PREVENIR MIME SNIFFING
Header set X-Content-Type-Options "nosniff"

# 4. CACHÉ + DESHABILITAR LISTADO
Header set Cache-Control "public, max-age=31536000"
Options -Indexes
```

**Ataques prevenidos:**

- ❌ RCE vía upload de `shell.php`
- ❌ XSS vía upload de `xss.html`
- ❌ Ejecución de scripts `backdoor.sh`, `reverse.py`
- ❌ MIME sniffing (navegador interpreta `.jpg` como `.html`)
- ❌ Listado de directorios (DirectoryIndex deshabilitado)

**Nota técnica:** `.htaccess` requiere Apache. Si el servidor SENA usa **Nginx**, se requieren reglas equivalentes en el virtual host (documentado en el reporte).

**Reporte:** `REPORTE_E1-E06_VERIFICACION_SUBIDA_ARCHIVOS_SMARTCSET.md` (v1.0, 2026-06-13)

---

### E7: Corrección setup_smartcset.sh ✅

**Problema:** Instalador (bash) faltaban 4 funciones PL/pgSQL en array FUNCS

**Auditoría de las 4 funciones:**

| Función                  | Ubicación                              | Acción                                                                           | Resultado   |
| ------------------------- | --------------------------------------- | --------------------------------------------------------------------------------- | ----------- |
| `fun_validar_correo`    | `database/functions/acceso/usuarios/` | ✅ Agregada a FUNCS + alineada a `smartcset_handle_sql_error()`                 | Compila OK  |
| `fun_validar_login`     | `database/functions/acceso/usuarios/` | ✅ Agregada a FUNCS + refactorizada (eliminado GET STACKED DIAGNOSTICS)           | Compila OK  |
| `fun_validar_usuario`   | `database/functions/acceso/usuarios/` | ✅ Agregada a FUNCS + patrones de error estandarizados                            | Compila OK  |
| `fun_tab_menu_usuarios` | `database/functions/acceso/menus/`    | ❌**EXCLUIDA** (contiene legacy que habría regresionado mejores versiones) | No agregada |

**Decisión técnica sobre exclusión de `fun_tab_menu_usuarios`:**

- El archivo define 2 funciones: `fun_insert_menu_usuarios` y `fun_delete_perfil_usuario`
- Versiones mejoradas ya existen en `FUNCS` con validación + `smartcset_handle_sql_error()`
- Agregar el archivo habría sobreescrito las versiones buenas (regresión de seguridad)
- Impacto real: NINGUNO — ningún `.php` o `.sh` referencia el archivo directamente

**Verificación de impacto (confirmado 2026-06-13):**

- Las 2 funciones que define se crean igual en instalaciones nuevas (desde sus archivos individuales)
- Excluir el archivo evita riesgo de regresión
- El archivo permanece en el repo como código muerto/histórico

**Reporte:** `REPORTE_E1-E07_CORRECCION_SETUP_SMARTCSET.md` (v1.0, 2026-06-13)

---

### E10: SDLC Seguro ✅ (Adoptado como Proceso)

**Nota:** E10 no es código, es **PROCESO OBLIGATORIO** desde 2026-06-13

#### Checklist Pre-Commit (Bloqueo total si falla)

```
[BLOQUEO TOTAL] 5 ítems de SEGURIDAD:
  ☐ ¿Hay secretos hardcodeados? (API keys, DB password, tokens)
  ☐ ¿Hay input de usuario sin validar?
  ☐ ¿Hay SQL concatenado (no prepared statements)?
  ☐ ¿Hay output sin htmlspecialchars()?
  ☐ ¿Hay rutas sin guarda de sesión?

[VALIDACIÓN] 4 ítems de CALIDAD:
  ☐ php -l — sin errores sintácticos
  ☐ ruff check (si hay Python nuevo)
  ☐ PSR-12 — código legible
  ☐ Tests actualizados si cambió comportamiento
```

#### Checklist Pre-Deploy (Backup obligatorio)

```
[OBLIGATORIO] Pre-deploy:
  1. pg_dump -Fc db_smartcset > backup_$(date +%Y%m%d_%H%M%S).dump
  2. Verificar que el dump tiene >1MB (datos reales)
  3. Git status limpio (todo commiteado)

[VALIDACIÓN] Post-deploy:
  1. Login funciona (admin.smart / contraseña)
  2. Porteria ingreso y salida registran eventos
  3. Cambio de contraseña funciona
  4. grep "ERROR\|FATAL" /tmp/backend.log — sin errores nuevos
```

#### Procedimiento de Rollback de Emergencia

```bash
# Si algo falla en producción:
git checkout [commit previo]          # Revertir código
pg_restore -d db_smartcset backup.dump  # Restaurar BD
php -S localhost:8080                 # Verificar
# Si esto no funciona, contactar al custodio de claves
```

#### 6 Prohibiciones Absolutas

| Prohibición                                   | Razón                                            | Ejemplo                                                                        |
| ---------------------------------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------ |
| **1. Editar PHP directo en producción** | Imposible de auditar, versiones desincronizadas   | ❌`ssh` + `nano` + guardar. ✅ Git + deploy                                |
| **2. Hardcodear secretos**               | Exponerse en repositorio público                 | ❌`$db_pass = "Admin123";` ✅ `.env`                                       |
| **3. SQL concatenado**                   | SQL injection + RCE                               | ❌`"SELECT * FROM usuarios WHERE id = $id"` ✅ Prepared statement            |
| **4. var_dump / print_r en producción** | Expone estructura de BD                           | ❌`var_dump($usuario);` ✅ error_log()                                       |
| **5. PDO::ATTR_EMULATE_PREPARES=true**   | Anula protección de prepared statements          | ❌`$pdo->setAttribute(ATTR_EMULATE_PREPARES, true)` ✅ Dejar default (false) |
| **6. git push --force a main**           | Pierde historial, sobreescribe trabajo del equipo | ❌`git push --force origin main` ✅ Pull request + revisión                 |

**Reporte:** `REPORTE_E1-E10_SDLC_SEGURO_SMARTCSET.md` (v1.0, 2026-06-13)

---

### E8: Hardening de Red (Parcial — 30%)

**Vulnerabilidad:** Base de datos sin TLS, sin firewall, arquitectura sin documentación

**Implementado:**

- ✅ Infraestructura de código: `DB_SSLMODE` en `config.php`, `Db.php`, `.env.example`
- 🔲 Activación real: requiere coordinación con Oficina TI SENA
- 🔲 Configuración PostgreSQL: postgresql.conf, pg_hba.conf, certificados
- 🔲 Firewall: reglas de entrada/salida

**Status:** Infraestructura lista, **bloqueada por dependencia externa** (stakeholder: Oficina TI SENA)

**Pendiente:**

- Habilitar ssl=on en PostgreSQL
- Instalar certificados de BD
- Configurar reglas de firewall
- Documentar arquitectura de red real

---

## 🔲 PENDIENTES (Aún no implementados)

| Entregable            | Descripción                               | Bloqueador                  | Próximo paso             |
| --------------------- | ------------------------------------------ | --------------------------- | ------------------------- |
| **E3**          | Rate limiting + tab_intentos_login         | Ninguno                     | Diseño + código         |
| **E5**          | Tokens anti-CSRF en formularios POST       | Base E4 lista               | Implementar en E5         |
| **E2**          | Cifrado en reposo (pgcrypto)               | **Hallazgo crítico** | Replanteo de diseño      |
| **E1 (cierre)** | A03-A10 (Injection, Insecure Design, etc.) | Ninguno                     | Auditoría OWASP completa |
| **E9**          | Gestión de parches                        | Ninguno                     | Inventario + SLA          |
| **E8 (cierre)** | Activación de TLS PostgreSQL              | Oficina TI SENA             | Coordinación externa     |

### E2 — Hallazgo Crítico Bloqueando

**Contexto:** El plan original de E2 (Fase1-BLI-001 §4.1) asume una columna `tab_personas.documento_identidad` independiente que se podría cifrar.

**Problema descubierto (2026-06-12):** Esa columna NO existe. El número de documento es:

- La **PRIMARY KEY** de `tab_personas` (`id_persona NUMERIC(10,0)`)
- **FOREIGN KEY** referenciada por 5+ tablas (`tab_aprendices`, `tab_instructores`, `tab_funcionarios`, `tab_log_ingresos`, `tab_vehiculos`)

**Implicación:** Cifrar una PK con pgcrypto (BYTEA no determinístico) rompería TODOS los JOIN/FK/índices del sistema — esto es un **rediseño del modelo de datos**, no un cambio de columna.

**Opciones (requieren decisión con Anderson):**

1. Pausar E2 en Fase 1, documentar en reporte A02 que requiere diseño propio fuera de alcance
2. Replantear alcance a otro dato cifrable sin tocar PKs (ej. `val_huella_digital`, `val_patron_facial`)
3. Documentar rediseño completo (PK surrogate) como entregable nuevo de Fase 2

---

## MATRIZ COBERTURA ISC2 CC vs IMPLEMENTACIÓN

| Dominio ISC2                              | Descripción                                        | Cobertura | Implementado        | Pendiente                  |
| ----------------------------------------- | --------------------------------------------------- | --------- | ------------------- | -------------------------- |
| **D1 — Security Principles (26%)** | Políticas, roles, gobernanza, cumplimiento         | ✅        | FASE 0 (8 docs)     | E1 A03-A10                 |
| **D2 — BC/DR/IR (10%)**            | Continuidad, recuperación de desastres, incidentes | ✅        | FASE 0 doc 08       | FASE 2 (runbooks)          |
| **D3 — Access Controls (22%)**     | Autenticación, autorizacion, menús, RBAC          | ✅        | A01 + E4 + E7       | E3, E5                     |
| **D4 — Network Security (24%)**    | TLS, firewall, arquitectura, infraestructura        | ⚠️      | E8 (30%)            | E8 (70%), coordinación TI |
| **D5 — Security Operations (18%)** | Auditoría, logs, monitoreo, parches                | ✅        | FASE 0 docs 2/4/5/8 | E9 (gestión parches)      |

---

## ESTADÍSTICAS DE IMPLEMENTACIÓN

### Código PHP/SQL Modificado

| Métrica                                         | Antes       | Después          | Impacto                       |
| ------------------------------------------------ | ----------- | ----------------- | ----------------------------- |
| Scripts inline en `porteria/ingreso/index.php` | 255 líneas | ↓ Externalizadas | Reducción 25%                |
| Scripts inline en `porteria/salida/index.php`  | 250 líneas | ↓ Externalizadas | Reducción 25%                |
| Endpoints sin guarda de admin                    | 8           | ↓ 0              | 100% remediado                |
| Archivos JS nuevos                               | 0           | 12                | CSP compliance                |
| Tamaño cacheable JS                             | 0 KB        | ~55 KB            | Aceleración siguiente acceso |
| Headers de seguridad HTTP                        | 0           | 6                 | Defensa en profundidad        |

### Vulnerabilidades Cerradas

| Vulnerabilidad                         | Severidad   | Status | Cierre |
| -------------------------------------- | ----------- | ------ | ------ |
| Escalada vertical de privilegios (A01) | 🔴 Crítica | ✅     | E1-A01 |
| Tráfico en claro sin HTTPS (A02)      | 🔴 Crítica | ✅     | E1-A02 |
| Session fixation (A07)                 | 🟠 Alta     | ✅     | E4     |
| RCE via upload de PHP (E6)             | 🔴 Crítica | ✅     | E6     |
| Scripts inline violando CSP (E4)       | 🟠 Alta     | ✅     | E4     |
| Setup sin funciones críticas (E7)     | 🟠 Alta     | ✅     | E7     |

---

## SUITE DE TESTS AUTOMATIZADOS

**Ubicación:** `test_seguridad/` (Python 3 + unittest + requests)

**Coverage:**

- ✅ E1-A01: 6 tests (verifican guardias admin en 8 endpoints)
- ✅ E1-A02: 3 tests (HTTPS, redirect, cookie flags)
- ✅ E4: 6 tests (session security, CSP headers, session regen)
- ✅ E6: 5 tests (upload prevention, MIME sniffing)
- ✅ E7: 3 tests (funciones PL/pgSQL creadas)

**Resultado:** 23/23 PASS ✅

**Ejecución:**

```bash
cd test_seguridad
python3 -m unittest discover -v
```

---

## ARTEFACTOS GENERADOS

### Reportes de Auditoría Formal

| Reporte                                     | Versión | Fecha      | Entregable |
| ------------------------------------------- | -------- | ---------- | ---------- |
| REPORTE_E1-A01_BROKEN_ACCESS_CONTROL        | v1.1     | 2026-06-11 | E1-A01     |
| REPORTE_E1-A02_CRYPTOGRAPHIC_FAILURES       | v3.0     | 2026-06-17 | E1-A02     |
| REPORTE_E1-E04_HARDENING_SESIONES           | v2.0     | 2026-06-14 | E4         |
| REPORTE_E1-E06_VERIFICACION_SUBIDA_ARCHIVOS | v1.0     | 2026-06-13 | E6         |
| REPORTE_E1-E07_CORRECCION_SETUP             | v1.0     | 2026-06-13 | E7         |
| REPORTE_E1-E10_SDLC_SEGURO                  | v1.0     | 2026-06-13 | E10        |

**Ubicación:** `Documentacion para implementacion de MSPI/FASE 01_Blindaje Técnico Inmediato/`

### Guías y Documentación Técnica

| Documento                   | Propósito                                | Ubicación                 |
| --------------------------- | ----------------------------------------- | -------------------------- |
| GUIDE_JS_MODULES.md         | Referencia JS ↔ PHP para el equipo       | `js/GUIDE_JS_MODULES.md` |
| CHECKLIST_MAESTRO_BLINDAJE  | Avance panorámico transversal            | MSPI                       |
| PLAN_BLINDAJE_INSTITUCIONAL | Documento maestro (v1.2)                  | MSPI                       |
| handoff.txt                 | Handoff técnico de MSPI (este documento) | MSPI                       |

---

## PRÓXIMOS PASOS RECOMENDADOS

### Orden de Implementación (según plan)

1. **✅ E10** — SDLC seguro (adoptado)
2. **✅ E7** — Corrección setup (completado)
3. **✅ E4** — Hardening sesiones (completado)
4. **✅ E6** — Verificación uploads (completado)
5. **→ E5** — Tokens anti-CSRF (próximo)
6. **→ E3** — Rate limiting (siguiente)
7. **→ E1 (cierre)** — A03-A10 OWASP (paralelo)
8. **⛔ E2** — Requiere replanteo (bloqueado)
9. **→ E8** — Hardening red (coordinación TI)
10. **→ E9** — Gestión de parches

### Quick Wins (corto plazo)

- E5: Base técnica ya lista (CSP + headers), bajo acoplamiento
- E3: Protección crítica contra fuerza bruta, bien definido
- Integración móvil: Auditoría móvil pendiente de análisis (H-MOB-*)

---

## REFERENCIAS CRUZADAS

- **CLAUDE.md** — Patrones generales de código (raíz)
- **AGENTS.md** — Detalles técnicos y decisiones (carpeta MSPI)
- **handoff.txt** — Handoff específico MSPI (este documento)
- **HANDOFF_GENERAL_SMARTCSET.txt** — Contexto completo del proyecto (raíz)
- **GUIDE_JS_MODULES.md** — Orientación al equipo sobre JS/PHP (carpeta js/)

---

## CHECKLIST RÁPIDO PARA EQUIPO

Antes de cualquier cambio de código:

- [ ] ¿Necesita actualizar tabla de SEGURIDAD_IMPLEMENTADA.md?
- [ ] ¿Hay new code? → Pasar pre-commit checklist (E10)
- [ ] ¿Hay SQL nuevo? → ¿Prepared statements? ¿Sin concatenación?
- [ ] ¿Hay scripts HTML? → ¿Están externalizados a `.js`? (CSP)
- [ ] ¿Cambió PHP auth/acceso? → ¿Verificar guardias de sesión?
- [ ] ¿Cambió upload? → ¿Validación + .htaccess?

---
