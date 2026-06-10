# Resumen — Fases del Plan de Blindaje Institucional SmartCSET

> Versión condensada de `PLAN_BLINDAJE_INSTITUCIONAL_SMARTCSET.md`, enfocada únicamente en el roadmap: cuántas fases lo componen, qué se hace en cada una y qué entregables produce.

El plan se compone de **6 fases** (5 secuenciales + 1 de mejora continua permanente), con una duración total estimada de **16-22 semanas** para el núcleo (Fases 0-3).

> **Nota de alineación con ISC2 CC:** el plan fue revisado contra los 5 dominios del temario de **ISC2 Certified in Cybersecurity (CC)** (Security Principles · BC/DR/IR · Access Control · Network Security · Security Operations). Como resultado, se incorporaron a la **Fase 1** tres entregables nuevos: *Hardening de Red y Arquitectura de Despliegue* (E8 — cierra el Dominio 4, Network Security), *Gestión de Parches con SLA por CVSS* (E9) y *SDLC Seguro* (E10), que refuerzan el Dominio 5 y cierran los Ejes 6 y 8 del MSPI. Con estos ajustes, los 5 dominios quedan representados en el plan con entregables concretos — el detalle del mapeo está en el **Anexo F** de `PLAN_BLINDAJE_INSTITUCIONAL_SMARTCSET.md`.

---

## Fase 0 — Diagnóstico y Gobernanza Base ✅ COMPLETA (2026-06-08)

· **Responsable:** Equipo de Desarrollo - SmartCSET.

**Qué se hace:** Trabajo 100% documental (sin tocar código) para sentar la base legal y de gobernanza del sistema.

**Entregables (8 documentos producidos y auditados):**

1. Política de Tratamiento de Datos Personales (FASE0-POL-001)
2. Inventario de Activos de Información — clasificación C-I-D (FASE0-INV-002)
3. Matriz de Riesgos Inicial (FASE0-RIE-003)
4. Designación de Roles de Seguridad — RSSI, custodios, auditores (FASE0-ROL-004)
5. Cronograma de Auditorías Periódicas (FASE0-AUD-005)
6. Política General de Seguridad de la Información — documento raíz del SGSI, mapea los 11 ejes MSPI (FASE0-PSI-006)
7. Política de Control de Acceso y Seguridad Física (FASE0-ACC-007)
8. Marco de Gestión de Incidentes y Continuidad — RTO=4h, RPO=24h, DRP en 7 pasos (FASE0-INC-008)

---

## Fase 1 — Blindaje Técnico Inmediato 🔲 PRÓXIMO HITO (documento FASE1-BLI-001 v1.1 completo; implementación pendiente)

· **Responsable:** Equipo de Desarrollo - SmartCSET.

**Qué se hace:** Cierre de las vulnerabilidades críticas detectadas mediante cambios técnicos localizados (sin reescribir el sistema).

**Entregables (10):**

1. Auditoría OWASP Top 10 + plan de remediaciones
2. Cifrado en reposo de datos sensibles (cédula, foto)
3. Rate limiting + logging de intentos de login fallidos
4. Hardening de sesiones PHP (cookies seguras, regeneración de ID)
5. Tokens anti-CSRF en formularios POST
6. Validación robusta de subida de archivos (MIME real, tamaño, nombre) — ✅ verificado: ya implementado correctamente
7. Corrección de los bugs documentados en `setup_smartcset.sh` (pendiente: 4 funciones PL/pgSQL ausentes del array `FUNCS`)
8. **Hardening de Red y Arquitectura de Despliegue** *(cierra el Dominio 4 de ISC2 CC)*: segmentación de red (servidor web vs. servidor de BD), matriz de reglas de firewall perimetral y de host, TLS forzado en todos los tramos de comunicación (cliente↔web↔PostgreSQL), y checklist de hardening del servidor
9. **Gestión de Parches y Control de Versiones de Componentes**: inventario de componentes (PHP, PostgreSQL, Bootstrap CDN) + SLA de parcheo por criticidad CVSS (≥9.0 = 48h · 7.0-8.9 = 7 días · 4.0-6.9 = 30 días) + suscripción a fuentes de alerta (CVE PHP/PostgreSQL, COLCERT)
10. **SDLC Seguro — checklist de proceso**: checklist pre-commit y pre-deploy, plan de rollback y prohibiciones absolutas en producción (adopción día 0, sin código)

---

## Fase 2 — Continuidad y Resiliencia Operativa

· **Responsable:** Equipo de Desarrollo - SmartCSET.

**Qué se hace:** Garantizar que un incidente (falla, ataque, ransomware) no deje la operación detenida, y formalizar los procesos humanos y de desarrollo que sostienen la seguridad.

**Entregables (5):**

1. Plan de Copias de Seguridad y Recuperación (DRP) — política, procedimiento y prueba de restauración
2. Monitoreo y alertas (infraestructura y seguridad)
3. Plan de Respuesta a Incidentes (runbook con árboles de decisión y contactos de emergencia)
4. **Seguridad en el Talento Humano**: cláusulas de confidencialidad, procedimiento formal de offboarding (desactivación en máximo 2 horas hábiles) y programa de capacitación inicial obligatoria
5. **SDLC Seguro — proceso formal documentado**: amplía el E10 de la Fase 1 hacia una política institucional de gestión de cambios, ambientes (dev/test/prod) y control de versiones/releases

---

## Fase 3 — Cumplimiento Normativo Formal / Certificable

· **Responsable:** Equipo de Desarrollo - SmartCSET.

**Qué se hace:** Llevar la documentación y los controles a un nivel certificable/auditable frente a ISO 27001, MIPG y entes de control.

**Entregables:**

1. Alineación documental con ISO/IEC 27001 (Política de Seguridad + 14 políticas de control)
2. Evaluación de Impacto en Privacidad — PIA (enfocada en datos de menores de edad)
3. Determinación de clasificación como Infraestructura Crítica Cibernética — ICC (Decreto 338/2022)
4. Compilación de evidencia para auditorías MIPG, Contraloría y, opcionalmente, auditor externo

---

## Fase 4 — Preparación para Escalamiento e IA *(opcional, condicional)*

· **Responsable:** Equipo de Desarrollo - SmartCSET.

**Qué se hace:** Solo se ejecuta si el módulo de registro y seguimiento de personal incorpora componentes de IA (reconocimiento facial, OCR inteligente, scoring/ML, chatbot/LLM). Si el módulo es solo CRUD/búsqueda/reportes, esta fase se omite.

**Entregables:**

1. Evaluación de Riesgos Específicos de IA (marco NIST AI RMF: MAP-MEASURE-MANAGE-GOVERN)
2. Diseño seguro de IA ("security by design", guardarraíles)
3. Pruebas adversariales
4. Monitoreo de drift del modelo
5. Documento de impacto y explicabilidad
6. Esquema de supervisión humana sobre decisiones críticas
7. Clasificación formal del nivel de riesgo de la IA

---

## Fase 5 — Mejora Continua y Cultura *(permanente)*

· **Responsable:** RSSI / Oficina TI, con Equipo de Desarrollo - SmartCSET y personal de portería

**Qué se hace:** Sostener el blindaje en el tiempo y convertir la seguridad de la información en cultura institucional, no en un proyecto cerrado.

**Entregables:**

1. Ciclo permanente de auditorías (trimestral, semestral, anual)
2. Programa de capacitación continua (contraseñas, phishing, manejo de datos personales, respuesta a incidentes)
3. Monitoreo continuo de amenazas y aplicación oportuna de parches
4. Mecanismo de mejora de procesos a partir de hallazgos de auditoría e incidentes

---

*Para el detalle completo de cada entregable, criterios técnicos, estimaciones de esfuerzo, análisis de inversión/ROI y matriz RACI, consultar `PLAN_BLINDAJE_INSTITUCIONAL_SMARTCSET.md`.*
