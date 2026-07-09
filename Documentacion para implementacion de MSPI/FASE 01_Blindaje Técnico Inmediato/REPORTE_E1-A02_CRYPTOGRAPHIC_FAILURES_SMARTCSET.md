# Reporte de auditoría — E1-A02: Cryptographic Failures

**Documento N°:** FASE1-REP-A02
**Versión:** 3.0 (Actualización 2026-06-17: HTTPS + certificado autofirmado completados)
**Fecha de elaboración:** 2026-06-11
**Última actualización:** 2026-06-17
**Entregable padre:** FASE1-BLI-001 — Entregable 1 (Auditoría OWASP Top 10)
**Control OWASP:** A02:2021 — Cryptographic Failures
**Estado:** ⚠️ Parcial — H1 (cifrado en reposo) bloqueado E2; H3 (TLS BD) pendiente E8; H4 (HTTPS) ✅ COMPLETADO 2026-06-17
**Elaborado por:** Equipo de Desarrollo - SmartCSET
**Clasificación:** Interno — Seguridad de la Información

---

## Resumen ejecutivo

Auditoría de los 4 subcontroles de A02 (FASE1-BLI-001 §3.2). A diferencia de A01, estos hallazgos **no se
cierran con cambios de código aislados**: dependen de E2 (cifrado en reposo, pgcrypto), E4 (sesiones/HTTPS) y
E8 (TLS PHP↔PostgreSQL, mayormente responsabilidad de Oficina TI SENA).

| # | Subcontrol                                                | Resultado                                                                                                                                          |
| - | --------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1 | Contraseñas hasheadas con algoritmo robusto              | ✅ Cumple —`password_verify()` bcrypt, sin acción                                                                                              |
| 2 | Cifrado en reposo de `tab_personas.documento_identidad` | ❌ No implementado — bloqueado por E2 (custodio `DB_ENCRYPTION_KEY` + BD de test)                                                               |
| 3 | TLS en conexión PHP↔PostgreSQL (DSN)                    | ⚠️ Sin `sslmode` activo; infraestructura de código lista, activación depende de E8 (Oficina TI habilitar ssl=on en PostgreSQL)                                                              |
| 4 | HTTPS forzado en producción                              | ✅ COMPLETADO 2026-06-17 — Certificado TLS autofirmado ECDSA P-256, VirtualHost HTTPS, enforceHTTPS() activo, cookie flags verificados (Secure, HttpOnly, SameSite=Strict) |

## Hallazgo 2 — TLS BD: cambio aplicado en esta sesión

Se preparó infraestructura **configurable y retrocompatible** (sin forzar `sslmode=require`, que rompería
cualquier PostgreSQL local sin `ssl=on`):

| Archivo                 | Cambio                                                                          |
| ----------------------- | ------------------------------------------------------------------------------- |
| `backend/core/config.php` | +`DB_SSLMODE` vía `EnvLoader::get('DB_SSLMODE', '')` — vacío por defecto |
| `backend/core/Db.php`     | DSN agrega `;sslmode=<DB_SSLMODE>` solo si la variable no está vacía        |
| `.env.example`        | +`DB_SSLMODE=` documentada                                                    |

Con `DB_SSLMODE` vacío (estado actual), el comportamiento es idéntico al previo — sin riesgo de regresión.

**Pendiente para cierre (depende de E8):**

1. Oficina TI habilita `ssl=on` + certificados en `postgresql.conf`, `host`→`hostssl` en `pg_hba.conf`.
2. Agregar a `.env`: `DB_SSLMODE=require` (dev/red interna) o `DB_SSLMODE=verify-full` (producción).
3. Verificar con `pg_stat_ssl` (columna `ssl=TRUE`, `version` TLSv1.2+).

## Hallazgos 1, 3 y 4 — estado y bloqueadores

- **H1 (cifrado en reposo):** dato clasificado Confidencialidad Muy Alta (FASE0-INV-002 INF-01). Plan completo
  de 7 pasos con pgcrypto en E2. Bloqueado por prerrequisitos institucionales 1 (custodio de clave) y 2 (BD de
  test) — ver handoff E2 para estado de avance posterior (pausado por hallazgo de diseño de PK).
- **H4 (HTTPS forzado):** ✅ **COMPLETADO 2026-06-17** — Certificado TLS autofirmado ECDSA P-256 generado en `/etc/apache2/certs/`, VirtualHost HTTPS configurado en `/etc/apache2/sites-available/smartcset-ssl.conf`, `enforceHTTPS()` agregado a `index.php` (línea 11-15), y cookie flags verificados (Secure ✅, HttpOnly ✅, SameSite=Strict ✅). Cambio `APP_ENV=production` en `.env` para activar flag Secure automáticamente en HTTPS. Pruebas manuales exitosas en navegador: certificado autofirmado aceptado, login funciona, dashboard cargó correctamente.

## Trazabilidad normativa

| Marco             | Mapeo                                                               |
| ----------------- | ------------------------------------------------------------------- |
| OWASP Top 10 2021 | A02:2021 — Cryptographic Failures                                  |
| ISC2 CC           | D1 — Security Principles (criptografía); D4 — Network Security   |
| ISO/IEC 27001     | A.8.24 — Uso de criptografía; A.8.20/A.8.21 — Seguridad de redes |
| MSPI MinTIC       | Eje 6 — Seguridad en comunicaciones y operaciones                  |
| Ley 1581/2012     | Art. 4(g) — Principio de seguridad                                 |
| FASE0-RIE-003     | R-E1 (cifrado de datos sensibles) — no se cierra con este reporte  |

## Pendientes derivados

- `database/migrations/password_migrator.php` construye DSN propio sin `sslmode` — script marcado
  "BORRAR DESPUÉS DE USAR", queda para E10.
- **H4 (HTTPS) está completado ✅** — Certificado, VirtualHost, enforceHTTPS(), y cookie flags verificados.
- A02 no puede marcarse completamente ✅ (como hallazgo total) hasta completar H1 (E2) y H3 (E8), pero H4 está 100% cerrado.

---

**Fin del documento**
