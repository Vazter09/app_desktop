# Documentación de entrega — App de Escritorio SGI

**Módulo:** SmartCSET Portería (cliente de escritorio)  
**Versión documental:** 1.0.0  
**Fecha:** 2026-09-01

---

## Propósito

Este directorio contiene el **paquete documental profesional** del módulo `app_desktop`. Está diseñado para entrega institucional, académica o de auditoría, y describe el sistema **tal como está implementado** (as-built), no el diseño aspiracional.

Para desarrollo interno y bitácora de sesiones, consultar [`HANDOFF.md`](../HANDOFF.md) y [`REGLAS_APP_ESCRITORIO_SGI.md`](../REGLAS_APP_ESCRITORIO_SGI.md) — documentos internos que pueden contener información desactualizada respecto al código actual.

---

## Lectura por rol

| Rol | Documentos recomendados |
|-----|------------------------|
| **Revisor académico / institucional** | [00](00-que-debe-contener-un-proyecto.md) → [01](01-vision-y-alcance.md) → [11](11-matriz-trazabilidad.md) |
| **Operario de portería** | [06 — Manual de usuario](06-manual-usuario.md) |
| **TI / instalador** | [05 — Instalación](05-manual-instalacion.md) → [10 — Operación](10-operacion-y-mantenimiento.md) |
| **Desarrollador** | [03 — Arquitectura](03-arquitectura.md) → [04 — Diseño](04-diseno-detallado.md) → [07 — API](07-contrato-integracion.md) |
| **Auditor MSPI / seguridad** | [09 — Seguridad MSPI](09-seguridad-mspi.md) → [11 — Trazabilidad](11-matriz-trazabilidad.md) |
| **QA / pruebas** | [08 — Plan de pruebas](08-plan-y-evidencia-pruebas.md) |

---

## Índice completo

| # | Documento | Descripción |
|---|-----------|-------------|
| 00 | [Qué debe contener un proyecto de software](00-que-debe-contener-un-proyecto.md) | Guía genérica + autoevaluación del módulo |
| 01 | [Visión y alcance](01-vision-y-alcance.md) | Problema, actores, alcance incluido/excluido |
| 02 | [Especificación de requisitos (SRS)](02-especificacion-requisitos.md) | RF-xx y RNF-xx numerados |
| 03 | [Arquitectura](03-arquitectura.md) | Diagramas, capas, decisiones (as-built) |
| 04 | [Diseño detallado](04-diseno-detallado.md) | Módulos, clases, flujos paso a paso |
| 05 | [Manual de instalación](05-manual-instalacion.md) | Desarrollo, empaquetado, checklist |
| 06 | [Manual de usuario](06-manual-usuario.md) | Guía para operario de portería |
| 07 | [Contrato de integración (API)](07-contrato-integracion.md) | Endpoints, payloads, errores |
| 08 | [Plan y evidencia de pruebas](08-plan-y-evidencia-pruebas.md) | 34 tests, ejecución, huecos |
| 09 | [Seguridad y MSPI](09-seguridad-mspi.md) | E-tasks, amenazas, checklist pre-prod |
| 10 | [Operación y mantenimiento](10-operacion-y-mantenimiento.md) | Logs, incidentes, escalación |
| 11 | [Matriz de trazabilidad](11-matriz-trazabilidad.md) | RF → código → test → MSPI |

---

## Resumen ejecutivo del módulo

| Aspecto | Valor |
|---------|-------|
| **Qué es** | Cliente de escritorio para portería SENA (ingreso/salida) |
| **Stack** | Python 3.11+ · Tkinter · urllib · OpenCV (YuNet+SFace 128-d) |
| **Backend** | SmartCSET PHP existente (misma BD PostgreSQL) |
| **Autenticación** | Sesión web real (usuario/contraseña, cookie PHPSESSID) |
| **Biometría** | Facial operativa; huella = placeholder |
| **Empaquetado** | `SmartCSET_Porteria.exe` (PyInstaller onefile) |
| **Tests** | 34 casos (17 integración HTTP + 17 unitarios) |
| **Estado** | Operativo en laboratorio; validación institucional pendiente |

---

## Estado as-built vs diseño original

| Tema | Diseño original | Implementación actual |
|------|----------------|----------------------|
| Carpeta de código | `app/` (histórico) | `src/` |
| Motor biométrico | Proceso HTTPS separado | In-process (`FaceEmbedder`) |
| Dimensión vector | 512 (diseño inicial) | 128 (SFace) |
| Navegación UI | Sidebar con Inicio/Salida/Entradas | Solo pantalla de ingreso post-login |
| TLS | Siempre verificado | Configurable (`verify_tls` en JSON) |

---

## Enlaces rápidos

- Código fuente: [`../src/`](../src/)
- Tests: [`../tests/`](../tests/)
- Empaquetado: [`../packaging/`](../packaging/)
- Changelog: [`../CHANGELOG.md`](../CHANGELOG.md)
- README del módulo: [`../README.md`](../README.md)
