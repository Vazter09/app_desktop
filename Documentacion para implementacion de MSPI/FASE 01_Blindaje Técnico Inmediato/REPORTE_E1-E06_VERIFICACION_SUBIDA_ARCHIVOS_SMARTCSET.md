# Reporte de implementación — E1-E06: Verificación de Subida de Archivos

**Documento N°:** FASE1-REP-E06
**Versión:** 2.0 (abreviada — supersede v1.0)
**Fecha de elaboración:** 2026-06-13
**Entregable padre:** FASE1-BLI-001 — Entregable 6 (Verificación de subida de archivos)
**Control OWASP:** A04:2021 — Insecure Design (upload validation)
**Estado:** ✅ Completado — código validado + protecciones de servidor implementadas
**Elaborado por:** Equipo de Desarrollo - SmartCSET
**Clasificación:** Interno — Seguridad de la Información

---

## Resumen ejecutivo

E6 verifica que `frontend/web/public/uploads/logos/` y `storage/porteria/` están protegidos contra ejecución de código.
La auditoría de código (2026-06-08) confirmó que `LogoUpload.php` y `porteria_foto.php` ya validan
correctamente (finfo MIME, recompresión, base64 estricto). Faltaba la **protección a nivel servidor web**:
si la validación PHP fallara y un `.php` llegara al disco, Apache lo ejecutaría como `www-data`
(severidad medio-alta).

## Solución implementada

2 archivos `.htaccess` idénticos (20 líneas, permisos 644), uno por directorio:
`frontend/web/public/uploads/logos/.htaccess` y `storage/porteria/.htaccess`. 4 capas de protección:

1. **Bloqueo de ejecución de scripts** (`.php`, `.phtml`, `.phar`, `.pl`, `.py`, `.cgi`, `.sh`, `.asp`,
   `.aspx`, `.jsp`) → `403 Forbidden` sin ejecutar.
2. **Content-Type forzado** para imágenes (`image/jpeg`) + `X-Content-Type-Options: nosniff` +
   `Cache-Control: 1 año`.
3. **Bloqueo de acceso al propio `.htaccess`**.
4. **`Options -Indexes`** — sin listado de directorio.

Defensa en profundidad: validación PHP (capa 1) + protección servidor `.htaccess` (capa 2) + interpretación
del navegador vía headers (capa 3) — si una falla, las otras protegen.

## Diseño: por qué solo en directorios de uploads (no `.htaccess` general en raíz)

Un `.htaccess` global en la raíz del proyecto bloquearía PHP en **TODOS** los directorios, incluyendo `src/`,
`index.php`, y el módulo `registro/` — romperíaría completamente el sistema. La mejor práctica es **defensa
en profundidad en los directorios específicos de riesgo**:

- `frontend/web/public/uploads/logos/` — único punto de subida controlado de logos (vía `LogoUpload.php`)
- `storage/porteria/` — único punto de subida controlado de fotos (vía `porteria_foto.php`)

Otros directorios (`/frontend/web/frontend/web/public/assets/css/`, `/frontend/web/frontend/web/public/assets/js/`, `/frontend/web/frontend/web/public/assets/img/`) contienen assets estáticos no controlados por usuarios y no son
puntos de riesgo del mismo nivel.

## Nota sobre Nginx

`.htaccess` solo aplica en Apache. Si el servidor SENA usa Nginx, se requiere configuración equivalente en
el virtual host (bloque `location` con `return 403` para `.php` + headers de imagen). Documentado en el
reporte original (git history) para entregar a Oficina TI si aplica.

## Trazabilidad normativa

| Marco | Mapeo |
|---|---|
| OWASP Top 10 2021 | A04:2021 — Insecure Design |
| ISC2 CC | D3 — Access Control (archivos); D5 — Security Operations |
| ISO/IEC 27001 | A.8.20 — Seguridad de servicios de red; A.8.7 — Control de medios |
| MSPI MinTIC | Eje 5 — Control de acceso; Eje 7 — Seguridad en desarrollo |
| FASE0-RIE-003 | Cierra R-C02 (XSS en subida de archivos) a nivel servidor |

## Pendientes derivados

- Confirmar con Oficina TI si el servidor es Apache o Nginx (único bloqueador para cierre 100% en
  producción).
- E4 (HTTPS): si el servidor opera solo en HTTPS, agregar `Strict-Transport-Security` al `.htaccess`
  sería hardening adicional (no obligatorio).

---

**Fin del documento**
