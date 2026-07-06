# 📋 Justificación MSPI — SmartCSET

Carpeta de investigación y documentos de justificación estratégica para la implementación de SmartCSET y sus **tres sistemas**: **SGI** (Gestión de Ingreso), **SGA** (Gestión Administrativa) y **SAA** (Atención al Aprendiz).

**Objetivo:** Fundamentar ante la dirección del SENA por qué es obligatorio completar SmartCSET para cumplir con regulaciones de Protección de Datos y MSPI.

**Alcance:** los docs. 01-05 construyen el marco legal completo y justifican el **SGI** (el módulo con el problema legal vivo: la empresa de vigilancia). El doc. 06 extiende la justificación a **SGA** y **SAA** sobre ese mismo marco.

---

## 📑 Documentos

### 1. **01_INVESTIGACION_NORMATIVA_MSPI_LEY1581_2026.md**
**Ref:** JUS-INV-001  
**Propósito:** Investigación profunda de normativa aplicable

**Contiene:**
- ✅ Qué es MSPI (Marco de Seguridad y Privacidad de la Información)
- ✅ Ley 1581/2012 + Decreto 1377/2013 — Protección de Datos Personales Colombia
- ✅ Definiciones legales críticas (responsable, encargado, dato sensible)
- ✅ Multas de SIC (hasta $82M COP por incumplimiento grave)
- ✅ Regulaciones internas SENA — **verificadas contra documentos oficiales** (Acuerdo 2019, Regl. Aprendiz 2024; cross-ref a doc. 05)
- ✅ Protección especial de menores de edad (confirmada: aprendices desde 14 años, Regl. Aprendiz Art. 10)
- ✅ Comparativa legal PRE vs. POST SmartCSET

**Uso:** Apoyo técnico-legal para equipo de Oficina Jurídica SENA

---

### 2. **02_MATRIZ_RIESGOS_INCUMPLIMIENTO_PRE_SMARTCSET.md**
**Ref:** JUS-RIE-002  
**Propósito:** Cuantificar exposición legal y financiera

**Contiene:**
- ✅ Inventario de 7,384 personas cuyos datos SENA administra
- ✅ **7 riesgos críticos** identificados (pérdida soberanía, auditoría débil, integridad, menores, derechos de titulares, responsabilidad, **tratamiento sin autorización válida — R7**)
- ✅ Cada riesgo **anclado a la norma interna SENA que viola** (tabla R1-R7 → hallazgos H1-H12 del doc. 05)
- ✅ Probabilidades, impactos, multas estimadas
- ✅ **Exposición total:** $328.5M–$493M COP (peor caso)
- ✅ **Exposición esperada anual:** $102.2M COP
- ✅ Matriz de mitigación con SmartCSET
- ✅ Análisis costo-beneficio (ROI 13 meses)
- ✅ Comparativa de 3 opciones estratégicas

**Uso:** Presentación a Junta Directiva / Análisis Financiero

---

### 3. **03_JUSTIFICACION_ESTRATEGICA_IMPLEMENTACION_SMARTCSET.md**
**Ref:** JUS-EST-003  
**Propósito:** Documento ejecutivo para decisión estratégica

**Contiene:**
- ✅ Resumen ejecutivo (problema, solución, recomendación)
- ✅ Contexto legal en 3 párrafos
- ✅ Diagnóstico actual (incumplimientos detectados, incluye R7)
- ✅ **§2.2 "El SENA Está Incumpliendo Su Propia Política"** — tabla de mandatos del Acuerdo 2019 y Regl. Aprendiz 2024 vs. situación actual (argumento definitivo)
- ✅ Solución SmartCSET (qué es, arquitectura, incumplimientos resueltos)
- ✅ Análisis de decisión (3 opciones)
- ✅ Plan de acción con cronograma y costos
- ✅ Recomendación formal para Dirección (fundamentación legal externa + interna)
- ✅ FAQ (incluye: "¿SmartCSET requiere nuevas autorizaciones de datos?" → No, ver H10)

**Uso:** Presentación a dirección, aprobación de presupuesto

---

### 4. **04_DOCUMENTOS_SENA_REQUERIDOS_INVESTIGACION.md**
**Ref:** JUS-DOC-004
**Propósito:** Plantilla de identificación de normativa interna SENA a investigar

**Contiene:**
- ✅ Lista de políticas internas esperadas (DO-pol0006, etc.)
- ✅ Qué buscar en cada una y cómo mapea a SmartCSET
- ✅ Emails modelo para Oficina Jurídica y Oficina TI
- ✅ Banner de estado: **búsqueda ejecutada el 2026-07-05** — mapeo de cada categoría al documento oficial que la cubrió

**Uso:** Registro metodológico de la recolección documental (resultados en doc. 05)

---

### 5. **05_ANALISIS_NORMATIVA_INTERNA_SENA.md** ⭐ NUEVO
**Ref:** JUS-INT-005
**Propósito:** Análisis de los documentos oficiales REALES del SENA (descargados de sena.edu.co)

**Contiene:**
- ✅ 7 documentos oficiales SENA analizados (Acuerdo 2019 + Manual, Planes 2019/2023/2026, Política 2016, Reglamento del Aprendiz 2024 leído íntegro, Reglamento de Centros)
- ✅ 12 hallazgos con **citas textuales** (H1-H12)
- ✅ **Hallazgo central 1 (H1):** el Manual 2019 §15.7 declara "Todos los datos están almacenados en un servidor del SENA en Colombia" — la situación actual viola la propia política del SENA
- ✅ **Hallazgo central 2 (H10):** la autorización de datos que firma cada aprendiz (Regl. Aprendiz 2024, Art. 11 Par. 5) cubre solo a **la entidad** y el intercambio con **entidades públicas** — el proveedor privado de vigilancia trata datos **sin autorización válida**; SmartCSET en cambio queda amparado por la autorización ya firmada
- ✅ **Hallazgo central 3 (H12):** aprendices desde 14 años; consentimiento de padres otorgado solo al SENA → datos de menores en software del tercero = sin autorización de representantes legales (máxima gravedad ante la SIC)
- ✅ Matriz de 16 requisitos internos: situación actual incumple 10 con certeza
- ✅ Checklist de verificación del contrato con la empresa de vigilancia (§11)
- ✅ Nota sobre DO-pol0006 → vive en CompromISO (SIGA), acceso interno
- ✅ 3 acciones de verificación pendientes (contrato, CompromISO, RNBD)

**Uso:** Núcleo probatorio de la justificación — argumento "el Consejo Directivo ya lo ordenó en 2019"

---

### 6. **06_JUSTIFICACION_MODULOS_SGA_SAA.md** ⭐ NUEVO
**Ref:** JUS-MOD-006
**Propósito:** Extender la justificación a los sistemas SGA y SAA (los docs. 01-05 cubren el SGI)

**Contiene:**
- ✅ Arquitectura de los 3 sistemas (SGI `10` / SGA `20` / SAA `30`) con estado de cada uno
- ✅ Tabla del marco legal común: qué fundamentos de los docs. 01/05 aplican a los tres (incluida la autorización H10 — **ningún módulo requiere autorizaciones nuevas de aprendices**)
- ✅ **SGA — argumento central: debido proceso y trazabilidad académica.** Asistencia, deserción (Regl. Arts. 28-30) y régimen disciplinario (Cap. V) exigen registros íntegros que hoy viven en Excel/papel. Anclado a Regl. Art. 8.4/8.5, Art. 5.10-5.11 y Manual §8.4/§15.3.1. Incluye la **precisión estratégica obligatoria:** SGA complementa a Sofía Plus a nivel de centro, no lo reemplaza
- ✅ **SAA — argumento central: bienestar como derecho reglamentario** (Regl. Art. 5.6) + cumplimiento por diseño (datos de salud = sensibles; nacer dentro del SGSI evita sistemas paralelos)
- ✅ Matriz de cumplimiento por sistema (11 requisitos × 3 módulos)
- ✅ Integración SGI→SGA (ingreso en portería alimenta asistencia/retardos — cadena de integridad)
- ✅ Prioridad recomendada: SGI → SGA → SAA

**Uso:** Justificación de la plataforma completa; insumo para fases posteriores del proyecto

---

### 📂 **documentos_sena/** (evidencia descargada)
7 PDFs oficiales del SENA:
- `manual_seguridad_proteccion_datos_2019.pdf` ⭐ (Acuerdo + Manual, el más importante)
- `plan_seguridad_privacidad_2019.pdf` / `plan_seguridad_privacidad_2023.pdf`
- `plan_tratamiento_riesgos_2026.pdf`
- `proteccion_datos_personales_2016.pdf` (Acuerdo 009/2016, vigente transitoriamente)
- `reglamento_aprendiz_2024.pdf` ⭐ (Acuerdo 0009 del 5-nov-2024 — leído íntegro; fuente de los hallazgos H10-H12)
- `reglamento_interno_centros.pdf`

---

## 🎯 Hallazgos Principales

### El Problema
- SENA recopila 7,384 registros de personas (7,369 aprendices, incluidos menores desde 14 años — Regl. Aprendiz Art. 10)
- Datos de ingreso/salida en software propio de la empresa de vigilancia = **incumplimiento crítico de MSPI + Ley 1581 + la propia política del SENA (Acuerdo 2019)**
- Auditoría imposible (datos no en control SENA)
- La autorización de datos firmada por los aprendices **no cubre al proveedor privado** (Regl. Aprendiz Art. 11 Par. 5 — hallazgo H10)

### El Costo del Incumplimiento
| Métrica | Valor |
|---|---|
| Multa por incumplimiento grave (SIC) | **$82M COP** |
| Exposición peor caso | **$493M COP** |
| Exposición anual esperada | **$102.2M COP** |
| Sanciones complementarias | Suspensión 6 meses a cierre operacional |

### La Solución
- **SmartCSET centraliza datos en servidor SENA** → soberanía garantizada
- **Auditoría exhaustiva con logs JSON** → SIEM verificable por SIC
- **Control de acceso por usuario** → trazabilidad completa
- **Workflow de consentimiento** → derechos de menores protegidos
- **ROI positivo:** Se paga en 13 meses con multas evitadas
- **Plataforma de 3 sistemas** (doc. 06): SGI operativo (soberanía) → SGA parcial (debido proceso académico, complementa a Sofía Plus) → SAA en construcción (bienestar por diseño)

### El Argumento Definitivo (doc. 05)
La normativa interna del SENA **ya ordena** todo lo que SmartCSET implementa:
- Manual 2019 §7.1.1: "los ingresos y salidas de las instalaciones del SENA **deben ser registrados**"
- Manual 2019 §15.7: "**Todos los datos están almacenados en un servidor del SENA en Colombia**"
- Manual 2019 §11: terceros que procesen información requieren acuerdo de confidencialidad + anexo técnico + responsabilidad civil/penal
- Manual 2019 §15.4: tratamiento de datos de menores fuera del marco = **proscrito**
- Regl. Aprendiz 2024 Art. 8.19: el aprendiz debe identificarse al ingreso **según lo que disponga la entidad**
- Regl. Aprendiz 2024 Art. 11 Par. 5: la autorización firmada cubre a **la entidad** — SmartCSET ya está amparado; el tercero no

**SmartCSET no pide una decisión nueva de política — ejecuta la que ya existe y hoy está en incumplimiento.**

---

## 📊 Recomendación

**IMPLEMENTAR SmartCSET es obligatorio, no opcional.**

Las tres opciones estratégicas evaluadas:
- **Opción A (No hacer nada):** 🔴 **NO VIABLE** — Incumplimiento permanente
- **Opción B (Mejorar contrato tercero):** 🟡 **PARCIAL** — Insuficiente para riesgos críticos
- **Opción C (SmartCSET completo):** 🟢 **OBLIGATORIO** — Única opción legalmente viable

---

## 📅 Cronograma de Implementación

### FASE 1 (En Progreso) — 10 semanas faltantes
- E3 — Rate limiting: 2 semanas (~$3M)
- E8 — Hardening red: 3 semanas (~$5M)
- E9 — Gestión de parches: 1 semana (~$1M)
- E2 — Cifrado en reposo: 3 semanas (~$8M)
- **Objetivo:** Septiembre 2026

### FASE 2 (Post-FASE 1) — Q4 2026
- Continuidad y resiliencia
- DRP (Disaster Recovery Plan)
- Monitoreo continuo

---

## 🔒 Clasificación de Documentos

| Documento | Clasificación | Audiencia |
|---|---|---|
| 01_INVESTIGACION_NORMATIVA | CONFIDENCIAL — Legal | Oficina Jurídica SENA |
| 02_MATRIZ_RIESGOS | CONFIDENCIAL — Estratégico | Junta Directiva, Dirección Administrativa |
| 03_JUSTIFICACION_ESTRATEGICA | CONFIDENCIAL — Dirección | Junta Directiva, Director General |
| 04_DOCUMENTOS_SENA_REQUERIDOS | Interno — Metodológico | Equipo SmartCSET |
| 05_ANALISIS_NORMATIVA_INTERNA | CONFIDENCIAL — Legal | Oficina Jurídica, Dirección |
| 06_JUSTIFICACION_MODULOS_SGA_SAA | CONFIDENCIAL — Dirección | Junta Directiva, Dirección de Formación |
| documentos_sena/ (PDFs) | Públicos (portal de transparencia SENA) | Referencia probatoria |

**Nota:** No compartir los análisis (01-05) externamente sin aprobación de Oficina Jurídica. Los PDFs de `documentos_sena/` son públicos.

---

## 📚 Documentación Relacionada

**Dentro de SmartCSET:**
1. `CLAUDE.md` — Arquitectura técnica completa
2. `Documentacion para implementacion de MSPI/FASE 0_documentos...` — 8 documentos legales (políticas, inventario, roles, matrices de riesgo)
3. `Documentacion para implementacion de MSPI/FASE 01_Blindaje Técnico Inmediato/` — Reportes técnicos E1-E10

**Normativa interna SENA (oficial, copias en `documentos_sena/`):**
- Acuerdo Consejo Directivo Nacional de 2019 (Política General de Seguridad + Manual)
- Acuerdo 009 de 2016 (Política de Protección de Datos, vigente transitoriamente)
- Reglamento del Aprendiz — Acuerdo 0009 del 5-nov-2024
- Planes de Seguridad y Privacidad 2019/2023 + Plan de Riesgos 2026

**Legislación Colombiana (referencias externas):**
- Resolución MinTIC 02277/2025 (MSPI 2026)
- Ley 1581/2012 (Protección de Datos Personales)
- Decreto 1377/2013 (Regulación)
- Sentencia Corte Constitucional T-260-12 (Menores)

---

## ✅ Próximos Pasos

1. **Verificaciones internas pendientes** (doc. 05 §5): contrato de la empresa de vigilancia vs. checklist §11 · texto de DO-pol0006 en CompromISO · registro de la BD de control de ingreso en el RNBD (SIC)
2. **Revisión Jurídica** — Oficina Jurídica SENA valida documentos
3. **Presentación a Dirección** — Usar `03_JUSTIFICACION_ESTRATEGICA` para aprobación (presentación al Director Regional: 29 de julio de 2026)
4. **Aprobación de Presupuesto** — $19M COP para completar FASE 1
5. **Asignación de Recursos** — Equipo de desarrollo + TI
6. **Auditoría Voluntaria SIC** — Una vez FASE 1 completa (muestra buena fe)

---

**Carpeta creada:** 2026-07-05  
**Estado:** LISTO PARA REVISIÓN JURÍDICA Y PRESENTACIÓN A DIRECCIÓN  
**Clasificación:** CONFIDENCIAL — USO EXCLUSIVO INTERNO SENA

---

## 📞 Contacto

**Equipo SmartCSET:** Desarrollo, Seguridad, Arquitectura  
**Oficina Jurídica:** Revisión legal de interpretaciones normativas  
**Dirección TI:** Coordinación de infraestructura (E8 — Hardening)
