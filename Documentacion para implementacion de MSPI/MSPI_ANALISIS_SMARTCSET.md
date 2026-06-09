# Análisis MSPI aplicado a SmartCSET
## Modelo de Seguridad y Privacidad de la Información (MinTIC) — Implicaciones, Marco Normativo y Recomendaciones para el Sistema

**Fecha del análisis:** Junio 2026
**Documentación fuente:** 9 documentos oficiales ubicados en `/Documentacion para implementacion de MSPI/` (MinTIC, COLCERT, CONPES, normativa nacional e internacional)
**Sistema analizado:** SmartCSET — Plataforma de gestión institucional del SENA (control de acceso, registro de personas, gestión de aprendices/instructores/contratistas, reemplazo progresivo de SofiaPlus)

---

## 1. Resumen Ejecutivo

SmartCSET es un sistema de información que procesa **datos personales sensibles** (documentos de identidad, fotografías, datos biográficos, posiblemente datos de menores de edad — aprendices SENA pueden ser menores) en el contexto de una **entidad pública del Estado colombiano** (SENA — Servicio Nacional de Aprendizaje, sector Educación).

Esto significa que SmartCSET **no es un proyecto de software libre de obligaciones regulatorias**: cae directamente bajo el paraguas del **Modelo de Seguridad y Privacidad de la Información (MSPI)** de MinTIC, la **Ley de Protección de Datos Personales (Ley 1581/2012)**, la **Ley de Habeas Data (Ley 1266/2008)**, y potencialmente bajo la clasificación de **Infraestructura Crítica Cibernética (ICC)** según el Decreto 338/2022, dado que el sector Educación es uno de los 14 sectores críticos nacionales de Colombia.

La conclusión central de este análisis es:

> **Cumplir el MSPI no es opcional ni un "extra de seguridad"** — es una obligación legal para cualquier sistema de información que opere dentro de una entidad pública colombiana, con consecuencias jurídicas, económicas, reputacionales y operativas concretas en caso de incumplimiento.

---

## 2. Marco Normativo Aplicable — Qué Leyes y Políticas Rigen a SmartCSET

### 2.1. Marco constitucional
| Artículo | Relevancia para SmartCSET |
|---|---|
| Art. 13 (Igualdad) | Prohíbe discriminación en sistemas automatizados (relevante si se introduce IA para clasificar/priorizar personas) |
| Art. 15 (Intimidad y datos personales) | Base constitucional de la protección de datos — SmartCSET almacena cédulas, fotos, biometría potencial |
| Art. 20 (Libertad de expresión) | Relevante si el sistema modera o filtra contenido generado por usuarios |
| Art. 25 (Derecho al trabajo) | Relevante en módulos de gestión de personal/contratistas |

### 2.2. Marco legal y reglamentario
| Norma | Qué exige | Aplicación directa en SmartCSET |
|---|---|---|
| **Ley 1581 de 2012** (Protección de Datos Personales) | Consentimiento informado, finalidad del tratamiento, derechos ARCO (Acceso, Rectificación, Cancelación, Oposición) | Cada registro de persona (visitante, aprendiz, instructor, contratista) requiere base legal de tratamiento documentada |
| **Ley 1266 de 2008** (Habeas Data) | Calidad, veracidad y seguridad de datos personales en bases de datos | `tab_personas`, `tab_log_ingresos` deben cumplir estándares de calidad y trazabilidad |
| **Ley 1273 de 2009** (Delitos Informáticos) | Tipifica el acceso abusivo a sistemas, daño informático, hurto de datos como delitos penales | Brechas de seguridad en SmartCSET pueden derivar en **responsabilidad penal**, no solo administrativa |
| **Ley 1712 de 2014** (Transparencia y Acceso a Información Pública) | Obligación de las entidades públicas de proteger y divulgar información de manera responsable | Aplica a reportes generados por SmartCSET (DF-49, PE-04, juicios de evaluación) |
| **Decreto 1377 de 2013** | Reglamenta la Ley 1581 — autorización del titular, políticas de tratamiento, registro de bases de datos | SmartCSET debe tener política de tratamiento de datos publicada y accesible |
| **Decreto 1078 de 2015 (DUR-TIC)** | Decreto Único Reglamentario del sector TIC — incluye lineamientos de Gobierno Digital y MSPI | Marco regulatorio "padre" del MSPI |
| **Decreto 338 de 2022** | Define qué es Infraestructura Crítica Cibernética (ICC) y establece la institucionalidad de ciberseguridad nacional | Determina si el SENA/SmartCSET debe registrarse como ICC ante COLCERT |
| **Decreto 767 de 2022** | Lineamientos sobre uso y gobernanza de tecnologías emergentes (incluida IA) en el sector público | Aplica si se incorpora IA al nuevo módulo de personal |
| **CONPES 3701 de 2011** | Primera política nacional de ciberseguridad y ciberdefensa | Antecedente normativo del marco actual |
| **CONPES 3854 de 2016** | Política Nacional de Seguridad Digital | Marco de referencia para la gestión de riesgos digitales en entidades del Estado |
| **CONPES 3995 de 2020** | Política Nacional de Confianza y Seguridad Digital | Lineamiento vigente que orienta la postura de ciberseguridad estatal |
| **CONPES 4144 de 2025** | Política Nacional de Inteligencia Artificial | Aplica si SmartCSET incorpora componentes de IA (reconocimiento facial, OCR inteligente, clasificación automática) |

### 2.3. Marco internacional de referencia (citado en el MSPI)
- **ISO/IEC 27001** — Sistema de Gestión de Seguridad de la Información (estándar base referenciado constantemente en el MSPI para cifrado, control de acceso, gestión de incidentes)
- **ISO/IEC 9000:2015** — Define "validez" de un sistema (citado en criterios de fiabilidad)
- **ISO/IEC TS 5723:2022** — Define "fiabilidad", "seguridad" y "resiliencia" de sistemas (aplica si se usa IA)
- **ISO/IEC 22989:2022** — Terminología y conceptos de IA
- **ISO/IEC 42001:2023** — Sistema de Gestión para IA (aplica si se usa IA)
- **NIST AI RMF 1.0 / NIST AI 600-1 / NIST AI 100-2e2025** — Marco de gestión de riesgos en IA y taxonomía de ataques adversariales (referencia internacional para el marco MSPI de IA)
- **OWASP Top 10 – 2025 para LLMs y aplicaciones de IA Generativa** — Catálogo de vulnerabilidades específicas de sistemas con IA generativa

---

## 3. ¿Qué es el MSPI y por qué aplica a SmartCSET?

El **Modelo de Seguridad y Privacidad de la Información (MSPI)** es el marco oficial de MinTIC que toda entidad pública colombiana —incluido el SENA— debe implementar como parte de su Sistema de Gestión de Seguridad de la Información (SGSI). No es una recomendación: es **un componente obligatorio del Modelo Integrado de Planeación y Gestión (MIPG)** que el Departamento Administrativo de la Función Pública exige a las entidades del Estado.

**SmartCSET, al ser un sistema de información operado dentro del SENA**, queda automáticamente comprendido dentro del alcance del SGSI institucional. Esto implica que:

1. El **ciclo de vida completo** de SmartCSET (diseño → desarrollo → despliegue → operación → retiro) debe seguir los lineamientos del MSPI.
2. Toda **base de datos de información personal** (tab_personas, tab_log_ingresos, tab_usuarios) debe estar inventariada y clasificada según los tres principios de seguridad de la información: **Integridad, Confidencialidad y Disponibilidad**.
3. Las funciones PL/pgSQL y el manejo de excepciones (`smartcset_raise_validacion`, `smartcset_raise_negocio`) ya alinean parcialmente con buenas prácticas, pero **no constituyen, por sí solas, cumplimiento del MSPI** — falta la capa de gobernanza, documentación, auditoría periódica y gestión de riesgos formal que el modelo exige.

---

## 4. Infraestructura Crítica Cibernética (ICC) — ¿Aplica al SENA / SmartCSET?

### 4.1. Contexto normativo (Decreto 338/2022)
Colombia identificó **14 sectores críticos nacionales**, entre ellos: Alimentación/Agricultura, Agua, TIC, Comercio/Industria/Turismo, Recursos Minero-Energéticos, Electricidad, Salud, Financiero, Medio Ambiente, Estado, Defensa, **Educación**, Transporte, y "Evento Transitorio Multifactor" (ETM).

El **SENA pertenece al sector Educación**, lo que significa que sus sistemas de información (incluyendo SmartCSET, en la medida en que gestiona el acceso físico, identidad de personas y procesos administrativos críticos del centro de formación) podrían estar sujetos a la metodología de evaluación ICC.

### 4.2. Metodología de clasificación (5 variables)
El documento 08_02 establece 5 variables que determinan si un sistema/infraestructura debe clasificarse como ICC, cada una con escala Bajo(1)/Moderado(2)/Alto(3)/Extremo(4):

1. **Impacto operacional**
2. **Contexto / población afectada** (escala Hanlon: <99,999 / 100k-249k / 250k-499k / 500k+)
3. **Impacto a funciones críticas nacionales**
4. **Afectación económica nacional** (% del PIB: <0.1% / 0.1-0.5% / 0.5-1% / >1%)
5. **Impacto nacional al servicio**

### 4.3. Categorías resultantes
| Categoría | Rango (promedio variables) |
|---|---|
| Crítico / Extremo | 2.95 - 4.0 |
| Esencial / Alto | 1.95 - 2.94 |
| Importante / Moderado | 0.95 - 1.94 |
| Secundario / Bajo | < 0.95 |

### 4.4. Implicación práctica
Si el SENA, a través de su oficina de TI, determina que SmartCSET (al centralizar el control de acceso, identidad y procesos formativos de un Centro de Formación) cae en una categoría **Importante o superior**, deberá:
- Diligenciar el **Anexo 1** (matriz de delimitación de sectores) y el **Anexo 2** (formulario de madurez vía Microsoft Forms)
- Reportarse formalmente ante **COLCERT** (`icc@colcert.gov.co`, `csirtgob@mintic.gov.co`)
- Aplicar la **matriz RACI** para asignar responsabilidades de seguridad
- Cumplir el checklist de 14 puntos de "Fortalecimiento de Seguridad Digital": SGSI/MSPI, planes estratégicos, DRP (Disaster Recovery Plan), actualización de sistemas, firewalls/IPS, MFA, cifrado, monitoreo continuo, gestión de activos críticos, respuesta a incidentes, copias de seguridad, etc.

---

## 5. Lineamientos de Seguridad para Sistemas de IA (Documento 09) — ¿Cuándo Aplican?

Este documento es un **anexo específico del MSPI para sistemas que incorporan Inteligencia Artificial**. **Solo aplica si SmartCSET incorpora componentes de IA** — por ejemplo:
- Reconocimiento facial o biométrico para control de acceso
- OCR inteligente / parsing automatizado de cédulas más allá del parser PDF417 actual
- Clasificación automática, scoring o priorización de personas/solicitudes
- Chatbots o asistentes conversacionales (LLM/RAG) para soporte interno

### 5.1. Si se decide incorporar IA, el documento exige:

**Principios rectores obligatorios (6):**
1. Centralidad humana y bien público
2. Transparencia, explicabilidad y rendición de cuentas
3. Equidad, igualdad y no discriminación
4. Privacidad y gobernanza de datos
5. Robustez, fiabilidad y seguridad
6. Sostenibilidad ambiental y bienestar

**Top 10 OWASP 2025 para LLM/IA Generativa** — riesgos que deberían mitigarse desde el diseño si se usa IA generativa:
- LLM01: Inyección de Prompts
- LLM02: Divulgación de Información Sensible
- LLM03: Cadena de Suministro Insegura
- LLM04: Envenenamiento de Datos y Modelo
- LLM05: Manejo Inadecuado de la Salida
- LLM06: Agencia Excesiva
- LLM07: Filtración de prompts de sistema
- LLM08: Debilidades de vector y representaciones vectoriales
- LLM09: Desinformación
- LLM10: Consumo Ilimitado

**Clasificación de riesgo según el Reglamento Europeo de IA (referencia internacional citada):**
- Riesgo mínimo (sin obligaciones)
- Riesgo limitado (obligaciones de transparencia — ej. "este es un chatbot")
- **Riesgo alto** (afecta salud, seguridad o derechos fundamentales — ej. herramientas de selección de personal) → requisitos estrictos de calidad, transparencia y supervisión humana
- Riesgo inaceptable (prohibido — ej. reconocimiento biométrico en tiempo real en espacios públicos)

> **Nota crítica:** Si el módulo de "registro y seguimiento de personal" usa IA para **evaluar, clasificar o tomar decisiones sobre personas** (por ejemplo, priorizar revisiones, detectar anomalías de comportamiento, scoring de riesgo), probablemente caería en la categoría de **"Riesgo alto"** del marco europeo (análogo aplicado por MinTIC), lo que **incrementa significativamente las obligaciones de cumplimiento**.

### 5.2. Recomendación de diseño
Dado que el módulo planeado es esencialmente de **registro y seguimiento** (CRUD + búsqueda + reportes, similar al patrón ya existente en `src/modulos/registro/`), **la recomendación es NO introducir IA** salvo que exista un caso de uso claramente justificado. Esto evita activar todo el aparato regulatorio del documento 09 y mantiene el sistema dentro del alcance "tradicional" del MSPI (mucho más simple de cumplir).

---

## 6. Escenarios Comparativos: Cumplir vs. No Cumplir

### 6.1. Escenario A — SmartCSET NO implementa el MSPI adecuadamente

| Área de impacto | Consecuencia concreta |
|---|---|
| **Legal / Penal** | Exposición a sanciones bajo la Ley 1273/2009 (Delitos Informáticos) en caso de filtración de datos; responsabilidad disciplinaria para funcionarios del SENA bajo el régimen de la Procuraduría General |
| **Administrativo** | Hallazgos de auditoría por parte de la Contraloría General de la República y la Oficina de Control Interno del SENA — posibles **glosas fiscales** (devolución de recursos invertidos en el sistema si se determina que no cumple estándares mínimos) |
| **Económico — Sanciones SIC** | La Superintendencia de Industria y Comercio (SIC) puede imponer multas de hasta **2.000 SMLMV** (aproximadamente **$2.700 millones de pesos colombianos en 2026**, a una tasa de SMLMV ≈ $1.350.000) por violaciones a la Ley 1581/2012 (protección de datos personales) |
| **Económico — Pérdida de recursos invertidos** | Si el sistema no puede certificarse o pasar auditorías de TI del MIPG, el SENA podría verse obligado a **reemplazarlo o reconstruirlo**, perdiendo la inversión completa en desarrollo (estimable en cientos de horas-hombre y costos de infraestructura) |
| **Reputacional** | El SENA es una entidad de alta visibilidad pública; una brecha de datos de aprendices (muchos de ellos menores de edad) generaría escándalo mediático, pérdida de confianza ciudadana y escrutinio político |
| **Operativo** | Sin gestión formal de riesgos, cualquier incidente (caída del sistema, corrupción de datos, acceso no autorizado) **no tiene plan de respuesta ni de recuperación (DRP)** — la operación de portería y registro del centro de formación podría detenerse por días |
| **Children/Privacidad** | Dado que aprendices SENA frecuentemente son menores de edad, el incumplimiento de controles especiales de protección de datos de NNA (Niños, Niñas y Adolescentes) — exigidos en la Circular SIC citada en el doc. 09 — constituye una **falta agravada** con sanciones reforzadas |

### 6.2. Escenario B — SmartCSET SÍ implementa el MSPI correctamente

| Área de impacto | Beneficio concreto |
|---|---|
| **Legal** | Blindaje jurídico: el sistema cuenta con políticas de tratamiento de datos documentadas, consentimiento informado y bases legales claras — reduce drásticamente la exposición a sanciones |
| **Administrativo** | El sistema pasa auditorías del MIPG sin observaciones — fortalece la posición del SENA en evaluaciones de gestión institucional ante el DAFP |
| **Económico** | Se evitan sanciones, glosas fiscales y costos de reconstrucción; además, un sistema certificado bajo MSPI/ISO 27001 **incrementa su valor institucional** y puede ser replicado en otros centros de formación del SENA a nivel nacional, generando economías de escala |
| **Reputacional** | El SENA puede presentar a SmartCSET como un caso de éxito de transformación digital responsable — valor político y mediático positivo |
| **Operativo** | Existencia de DRP, copias de seguridad, monitoreo continuo y plan de respuesta a incidentes → continuidad operativa garantizada incluso ante fallos o ataques |
| **Estratégico** | Cumplir el MSPI desde el diseño facilita la futura clasificación voluntaria como buena práctica ante COLCERT, posicionando al SENA como referente de seguridad digital en el sector Educación |
| **Escalabilidad** | Un sistema que cumple MSPI desde el inicio puede integrarse sin fricciones con otros sistemas del Estado (interoperabilidad MinTIC) y escalar a nivel nacional sin necesidad de reescritura regulatoria |

---

## 7. Comparativo Directo: ¿En Qué Nos Ayuda Aplicar el MSPI vs. No Aplicarlo?

| Dimensión | **Sin MSPI** | **Con MSPI** |
|---|---|---|
| Confianza ciudadana | Riesgo de pérdida de confianza ante cualquier incidente | Confianza reforzada — el sistema demuestra responsabilidad institucional |
| Costos a largo plazo | Costos ocultos: sanciones, reconstrucciones, litigios | Costos predecibles: inversión planificada en controles desde el diseño |
| Continuidad operativa | Sin DRP — un incidente puede paralizar la portería del centro de formación | Con DRP — la operación se recupera en tiempo acotado y documentado |
| Exposición legal | Alta — responsabilidad civil, penal y disciplinaria | Baja — cumplimiento documentado reduce la exposición de Anderson y del SENA |
| Auditorías | Observaciones, hallazgos, posibles glosas fiscales | Aprobación sin observaciones — fortalece la gestión institucional |
| Escalabilidad nacional | El sistema queda limitado a un centro de formación, sin posibilidad de réplica oficial | El sistema puede convertirse en modelo nacional para otros centros SENA |
| Manejo de datos de menores | Riesgo de sanciones agravadas por incumplir Circular SIC sobre NNA | Controles reforzados desde el diseño — cumplimiento proactivo |
| Percepción ante COLCERT/MinTIC | Sistema fuera del radar regulatorio — riesgo de hallazgos sorpresivos | Sistema registrado y evaluado proactivamente — relación de colaboración con el ente regulador |

---

## 8. Recomendaciones Concretas para SmartCSET

### 8.1. Acciones inmediatas — COMPLETADAS (Fase 0 ✅ 2026-06-08)

Las tres acciones inmediatas identificadas originalmente fueron completadas en la **Fase 0 del Plan de Blindaje Institucional**:

1. ~~**Documentar la política de tratamiento de datos personales**~~ → ✅ **Completado:** `FASE0-POL-001` — Política y Tratamiento de Datos Personales (Ley 1581, D1, Ejes 1/11)
2. ~~**Inventariar los activos de información existentes**~~ → ✅ **Completado:** `FASE0-INV-002` — Inventario de Activos de Información clasificado por C-I-D (ISO 27001 A.8)
3. ~~**Verificar/establecer un plan de copias de seguridad y recuperación (DRP)**~~ → ✅ **Completado:** `FASE0-INC-008` — Marco de Gestión de Incidentes y Continuidad (RTO=4h, RPO=24h, DRP en 7 pasos)

Adicionalmente, la Fase 0 produjo 5 documentos complementarios: `FASE0-RIE-003` (Matriz de Riesgos), `FASE0-ROL-004` (Roles y Responsabilidades), `FASE0-AUD-005` (Cronograma de Auditorías), `FASE0-PSI-006` (Política General de Seguridad — documento raíz del SGSI que mapea los 11 ejes MSPI) y `FASE0-ACC-007` (Política de Control de Acceso y Seguridad Física).

**Próximo paso activo: Fase 1 — Blindaje Técnico Inmediato** (10 entregables, implementación pendiente). Ver `PLAN_BLINDAJE_INSTITUCIONAL_SMARTCSET.md` para el detalle completo.

### 8.2. Para el nuevo módulo de "registro y seguimiento de personal"
1. **Mantener el patrón sin IA** (CRUD + funciones PL/pgSQL + auditoría `usr_insert/fec_insert`) — evita activar las obligaciones del documento 09
2. **Aplicar controles reforzados de protección de datos de menores** desde el diseño, dado que aprendices SENA pueden ser menores de edad (Circular SIC)
3. **Documentar la finalidad específica del nuevo módulo** y obtener/verificar consentimiento informado donde aplique (Decreto 1377/2013, Art. del Decreto reglamentario de la Ley 1581)
4. **Aplicar cifrado en reposo** para campos sensibles (documentos de identidad, fotos) conforme a ISO/IEC 27001, citado reiteradamente en el MSPI — planificado en Fase 1 E2

### 8.3. A mediano plazo (institucional) — en progreso
1. **Coordinar con la Oficina de TI del SENA** para determinar si SmartCSET debe **registrarse formalmente como ICC** (clasificación según las 5 variables del documento 08_02) — previsto en Fase 3
2. **Incorporar SmartCSET al inventario institucional del SGSI del SENA** bajo el MSPI — base documental ya establecida en Fase 0
3. **Sostener el ciclo de auditorías periódicas** programado en `FASE0-AUD-005` (trimestral, semestral, anual) — ejecutado en Fase 5 (mejora continua permanente)

---

## 9. Conclusión

SmartCSET, al ser un sistema de información de una entidad pública que procesa datos personales sensibles —incluyendo potencialmente datos de menores de edad— **no puede tratarse como un proyecto de software convencional**. El marco MSPI no es un costo adicional opcional: es la diferencia entre:

- Un sistema que **protege al SENA** de sanciones, pérdidas económicas y daño reputacional, **y**
- Un sistema que **expone al SENA** (y potencialmente a las personas responsables de su desarrollo y operación) a responsabilidad legal, disciplinaria y económica significativa.

La buena noticia es que el patrón arquitectónico que ya sigue SmartCSET —funciones PL/pgSQL con manejo estructurado de excepciones, auditoría con `usr_insert/fec_insert`, separación de capas, prepared statements— **ya está alineado en su base técnica** con varios principios del MSPI (integridad, trazabilidad, prevención de inyección SQL). Lo que falta es la **capa de gobernanza formal**: políticas documentadas, clasificación de activos, gestión de riesgos, planes de continuidad y, eventualmente, registro ante las autoridades correspondientes (COLCERT si aplica clasificación ICC).

---

## 10. Referencias (Documentos Fuente)

Todos los documentos analizados se encuentran en `/Documentacion para implementacion de MSPI/`:

1. Documentos 01-07 — Marco general del MSPI, principios, fases de implementación
2. Documento 08_01 / 08_02 — Lineamientos para la identificación de Infraestructuras Críticas Cibernéticas V1
3. Documento 09 — Lineamientos de Seguridad y Privacidad de la Información para Sistemas de Inteligencia Artificial V1.0

Bibliografía citada dentro de los documentos MSPI (normas y estándares internacionales referenciados): ISO/IEC 27001, ISO/IEC 22989:2022, ISO/IEC 42001:2023, ISO/IEC TS 5723:2022, ISO 9000:2015, NIST AI RMF 1.0, NIST AI 600-1, NIST AI 100-2e2025, OWASP Top 10 2025 (LLM/GenAI), MITRE ATLAS, OCDE Recommendation on AI (2019), UNESCO Recommendation on Ethics of AI (2021), UNICEF Policy Guidance on AI for Children (2021), Reglamento Europeo de IA (AI Act, 2024).

---

*Documento generado a partir del análisis detallado de la documentación MSPI provista por el usuario. Este análisis tiene fines de orientación técnica y no sustituye asesoría jurídica formal — se recomienda validar con la Oficina Jurídica y la Oficina de TI del SENA antes de tomar decisiones de cumplimiento normativo definitivas.*
