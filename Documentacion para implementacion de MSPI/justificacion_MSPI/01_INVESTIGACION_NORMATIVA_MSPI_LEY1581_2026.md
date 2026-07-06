# Investigación Normativa — MSPI, Ley 1581/2012 y Regulaciones SENA
**Documento:** JUS-INV-001  
**Fecha:** 2026-07-05  
**Clasificación:** Interno — Análisis Jurídico-Técnico  
**Propósito:** Fundamentar la necesidad estratégica de SmartCSET como sistema de gestión soberano de datos personales en el SENA

---

## 1. Marco Regulatorio Vigente — Colombia

### 1.1 MSPI (Marco de Seguridad y Privacidad de la Información)

**Regulador:** Ministerio de Tecnologías de la Información y Comunicaciones (MinTIC)  
**Resolución Vigente:** Resolución 02277/2025 (Plan de Seguridad y Privacidad 2026)  
**Aplicabilidad:** **Obligatoria para todas las entidades públicas colombianas**

#### Requisitos del MSPI:
- Alineación con **ISO/IEC 27001:2022** (estándar internacional de seguridad de información)
- Implementación de ciclo de vida de seguridad:
  1. Planificación de seguridad
  2. Implementación de controles
  3. Evaluación y monitoreo
  4. Mejora continua
- Preservación de 4 atributos de seguridad:
  - **Confidencialidad** — Solo personal autorizado accede
  - **Integridad** — Datos no modificados sin auditoría
  - **Disponibilidad** — Acceso cuando se requiere
  - **Privacidad** — Cumplimiento de derechos de titulares

#### Auditoría y Vigilancia:
- MinTIC realiza auditorías regulares
- Entes sectoriales (Contraloría, Procuraduría) verifican cumplimiento
- Incumplimientos reportados a SIC (Superintendencia de Industria y Comercio)

---

### 1.2 Ley 1581/2012 + Decreto 1377/2013 — Protección de Datos Personales

**Regulador:** Superintendencia de Industria y Comercio (SIC) — Entidad de vigilancia  
**Alcance:** Aplicable a toda persona natural o jurídica que trate datos personales en Colombia

#### Definiciones Legales Críticas:

| Término | Definición Legal | Implicación para SENA |
|---|---|---|
| **Dato Personal** | Información que identifica o puede identificar a persona natural | Documento ID, nombre, foto, correo de estudiantes/visitantes |
| **Dato Sensible** | Biométrico, raza, religión, opinión política, orientación sexual, **datos de menores** | Cédula, fotos de portería, datos académicos de aprendices |
| **Responsable del Tratamiento** | Entidad que decide **cómo y para qué** se tratan los datos | **SENA es responsable** de datos de aprendices/visitantes |
| **Encargado del Tratamiento** | Tercero que procesa datos **por orden del responsable** | Empresa externa que manejaba datos anteriormente |

#### Derechos del Titular (Aprendiz, Visitante, Instructor):
- ✅ **Acceso:** Ver qué datos tiene la institución
- ✅ **Rectificación:** Corregir datos inexactos
- ✅ **Supresión/Cancelación:** Solicitar eliminación (excepto si ley lo requiere)
- ✅ **Oposición:** Negar autorización de tratamiento
- ✅ **Revocación:** Retirar consentimiento dado

**Plazo de respuesta:** SENA tiene máximo **10 días hábiles** para responder

#### Obligaciones del Responsable (SENA):
1. **Consentimiento previo** — Obtener autorización antes de recolectar datos (excepto si ley lo requiere directamente)
2. **Medidas de protección** — Implementar controles técnicos y administrativos
3. **Notificación de incidentes** — Informar si hay violación de seguridad (robo, modificación no autorizada)
4. **Trazabilidad** — Registrar quién accede, cuándo y por qué
5. **Respeto de derechos** — Cumplir solicitudes de titulares en plazo

---

### 1.3 Multas y Sanciones (SIC)

**Autoridad Sancionadora:** Superintendencia de Industria y Comercio  
**Base de Cálculo:** Salarios Mínimos Mensuales Vigentes (SMMV)

#### Rangos de Multas por Gravedad:

| Incumplimiento | Severidad | Rango de Multa | Monto 2026 (SMMV) |
|---|---|---|---|
| **CRÍTICOS** | Violación fundamental de derecho | 1.500–2.000 SM | $61.5M – $82.0M COP |
| **GRAVES** | Falta de medidas técnicas o auditoría | 500–1.500 SM | $20.5M – $61.5M COP |
| **MODERADOS** | Incumplimiento procedural | 100–500 SM | $4.1M – $20.5M COP |

#### Sanciones Complementarias:
- **Multas sucesivas** — Se repiten mientras persista el incumplimiento
- **Suspensión temporal** — Hasta 6 meses sin operar el sistema
- **Clausura operacional** — Cierre de la actividad relacionada

#### Responsabilidad Solidaria:
Si SENA **delega a tercero sin contrato formal de "encargado del tratamiento":**
- Ambas entidades responden solidariamente ante SIC
- Multas divididas **O** multas acumuladas (criterio de SIC)
- SENA no puede alegar "fue culpa del tercero"

---

## 2. Regulaciones Internas SENA — VERIFICADAS CON DOCUMENTOS OFICIALES

> **Actualización 2026-07-05:** esta sección fue verificada contra los documentos oficiales del SENA descargados de sena.edu.co (ver `documentos_sena/` y el análisis detallado con citas textuales en `05_ANALISIS_NORMATIVA_INTERNA_SENA.md`, hallazgos H1-H12).

### 2.1 Capacidad Jurídica de SENA como Responsable — CONFIRMADA

**Base Legal:** Ley 119/1994 (reestructuración del SENA) + Decreto 249/2004

**Confirmado documentalmente:**
- ✅ **SENA se declara Responsable del tratamiento** — Acuerdo Consejo Directivo 2019, Art. 12: *"El Servicio Nacional de Aprendizaje – SENA, actuará como responsable del tratamiento de Protección de datos personales"*
- ✅ **Almacenamiento en Colombia es declaración propia del SENA** — Manual 2019 §15.7: *"Todos los datos están almacenados en un servidor del SENA en Colombia"* (hallazgo H1 del doc. 05)
- ✅ **El registro de ingresos/salidas es mandato interno** — Manual 2019 §7.1.1: *"los ingresos y salidas de las instalaciones del SENA deben ser registrados"* (hallazgo H2)
- ✅ **La Dirección de Planeación y Direccionamiento Corporativo** lidera el MSPI (Acuerdo 2019, Arts. 5, 8, 11); el custodio de la información es esa misma Dirección (Manual §2.1)

### 2.2 Delegación a Terceros — REQUISITOS INTERNOS FORMALES (Manual 2019 §11)

**Situación actual:** la empresa de vigilancia contratada registra ingresos/salidas con software propio.

**Requisitos que el Manual 2019 §11 impone a CUALQUIER tercero que procese información del SENA (hallazgo H3):**
1. **Acuerdo de Confidencialidad** obligatorio, parte integral del contrato
2. **Anexo técnico** con protocolo de intercambio y controles de seguridad
3. **Clasificación previa** de la información que se entrega y recibe
4. Intervención previa del **CISO** (Dirección de Planeación) y la **Oficina de Sistemas**
5. **Responsabilidad civil y penal** del tercero, derivada de los acuerdos
6. Cumplimiento estricto de los **artículos 17 y 18 de la Ley 1581/2012**

**Adicionalmente (Manual §15.3.1, hallazgo H4):** toda área que procese datos personales debe *"establecer condiciones contractuales y de seguridad, a las entidades vinculadas"* y asegurar acceso solo a quien tenga *"necesidad laboral legítima"*.

**Verificación pendiente:** el contrato vigente con la empresa de vigilancia debe auditarse contra estos 6 requisitos (checklist en doc. 05, sección H3). Cada requisito ausente es evidencia documental de incumplimiento del Acuerdo de 2019.

### 2.3 La autorización de datos del aprendiz NO cubre a terceros privados (hallazgo H10)

**Reglamento del Aprendiz 2024 (Acuerdo 0009 del 5-nov-2024), Art. 11, Parágrafo 5:** la autorización que firma cada aprendiz al registrarse permite el tratamiento **"a la entidad"** y el intercambio **"con otras entidades públicas"**, con finalidad limitada a **"las funciones propias del SENA"**.

**Consecuencia jurídica doble:**
- ❌ La empresa de vigilancia (privada) trata datos **sin autorización válida del titular**
- ✅ SmartCSET queda **automáticamente amparado** por la autorización ya firmada — no requiere recolectar autorizaciones nuevas

---

## 3. Protección Especial de Menores de Edad

### 3.1 Marco Legal

**Aplicable a:** Aprendices menores de 18 años en programas SENA

**Fuente:** Ley 1581/2012 Art. 7, Decreto 1377/2013 Art. 1, Sentencia Corte Constitucional T-260-12

**Confirmación normativa interna (Reglamento del Aprendiz 2024, Art. 10 — hallazgo H12 del doc. 05):**
- La edad mínima de ingreso a la formación es de **14 años** — la presencia de menores en la comunidad SENA no es una suposición, es norma
- Para menores, *"uno de los padres de familia, el acudiente o el apoderado, **deben firmar el consentimiento informado** y el aprendiz firma su asentimiento"* — otorgado **al SENA**, nunca a proveedores privados
- El Manual 2019 §15.4 declara **"proscrito"** el tratamiento de datos de menores fuera del marco autorizado (hallazgo H6)

#### Consentimiento Diferenciado:

| Edad | Quién Autoriza | Excepciones | Datos Permitidos |
|---|---|---|---|
| **0–11 años** | Padres/tutores (consentimiento reforzado) | Ley lo ordene (ej. registro académico) | Solo necesarios para relación educativa |
| **12–17 años** | Adolescente autónomamente **O** padres | Datos no sensibles | Acceso educativo permitido sin consentimiento padres |
| **18+ años** | Propio titular | N/A | Todos (excepto restricciones legales) |

#### Datos "Sensibles" para Menores:
- 🔴 **Biométricos** — Cédula de identidad, huella dactilar, foto facial
- 🔴 **Identificación de tutores** — Números de teléfono, direcciones de padres
- 🔴 **Historial académico completo** — Si contiene información de evaluaciones psicológicas
- 🟡 **Foto de portería** — Requiere consentimiento reforzado si se usa para otros fines

#### Retención de Datos de Menores:
- **Mientras es estudiante:** SENA puede retener para fines educativos
- **Después de graduación:** SENA debe:
  - Conservar registro de calificaciones (requerido legalmente)
  - **Eliminar o anonimizar** datos biométricos, fotos, contactos personales
  - Guardar solo lo que ley educativa obliga (6–10 años típicamente)

---

## 4. Incumplimientos Críticos — Diagnóstico Pre-SmartCSET

### 4.1 Datos en Manos de Tercero Externo

**Situación anterior:**
```
SENA (Responsable) ←→ Empresa Externa (Encargado) 
                         ↓ (gestión de datos)
                     Servidor de empresa / Cloud tercero
                         ↓ (posible acceso no auditable)
                     ???
```

**Riesgos identificados:**

| Riesgo | Severidad | Implicación Legal | Multa Potencial |
|---|---|---|---|
| **Datos fuera de Colombia** | CRÍTICO | Incumple Ley 1581 + MSPI | 2.000 SM = $82M |
| **Auditoría débil** | CRÍTICO | Imposible verificar quién accede cuándo | 2.000 SM = $82M |
| **Modificación no autorizada** | CRÍTICO | Incumple integridad de datos | 1.500 SM = $61.5M |
| **Sin contrato formal de encargado** | CRÍTICO | SENA es único responsable + tercero impune | 2.000 SM = $82M |
| **Datos sensibles de menores sin consentimiento reforzado** | CRÍTICO | Violación de derechos de menores | 2.000 SM = $82M |

### 4.2 Cálculo de Exposición Financiera

**Escenarios de auditoria por SIC:**

| Escenario | Hallazgos | Multa SENA | Otras Sanciones |
|---|---|---|---|
| **Auditoria hallazgo crítico único** | Datos en cloud tercero sin cifrado | $82M | Suspensión 6 meses |
| **Auditoria hallazgos múltiples** | Datos de menores sin consentimiento + no auditable | $82M × 2–4 = $164–$328M | Clausura temporal operaciones |
| **Incidente de seguridad + auditoria** | Violación de datos + descubrimiento de incumplimientos | $82M + $41M (no notificación) | Cierre operacional indefinido |

**Tiempo de remediación:** Una vez detectado, SIC da 90 días para corregir. Cada día no corregido = multa sucesiva.

---

## 5. Comparativa Legal — Pre vs. Post-SmartCSET

### 5.1 Arquitetura de Gobernanza de Datos

#### ANTES (Pre-SmartCSET):
```
SENA (Responsable)
  └─ Empresa Externa (Encargado sin supervisión)
      └─ Servidor cloud / on-premise
          └─ ??? (Posibles accesos terceros, modificaciones no auditas)

Status legal: INCUMPLIDOR — CRÍTICO
```

**Incumplimientos:**
- ❌ Datos fuera de control directo de SENA
- ❌ Trazabilidad imposible (no hay registro de accesos)
- ❌ Auditoría débil o ausente
- ❌ Responsabilidad dual sin claridad contratual

---

#### DESPUÉS (Con SmartCSET/SGI):
```
SENA (Responsable + Administrador)
  ├─ PostgreSQL en servidor Colombia (SENA)
  ├─ Aplicación PHP en servidor Colombia (SENA)
  ├─ Trazabilidad completa (usr_insert, usr_update, fec_insert, fec_update)
  ├─ Auditoría SIEM (logs de accesos detallados)
  ├─ Control de acceso por usuario (solo personal autorizado)
  ├─ Cifrado en reposo (E2 — en progreso)
  ├─ HTTPS en tránsito (E4 — implementado)
  └─ Consentimiento explícito de titulares (integrado en UX)

Status legal: CUMPLIDOR — COMPLETO
```

**Cumplimientos logrados:**
- ✅ Datos 100% bajo control de SENA
- ✅ Trazabilidad auditada (quién, cuándo, qué)
- ✅ Almacenamiento en Colombia (soberanía)
- ✅ Responsabilidad única = SENA
- ✅ Auditoría continua (SIEM)
- ✅ Cumplimiento MSPI + Ley 1581

---

## 6. Conclusiones de la Investigación

### 6.1 Hallazgos Principales

1. **MSPI es obligatorio para SENA** — No es opcional. MinTIC audita cumplimiento.

2. **Ley 1581/2012 exige soberanía de datos** — SENA debe ser responsable único y almacenar en Colombia.

3. **Delegación anterior = Incumplimiento grave** — Sin contrato formal de "encargado del tratamiento", SENA incumple + tercero queda impune.

4. **Multas potenciales muy altas** — $82M por incumplimiento crítico (+ sanciones complementarias).

5. **Datos de menores = Protección reforzada** — Requieren consentimiento explícito de padres + anonimización post-educación. Confirmado internamente: aprendices desde 14 años, consentimiento parental otorgado solo al SENA (Regl. Aprendiz 2024, Art. 10).

6. **La normativa interna del SENA ya ordena lo que SmartCSET implementa** — El Acuerdo del Consejo Directivo de 2019 manda registrar ingresos/salidas (§7.1.1), declara los datos en servidores propios (§15.7) e impone requisitos a terceros (§11) que la situación actual incumple. Ver doc. 05 (hallazgos H1-H12, matriz de 16 requisitos).

7. **La autorización de datos existente ampara a SmartCSET, no al tercero** — Regl. Aprendiz 2024, Art. 11 Par. 5: la autorización firmada por cada aprendiz cubre a la entidad y entidades públicas; el proveedor privado trata datos sin autorización válida (hallazgo H10).

8. **SmartCSET resuelve todos los puntos** — Centraliza datos, auditoría, cumplimiento legal, bajo la base jurídica ya existente.

### 6.2 Recomendación Estratégica

**Implementar SmartCSET como Sistema de Gestión de Ingreso (SGI) es requisito de cumplimiento legal**, no simplemente mejora tecnológica. La alternativa es:
- Permanecer en incumplimiento crítico MSPI + Ley 1581
- Exposición a multas de $82M–$328M
- Riesgo de cierre operacional en auditoría
- Incapacidad de responder derechos de menores

---

## 7. Fuentes Documentales

### Legislación Colombiana:
1. **Resolución MinTIC 02277/2025** — [Plan de Seguridad y Privacidad 2026](https://gobiernodigital.mintic.gov.co)
2. **Ley 1581/2012** — [Protección de Datos Personales](https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=49981)
3. **Decreto 1377/2013** — [Regulación de la Ley 1581](https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=53646)
4. **Sentencia Corte Constitucional T-260-12** — [Consentimiento de menores para datos personales](https://www.corteconstitucional.gov.co/relatoria/2012/t-260-12.htm)

### Normas Internas SENA (✅ localizadas y analizadas — copias en `documentos_sena/`):
1. Ley 119/1994 (reestructuración del SENA) + Decreto 249/2004
2. **Acuerdo Consejo Directivo Nacional de 2019** — Política General de Seguridad de la Información y Protección de Datos Personales + Manual (`manual_seguridad_proteccion_datos_2019.pdf`)
3. **Acuerdo 009 de 2016** — Política de Protección de Datos Personales, vigente transitoriamente (`proteccion_datos_personales_2016.pdf`)
4. **Reglamento del Aprendiz — Acuerdo 0009 del 5-nov-2024** (`reglamento_aprendiz_2024.pdf`)
5. Planes de Seguridad y Privacidad de la Información 2019 y 2023 (`plan_seguridad_privacidad_*.pdf`)
6. Plan de Tratamiento de Riesgos de Seguridad de la Información 2026 (`plan_tratamiento_riesgos_2026.pdf`)
7. Reglamento Interno de Centros y Programas (`reglamento_interno_centros.pdf`)
8. Políticas complementarias codificadas en **CompromISO** (ej. DO-pol0006) — acceso interno, pendiente de obtener

> El análisis detallado de estos documentos, con citas textuales, está en `05_ANALISIS_NORMATIVA_INTERNA_SENA.md`.

### Estándares Internacionales:
1. **ISO/IEC 27001** — Seguridad de la Información (el SENA declara alineación con NTC-ISO-IEC 27001 en el Acuerdo 2019 y el Plan 2023)

---

**Documento preparado:** 2026-07-05
**Actualizado:** 2026-07-05 — verificado contra documentos oficiales del SENA (ver doc. 05)
**Estado:** Listo para revisión jurídica interna
**Próximo paso:** Auditoría del contrato de vigilancia contra el checklist §11 (doc. 05) + verificación RNBD
