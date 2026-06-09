# Checklist Legal y Normativo — SmartCSET MSPI Fase 0

**Propósito:** Referencia centralizada de validación legal/normativa y patrones de redacción para documentos de Fase 0.
**Ubicación:** Proyecto smartcset (versionado en git)
**Última actualización:** Junio 8, 2026

---

## 1. Marco Normativo Aplicable

### Leyes y Decretos — Protección de Datos Personales
| Norma | Qué exige | Aplicación en SmartCSET |
|---|---|---|
| **Ley 1581/2012** | Consentimiento, finalidad, derechos ARCO | Cada registro de persona requiere base legal documentada |
| **Decreto 1377/2013** | Reglamenta Ley 1581 — política de tratamiento, autorización | Política pública + consentimiento informado |
| **Ley 1266/2008** (Habeas Data) | Calidad, veracidad, seguridad de datos personales | tab_personas, tab_log_ingresos deben cumplir estándares |
| **Art. 13 Constitución** | Prohíbe discriminación en sistemas automatizados | Relevante si se introduce IA en futuro |
| **Art. 15 Constitución** | Base constitucional protección de datos personales | SmartCSET almacena cédulas, fotos, biometría potencial |

### Leyes y Decretos — Seguridad de la Información
| Norma | Qué exige | Aplicación en SmartCSET |
|---|---|---|
| **Ley 1273/2009** | Delitos Informáticos (acceso abusivo, daño, hurto de datos) | Brechas pueden derivar en responsabilidad penal, no solo administrativa |
| **Ley 1712/2014** | Transparencia y acceso a información pública | Reportes generados por SmartCSET (DF-49, PE-04) bajo este régimen |
| **Decreto 1078/2015** (DUR-TIC) | Decreto Único Reglamentario TIC; incluye MSPI y Gobierno Digital | Marco regulatorio "padre" del MSPI |
| **Decreto 338/2022** | Define Infraestructura Crítica Cibernética (ICC) | Determina si SENA/SmartCSET debe registrarse como ICC ante COLCERT |
| **Decreto 767/2022** | Uso y gobernanza de tecnologías emergentes (IA) en sector público | Aplica si se incorpora IA (activar documento 09 MSPI) |

### Políticas Nacionales (CONPES)
| CONPES | Tema | Aplicación |
|---|---|---|
| **3854/2016** | Política Nacional de Seguridad Digital | Marco de gestión de riesgos digitales en entidades del Estado |
| **3995/2020** | Política Nacional de Confianza y Seguridad Digital | Lineamiento vigente para postura de ciberseguridad estatal |
| **4144/2025** | Política Nacional de Inteligencia Artificial | Aplica si SmartCSET incorpora componentes de IA |

### Normativa Especial — Protección de Menores de Edad (NNA)
| Referencia | Qué exige | Aplicación en SmartCSET |
|---|---|---|
| **Circular SIC** (Protección de datos NNA) | Controles reforzados para menores de edad | Aprendices SENA < 18 años → sanciones agravadas si incumple |
| **UNICEF Policy Guidance on AI for Children (2021)** | Principios de protección de niños en sistemas automatizados | Referencia internacional citada en MSPI |
| **Ley 1098/2006** (Código de Infancia y Adolescencia) | Protección integral de menores | Deber institucional del SENA |

### Estándares Internacionales Citados en MSPI
| Estándar | Para qué | Obligatoriedad en SmartCSET |
|---|---|---|
| **ISO/IEC 27001** | Sistema de Gestión de Seguridad de la Información | Base técnica referenciada constantemente en MSPI |
| **ISO/IEC 27701** | Extensión de ISO 27001 para Privacidad de Datos | Aplicable a tratamiento de datos personales |
| **ISO/IEC 42001:2023** | Sistema de Gestión para Inteligencia Artificial | Solo si se incorpora IA (documento 09) |
| **NIST AI RMF 1.0** | Marco de gestión de riesgos en IA (USA) | Referencia internacional para MSPI de IA |
| **OWASP Top 10 2025** | Vulnerabilidades web comunes | Contra-medidas para aplicaciones web como SmartCSET |

---

## 2. Documentos de Fase 0 — Checklist de Validación por Documento

### Documento 01: POLÍTICA DE TRATAMIENTO DE DATOS PERSONALES

**Estado:** Redactado ✅ | **Próxima acción:** Revisión contra checklist + ajustes

#### Estructura Obligatoria (Decreto 1377/2013, Art. 8):
- [ ] **Título y Encabezado** — Identifica responsable de datos (SENA Centro Formación X)
- [ ] **Marco Normativo Aplicable** — Cita mínimo: Art. 13/15 Constitución, Ley 1581/2012, Decreto 1377/2013, Ley 1266/2008, Ley 1273/2009, Decreto 338/2022 (si aplica)
- [ ] **Objeto y Alcance** — Qué es SmartCSET, a quién aplica, perímetro (control de acceso físico, registros administrativos)
- [ ] **Definiciones** — Responsable, Encargado, Titular, Tratamiento, Datos sensibles, Datos de menores
- [ ] **Identificación de Responsable y Encargado** — Responsable: SENA (Director Centro / Rector Nacional); Encargado: Oficina TI / desarrollador; Contacto para consultas/reclamos
- [ ] **Datos Personales Tratados** — Lista explícita por módulo (Portería, Registro de Personas, Usuarios del Sistema)
- [ ] **Finalidades del Tratamiento** — Primaria (control de acceso) y secundarias (administración académica, reportes SENA, auditoría, DRP); prohibición de uso comercial/discriminatorio
- [ ] **Principios Rectores** — Finalidad, Lealtad, Minimización, Exactitud, Integridad/Confidencialidad, Responsabilidad
- [ ] **Tratamiento de Datos de Menores de Edad** — Sección crítica: identificación de menores, consentimiento reforzado (titular vs. tutor), protecciones especiales, cita Circular SIC/UNICEF/Ley 1098
- [ ] **Tratamiento de Datos Sensibles** — Cédula y foto como datos sensibles; restricción explícita sobre datos de origen racial, religioso, salud, etc.
- [ ] **Autorización del Titular** — Forma de consentimiento (explícito/implícito), revocabilidad
- [ ] **Derechos ARCO** — Acceso, Rectificación, Cancelación, Oposición con plazos y procedimiento
- [ ] **Procedimiento para Consultas y Reclamos** — Canal, plazo (10 días hábiles), escalación a SIC
- [ ] **Transferencia y Transmisión de Datos** — Internacional (no aplica), interna, a terceros (SENA Central, otros centros)
- [ ] **Medidas de Seguridad Técnicas** — Cifrado en tránsito/reposo, RBAC, auditoría, prepared statements
- [ ] **Medidas de Seguridad Humanas y Administrativas** — Capacitación, cambio de contraseña, segregación de funciones
- [ ] **Tiempo de Conservación de Datos** — Plazos por tipo de dato, excepciones legales
- [ ] **Procedimiento ante Incidentes de Seguridad** — Detección, investigación, notificación (titulares, SIC, SENA Central), mitigación, documentación
- [ ] **Áreas Responsables y Canal de Atención** — Cargo, contacto, horario, escalación
- [ ] **Vigencia y Actualización** — Fecha, revisión anual, procedimiento de cambios

---

### Documento 02: INVENTARIO Y CLASIFICACIÓN DE ACTIVOS DE INFORMACIÓN (C-I-D)

**Estado:** Redactado ✅ | **Próxima acción:** Validar completitud + agregar mapeo de flujos

- [ ] **Metodología C-I-D clara** — Escalas de Confidencialidad/Integridad/Disponibilidad explicadas
- [ ] **Categorías de activos cubiertas** — Datos, Software, Infraestructura, Servicios, Físicos, Humanos, Intangibles
- [ ] **Matriz de criticidad consolidada** — Top activos críticos vs. importantes vs. secundarios, con controles diferenciales
- [ ] **Evaluación preliminar como ICC** (Decreto 338/2022) — Aplica las 5 variables (impacto operacional, contexto/población, funciones críticas, impacto económico, impacto nacional); categoriza y recomienda si registrarse ante COLCERT
- [ ] **Mapa de flujo de información** — Entrada, almacenamiento, salida, puntos de exposición
- [ ] **Plan de mantenimiento del inventario** — Revisión anual, responsable, procedimiento ante nuevos activos

---

### Documento 03: MATRIZ DE RIESGOS INICIAL

**Estado:** Redactado ✅ | **Próxima acción:** Validar escalas + priorización

- [ ] **Escalas de probabilidad e impacto** definidas en términos concretos ($, operación, reputación)
- [ ] **Mapa de calor (Probabilidad × Impacto)** — matriz 4×4 con codificación visual de prioridad
- [ ] **Análisis de riesgos por las 7 categorías** — A: Acceso/Autenticación, B: Integridad/Manipulación, C: Disponibilidad/Continuidad, D: Confidencialidad/Privacidad, E: Infraestructura, F: Cumplimiento Normativo, G: Factor Humano
- [ ] **Top 10 de riesgos prioritarios** — Ordenados por riesgo residual, con plan de tratamiento por riesgo
- [ ] **Plan de seguimiento y revisión** — Periodicidad (trimestral mínimo), responsable, métricas de mejora

---

### Documento 04: ROLES Y RESPONSABILIDADES EN SEGURIDAD

**Estado:** Redactado ✅ | **Próxima acción:** Validar con Dirección SENA

- [ ] **Estructura de gobernanza clara** — Roles institucionales (Dirección, Jurídica, TI, Control Interno), técnicos (Desarrollador, DBA, Operador), de auditoría
- [ ] **Matriz RACI por proceso** — Cubre desarrollo, despliegue, operación, auditoría, incidentes, cambios
- [ ] **Segregación de Funciones (SoD)** — Conflictos potenciales identificados y mitigaciones (ej. quien desarrolla ≠ quien aprueba cambios)
- [ ] **Plan de transición y respaldo** — Qué pasa si Anderson se va; documentación de procesos críticos
- [ ] **Requisitos de competencia y formación** — Capacitación por rol, cadencia, temas (MSPI, OWASP, privacidad)
- [ ] **Procedimiento de designación formal** — Pasos para que Dirección designe roles, documentación, comunicación

---

## 3. Validación Cruzada — Coherencia entre Documentos

| Elemento | Doc 01 Política | Doc 02 Inventario | Doc 03 Riesgos | Doc 04 Roles | ¿Consistente? |
|---|---|---|---|---|---|
| Datos tratados | Listado explícito | Clasificación C-I-D | Riesgos por dato | Acceso por rol | |
| Medidas de seguridad | Sección 14 | Mapeadas a activos | Riesgos → controles | Responsables asignados | |
| Activos críticos | Identificados implícitos | Clasificados como CRÍTICOS | Top 10 riesgos | Acceso restringido | |
| Menores de edad | Sección 8 especial | Datos de aprendices marcados | Riesgos NNA | Capacitación especial | |
| Incidentes | Procedimiento sección 16 | Impacto en disponibilidad | Riesgo D3/D4 | Investigación + notificación | |

> Marcar cada celda con ✅ (consistente) o ⚠️ (revisar) durante la auditoría cruzada de los 4 documentos.

---

## 4. Plantillas de Cita Normativa

Usar estas frases como base al redactar cláusulas específicas — ya están alineadas con el lenguaje legal esperado:

```
# Ley 1581/2012 — derechos ARCO
"Conforme al artículo 17 de la Ley 1581 de 2012, el titular de los datos
tiene derecho de acceso, rectificación, cancelación y oposición (derechos ARCO)."

# Decreto 1377/2013 — fundamento de la política
"La presente política de tratamiento de datos personales se elabora conforme
al Decreto 1377 de 2013 que reglamenta la Ley 1581 de 2012."

# Ley 1266/2008 — calidad y seguridad de datos (Habeas Data)
"SmartCSET garantiza la calidad, veracidad y seguridad de los datos personales
conforme a los principios de la Ley 1266 de 2008 (Habeas Data)."

# Circular SIC — protección de menores (NNA)
"Para el tratamiento de datos de menores de edad, SmartCSET implementa controles
especiales conforme a la Circular [número] de la SIC y las buenas prácticas
internacionales de protección de la infancia (UNICEF, Ley 1098 de 2006)."

# ISO/IEC 27001 — medidas técnicas
"Las medidas técnicas de seguridad implementadas se alinean con el estándar
ISO/IEC 27001, adoptado como referencia técnica dentro del MSPI colombiano."
```

---

## 5. Checklist Final de Fase 0 — Antes de Circular a Jurídica

- [ ] Los 4 documentos cumplen su checklist de estructura/contenido (sección 2)
- [ ] Coherencia cruzada verificada (tabla sección 3, sin ⚠️ pendientes)
- [ ] Referencias normativas citadas explícitamente (no genéricas — usar plantillas sección 4)
- [ ] Lenguaje claro, sin jerga técnica sin explicar (documento dirigido a Jurídica/Dirección, no solo a TI)
- [ ] Nombres de activos/tablas consistentes entre los 4 documentos (tab_personas, tab_log_ingresos, etc.)
- [ ] Menores de edad reciben tratamiento diferenciado y consistente en los 4 documentos
- [ ] Responsables de datos identificados con cargo y contacto real (no placeholder)
- [ ] Aprobadores formales identificados (Dirección, Jurídica, TI) con fechas de revisión propuestas
- [ ] Próxima revisión anual programada en el documento

---

**Nota de mantenimiento:** Este checklist es una guía de trabajo, no un documento legal en sí. Sirve para que Anderson y Claude verifiquen precisión normativa antes de circular documentos a Jurídica/Dirección SENA. Actualizar cuando aparezcan nuevos gaps o cambie la normativa citada.
