# CHECKLIST MAESTRO — PLAN DE BLINDAJE INSTITUCIONAL SMARTCSET
## Vista panorámica del avance por fase

---

| Campo | Valor |
|---|---|
| **Versión** | 1.0 |
| **Fecha de elaboración** | 2026-06-10 |
| **Elaborado por** | Equipo de Desarrollo - SmartCSET |
| **Tipo** | Documento de trabajo — vista macro de seguimiento (sin prefijo de fase, es transversal) |
| **Documentos relacionados** | `PLAN_BLINDAJE_INSTITUCIONAL_SMARTCSET.md` (detalle completo) · `RESUMEN_FASES_PLAN_BLINDAJE_SMARTCSET.md` (roadmap narrativo) |

> **Propósito:** este documento es el "mapa de un vistazo" de las 6 fases del plan. Marca el estado de cada fase y, a nivel de entregable, si está documentado y/o implementado. **No reemplaza** los checklists detallados de tarea-por-tarea de cada fase — esos viven en `NN_CHECKLIST_IMPLEMENTACION_FASEN_SMARTCSET.md` dentro de la carpeta de cada fase y se crean cuando el documento de esa fase existe. Actualizar este archivo cada vez que cambie el estado de una fase o entregable.

**Marcadores:** ✅ Completo · ⚠️ Documentado, implementación parcial/pendiente · 🔲 No iniciado · ⛔ Bloqueado por dependencia externa

---

## ESTADO GLOBAL

| Fase | Documento | Estado documental | Estado implementación | Checklist detallado |
|---|---|---|---|---|
| Fase 0 — Diagnóstico y Gobernanza Base | 8 docs FASE0-*-00N | ✅ Completa y auditada | ✅ N/A — 100% documental | No requerido (cerrada) |
| Fase 1 — Blindaje Técnico Inmediato | FASE1-BLI-001 v1.1 | ✅ Completo | 🔲 Pendiente — 0/10 entregables cerrados | [02_CHECKLIST_IMPLEMENTACION_FASE1_SMARTCSET.md](FASE%2001_Blindaje%20Técnico%20Inmediato/02_CHECKLIST_IMPLEMENTACION_FASE1_SMARTCSET.md) |
| Fase 2 — Continuidad y Resiliencia Operativa | 🔲 Por crear | 🔲 No iniciado | 🔲 No iniciado | Se crea junto con el documento de Fase 2 |
| Fase 3 — Cumplimiento Normativo Formal | 🔲 Por crear | 🔲 No iniciado | 🔲 No iniciado | Se crea junto con el documento de Fase 3 |
| Fase 4 — Riesgos IA *(condicional)* | 🔲 Evaluar aplicabilidad | 🔲 No iniciado | 🔲 No iniciado | Solo si SmartCSET incorpora IA |
| Fase 5 — Mejora Continua *(permanente)* | 🔲 Por crear | 🔲 No iniciado | 🔲 No iniciado | Se crea junto con el documento de Fase 5 |

**Regla de actualización:** este checklist es transversal. Cada checklist detallado de fase es la fuente de verdad de SU fase; este documento solo refleja el resumen agregado — no duplicar el detalle de tareas aquí.

---

## FASE 0 — DIAGNÓSTICO Y GOBERNANZA BASE ✅ COMPLETA (2026-06-08, re-auditada 2026-06-10)

- [x] FASE0-POL-001 — Política de Tratamiento de Datos Personales
- [x] FASE0-INV-002 — Inventario de Activos de Información C-I-D
- [x] FASE0-RIE-003 — Matriz de Riesgos Inicial
- [x] FASE0-ROL-004 — Roles y Responsabilidades de Seguridad
- [x] FASE0-AUD-005 — Cronograma de Auditorías Periódicas
- [x] FASE0-PSI-006 — Política General de Seguridad de la Información (documento raíz del SGSI)
- [x] FASE0-ACC-007 — Política de Control de Acceso y Seguridad Física
- [x] FASE0-INC-008 — Marco de Gestión de Incidentes y Continuidad

---

## FASE 1 — BLINDAJE TÉCNICO INMEDIATO 🔴 EN CURSO

> Documento: FASE1-BLI-001 v1.1 (completo) · Checklist detallado: FASE1-CHK-002

- [ ] E1 — Auditoría OWASP Top 10
- [ ] E2 — Cifrado en reposo (pgcrypto)
- [ ] E3 — Rate limiting + logging de autenticación
- [ ] E4 — Hardening de sesiones PHP
- [ ] E5 — Tokens anti-CSRF en formularios
- [ ] E6 — Verificación de subida de archivos *(código ya correcto; falta verificación de servidor)*
- [x] E7 — Corrección de bugs en `setup_smartcset.sh` ✅ *(completado 2026-06-13: 3/4 funciones agregadas a FUNCS; ver REPORTE_E1-E07)*
- [ ] E8 — Hardening de red y TLS *(⛔ requiere Oficina TI SENA)*
- [ ] E9 — Gestión de parches y actualización de componentes
- [ ] E10 — SDLC seguro: checklist de código y despliegue

**Orden recomendado:** E10 → E7 → E4 → E6 → E5 → E3 → E1 (inicial) → E2 → E8 → E9 → E1 (cierre)

> 🔲 **No iniciar implementación de Fase 1 sin autorización explícita de Anderson.** El documento y el checklist detallado están listos; la ejecución se hace por partes, una a la vez.

---

## FASE 2 — CONTINUIDAD Y RESILIENCIA OPERATIVA 🟠 POR PRODUCIR

> Documento por crear: `FASE 02_Continuidad y Resiliencia Operativa/01_CONTINUIDAD_RESILIENCIA_OPERATIVA_SMARTCSET.md`

- [ ] E1 — DRP detallado + procedimiento de backup operativo (runbook ejecutable, amplía FASE0-INC-008)
- [ ] E2 — Monitoreo y alertas (infraestructura + seguridad)
- [ ] E3 — Runbook de respuesta a incidentes (árboles de decisión, contactos, formularios)
- [ ] E4 — Seguridad en talento humano (confidencialidad, offboarding ≤2h hábiles, capacitación)
- [ ] E5 — SDLC seguro — proceso formal (amplía Fase 1 E10)

---

## FASE 3 — CUMPLIMIENTO NORMATIVO FORMAL / CERTIFICABLE 🔲 POR PRODUCIR

> Documento por crear: `FASE 03_Cumplimiento Normativo Formal/`

- [ ] E1 — Alineación ISO/IEC 27001 (Política de Seguridad + 14 dominios de control, evidencia para auditor externo)
- [ ] E2 — PIA — Evaluación de Impacto en Privacidad (énfasis en datos de menores de edad + columnas biométricas INF-16)
- [ ] E3 — Evaluación ICC (Decreto 338/2022 — pre-evaluación en doc 02 §12: NO califica a nivel de centro)
- [ ] E4 — Compilación de evidencia para auditorías MIPG / Contraloría

---

## FASE 4 — PREPARACIÓN PARA ESCALAMIENTO E IA 🔲 CONDICIONAL

> Solo se ejecuta si SmartCSET incorpora componentes de IA (reconocimiento facial, OCR inteligente, scoring/ML, chatbot/LLM). Si el módulo permanece CRUD/búsqueda/reportes, esta fase se omite.

- [ ] Determinar aplicabilidad de la fase
- [ ] E1 — Evaluación de Riesgos de IA (NIST AI RMF: MAP-MEASURE-MANAGE-GOVERN)
- [ ] E2 — Diseño seguro de IA (security by design, guardarraíles)
- [ ] E3 — Pruebas adversariales
- [ ] E4 — Monitoreo de drift del modelo
- [ ] E5 — Documento de impacto y explicabilidad
- [ ] E6 — Esquema de supervisión humana sobre decisiones críticas
- [ ] E7 — Clasificación formal del nivel de riesgo de la IA

---

## FASE 5 — MEJORA CONTINUA Y CULTURA 🔲 PERMANENTE — POR PRODUCIR

> Documento por crear: `FASE 05_Mejora Continua/`

- [ ] E1 — Ciclo permanente de auditorías (trimestral, semestral, anual)
- [ ] E2 — Programa de capacitación continua (contraseñas, phishing, datos personales, IR)
- [ ] E3 — Monitoreo continuo de amenazas y aplicación oportuna de parches
- [ ] E4 — Mecanismo de mejora de procesos a partir de hallazgos de auditoría e incidentes

---

## REGISTRO DE CAMBIOS DE ESTADO

| Fecha | Cambio |
|---|---|
| 2026-06-10 | Creación del checklist maestro. Fase 0 marcada completa (8/8). Fase 1 con checklist detallado FASE1-CHK-002 creado, implementación 0/10 — pendiente autorización para iniciar. Fases 2-5 sin documento aún. |

---

*Fin del documento — Checklist Maestro del Plan de Blindaje Institucional — SmartCSET*
