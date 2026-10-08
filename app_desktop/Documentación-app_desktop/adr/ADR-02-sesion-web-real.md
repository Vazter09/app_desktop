# ADR-02 — Sesión web real (cookie PHPSESSID)

**Módulo:** `app_desktop`  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3 (control de acceso), 6 (privacidad — auditoría por usuario real), 8 (seguridad de sesión)

**Estado:** Aceptada (as-built)

---

## Contexto

La portería web ya autentica con login AJAX, rate limiting (E3), sesiones en `tab_sesiones` y control de menú. Un token de “dispositivo compartido” o credencial fija de módulo rompería la trazabilidad (`usr_insert`) y duplicaría un canal de acceso paralelo al SIEM.

Alternativas: API key de dispositivo, JWT propio del desktop, login standalone compartido (patrón descartado del módulo registro — Bug 8).

---

## Decisión

La app usa el **mismo login web** (`POST /routers/auth/v1/login.php` con `origen: "desktop"`). Tras el éxito, el servidor emite cookie **`PHPSESSID`**; el cliente la conserva en memoria vía `http.cookiejar.CookieJar` y la reenvía en cada request.

Los endpoints de portería/biometría se protegen con `porteriaRequireSessionOrDevice()` en el **camino de sesión web** (no el de token de dispositivo móvil). Al cerrar la app se llama `logout()` para cerrar la sesión en servidor.

Implementación: [`../src/smartcset_client.py`](../../src/smartcset_client.py) — métodos `login`, `logout`, `has_session_cookie`.

---

## Consecuencias

**Positivas**

- Hereda E1/E3/E4 del backend: menú portería, bloqueo por IP, timeout de sesión.
- Auditoría real: `usr_insert` / `app.usuario` = usuario de portería, no genérico.
- Un solo modelo de identidad con la web y el SIEM (E11 pasivo).

**Negativas / trade-offs**

- Dependencia de cookies stateful; redirects HTML a login se interpretan como fallo de sesión/URL.
- Cookie no se escribe en disco plano (bien para seguridad); el operario debe re-autenticarse tras reinicio o expiración.
- El camino “device token” existe en backend pero **no** lo usa el desktop — no documentar como mecanismo de esta app.
