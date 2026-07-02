# Reporte de remediación — E1-A01: Broken Access Control

**Documento N°:** FASE1-REP-A01
**Versión:** 2.0 (abreviada — supersede v1.2, ver historial git para procedimiento detallado de pruebas)
**Fecha de elaboración:** 2026-06-10 | **Última actualización:** 2026-06-11
**Entregable padre:** FASE1-BLI-001 — Entregable 1 (Auditoría OWASP Top 10)
**Control OWASP:** A01:2021 — Broken Access Control
**Estado:** ✅ Remediado, verificado (lint PHP) y validado con 11/11 pruebas manuales en producción (2026-06-11)
**Elaborado por:** Equipo de Desarrollo - SmartCSET
**Clasificación:** Interno — Seguridad de la Información

---

## Resumen ejecutivo

Auditoría del control A01 (3 subcontroles: validación admin, IDOR por centro, sesión en módulos). Hallazgo
principal: **escalada vertical de privilegios** — 8 endpoints de administración de menús/usuarios validaban
solo `isset($_SESSION['id_usuario'])`, sin verificar `ind_usuario` (admin). 2 de ellos (`procesar_perfil.php`,
`procesar_permiso.php`) ni siquiera exigían sesión. Riesgo R-B02 de FASE0-RIE-003: un usuario no-admin (o un
atacante sin sesión, en 2 casos) podía crear/editar menús, crear/editar usuarios y reasignar permisos de
cualquier usuario.

**Remediación:** guardia `usuarioEsAdministrador($pdo, $_SESSION['id_usuario'])` en los 8 endpoints,
replicando el patrón ya correcto de `backend/routers/admin/v1/configuracion.php`. Páginas HTML → `403` + mensaje; endpoints
JSON → `403` + envoltura `ErrorHandler::createResponse`.

## Alcance y resultado por subcontrol

| Subcontrol A01                                            | Resultado                      | Acción                                               |
| --------------------------------------------------------- | ------------------------------ | ----------------------------------------------------- |
| 1. Validación admin antes de acciones de administración | ❌ Roto en 8 endpoints         | ✅ Corregido                                          |
| 2. IDOR — usuario solo accede a datos de su centro       | ✅ Aceptable (mono-centro hoy) | Revisar cuando opere multi-centro                     |
| 3. Rutas de módulos requieren sesión válida            | ✅ Sin gaps reales             | Módulo `registro` usa su propio control standalone |

## Archivos corregidos (8)

`backend/routers/menus/v1/menus.php`, `backend/routers/usuarios/v1/usuarios.php`, `backend/routers/menus/v1/menu_usuarios.php`,
`backend/routers/menus/v1/copiar_menu_usuarios.php` — guardia HTML 403 tras chequeo de sesión.
`backend/routers/menus/v1/procesar_perfil.php`, `backend/routers/menus/v1/procesar_permiso.php` (+ `require_once helpers.php`),
`backend/routers/menus/v1/procesar_copiar_perfil.php`, `backend/routers/menus/v1/obtener_menus_usuario.php` — guardia sesión+admin (JSON 403).

La lógica preexistente que aplicaba `usuarioEsAdministrador()` al **usuario objetivo** de la operación se
conservó (propósito de negocio distinto y complementario).

## Validación — resultado 2026-06-11 (producción)

**11/11 PASS:**

- `porteria` (no-admin) → `403 Forbidden` en los 4 CRUDs HTML (menus, usuarios, menu_usuarios, copiar_menu_usuarios)
- `POST` sin sesión a `procesar_perfil.php` / `procesar_permiso.php` → `403` JSON, sin cambios en `tab_menu_usuarios`
- `POST` con sesión `porteria` (no-admin) → `403` igual que sin sesión
- `admin.smart` → `200` en los 4 CRUDs y operaciones reales (`procesar_permiso.php`, `procesar_perfil.php`) con `status:success` y cambios persistidos correctamente

Notas operativas: las pruebas de escritura sobre `tab_menu_usuarios` del usuario `porteria` se revirtieron al
estado previo al finalizar; el hash bcrypt temporal usado para `porteria` fue restaurado; sesión activa
preexistente de `admin.smart` se cerró con autorización antes de probar.

## Trazabilidad normativa

| Marco             | Mapeo                                                              |
| ----------------- | ------------------------------------------------------------------ |
| OWASP Top 10 2021 | A01:2021 — Broken Access Control                                  |
| ISC2 CC           | D3 — Access Controls (función-level); D5 — Security Operations  |
| ISO/IEC 27001     | A.8 / A.5.15 — Control de acceso; A.8.3 — Restricción de acceso |
| MSPI MinTIC       | Eje 5 — Control de acceso                                         |
| FASE0-RIE-003     | Cierra parcialmente R-B02 a nivel funciones administrativas        |
| Ley 1273/2009     | Refuerza art. 269A                                                 |

## Pendientes derivados (fuera de alcance de A01)

- Scoping multi-centro (subcontrol 2) — diferido a cuando aplique despliegue multi-centro.
- CSRF (tokens) → Entregable 5.
- Rate limiting → Entregable 3.
- Hardening de sesión → Entregable 4 ✅ cerrado (2026-06-14, ver REPORTE_E1-E04).

---

**Fin del documento**
