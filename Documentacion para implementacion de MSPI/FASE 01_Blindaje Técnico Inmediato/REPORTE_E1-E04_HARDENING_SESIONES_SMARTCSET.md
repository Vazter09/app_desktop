# Reporte de remediación — E4: Hardening de sesiones PHP

**Documento N°:** FASE1-REP-E04
**Versión:** 3.0 (abreviada — supersede v2.0)
**Fecha de elaboración:** 2026-06-14
**Entregable padre:** FASE1-BLI-001 — Entregable 4 (Hardening de sesiones PHP, §6)
**Estado:** ✅ Completo — 100% (sesión 1: hardening sesión/cookies/headers; sesión 2: refactor portería + CSP activo)
**Elaborado por:** Equipo de Desarrollo - SmartCSET
**Clasificación:** Interno — Seguridad de la Información

---

## Resumen ejecutivo

E4 cierra dos brechas OWASP:

- **A07:2021** (Session Fixation): el `PHPSESSID` no cambiaba tras login exitoso.
- **A04:2021** (Insecure Design / Clickjacking + cookies): `SecurityMiddleware.php` existía pero era
  **código muerto** — nunca se incluía desde `prepare.php`/`prepare_login.php`.

Durante la implementación se detectó que activar `Content-Security-Policy: script-src 'self'` rompería los
~250 líneas de JS inline de `porteria/ingreso/index.php` y `porteria/salida/index.php` (wizards de uso diario
crítico). Se dividió en 2 sesiones.

## Hallazgos

1. `cookie_secure` hardcodeado a `'1'` — habría roto el login en dev (sin HTTPS).
2. `SecurityMiddleware.php` nunca incluido por `prepare.php`/`prepare_login.php`.
3. `index.php` duplicaba 4/5 headers de seguridad (faltaba `Permissions-Policy`), solo en esa página.
4. `session_start()` se llamaba antes de los `ini_set()` de cookies → sin efecto.
5. Sin `session_regenerate_id()` tras login → vulnerable a session fixation (A07).
6. 9 archivos con scripts inline de riesgo bajo/medio + 2 de riesgo alto (wizards portería) que CSP
   `script-src 'self'` bloquearía.

## Remediación

- `cookie_secure` condicionado: `(APP_ENV === 'production') ? '1' : '0'`.
- `SecurityMiddleware.php` incluido en `prepare.php` y `prepare_login.php` (tras `config.php`, antes de `Db.php`)
  → activa en todo el sistema: `X-Content-Type-Options`, `X-Frame-Options`, `X-XSS-Protection`,
  `Referrer-Policy`, `Permissions-Policy`, cookies `HttpOnly`+`SameSite=Strict`(+`Secure` en prod),
  `session.use_strict_mode=1`, whitelist de métodos HTTP.
- CSP dejado **comentado con TODO** (pendiente externalizar scripts portería).
- `index.php`: eliminados 4 headers duplicados y `session_start()` manual; agregado
  `session_regenerate_id(true)` tras `password_verify()` exitoso.
- 9 scripts inline externalizados a `frontend/web/frontend/web/public/assets/js/` (login, registro x5, recuperar, admin/personas/config, theme-init).

 **refactor portería + CSP:**

- `porteria/ingreso/index.php`: wizard (~255 líneas) → `frontend/web/frontend/web/public/assets/js/porteria-ingreso-modal.js` (1017→764 líneas).
- `porteria/salida/index.php`: → `frontend/web/frontend/web/public/assets/js/porteria-salida-modal.js` (914→683 líneas).
- Bug adicional encontrado: `cambiar_clave.php` tenía `session_start()` antes de `prepare.php` (mismo patrón
  que el bug #4) — corregido + script → `frontend/web/frontend/web/public/assets/js/auth-cambiar-clave.js`.
- CSP activado en `SecurityMiddleware::setSecurityHeaders()`:
  `default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; font-src 'self'; img-src 'self' data:;`
  (`unsafe-inline` en estilos por theming embebido; `data:` en imágenes por `porteria_foto.php`).

## Validación

- Headers de seguridad presentes en `/` (sin `Secure` en dev, sin CSP hasta sesión 2 — correcto).
- SID cambia tras login (`f8ep25l5...` → `aqnmlf6k...`) → A07 cerrado.
- Login → dashboard → logout: 302/200/302 correctos.
- `porteria/ingreso`, `porteria/salida`, `cambiar_clave.php` → `200`, header CSP presente, **0** `<script>`
  inline, JS externos cargados correctamente, sin violaciones de CSP.
- `php -l` sin errores en los 16 archivos PHP modificados (ambas sesiones).

## Archivos tocados (resumen)

- Código: `SecurityMiddleware.php`, `prepare.php`, `prepare_login.php`, `index.php`,
  `frontend/web/layout/head.php`, `backend/routers/registro/v1/init.php` + 5 forms de registro,
  `backend/routers/admin/v1/personas/config.php`, `backend/routers/auth/v1/recuperar.php`, `backend/routers/auth/v1/cambiar_clave.php`,
  `porteria/ingreso/index.php`, `porteria/salida/index.php`.
- JS nuevos: `theme-init.js`, `registro-session-clock.js`, `registro-cargar-ciudades.js`,
  `registro-form-funcionario.js`, `login-page.js`, `admin-personas-config.js`, `recuperar.js`,
  `porteria-ingreso-modal.js`, `porteria-salida-modal.js`, `auth-cambiar-clave.js`.

## Trazabilidad normativa

| Marco             | Mapeo                                                                |
| ----------------- | -------------------------------------------------------------------- |
| OWASP Top 10 2021 | A07 (Session Fixation) — cerrado; A04 (Clickjacking/CSP) — cerrado |
| ISC2 CC           | D3 — Access Control Concepts (gestión de sesión)                  |
| ISO/IEC 27001     | A.8.5 — Secure authentication; A.8.23 — Web filtering              |
| MSPI MinTIC       | Eje 7 — Seguridad en desarrollo                                     |

## Pendientes derivados (fuera de alcance de E4)

- `enforceHTTPS()` sigue sin activar — depende de E8/TLS (Oficina TI).
- Verificar `php.ini` de producción (`session.gc_maxlifetime`, `display_errors=Off`, etc.) — config de
  servidor, no de código.
- Regresión de CSP en navegador real (DevTools) contra módulos no tocados — recomendado como parte de E5.

---

**Fin del documento**
