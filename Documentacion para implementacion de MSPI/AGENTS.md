# AGENTS.md — Contexto total del proyecto MSPI SmartCSET

> Este archivo es la memoria de trabajo del agente IA para esta carpeta. Documenta con precisión qué se ha hecho, en qué estado está cada entregable, qué falta, qué decisiones se tomaron y por qué. Leer este archivo antes de cualquier tarea relacionada con la documentación MSPI de SmartCSET.

---

## 1. QUÉ ES ESTO Y POR QUÉ EXISTE

### El sistema
**SmartCSET** es un sistema de **registro y control de personal** para el **SENA — Servicio Nacional de Aprendizaje** (Colombia). Controla el acceso y registro de visitantes, aprendices, instructores, funcionarios y contratistas de un centro de formación SENA. Tiene también un componente administrativo completo (gestión de usuarios, menús, configuración visual, módulo standalone de registro de personas).

Stack técnico: **PHP 8+ puro** (sin Composer, sin framework) + **PostgreSQL 14+** (con lógica de negocio en PL/pgSQL) + **Bootstrap 5** + **vanilla JS**. No hay dependencias de terceros en el backend.

### El objetivo de esta carpeta
Producir toda la documentación técnica, legal y de gobernanza necesaria para que SmartCSET cumpla el **Modelo de Seguridad y Privacidad de la Información (MSPI)** de MinTIC Colombia, dentro del marco más amplio de:

| Marco | Fuente | Obligatoriedad |
|---|---|---|
| MSPI MinTIC | Decreto 1078/2015 (DUR-TIC) + documentos MinTIC en `MSPI_liniamientos/` | **Obligatorio** — SmartCSET opera en entidad pública colombiana |
| Ley 1581/2012 | Protección de Datos Personales (Habeas Data) | **Obligatorio** — SmartCSET procesa datos personales sensibles |
| Ley 1273/2009 | Delitos Informáticos | **Obligatorio** — define responsabilidad penal por brechas |
| Ley 1712/2014 | Transparencia y Acceso a Información Pública | **Obligatorio** — entidad pública |
| ISO/IEC 27001 | Sistema de Gestión de Seguridad de la Información | Referencia técnica del MSPI |
| OWASP Top 10 2021 | Vulnerabilidades web críticas | Referencia técnica de la Fase 1 |
| **ISC2 Certified in Cybersecurity (CC)** | 5 dominios: Security Principles, BC/DR/IR, Access Controls, Network Security, Security Operations | **Objetivo académico/profesional de Anderson** — el plan debe cubrir el temario completo |
| CONPES 3854/2016, 3995/2020 | Políticas nacionales de seguridad digital | Marco de referencia normativo |
| Decreto 338/2022 | Infraestructura Crítica Cibernética (ICC) | Evaluar si SENA/SmartCSET aplica |

### Quién es Anderson
Anderson es el desarrollador principal y administrador único de SmartCSET. Está preparando el examen **ISC2 CC** (Certified in Cybersecurity) y quiere que el plan de blindaje de SmartCSET le sirva simultáneamente como proyecto práctico para cubrir el temario del examen. Es el único responsable técnico de implementar los entregables.

---

## 2. ESTRUCTURA DE CARPETAS Y ARCHIVOS (estado real verificado)

```
Documentacion para implementacion de MSPI/
│
├── AGENTS.md                          ← Este archivo (memoria del agente)
├── PLAN_BLINDAJE_INSTITUCIONAL_SMARTCSET.md   ← Documento maestro del plan completo
├── RESUMEN_FASES_PLAN_BLINDAJE_SMARTCSET.md   ← Versión condensada (roadmap por fases)
├── MSPI_ANALISIS_SMARTCSET.md         ← Análisis del marco normativo aplicable
├── ESTANDARES_INTERNACIONALES_MSPI.md ← Estándares internacionales referenciados
│
├── MSPI_liniamientos/                 ← Documentos oficiales MinTIC (PDFs)
│   ├── 01_documento_maestro_articles-401770.pdf
│   ├── 02_roles_y_responsabilidades_articles-401771.pdf
│   ├── 03_Indicadores_de_Gestión_...pdf
│   ├── 04_Inventario_y_Clasificación_de_Activos_...pdf
│   ├── 05_Modelo_Nacional_de_Gestión_de_Riesgo_...pdf
│   ├── 06_Relación_con_Proveedores_...pdf
│   ├── 07_Seguridad_en_servicios_en_la_nube_...pdf
│   ├── 08_01_Identificación_de_ICC_...pdf
│   ├── 08_02_Lineamientos_ICC_...pdf
│   └── 09_Seguridad_en_sistemas_de_IA_...pdf
│
├── plantillas_gov/                    ← Plantillas oficiales MinTIC (Excel, Word)
│   └── (8 archivos .xlsm/.xlsx/.docx)
│
├── FASE 0_documentos politicas de tratamiento de datos/    ✅ COMPLETA — 8 documentos auditados
│   ├── 01_POLITICA_Y_TRATAMIENTO_DATOS_PERSONALES_SMARTCSET_DOCUMENTO_LEGAL.md
│   ├── 02_INVENTARIO_ACTIVOS_INFORMACION_CID_SMARTCSET_DOCUMENTO_LEGAL.md
│   ├── 03_MATRIZ_RIESGOS_INICIAL_SMARTCSET_DOCUMENTO_LEGAL.md
│   ├── 04_ROLES_Y_RESPONSABILIDADES_SEGURIDAD_SMARTCSET_DOCUMENTO_LEGAL.md
│   ├── 05_CRONOGRAMA_AUDITORIAS_PERIODICAS_SMARTCSET_DOCUMENTO_LEGAL.md
│   ├── 06_POLITICA_GENERAL_SEGURIDAD_INFORMACION_SMARTCSET_DOCUMENTO_LEGAL.md
│   ├── 07_POLITICA_CONTROL_ACCESO_SEGURIDAD_FISICA_SMARTCSET_DOCUMENTO_LEGAL.md
│   └── 08_MARCO_GESTION_INCIDENTES_CONTINUIDAD_SMARTCSET_DOCUMENTO_LEGAL.md
│
├── FASE 01_Blindaje Técnico Inmediato/    ✅ DOCUMENTO v1.1 COMPLETO — implementación pendiente
│   └── 01_BLINDAJE_TECNICO_INMEDIATO_SMARTCSET.md
│
├── FASE 02_Continuidad y Resiliencia Operativa/    🔲 PENDIENTE
│
├── FASE 03_Cumplimiento Normativo Formal/           🔲 PENDIENTE
│
├── FASE 04_Riesgos IA (condicional)/                🔲 Solo si SmartCSET incorpora IA
│
└── FASE 05_Mejora Continua/                         🔲 PENDIENTE
```

> ⚠️ **NOTA CRÍTICA DE NOMENCLATURA:**
> - Fase 0: `NN_NOMBRE_SMARTCSET_DOCUMENTO_LEGAL.md`
> - Fase 1+: `NN_NOMBRE_SMARTCSET.md` (sin `_DOCUMENTO_LEGAL`)
> - No existen versiones sin prefijo numérico en carpetas de fases.

---

## 3. ESTADO ACTUAL — QUÉ ESTÁ HECHO

### FASE 0 — Diagnóstico y Gobernanza Base ✅ COMPLETA Y AUDITADA (2026-06-08)

| # | Doc N° | Entregable | ISC2 CC | MSPI |
|---|---|---|---|---|
| 1 | FASE0-POL-001 | Política de Tratamiento de Datos Personales | D1 | Eje 1, 11 |
| 2 | FASE0-INV-002 | Inventario de Activos de Información C-I-D | D1, D5 | Eje 3 |
| 3 | FASE0-RIE-003 | Matriz de Riesgos Inicial | D1 completo | Eje 2 |
| 4 | FASE0-ROL-004 | Roles y Responsabilidades de Seguridad | D1, D5 | Eje 1, 4 |
| 5 | FASE0-AUD-005 | Cronograma de Auditorías Periódicas | D5 | Eje 1, 6 |
| 6 | FASE0-PSI-006 | Política General de Seguridad de la Información | D1 completo | **Ejes 1–11** (documento raíz — mapea todos los ejes) |
| 7 | FASE0-ACC-007 | Política de Control de Acceso y Seguridad Física | D3 completo | Eje 5, 7 |
| 8 | FASE0-INC-008 | Marco de Gestión de Incidentes y Continuidad | D2 completo | Eje 9, 10 |

**Auditoría de coherencia realizada el 2026-06-08 — 3 issues encontrados y corregidos:**
1. Doc 01: campo Estado estaba vacío → corregido a "Borrador para revisión y aprobación..."
2. Doc 06: tabla de cumplimiento MSPI solo tenía Ejes 1-3 → ampliada a los 11 ejes con responsable de cada uno
3. Fase 1: versión decía 1.0 → corregida a 1.1

**Resultado: 0 issues pendientes. Fase 0 y Fase 1 cumplen todos los criterios.**

---

### FASE 1 — Blindaje Técnico Inmediato ✅ DOCUMENTO v1.1 COMPLETO — implementación pendiente

Archivo: `FASE 01_Blindaje Técnico Inmediato/01_BLINDAJE_TECNICO_INMEDIATO_SMARTCSET.md`
Documento N°: FASE1-BLI-001 | Versión: 1.1 | 1491 líneas | 18 secciones | 10 entregables

| # | Entregable | Estado doc | Estado en código |
|---|---|---|---|
| E1 | Auditoría OWASP Top 10 (A01–A10) | ✅ Checklist completo con hallazgos pre-llenados | 🔲 Pendiente ejecutar |
| E2 | Cifrado en reposo (pgcrypto — tab_personas) | ✅ Procedimiento de migración paso a paso | 🔲 Pendiente |
| E3 | Rate limiting + logging de autenticación | ✅ Diseño PL/pgSQL + cambios PHP exactos | 🔲 Pendiente |
| E4 | Hardening de sesiones PHP | ✅ 4 líneas `ini_set` + `session_regenerate_id` identificados | 🔲 SecurityMiddleware existe pero es código muerto |
| E5 | Tokens anti-CSRF | ✅ Lista de formularios + helper `validarCSRFoAbortar()` | 🔲 Pendiente |
| E6 | Verificación subida de archivos | ✅ Checklist de verificación | ✅ Ya implementado correctamente en LogoUpload.php y porteria_foto.php |
| E7 | Corrección bugs setup_smartcset.sh | ✅ 4 funciones SQL faltantes + diff exacto | 🔲 Pendiente |
| E8 | Hardening de red y arquitectura de despliegue | ✅ Diagrama ASCII, reglas firewall, TLS DSN | 🔲 Requiere coordinación Oficina TI SENA |
| E9 | Gestión de parches y actualización de componentes | ✅ Inventario de componentes + SLA por CVSS + proceso 5 pasos | 🔲 Pendiente — crear `database/REGISTRO_PARCHES.md` |
| E10 | SDLC seguro: checklist de código y despliegue | ✅ Pre-commit, pre-deploy, rollback, prohibiciones absolutas | 🔲 Pendiente adopción formal |

**Orden de implementación recomendado (Sección 13 del documento):**
1. Día 0: Adoptar E10 (checklist de despliegue — sin cambio de código)
2. E7 (bugs setup.sh) → E4 (SecurityMiddleware) → E6 (verificar uploads) → E5 (CSRF) → E3 (rate limiting) → E1 (auditoría OWASP) → E2 (cifrado en reposo) → E8 (red con TI) → E9 (inventario de parches)

---

## 4. COBERTURA POR MARCOS — ESTADO AL 2026-06-08 (POST AUDITORÍA FASE 0 + FASE 1)

### ISC2 CC — Cobertura por dominio

| Dominio | Peso | Cubierto en | Estado |
|---|---|---|---|
| **D1 — Security Principles** | 26% | Fase 0 docs 01-06 (gobernanza, CIA, riesgos, roles, código de conducta, Ley 1273) | ✅ Completo |
| **D2 — BC / DR / IR** | 10% | Fase 0 doc 08 (RTO=4h, RPO=24h, DRP 7 pasos, backup policy, simulacros) | ✅ Completo |
| **D3 — Access Controls** | 22% | Fase 0 doc 07 (RBAC, ciclo de vida, MFA roadmap, seguridad física) + Fase 1 E3/E4/E5 | ✅ Completo |
| **D4 — Network Security** | 24% | Fase 1 E8 (TLS PostgreSQL, firewall, arquitectura de red, hardening SSH) | ✅ Completo en documento — implementación requiere Oficina TI |
| **D5 — Security Operations** | 18% | Fase 0 docs 02, 04, 05, 08 + Fase 1 E1 (OWASP), E9 (parches), E10 (SDLC) | ✅ Completo |

### MSPI MinTIC — Cobertura por eje

| Eje MSPI | Cubierto en | Estado |
|---|---|---|
| 1. Gobierno de seguridad y privacidad | Docs 01, 04, 06 | ✅ |
| 2. Gestión de riesgos | Doc 03 | ✅ |
| 3. Gestión de activos | Doc 02 | ✅ |
| 4. Seguridad en el talento humano | Docs 04, 06, 07 | ✅ |
| 5. Seguridad física y del entorno | Doc 07 Sección 9 | ✅ |
| 6. Seguridad en comunicaciones y operaciones | Fase 1 E8 (TLS), E9 (parches), Doc 08 (backups) | ✅ |
| 7. Control de acceso | Doc 07 + Fase 1 E3/E4/E5 | ✅ |
| 8. Adquisición, desarrollo y mantenimiento | Fase 1 E10 (SDLC seguro), E9 (parches) | ✅ |
| 9. Gestión de incidentes | Doc 08 | ✅ |
| 10. Continuidad del negocio | Doc 08 (RTO/RPO/DRP) | ✅ |
| 11. Cumplimiento legal | Docs 01, 06, 07, 08 | ✅ |

### Leyes colombianas — Cobertura

| Norma | Documentos que la citan | Estado |
|---|---|---|
| Ley 1581/2012 | Docs 01, 04, 06, 07, 08 | ✅ |
| Ley 1266/2008 | Doc 01 | ✅ |
| Ley 1273/2009 | Docs 06 (arts. 269A/F/I con penas), 07, 08 | ✅ |
| Ley 1712/2014 | Docs 01, 06 | ✅ |
| Decreto 338/2022 (ICC) | Docs 01, 02, 06 | ✅ Referenciado; evaluación formal en Fase 3 |
| CONPES 3995/2020 | Docs 01, 06, 07, 08 | ✅ |

---

## 5. QUÉ FALTA — LISTA PRIORIZADA DE TRABAJO PENDIENTE

### Tarea 1 — Implementar Fase 1 en el código 🔴 PRIORIDAD MÁXIMA

El documento `01_BLINDAJE_TECNICO_INMEDIATO_SMARTCSET.md` v1.1 está completo con 10 entregables, código exacto y procedimientos paso a paso. Lo que falta es **ejecutar los cambios** según el orden de la Sección 13 del documento.

### Tarea 2 — Producir documento de Fase 2 (Continuidad y Resiliencia Operativa) 🟠

La Fase 0 define políticas de alto nivel para BC/DR/IR. La Fase 2 las convierte en **procedimientos operativos ejecutables**:

| Entregable | Propósito | Cierra en ISC2 CC | Cierra en MSPI |
|---|---|---|---|
| E1: DRP detallado + procedimiento de backup operativo | Runbook ejecutable que amplía el doc 08 de política | D2 | Eje 10 |
| E2: Monitoreo y alertas | Infraestructura de observabilidad + alertas de seguridad | D4, D5 | Eje 6, 9 |
| E3: Runbook de respuesta a incidentes | Árboles de decisión, contactos, formularios impresos | D2 | Eje 9 |
| E4: Seguridad en el talento humano | Cláusulas de confidencialidad, offboarding detallado, capacitación obligatoria | D1, D5 | Eje 4 |
| E5: SDLC seguro — proceso formal | Expande Fase 1 E10 hacia un proceso documentado de ciclo de desarrollo | D5 | Eje 8 |

### Tarea 3 — Producir documento de Fase 3 (Cumplimiento Normativo Formal / Certificable) 🟡

- E1: Alineación ISO/IEC 27001 (evidencia por los 14 dominios de control para auditor externo)
- E2: PIA — Evaluación de Impacto en Privacidad (énfasis en datos de menores de edad)
- E3: Evaluación ICC (Decreto 338/2022 — ¿es SmartCSET infraestructura crítica cibernética?)
- E4: Compilación de evidencia para auditorías MIPG / Contraloría

### Tarea 4 — Actualizar plan maestro
`PLAN_BLINDAJE_INSTITUCIONAL_SMARTCSET.md` fue creado antes de la revisión de brechas ISC2. Requiere actualizar:
- Sección de Fase 1: ahora tiene 10 entregables (no 8)
- Sección de Fase 2: añadir E4 (talento humano) y E5 (SDLC formal)
- Anexo F (mapeo ISC2 CC vs. entregables): actualizar con E9 y E10

### Tarea 5 — Fases 4 y 5
Condicionales y de largo plazo. No tienen fecha de inicio definida.

---

## 6. HALLAZGOS TÉCNICOS DEL CODEBASE

Auditoría realizada el 2026-06-08 sobre el código fuente real de SmartCSET:

| Archivo | Hallazgo | Urgencia |
|---|---|---|
| `index.php` líneas 54-68 | Sin `session_regenerate_id(true)` tras login exitoso — vulnerable a session fixation | 🔴 |
| `index.php` (todo el archivo) | Sin rate limiting — ilimitados intentos de contraseña posibles | 🔴 |
| `src/core/SecurityMiddleware.php` | Código de CSRF, headers HTTP y cookie flags bien escritos pero el archivo **nunca se incluye** (`require_once`) en el flujo real — todo es código muerto | 🔴 |
| `src/core/Db.php` líneas 24-39 | DSN de PostgreSQL sin `sslmode` — conexión PHP↔BD sin cifrar | 🔴 |
| `src/core/config.php` | `session.cookie_httponly`, `session.cookie_secure`, `session.cookie_samesite` no configurados | 🔴 |
| `src/core/LogoUpload.php` | ✅ Bien implementado — finfo, whitelist MIME, límite 5MB, nombre aleatorio | — |
| `src/modulos/porteria/lib/porteria_foto.php` | ✅ Bien implementado — base64 estricto, recompresión JPEG, JSONB | — |
| `database/setup_smartcset.sh` | Bugs 1 y 3 del SETUP_AUDIT.md ya corregidos (schema V.1.7, migraciones presentes). Persiste Bug 2 parcial: 4 funciones existen en disco pero NO están en el array FUNCS | 🟠 |

### Funciones PL/pgSQL en disco pero ausentes de setup_smartcset.sh FUNCS

```
database/functions/acceso/usuarios/fun_validar_correo.sql     ← ausente de FUNCS
database/functions/acceso/usuarios/fun_validar_login.sql      ← ausente de FUNCS
database/functions/acceso/usuarios/fun_validar_usuario.sql    ← ausente de FUNCS
database/functions/acceso/menus/fun_tab_menu_usuarios.sql     ← ausente de FUNCS
```
Una instalación limpia ejecutada hoy NO desplegará estas funciones → recuperación de contraseña falla en servidor nuevo. Este es el Bug 2 de SETUP_AUDIT.md — se cierra en Fase 1 E7.

---

## 7. DECISIONES Y CRITERIOS TOMADOS

| Decisión | Justificación |
|---|---|
| Fase 0 produce solo documentos legales formales con prefijo numérico | Decisión tomada 2026-06-08. La nomenclatura `NN_NOMBRE_SMARTCSET_DOCUMENTO_LEGAL.md` es la definitiva. |
| Fase 1 en adelante: un documento de trabajo por fase (sin versión legal adicional) | Confirmado explícitamente por Anderson. Los documentos de fases técnicas no requieren formato legal. |
| Cifrado en reposo: pgcrypto (PostgreSQL) como primera implementación | Menos cambios de código PHP, más simple. libsodium se evalúa como evolución futura. |
| Rate limiting: tabla `tab_intentos_login` en PostgreSQL | Consistente con la filosofía del proyecto: lógica crítica en PL/pgSQL, PHP solo presenta. |
| MFA: no en Fase 1 | Complejidad alta para "blindaje inmediato". Documentada con hoja de ruta en doc 07 Sección 14. |
| Fase 0 ampliada a 8 documentos (no 5) | Decisión 2026-06-08: docs 01-05 no cubrían ISC2 D1 completo, D2, D3 ni MSPI Ejes 5, 7, 9, 10. Docs 06, 07, 08 cerraron esas brechas. |
| Fase 1 ampliada a 10 entregables (no 8) | Decisión 2026-06-08: E9 (gestión de parches) cierra MSPI Eje 6 y D5; E10 (SDLC seguro) cierra MSPI Eje 8 que no estaba en ningún documento anterior. |
| Doc 06 mapea los 11 ejes MSPI | Corrección aplicada 2026-06-08: la Política General es el documento raíz del SGSI y debe referenciar todos los ejes con su documento responsable. |
| "Registro y control de personal" — nombre correcto | No llamarlo "sistema de portería". SmartCSET tiene componente de portería + componente administrativo completo. |

---

## 8. CONVENCIONES DEL PROYECTO

### Nomenclatura de documentos
- **Documentos de Fase 0:** `NN_NOMBRE_EN_MAYUSCULAS_SMARTCSET_DOCUMENTO_LEGAL.md`
- **Documentos de Fase 1+:** `NN_NOMBRE_EN_MAYUSCULAS_SMARTCSET.md` (sin `_DOCUMENTO_LEGAL`)
- **Documentos de análisis/referencia:** sin prefijo numérico
- **Planes y resúmenes:** sin prefijo

### Estructura de documentos legales (Fase 0)
1. `# TÍTULO EN MAYÚSCULAS` como H1
2. `## Sistema SmartCSET — Servicio Nacional de Aprendizaje (SENA)` como H2
3. Header table: Documento N°, Versión, Elaborado por, Estado, Próxima revisión, Clasificación
4. Tabla de contenido con anclas
5. Nota de gobernanza con `⚠️` (por qué este documento no es opcional)
6. Secciones numeradas con `###` subsecciones
7. `🔲` para ítems que requieren acción institucional pendiente
8. Tabla de aprobación `ELABORÓ / REVISÓ / APROBÓ` al final
9. Línea de pie: `*Fin del documento — Título — SmartCSET v1.0*`

### Numeración de documentos internos
- FASE0-POL-001, FASE0-INV-002, FASE0-RIE-003, FASE0-ROL-004, FASE0-AUD-005
- FASE0-PSI-006, FASE0-ACC-007, FASE0-INC-008
- FASE1-BLI-001

### Marcadores de estado
- ✅ Implementado / Correcto / Completo
- ⚠️ Existe pero incompleto / Requiere revisión / Código presente pero no activo
- ❌ No existe / Faltante / Vulnerabilidad activa
- 🔲 Tarea pendiente (en docs legales: decisión institucional pendiente)
- 🔴 Urgencia crítica | 🟠 Alta | 🟡 Media

---

## 9. REFERENCIAS CRUZADAS ENTRE DOCUMENTOS

```
MSPI_ANALISIS_SMARTCSET.md
    └─ Fundamenta normativamente todos los documentos de Fase 0

PLAN_BLINDAJE_INSTITUCIONAL_SMARTCSET.md
    └─ Documento maestro → todos los demás son hijos de este
    └─ Anexo F → mapeo ISC2 CC vs. entregables
    └─ ⚠️ Necesita actualización: Fase 1 tiene 10 entregables (no 8), Fase 2 necesita E4 y E5

FASE0-PSI-006 (Política General — documento raíz del SGSI)
    └─ Mapea los 11 ejes MSPI con el documento responsable de cada uno
    └─ Todos los demás documentos de Fase 0 la desarrollan
    └─ Ley 1273/2009 incorporada aquí → referenciada en FASE0-ACC-007 y FASE0-INC-008

FASE0-POL-001 (Política de Tratamiento de Datos)
    └─ Sección 13 (Medidas de Seguridad) → implementada en Fase 1 E2, E3, E4
    └─ Sección 15 (Incidentes de datos) → desarrollada en FASE0-INC-008

FASE0-INV-002 (Inventario de Activos C-I-D)
    └─ INF-01 (tab_personas, Confidencialidad Muy Alta) → Fase 1 E2 (cifrado)
    └─ INF-02 (tab_log_ingresos) → Fase 1 E3 (logging)

FASE0-RIE-003 (Matriz de Riesgos)
    └─ R-A01, R-A03, R-C04, R-E1 → Fase 1 E3, E4, E5, E2 respectivamente

FASE0-ROL-004 (Roles y Responsabilidades)
    └─ Matriz RACI → aplica directamente a todos los entregables de Fase 1+

FASE0-AUD-005 (Cronograma de Auditorías)
    └─ Simulacros de FASE0-INC-008 se integran en el calendario de auditorías
    └─ Resultados de Fase 1 E1 (OWASP) alimentan las auditorías trimestrales

FASE0-ACC-007 (Control de Acceso y Seguridad Física)
    └─ Implementación técnica → Fase 1 E3/E4/E5 (SecurityMiddleware, sesiones, CSRF)
    └─ MFA roadmap → Fase 2 entregable a definir

FASE0-INC-008 (Gestión de Incidentes y Continuidad)
    └─ Plan de backups → Fase 2 E1 (procedimiento operativo detallado)
    └─ Runbook IR → Fase 2 E3 (versión ejecutable con árboles de decisión)
    └─ Simulacros anuales → FASE0-AUD-005 Sección 4.4

FASE1-BLI-001 (Blindaje Técnico Inmediato)
    └─ E9/E10 → cierran MSPI Ejes 6 y 8 (referenciados desde FASE0-PSI-006 Sección 12.1)
    └─ Checklist pre-deploy E10 → alineado con política de backups de FASE0-INC-008
```

---

## 10. CONTEXTO DE INFRAESTRUCTURA Y RESTRICCIONES

- **Un solo desarrollador:** Anderson es el responsable técnico único. No hay equipo de desarrollo.
- **Coordinación externa requerida para:** reglas de firewall, `postgresql.conf`, certificados TLS, acceso físico a servidores → depende de la **Oficina TI SENA** y debe coordinarse formalmente.
- **Clave de cifrado `DB_ENCRYPTION_KEY`:** debe generarse y custodiarse antes de implementar Fase 1 E2. No puede estar en el repositorio git ni en `.env` versionado. Alguien en la organización debe ser custodio formal.
- **BD de test requerida para:** Fase 1 E2 (migración de cifrado) y Fase 1 E7 (setup_smartcset.sh). Sin BD de test, no se puede validar de forma segura antes de producción.
- **Sin Composer / sin autoloading:** cualquier nueva clase o librería PHP se carga con `require_once` explícito. No introducir autoloading.
- **Backups:** política definida en FASE0-INC-008 Sección 13. Implementación (`pg_dump` + cron + `gpg`) pendiente con Oficina TI SENA.

---

*Última actualización: 2026-06-08 — Fase 0 completada y auditada (8 docs). Fase 1 v1.1 completada (10 entregables). Todos los criterios MSPI/ISC2/legal confirmados. Siguiente paso: implementación Fase 1 en código, o producción del documento de Fase 2.*
