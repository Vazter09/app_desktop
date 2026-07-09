# Documentos Internos SENA — Requeridos en la Investigación MSPI

**Documento:** JUS-DOC-004
**Fecha:** 2026-07-05
**Propósito:** Identificar y recopilar políticas internas SENA relevantes para justificación de SmartCSET

---

> ## ✅ ESTADO: BÚSQUEDA EJECUTADA (2026-07-05)
>
> Este documento se escribió como **plan de búsqueda** antes de localizar la normativa interna. La búsqueda ya se ejecutó el mismo día:
>
> - **7 documentos oficiales del SENA** fueron descargados de sena.edu.co y repositorio.sena.edu.co → carpeta `documentos_sena/`
> - El análisis completo con citas textuales está en **`05_ANALISIS_NORMATIVA_INTERNA_SENA.md`** (12 hallazgos H1-H12, matriz de 16 requisitos)
> - Los documentos "esperados" de las categorías 1-5 de abajo resultaron cubiertos así:
>   - **Categoría 1 (Protección de datos):** ✅ Acuerdo Consejo Directivo 2019 + Manual (`manual_seguridad_proteccion_datos_2019.pdf`) + Acuerdo 009/2016 (`proteccion_datos_personales_2016.pdf`). El código **DO-pol0006** pertenece a **CompromISO** (plataforma SIGA, acceso interno) — su documento padre es el Acuerdo 2019, ya analizado
>   - **Categoría 2 (Menores / portería):** ✅ Reglamento del Aprendiz 2024 (Art. 8.19, 9.12, 10, 11 Par. 5 — hallazgos H10-H12) + Manual 2019 §7.1.1 y §15.4 + Reglamento Interno de Centros
>   - **Categoría 3 (TI y seguridad):** ✅ Manual 2019 (dominios 5-10) + Planes de Seguridad 2019/2023 + Plan de Riesgos 2026
>   - **Categoría 4 (Roles):** ✅ Acuerdo 2019 Arts. 10-13 (Comité Institucional, Dirección de Planeación, CISO, custodio)
>   - **Categoría 5 (Auditorías):** ✅ Manual 2019 §8.7 y §14 + Planes MSPI
> - **Pendientes que sí requieren acceso interno:** texto de DO-pol0006 en CompromISO, contrato con la empresa de vigilancia (checklist §11 en doc. 05), verificación RNBD ante la SIC
>
> El resto de este documento se conserva como registro metodológico de qué se buscó y por qué.

---

## 📋 Introducción

Para completar la investigación de cumplimiento legal, se requiere **mapear cómo SENA ya regula internamente** los temas de:

- Protección de datos personales
- Seguridad informática
- Gestión de información
- Protección de menores de edad
- Responsabilidades de TI y administración

Estos documentos permitirán demostrar que SmartCSET **NO es un cambio de políticas**, sino la **implementación técnica de políticas que SENA ya tiene**.

---

## 🔍 Documentos SENA Esperados (Por Investigar)

### CATEGORÍA 1: Políticas de Protección de Datos

#### **DO-pol0006** (Mencionado por usuario)

**Código:** DO-pol0006 (asumido: Política de Protección de Datos)
**Propósito esperado:** Definir cómo SENA debe proteger datos de personas
**Relevancia:** CRÍTICA

**Qué buscar:**

- [ ] Quién es responsable del tratamiento de datos en SENA
- [ ] Qué tipos de datos se recopilan (personas, menores, académicos)
- [ ] Cómo debe almacenarse información (geografía, servidor)
- [ ] Requisitos de auditoría (quién accede, cuándo)
- [ ] Consentimiento de menores (ley de protección de menores)
- [ ] Derechos de titulares (acceso, supresión, rectificación)
- [ ] Plazo de respuesta a solicitudes (máximo 10 días por Ley 1581)
- [ ] Delegación a terceros (si está permitida y bajo qué condiciones)

**Mapeo a SmartCSET:**

- ✅ SmartCSET **implementa** lo que DO-pol0006 **ordena**

---

#### **DO-pol XXXX** (Política de Seguridad de la Información — MSPI)

**Código:** TBD (buscar referencia a MSPI o seguridad informática)
**Propósito esperado:** Alinear SENA con MSPI obligatorio (MinTIC)
**Relevancia:** CRÍTICA

**Qué buscar:**

- [ ] Definición de SENA como entidad sujeta a MSPI
- [ ] Responsabilidades de áreas de TI
- [ ] Auditoría de sistemas de información
- [ ] Gestión de incidentes de seguridad
- [ ] Clasificación de datos por sensibilidad
- [ ] Cifrado obligatorio (datos en tránsito y reposo)
- [ ] Trazabilidad de accesos (logs)
- [ ] Control de cambios en sistemas críticos

**Mapeo a SmartCSET:**

- ✅ SmartCSET **cumple** requisitos MSPI que SENA ya debe tener

---

### CATEGORÍA 2: Regulación de Datos de Menores de Edad

#### **DO-pol XXXX** (Protección de Menores — Derecho a la Infancia)

**Código:** TBD (buscar: ESCNNA, protección menores, ICBF)
**Propósito esperado:** Cumplir normativa de protección de menores en espacios educativos
**Relevancia:** CRÍTICA

**Qué buscar:**

- [ ] Consentimiento informado de padres/tutores (obligatorio <18 años)
- [ ] Autorización para recopilar biometría (cédula, foto)
- [ ] Restricciones en uso de datos de menores
- [ ] Retención de datos post-educación
- [ ] Procedimiento de "derecho al olvido" para menores
- [ ] Responsable de cumplimiento en SENA (departamento/persona)
- [ ] Cómo se verifica cumplimiento (auditoría interna)

**Mapeo a SmartCSET:**

- ✅ SmartCSET **integra** workflow de consentimiento de menores
- ✅ SmartCSET **audita** quién accede datos de menores

---

#### **DO-pol XXXX** (Política de Portería / Acceso a Sedes)

**Código:** TBD (buscar: portería, control de acceso, registro de personas)
**Propósito esperado:** Regular cómo portería debe registrar ingreso/salida
**Relevancia:** ALTA

**Qué buscar:**

- [ ] Quién autoriza recopilación de datos en portería
- [ ] Qué datos pueden recolectarse (documento, foto, datos de contacto)
- [ ] Cómo se almacenan datos de ingreso/salida
- [ ] Plazo de retención (¿cuánto tiempo guardar registros?)
- [ ] Quién tiene acceso a registros de portería
- [ ] Auditoría de accesos a datos de portería
- [ ] Procedimiento para solicitud "derecho al olvido" (ej. visitante pide eliminar su registro)

**Mapeo a SmartCSET:**

- ✅ SmartCSET **formaliza** proceso de portería dentro de marco legal

---

### CATEGORÍA 3: Responsabilidades de TI y Seguridad

#### **DO-pol XXXX** (Política de Seguridad Física y Lógica)

**Código:** TBD (buscar: seguridad, TI, servidores, backup)
**Propósito esperado:** Definir responsabilidades de Oficina TI
**Relevancia:** MEDIA

**Qué buscar:**

- [ ] Ubicación física de servidores (¿en Colombia?)
- [ ] Responsable de seguridad de bases de datos
- [ ] Requisitos de cifrado para datos sensibles
- [ ] Procedimiento de backup y recuperación
- [ ] Gestión de cambios en sistemas críticos
- [ ] Auditoría de accesos a infraestructura
- [ ] Responsable de cumplimiento MSPI

**Mapeo a SmartCSET:**

- ✅ SmartCSET **requiere** apoyo de TI (E8 — hardening de red)

---

#### **DO-pol XXXX** (Gestión de Cambios / SDLC)

**Código:** TBD (buscar: cambios en sistemas, desarrollo, deploy)
**Propósito esperado:** Formalizar cómo se hacen cambios en sistemas críticos
**Relevancia:** MEDIA

**Qué buscar:**

- [ ] Quién autoriza cambios en sistemas de datos personales
- [ ] Proceso de prueba antes de deploy
- [ ] Rollback en caso de fallo
- [ ] Testing de seguridad obligatorio
- [ ] Auditoría de cambios
- [ ] Responsable de validación

**Mapeo a SmartCSET:**

- ✅ SmartCSET **implementa** checklist SDLC seguro (E10)

---

### CATEGORÍA 4: Responsabilidades y Roles

#### **DO-org XXXX** (Designación de Roles de Seguridad)

**Código:** TBD (buscar: RSSI, responsables, custodios de datos)
**Propósito esperado:** Definir quién es responsable de qué en seguridad
**Relevancia:** ALTA

**Qué buscar:**

- [ ] ¿Quién es el RSSI (Responsable de Seguridad de la Información)?
- [ ] ¿Quién es custodio de datos de menores?
- [ ] ¿Quién es responsable de auditoría de TI?
- [ ] ¿Quién aprueba políticas de protección de datos?
- [ ] Cadena de escalamiento para incidentes
- [ ] Contacto para solicitudes de acceso/supresión de datos

**Mapeo a SmartCSET:**

- ✅ SmartCSET **clarifica** quién es responsable (SENA, no terceros)

---

#### **DO-org XXXX** (Comité de Seguridad de la Información)

**Código:** TBD (buscar: comité, gobernanza, SGSI)
**Propósito esperado:** Formalizar goberanza de seguridad
**Relevancia:** MEDIA

**Qué buscar:**

- [ ] ¿Existe comité de seguridad en SENA?
- [ ] Quiénes lo integran (Jurídica, TI, Académica)
- [ ] Frecuencia de reuniones
- [ ] Qué decisiones toma
- [ ] Reporta a quién (¿Dirección General?)

**Mapeo a SmartCSET:**

- ✅ SmartCSET **requiere** aprobación de comité

---

### CATEGORÍA 5: Cumplimiento Normativo

#### **DO-pol XXXX** (Auditorías Internas y Externas)

**Código:** TBD (buscar: auditoría, cumplimiento, SIC)
**Propósito esperado:** Definir cómo SENA verifica cumplimiento de normas
**Relevancia:** MEDIA

**Qué buscar:**

- [ ] ¿Audita SENA sus propios sistemas?
- [ ] ¿Auditoría externa anual?
- [ ] ¿Cumplimiento de SIC/MinTIC verificado?
- [ ] Cronograma de auditorías (¿cuándo?)
- [ ] Quién remedia hallazgos de auditoría
- [ ] Cuánto tiempo tiene SENA para corregir (ley da 90 días típicamente)

**Mapeo a SmartCSET:**

- ✅ SmartCSET **proporciona evidencia** para auditoría

---

## 📌 Documentos de Referencia Externa (Ya Identificados)

Estos documentos ya se usaron en la investigación:

| Documento                               | Clasificación  | Ubicación           |
| --------------------------------------- | --------------- | -------------------- |
| Ley 1581/2012                           | Legal Nacional  | Función Pública    |
| Decreto 1377/2013                       | Legal Nacional  | Función Pública    |
| Resolución MinTIC 02277/2025           | Legal Nacional  | MinTIC               |
| Sentencia Corte Constitucional T-260-12 | Legal Nacional  | Corte Constitucional |
| Marco ESCNNA (ICBF)                     | Legal Nacional  | ICBF                 |
| ISO/IEC 27001:2022                      | Estándar Int'l | ISO                  |

---

## 🎯 Plan de Búsqueda

### PASO 1: Localizar Documentos en Repo SENA

- [ ] Buscar en `Documentacion para implementacion de MSPI/` nuevamente
- [ ] Buscar en intranet SENA o portal de políticas
- [ ] Contactar a Oficina Jurídica: "¿Dónde están documentos DO-pol0006, etc.?"
- [ ] Contactar a Oficina TI: "¿Existe política de protección de datos? ¿De seguridad?"

### PASO 2: Mapeo Directo

Para cada política encontrada:

1. Leer el documento completo
2. Identificar requisitos técnicos/organizacionales
3. Mapear a cómo SmartCSET **cumple** esos requisitos
4. Anotar en tabla

### PASO 3: Análisis de Gaps

- ¿Hay políticas que SENA no tiene pero que debería tener? (ej. consentimiento de menores formalizado)
- ¿SmartCSET supera requisitos mínimos legales?
- ¿Qué cambios de política son necesarios además de SmartCSET?

---

## 📊 Tabla de Mapeo (Plantilla)

| Documento SENA | Requisito Clave              | Cumplimiento Pre-SmartCSET | Cumplimiento Post-SmartCSET | Gap                 |
| -------------- | ---------------------------- | -------------------------- | --------------------------- | ------------------- |
| DO-pol0006     | Datos personales en Colombia | ❌                         | ✅                          | Migración de datos |
| DO-pol0006     | Auditoría de accesos        | ❌                         | ✅                          | SIEM logging        |
| DO-pol XXXX    | Consentimiento menores       | ❓                         | ✅                          | UX workflow         |
| DO-pol XXXX    | Derecho al olvido <10 días  | ❌                         | ✅                          | Interfaz gestión   |
| ...            | ...                          | ...                        | ...                         | ...                 |

---

## 🔗 Próximos Pasos

**URGENTE:**

1. **Obtener DO-pol0006** y otros documentos DO-pol-XXXX de SENA
2. **Contactar Oficina Jurídica** para obtener lista completa de políticas
3. **Contactar Oficina TI** para políticas de seguridad/MSPI
4. **Leer y analizar** cada uno
5. **Actualizar investigación** con requisitos específicos SENA
6. **Crear matriz de cumplimiento** SmartCSET vs. políticas SENA

---

## 💡 Por Qué Es Importante

**Actualmente la investigación dice:** "Ley 1581 requiere X, MinTIC requiere Y, SmartCSET cumple."

**Con documentos SENA diremos:** "SENA ya políticó X, SENA ya fue responsabilizado con Y, SmartCSET es la implementación técnica de lo que SENA ya mandató."

**Esto es mucho más fuerte para dirección:** No es "convencer a SENA de hacer algo nuevo", es "SmartCSET es lo que SENA ya dijo que debería hacer".

---

**Documento preparado:** 2026-07-05
**Estado:** ✅ BÚSQUEDA EJECUTADA — resultados en `05_ANALISIS_NORMATIVA_INTERNA_SENA.md`; quedan 3 pendientes de acceso interno (CompromISO, contrato de vigilancia, RNBD)
**Clasificación:** CONFIDENCIAL — USO INTERNO SENA

---

## APÉNDICE A — Preguntas para Obtener Documentos

**Email a Oficina Jurídica SENA:**

```
Asunto: Localización de Políticas Internas SENA — Datos Personales y Seguridad

Estimado equipo,

En el contexto del proyecto SmartCSET (implementación de cumplimiento MSPI), 
necesitamos acceso a las siguientes políticas internas SENA:

1. Política de Protección de Datos Personales (código: DO-pol0006 o similar)
2. Política de Seguridad de la Información / Cumplimiento MSPI
3. Política de Protección de Menores de Edad
4. Política de Control de Acceso a Sedes (Portería)
5. Política de Seguridad Física y Lógica de TI
6. Política de Gestión de Cambios en Sistemas Críticos
7. Designación de Roles de Seguridad (RSSI, custodios)
8. Auditorías Internas y Cumplimiento Normativo

¿Dónde están localizados estos documentos? ¿Código de documento para cada uno?

Agradezco colaboración.
```

---

**Email a Oficina TI SENA:**

```
Asunto: Documentos MSPI y Seguridad Informática

Estimado equipo TI,

En contexto de SmartCSET, necesitamos:

1. Documento que formalice compromiso de SENA con MSPI (Resolución MinTIC 02277/2025)
2. Política de almacenamiento de datos personales (¿en qué servidor? ¿dónde?)
3. Política de auditoría de accesos a sistemas críticos
4. Política de cifrado de datos (en reposo y tránsito)
5. Procedimiento de backup y recuperación

¿Existen estos documentos? ¿Quién es responsable?

Agradezco colaboración.
```
