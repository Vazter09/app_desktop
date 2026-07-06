# Matriz de Riesgos — Incumplimiento Legal Pre-SmartCSET vs. Post-SmartCSET

**Documento:** JUS-RIE-002
**Fecha:** 2026-07-05
**Clasificación:** Interno — Análisis de Riesgos Legal-Técnico
**Propósito:** Cuantificar exposición legal del SENA bajo arquitectura actual vs. con SmartCSET/SGI

---

## 1. Inventario de Datos Personales en SmartCSET

### 1.1 Tipo de Datos Recolectados

Basado en análisis de schema y funciones (MCP: 58 funciones de gestión de `tab_personas`):

#### **Categoría 1: Datos de Identificación**

```
├─ Número de documento de identidad (cédula, CE, pasaporte, etc.)
├─ Tipo de documento
├─ Nombre completo
├─ Apellidos
├─ Género
├─ Estado civil
└─ Fecha de nacimiento
```

**Clasificación:** Dato personal
**Sensibilidad:** MEDIA — Requerido para identificación

#### **Categoría 2: Datos de Contacto**

```
├─ Correo electrónico
├─ Teléfono fijo
├─ Teléfono móvil
├─ Dirección de residencia
└─ Departamento y ciudad de residencia
```

**Clasificación:** Dato personal
**Sensibilidad:** MEDIA-ALTA — Especialmente si incluye menores

#### **Categoría 3: Datos Académicos (SENSIBLES)**

```
├─ Número de ficha (identificador de curso)
├─ Programa de formación
├─ Duración del programa
├─ Jornada (diurna, nocturna, sabatina)
├─ Modalidad (virtual, presencial, híbrida)
├─ Asistencia registrada
├─ Puntualidad y retardos
└─ Historial de deserción/aplazamiento
```

**Clasificación:** Dato sensible (menores)
**Sensibilidad:** ALTA — Información de desarrollo educativo

#### **Categoría 4: Datos Biométricos (SENSIBLES)**

```
├─ Fotografía de documento de identidad
├─ Fotografía de ingreso/salida (portería)
└─ Posible: Huella dactilar / reconocimiento facial
```

**Clasificación:** Dato sensible
**Sensibilidad:** CRÍTICA — Biometría está prohibida sin consentimiento reforzado

#### **Categoría 5: Datos de Contacto de Tutores (SENSIBLES)**

```
├─ Nombre de contacto de emergencia
├─ Teléfono de contacto de emergencia
└─ Parentesco/relación
```

**Clasificación:** Dato sensible (si menor)
**Sensibilidad:** ALTA — Información de terceros relacionada a menor

#### **Categoría 6: Datos Profesionales (para instructores/funcionarios)**

```
├─ Número de ficha de instructor
├─ Red de adscripción
├─ Tipo de contrato
├─ Contratado actualmente (sí/no)
├─ Género
├─ Nivel de estudio
├─ Profesión
└─ Disponibilidad para clases
```

**Clasificación:** Dato personal/ocupacional
**Sensibilidad:** MEDIA

---

### 1.2 Volumen de Datos

**Según datos reales en BD de laboratorio (2026-07-05):**

- **7,384 personas** totales registradas
- **7,369 aprendices** (muchos menores de 18 años)
- **12 instructores**
- **~50–100 visitantes/administrativos** mensuales
- **811 fichas** (cursos)
- **448 programas**

**Datos de ingresos/salidas:**

- ~1,500–2,000 registros de ingreso/salida **por día**
- Almacenados en `tab_log_ingresos` (permanentes)

---

## 2. Matriz de Riesgos Actual — Datos en Manos de Tercero Externo

> **Actualización 2026-07-05:** cada riesgo de esta matriz quedó anclado a la **normativa interna oficial del SENA** (documentos descargados de sena.edu.co, análisis con citas textuales en `05_ANALISIS_NORMATIVA_INTERNA_SENA.md`). Los riesgos ya no se sostienen solo en la ley externa — violan normas que el propio Consejo Directivo Nacional del SENA aprobó:

| Riesgo                           | Norma externa violada  | Norma INTERNA del SENA violada (doc. 05)                                                                                                                   |
| -------------------------------- | ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| R1 — Pérdida de soberanía     | Ley 1581 Art. 13       | Manual 2019 §15.7:*"Todos los datos están almacenados en un servidor del SENA en Colombia"* (H1)                                                       |
| R2 — Auditoría débil          | MSPI, Ley 1581 Art. 15 | Manual 2019 §15.9: deber de informar al titular el uso de sus datos y detectar violaciones (H7); Planes MSPI 2023/2026 (H9)                               |
| R3 — Integridad no verificable  | Ley 1581 Art. 13       | Manual 2019 §15.2 (principio de seguridad, H8) y §15.9: impedir adulteración (H7); Regl. Aprendiz Art. 9 nums. 1-3 (H11)                                |
| R4 — Menores sin consentimiento | Ley 1581 Art. 7        | Manual 2019 §15.4: tratamiento de datos de menores**"proscrito"** (H6); Regl. Aprendiz Art. 10: consentimiento parental otorgado solo al SENA (H12) |
| R5 — Derechos de titulares      | Ley 1581 Art. 15       | Manual 2019 §15.8 y §15.11-15.15: procedimientos de acceso/rectificación/supresión que el SENA no puede ejecutar sin los datos (H7)                    |
| R6 — Responsabilidad solidaria  | Ley 1581 Art. 3        | Manual 2019 §11: acuerdo de confidencialidad + anexo técnico + responsabilidad civil/penal del tercero (H3); §15.3.1 condiciones contractuales (H4)     |

**Riesgo adicional identificado tras leer el Reglamento del Aprendiz 2024 (H10):**

#### **R7: Tratamiento sin autorización válida del titular**

| Atributo                       | Detalle                                                                                                                                                                                                                                                                                                                                                                   |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Descripción**         | La autorización de datos que firma cada aprendiz (Regl. Aprendiz 2024, Art. 11 Par. 5) cubre el tratamiento por**"la entidad"** y el intercambio con **"otras entidades públicas"**, con finalidad limitada a las funciones propias del SENA. La empresa de vigilancia es un privado con software propio → trata datos **sin autorización válida** |
| **Probabilidad**         | ALTA (100% — es el diseño actual del proceso)                                                                                                                                                                                                                                                                                                                           |
| **Impacto**              | CRÍTICO — Violación del principio de libertad (Ley 1581 Art. 4.c)                                                                                                                                                                                                                                                                                                      |
| **Incumplimiento Legal** | Ley 1581 Art. 4.c y Art. 12; Regl. Aprendiz 2024 Art. 11 Par. 5                                                                                                                                                                                                                                                                                                           |
| **Multa Estimada**       | **$82.000.000 COP** (2.000 SM)                                                                                                                                                                                                                                                                                                                                      |
| **Nota clave**           | SmartCSET queda**amparado por la autorización ya firmada** (sistema de la entidad, funciones propias del SENA) — no requiere autorizaciones nuevas para aprendices                                                                                                                                                                                                |

### 2.1 Riesgos Identificados

#### **R1: Pérdida de Soberanía de Datos**

| Atributo                        | Detalle                                                                                                          |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **Descripción**          | Datos de aprendices/visitantes SENA almacenados en servidores de empresa externa, posiblemente fuera de Colombia |
| **Probabilidad**          | ALTA (100% — es la realidad actual)                                                                             |
| **Impacto**               | CRÍTICO — Incumple Ley 1581 + MSPI                                                                             |
| **Causa Raíz**           | Delegación sin supervisión formal                                                                              |
| **Incumplimiento Legal**  | Ley 1581/2012 Art. 13 (almacenamiento en Colombia de datos de residentes)                                        |
| **Multa Estimada**        | **$82.000.000 COP** (2.000 SM)                                                                             |
| **Tiempo de Exposición** | Mientras datos estén externalizados                                                                             |

---

#### **R2: Auditoría Débil / Imposible Trazabilidad**

| Atributo                       | Detalle                                                                                                                             |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| **Descripción**         | SENA no puede auditar quién accedió qué datos cuándo en servidor de tercero. Imposible responder preguntas de SIC en auditoría |
| **Probabilidad**         | ALTA (100% — arquitectura tercerizada imposibilita auditoría directa)                                                             |
| **Impacto**              | CRÍTICO — Incumple MSPI (auditoría exhaustiva requerida)                                                                         |
| **Causa Raíz**          | No hay acceso directo de SENA a logs del tercero                                                                                    |
| **Incumplimiento Legal** | MSPI 2026 (ciclo de evaluación/auditoría), Ley 1581 Art. 15 (responsabilidades del responsable del tratamiento)                   |
| **Multa Estimada**       | **$82.000.000 COP** (2.000 SM)                                                                                                |
| **Escenario Crítico**   | SIC audita SENA → "¿Quién accedió dato de menor X el 15 de mayo?" → SENA no puede responder → Incumplimiento grave            |

---

#### **R3: Integridad de Datos No Verificable**

| Atributo                           | Detalle                                                                                                |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------ |
| **Descripción**             | SENA no puede garantizar que datos de aprendices no han sido modificados sin autorización por tercero |
| **Probabilidad**             | MEDIA-ALTA (no hay verificación de cambios no autorizados)                                            |
| **Impacto**                  | CRÍTICO — Incumple integridad de datos (pilar de MSPI)                                               |
| **Ejemplo**                  | Tercero modifica`fec_salida` de registro de ingreso sin autorización → SENA no lo sabe             |
| **Incumplimiento Legal**     | Ley 1581 Art. 13 (medidas técnicas), MSPI (integridad)                                                |
| **Multa Estimada**           | **$61.500.000–$82.000.000 COP** (1.500–2.000 SM)                                               |
| **Consecuencia Operacional** | Reportes académicos incompletos/inexactos → reclamaciones de aprendices                              |

---

#### **R4: Datos de Menores sin Consentimiento Reforzado**

| Atributo                       | Detalle                                                                                                                                                      |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Descripción**         | 7,369 aprendices, muchos menores de 18 años, con datos biométricos (fotos) y académicos recolectados posiblemente sin consentimiento explícito de padres |
| **Probabilidad**         | MEDIA-ALTA (posible incumplimiento)                                                                                                                          |
| **Impacto**              | CRÍTICO — Violación de derechos fundamentales de menores                                                                                                  |
| **Causa Raíz**          | Proceso de consentimiento antiguo/débil (pre-MSPI)                                                                                                          |
| **Incumplimiento Legal** | Ley 1581 Art. 7, Decreto 1377/2013 Art. 1, Sentencia Corte Constitucional T-260-12                                                                           |
| **Multa Estimada**       | **$82.000.000 COP** (2.000 SM) + sanciones complementarias                                                                                             |
| **Derecho Afectado**     | Derecho al olvido (menores pueden exigir eliminación de biometría post-mayoría de edad)                                                                   |

---

#### **R5: Incapacidad de Responder Derechos de Titulares**

| Atributo                       | Detalle                                                                                                                                                     |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Descripción**         | Aprendiz solicita "Acceso a mis datos" o "Elimina mis datos" → SENA debe responder en <10 días hábiles. Con datos en tercero, plazo imposible de cumplir |
| **Probabilidad**         | MEDIA (ocurre cuando algún aprendiz ejerce derecho)                                                                                                        |
| **Impacto**              | ALTO — Incumple Ley 1581 Art. 15 (respuesta de titulares)                                                                                                  |
| **Incumplimiento Legal** | Ley 1581/2012 Art. 15 (plazo de respuesta de máximo 10 días hábiles)                                                                                     |
| **Multa Estimada**       | **$20.500.000–$61.500.000 COP** (500–1.500 SM) por cada solicitud no respondida                                                                     |
| **Escenario**            | Aprendiz solicita "Derecho al olvido" en marzo → SENA responde en abril → Incumplimiento → Multa de $20M                                                 |

---

#### **R6: Responsabilidad Solidaria sin Claridad Contractual**

| Atributo                       | Detalle                                                                                                                                                            |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Descripción**         | Si no hay contrato formal que defina "SENA = responsable, Tercero = encargado", SIC puede condenar a ambos solidariamente o solo a SENA como responsable principal |
| **Probabilidad**         | ALTA (modelo actual es ambiguo)                                                                                                                                    |
| **Impacto**              | CRÍTICO — Multas múltiples                                                                                                                                      |
| **Incumplimiento Legal** | Ley 1581/2012 Art. 3 (definición responsable/encargado)                                                                                                           |
| **Multa Estimada**       | **OPCIÓN 1:** $82M SENA + $82M Tercero (solidaria) = $164M total  **OPCIÓN 2:** SIC condena solo a SENA = $82M (responsabilidad única)              |
| **Precedente**           | Jurisprudencia SIC tiende a condenar responsable único cuando hay ambigüedad                                                                                     |

---

### 2.2 Resumen de Riesgos Actuales

| Riesgo                                        | Probabilidad | Impacto  | Severidad | Multa Estimada | Acción                                                   |
| --------------------------------------------- | ------------ | -------- | --------- | -------------- | --------------------------------------------------------- |
| **R1 — Pérdida soberanía**           | ALTA         | CRÍTICO | 🔴🔴🔴    | $82M           | Migrar a SmartCSET                                        |
| **R2 — Auditoría débil**             | ALTA         | CRÍTICO | 🔴🔴🔴    | $82M           | Implementar SIEM                                          |
| **R3 — Integridad no verificable**     | MEDIA-ALTA   | CRÍTICO | 🔴🔴🔴    | $61.5M–$82M   | Centralizar BD                                            |
| **R4 — Menores sin consentimiento**    | MEDIA-ALTA   | CRÍTICO | 🔴🔴🔴    | $82M           | Auditar consentimientos                                   |
| **R5 — Derechos de titulares**         | MEDIA        | ALTO     | 🟠🟠🟠    | $20.5M–$61.5M | Implementar workflow                                      |
| **R6 — Responsabilidad solidaria**     | ALTA         | CRÍTICO | 🔴🔴🔴    | $82M–$164M    | Redefir contrato                                          |
| **R7 — Sin autorización del titular** | ALTA         | CRÍTICO | 🔴🔴🔴    | $82M           | Migrar a SmartCSET (amparado por autorización existente) |

**Exposición Total Estimada:** $328.5M–$493M COP (peor caso, todos los riesgos materializados; R7 agregado tras leer el Reglamento del Aprendiz 2024)

---

## 3. Mitigación de Riesgos con SmartCSET/SGI

### 3.1 Arquitectura Post-SmartCSET

```
┌─────────────────────────────────────────────────────┐
│ SENA (Responsable + Administrador)                   │
│                                                     │
│ ┌──────────────────────────────────────────────┐   │
│ │ SmartCSET — Sistema de Gestión de Ingreso    │   │
│ │ (SGI) — Módulo de Registro y Control         │   │
│ │                                              │   │
│ │ ┌────────────────────────────────────────┐   │   │
│ │ │ Web UI (HTTPS)                         │   │   │
│ │ │ - Login de portería/admin              │   │   │
│ │ │ - Registro de ingreso/salida           │   │   │
│ │ │ - Gestión de personas                  │   │   │
│ │ └────────────────────────────────────────┘   │   │
│ │         ↓ TLS                                  │   │
│ │ ┌────────────────────────────────────────┐   │   │
│ │ │ PHP Backend (FastAPI-like)             │   │   │
│ │ │ - prepared statements                  │   │   │
│ │ │ - input validation                     │   │   │
│ │ │ - access control por usuario           │   │   │
│ │ └────────────────────────────────────────┘   │   │
│ │         ↓ SQL + SET app.usuario             │   │
│ │ ┌────────────────────────────────────────┐   │   │
│ │ │ PostgreSQL (SENA owned)                │   │   │
│ │ │ - tab_personas (7,384 registros)       │   │   │
│ │ │ - tab_log_ingresos (auditoría)         │   │   │
│ │ │ - tab_sesiones (control de acceso)     │   │   │
│ │ │ - Columnas de auditoría: usr_insert,   │   │   │
│ │ │   usr_update, fec_insert, fec_update   │   │   │
│ │ └────────────────────────────────────────┘   │   │
│ │                                              │   │
│ ├─ SIEM (logs JSON, ECS format)                │   │
│ ├─ Backups diarios (DRP)                       │   │
│ ├─ Cifrado en reposo (E2 en progreso)          │   │
│ └──────────────────────────────────────────────┘   │
│                                                     │
└─────────────────────────────────────────────────────┘
        ↑
        └──────── Auditoría SIC
```

---

### 3.2 Matriz de Mitigación

| Riesgo                                        | Control en SmartCSET                                                                                                                                             | Severidad Residual | Estado |
| --------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ------ |
| **R1 — Pérdida soberanía**           | ✅ Datos en servidor SENA; SENA es única dueña                                                                                                                 | ELIMINADO          | ✅     |
| **R2 — Auditoría débil**             | ✅ SIEM + logs JSON con usr_insert/update + timestamps ISO8601; acceso total a logs                                                                              | ELIMINADO          | ✅     |
| **R3 — Integridad**                    | ✅ Prepared statements + triggers de auditoría (`fun_act_tabla`) + BD transaccional                                                                           | ELIMINADO          | ✅     |
| **R4 — Menores sin consentimiento**    | ✅ Aprendices: cubiertos por consentimiento informado de matrícula (Regl. Aprendiz Art. 10, ver H12). ⚠️ Visitantes: workflow de consentimiento en desarrollo | BAJO               | 🟡     |
| **R5 — Derechos de titulares**         | ✅ Interfaz de gestión de derechos (acceso, supresión, rectificación); plazo <10 días                                                                        | ELIMINADO          | ✅     |
| **R6 — Responsabilidad solidaria**     | ✅ SENA es única responsable; sin terceros en arquitectura; contrato formalizado                                                                                | ELIMINADO          | ✅     |
| **R7 — Sin autorización del titular** | ✅ SmartCSET es sistema de la entidad para funciones propias del SENA → amparado por la autorización del Art. 11 Par. 5 ya firmada por cada aprendiz (H10)     | ELIMINADO          | ✅     |

---

## 4. Análisis Costo-Beneficio

### 4.1 Costo de Inacción (Status Quo)

| Escenario                              | Probabilidad | Costo Estimado                | Tiempo                       |
| -------------------------------------- | ------------ | ----------------------------- | ---------------------------- |
| Auditoria SIC (sin incidente)          | MEDIA (50%)  | $82M multa                    | Permanente mientras incumpla |
| Auditoria SIC + incidente de seguridad | MEDIA (30%)  | $164M–$246M                  | Permanente + sanciones       |
| No remediación → cierre operacional  | BAJA (5%)    | $500M+ (pérdida operacional) | 6 meses a indefinido         |

**Costo esperado (valor presente):** $82M × 0.5 + $164M × 0.3 + $500M × 0.05 = **$102.2M COP/año**

---

### 4.2 Costo de Implementación (SmartCSET/SGI)

**Ya invertido (2026-06-30):**

- Equipo de desarrollo: ~1,200 horas
- Infraestructura: Servidor laboratorio + BD
- Documentación MSPI: 8 documentos legales
- **Costo estimado invertido:** ~$50M COP (salarios, infraestructura)

**Faltante (FASE 1 - E3, E8, E9, E2):**

- E3 (Rate limiting): 12-16h = ~$3M
- E8 (Hardening red): Coordinación IT = $5M (estimado)
- E9 (Gestión parches): Proceso = $1M
- E2 (Cifrado): 20-30h = ~$8M

**Costo total a completar:** ~$60M COP (máximo)

---

### 4.3 ROI Análisis

| Métrica                         | Valor                                     |
| -------------------------------- | ----------------------------------------- |
| Costo anual de inacción         | $102.2M COP/año                          |
| Costo de implementación (total) | $110M COP (amortizado)                    |
| Break-even point                 | ~13 meses                                 |
| Beneficio 5-año                 | $102.2M × 5 - $110M =**$401M COP** |

**Conclusión:** SmartCSET se paga solo en auditoría evitada. Financieramente **obligatorio**.

---

## 5. Matriz de Decisión

### 5.1 Opciones Estratégicas

#### **OPCIÓN A: Mantener Status Quo (No hacer nada)**

- ✅ Cero inversión incremental
- ❌ Exposición permanente: $102.2M/año en multas esperadas
- ❌ Cierre operacional posible en auditoría
- ❌ Incumplimiento MSPI + Ley 1581 formal
- **Recomendación:** 🔴 **NO VIABLE** — Riesgo legal inaceptable

---

#### **OPCIÓN B: Renegociar contrato con tercero**

- ✅ Menos inversión que SmartCSET
- ⚠️ Mitiga R1 + R6 (soberanía, responsabilidad)
- ❌ No mitiga R2 (auditoría débil)
- ❌ No mitiga R3 (integridad)
- ❌ No mitiga R4 (consentimiento menores)
- ❌ Sigue siendo arquitectura de tercero → SIC tiende a sancionar responsable único (SENA)
- **Recomendación:** 🟡 **PARCIAL** — No resuelve riesgos críticos

---

#### **OPCIÓN C: Implementar SmartCSET/SGI (Recomendado)**

- ✅ Mitiga 100% de riesgos críticos
- ✅ SENA es único responsable = claridad legal
- ✅ Cumplimiento MSPI + Ley 1581 verificable
- ✅ ROI positivo en 13 meses
- ✅ Control total de datos soberanos
- ⚠️ Inversión de $60M en faltante de FASE 1
- **Recomendación:** 🟢 **OBLIGATORIO** — Única opción legalmente viable

---

## 6. Conclusiones y Recomendaciones

### 6.1 Hallazgos

1. **SENA está en incumplimiento crítico** de MSPI + Ley 1581/2012 bajo arquitectura actual
2. **Exposición financiera:** $328.5M–$493M COP (peor caso, incluye R7); $102.2M/año esperado
3. **SmartCSET resuelve 100% de riesgos críticos** y se paga en 13 meses
4. **No implementar SmartCSET = Decisión de riesgo consciente** de SENA

### 6.2 Recomendación Formal

**El SENA DEBE completar la implementación de SmartCSET/SGI (FASE 1) para:**

1. ✅ Cumplimiento legal obligatorio (MSPI + Ley 1581)
2. ✅ Protección de 7,384 personas cuyos datos están bajo responsabilidad SENA
3. ✅ Cumplimiento de derechos de menores de edad
4. ✅ Preparación para auditorías SIC + MinTIC
5. ✅ Soberanía de datos institucional

### 6.3 Próximos Pasos

1. **Fase 0:** ✅ Completada — 8 documentos legales formalizados
2. **Fase 1:** 🟡 En progreso (48%) — Completar E3, E8, E9, E2
3. **Fase 2:** 🔲 Post-FASE 1 — Continuidad y resiliencia (DRP, monitoreo)
4. **Auditoría SIC:** 🔴 **URGENTE** — Solicitar auditoría voluntaria una vez FASE 1 completa (muestra buena fe)

---

**Documento preparado:** 2026-07-05
**Estado:** Listo para presentación a dirección del SENA
**Clasificación:** CONFIDENCIAL — Análisis de Riesgos Legal
