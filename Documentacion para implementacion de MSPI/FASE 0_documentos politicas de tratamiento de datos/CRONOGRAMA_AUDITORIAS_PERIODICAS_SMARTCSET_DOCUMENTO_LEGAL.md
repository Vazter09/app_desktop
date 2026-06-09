# CRONOGRAMA DE AUDITORÍAS PERIÓDICAS DE SEGURIDAD Y PRIVACIDAD DE LA INFORMACIÓN

## Sistema SmartCSET — Servicio Nacional de Aprendizaje (SENA)

---

| Campo                                          | Valor                                                                                                                                                                                                                                                                                                               |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Documento N°**                        | FASE0-AUD-005                                                                                                                                                                                                                                                                                                       |
| **Versión**                             | 1.0                                                                                                                                                                                                                                                                                                                 |
| **Fecha de elaboración**                | 2026-06-08                                                                                                                                                                                                                                                                                                          |
| **Elaborado por**                        | Equipo de Desarrollo - SmartCSET                                                                                                                                                                                                                                                                                    |
| **Estado**                               |                                                                                                                                                                                                                                                                                                                     |
| **Fundamento normativo / metodológico** | Modelo de Seguridad y Privacidad de la Información (MSPI) — MinTIC; ISO/IEC 27001 (cláusula 9 — Evaluación del desempeño, incluye auditoría interna); Ley 1581 de 2012 (principio de responsabilidad demostrada); guía de Auditoría Interna del Departamento Administrativo de la Función Pública (DAFP) |
| **Insumos directos**                     | Inventario de Activos de Información C-I-D — SmartCSET; Matriz de Riesgos Inicial — SmartCSET; Designación de Roles y Responsabilidades de Seguridad — SmartCSET                                                                                                                                               |

---

## 1. OBJETIVO Y ALCANCE

### 1.1 Objetivo

Establecer un programa formal, periódico y verificable de auditorías internas de seguridad y privacidad de la información para el sistema SmartCSET, que permita:

1. Verificar de forma sistemática que los controles descritos en la Política de Tratamiento de Datos, el Inventario de Activos y la Matriz de Riesgos se aplican efectivamente en la operación diaria.
2. Detectar oportunamente accesos indebidos, configuraciones inseguras, cambios no autorizados de permisos y desviaciones respecto de los procedimientos documentados.
3. Generar evidencia periódica, archivable y verificable del principio de responsabilidad demostrada (*accountability*) ante la Oficina de Control Interno, la Contraloría y la Superintendencia de Industria y Comercio (SIC).
4. Cerrar el ciclo de gestión de riesgos del sistema: identificación, tratamiento, verificación y ajuste continuo.

### 1.2 Alcance

Este cronograma cubre las auditorías internas de:

- Accesos al sistema y a los datos personales que administra.
- Permisos y roles asignados, conforme al modelo de control de acceso basado en roles (RBAC).
- Cumplimiento de los procedimientos descritos en la Política de Tratamiento de Datos (autorización de los Titulares, atención de consultas y reclamos, gestión de incidentes de seguridad).
- Estado de los controles de seguridad de la información implementados sobre el sistema.
- Evolución del perfil de riesgo del sistema, conforme a la metodología de la Matriz de Riesgos.

Las auditorías generales de tecnologías de la información a nivel de infraestructura institucional, así como las auditorías administrativas y financieras de los entes de control externos, se articulan con este programa sin sustituirlo ni duplicarlo.

---

## 2. PRINCIPIOS QUE RIGEN EL PROGRAMA DE AUDITORÍA

1. **Independencia**: quien ejecuta una auditoría no debe ser, en la medida de lo posible, la misma persona que administra el control auditado, aplicando el principio de segregación de funciones.
2. **Periodicidad fija y predecible**: las auditorías se programan con anticipación y se ejecutan conforme al calendario establecido, salvo causa de fuerza mayor debidamente documentada.
3. **Trazabilidad**: cada auditoría genera evidencia archivable —listas de verificación, extractos de bitácoras, actas de hallazgos— que permite reconstruir en cualquier momento posterior qué se revisó y qué se encontró.
4. **Orientación a la mejora continua**: el objetivo del programa es identificar y corregir desviaciones, fortaleciendo el sistema de gestión de seguridad de la información.
5. **Proporcionalidad**: el esfuerzo de auditoría es proporcional a la criticidad de lo auditado, conforme a la clasificación de activos establecida en el Inventario de Activos de Información.

---

## 3. TIPOS DE AUDITORÍA Y PERIODICIDAD

| Tipo de auditoría              | Periodicidad                               | Enfoque principal                                                                                                                                                                                 | Profundidad                                                                                |
| ------------------------------- | ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| **Auditoría trimestral** | Cada tres (3) meses (cuatro veces al año) | Revisión de accesos: quién accedió a qué, cuándo, y si esos accesos son coherentes con el rol asignado                                                                                       | Operativa — revisión de bitácoras y muestreo                                            |
| **Auditoría semestral**  | Cada seis (6) meses (dos veces al año)    | Revisión de cambios en permisos y de intentos de acceso fallidos o anómalos                                                                                                                     | Táctica — análisis de tendencias y de la configuración del modelo de control de acceso |
| **Auditoría anual**      | Una vez al año                            | Auditoría integral de seguridad y privacidad: revisión completa de la serie documental de gestión de seguridad, del estado de los controles implementados y del cumplimiento normativo general | Estratégica — revisión integral, con participación de instancias de control interno    |

---

## 4. AUDITORÍA TRIMESTRAL — REVISIÓN DE ACCESOS

### 4.1 Qué se revisa

| Elemento revisado                                                            | Fuente de verificación                                                                                     | Pregunta que debe responder la auditoría                                                                                 |
| ---------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| Accesos al módulo de registro de ingreso y salida de personas               | Registro de bitácoras de acceso, con sus respectivas columnas de auditoría (usuario y fecha de creación) | ¿Los registros fueron creados por personal autorizado, en horarios coherentes con la operación del Centro?              |
| Accesos administrativos al sistema                                           | Registro de sesiones activas y bitácoras de inicio de sesión                                              | ¿Quién inició sesión con privilegios administrativos, cuándo, y es ello coherente con la planta de personal vigente? |
| Consultas a datos de personas registradas fuera del flujo normal de registro | Bitácoras de auditoría y consultas directas, cuando estén disponibles                                    | ¿Existen patrones de consulta que sugieran un uso de los datos distinto al control de acceso autorizado?                 |
| Generación y descarga de reportes oficiales                                 | Bitácoras del módulo de generación y carga de reportes                                                   | ¿Quién generó cada reporte, cuándo, y hacia qué destino se transfirió?                                              |

### 4.2 Quién realiza esta auditoría

Esta auditoría es ejecutada por el Responsable de Seguridad de la Información o, en su defecto, por la instancia que la Dirección del Centro designe formalmente para tal efecto, conforme a la matriz de roles y responsabilidades de seguridad del sistema. Cuando la persona que ejecuta la auditoría tenga responsabilidades operativas sobre el sistema, se aplica una revisión cruzada periódica como control compensatorio de segregación de funciones.

### 4.3 Procedimiento

1. Extraer del sistema el listado de accesos y registros correspondientes al trimestre.
2. Aplicar un muestreo representativo y verificar la coherencia de cada registro muestreado (horario, persona, punto de acceso, método de autenticación).
3. Contrastar el listado de usuarios con privilegios administrativos frente a la planta de personal vigente.
4. Documentar los hallazgos conforme al formato establecido en este documento.
5. Elaborar el acta de cierre de la auditoría trimestral.

---

## 5. AUDITORÍA SEMESTRAL — REVISIÓN DE PERMISOS E INTENTOS DE ACCESO FALLIDOS

### 5.1 Qué se revisa

| Elemento revisado                            | Fuente de verificación                                              | Pregunta que debe responder la auditoría                                                                                    |
| -------------------------------------------- | -------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Asignación de menús y permisos por usuario | Tablas de asignación de menús y permisos del sistema               | ¿Cada usuario cuenta exactamente con los permisos que su rol vigente requiere, conforme al principio de mínimo privilegio? |
| Usuarios con privilegios de administrador    | Catálogo de usuarios del sistema                                    | ¿La relación de administradores sigue siendo exacta? ¿Existen cuentas asignadas a personas que ya no ejercen ese rol?     |
| Intentos de acceso fallidos o bloqueos       | Bitácoras de intentos fallidos de inicio de sesión                 | ¿Existen patrones que sugieran intentos de acceso no autorizado dirigidos al sistema o a cuentas específicas?              |
| Cuentas inactivas o de personal desvinculado | Catálogo de usuarios, contrastado con la planta de personal vigente | ¿Existen cuentas activas asociadas a personas que ya no laboran en el Centro?                                               |

### 5.2 Quién realiza esta auditoría

Esta auditoría es ejecutada conforme a la matriz de roles y responsabilidades de seguridad del sistema, garantizando que la preparación de la información y su revisión independiente recaigan en instancias distintas, en aplicación del principio de segregación de funciones.

### 5.3 Procedimiento

1. Generar el listado completo de usuarios activos, su rol declarado y sus permisos efectivos.
2. Contrastar dicho listado con la planta de personal vigente, identificando cuentas que ya no correspondan a una vinculación activa.
3. Revisar el histórico de intentos fallidos de acceso del semestre y clasificar las anomalías detectadas.
4. Verificar que el procedimiento de revocación de accesos se haya ejecutado para cada desvinculación o cambio de rol ocurrido en el periodo.
5. Documentar los hallazgos y elaborar el acta de cierre de la auditoría semestral.

---

## 6. AUDITORÍA ANUAL — AUDITORÍA INTEGRAL DE SEGURIDAD Y PRIVACIDAD

### 6.1 Qué se revisa

Esta auditoría integra y profundiza el alcance de las auditorías trimestral y semestral, y adicionalmente cubre:

| Elemento revisado                                                         | Fuente de verificación                                                                                   | Pregunta que debe responder la auditoría                                                                                                                                                        |
| ------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Vigencia y aplicación de la Política de Tratamiento de Datos Personales | Política vigente, bitácora de consultas y reclamos, muestras de autorizaciones capturadas               | ¿La política se encuentra vigente, se aplica en la práctica, y se atienden las solicitudes de los Titulares dentro de los plazos legales?                                                     |
| Actualización del Inventario de Activos de Información                  | Comparación entre el inventario documentado y el estado real del sistema                                 | ¿El inventario refleja fielmente los activos, módulos e infraestructura vigentes?                                                                                                              |
| Vigencia de la Matriz de Riesgos                                          | Comparación entre los riesgos documentados, los controles declarados y su estado real de implementación | ¿Los riesgos identificados continúan siendo los relevantes? ¿Los controles declarados como implementados lo están efectivamente? ¿El perfil de riesgo evolucionó conforme a lo proyectado? |
| Cumplimiento de roles y responsabilidades de seguridad                    | Actas de designación, registros de capacitación, matriz de asignación de responsabilidades             | ¿Los roles designados ejercen efectivamente sus funciones? ¿Se ejecutaron las capacitaciones programadas?                                                                                      |
| Estado de los controles de seguridad implementados                        | Relación de controles planificados frente a su evidencia de implementación                              | ¿Qué proporción de los controles planificados se encuentra efectivamente implementada y verificada?                                                                                           |
| Procedimiento de gestión de incidentes de seguridad                      | Bitácora de incidentes de seguridad de la información                                                   | ¿Se presentaron incidentes en el periodo? ¿Se siguió el procedimiento establecido? ¿Se notificó a la Superintendencia de Industria y Comercio cuando correspondía?                         |

### 6.2 Quién realiza esta auditoría

Esta auditoría es liderada por la Oficina de Control Interno del Centro o de la Regional, con el apoyo técnico del Responsable de Seguridad de la Información y del Administrador del Sistema, quienes aportan la información requerida sin determinar las conclusiones de la auditoría, en aplicación del principio de independencia. Cuando la Dirección lo considere pertinente, se vincula un auditor externo o personal de la Oficina de Tecnologías de la Información del nivel central del SENA, con el fin de aportar una revisión independiente adicional.

### 6.3 Procedimiento

1. El Comité de Seguridad y Privacidad de la Información programa la auditoría anual con una anticipación mínima de sesenta (60) días calendario.
2. Se ejecuta una revisión consolidada y profunda de cada uno de los elementos descritos en el numeral 6.1, apoyándose en las actas y hallazgos de las auditorías trimestrales y semestrales del periodo.
3. Se elabora el informe anual de auditoría de seguridad y privacidad de la información, que incluye: resumen ejecutivo, hallazgos por categoría, nivel de cumplimiento frente al periodo anterior y recomendaciones priorizadas para el siguiente ciclo.
4. El informe se presenta ante el Comité de Seguridad y Privacidad de la Información y, cuando corresponda, ante la Dirección del Centro y la Oficina de Control Interno.
5. Con base en los hallazgos del informe, se actualizan la Matriz de Riesgos y el Inventario de Activos de Información, cerrando el ciclo anual de gestión de riesgos.

---

## 7. PROCEDIMIENTO GENERAL DE EJECUCIÓN DE UNA AUDITORÍA

El siguiente procedimiento aplica, con el nivel de profundidad correspondiente, a los tres tipos de auditoría descritos en este documento:

```
PASO 1 — PLANIFICACIÓN
   • Confirmar fecha, alcance y responsable(s) de la auditoría
   • Reunir los insumos: bitácoras del periodo, inventario vigente,
     matriz de riesgos vigente y hallazgos de auditorías anteriores
        ↓
PASO 2 — EJECUCIÓN
   • Aplicar las verificaciones correspondientes al tipo de auditoría:
     revisión documental, muestreo y, cuando aplique, entrevistas
        ↓
PASO 3 — DOCUMENTACIÓN DE HALLAZGOS
   • Registrar cada hallazgo conforme al formato establecido,
     clasificado por nivel de severidad
        ↓
PASO 4 — ACTA DE CIERRE
   • Elaborar el acta (auditorías trimestral y semestral) o el
     informe integral (auditoría anual) correspondiente
        ↓
PASO 5 — COMUNICACIÓN
   • Compartir el resultado con el Responsable de Seguridad de la
     Información y, según la severidad, escalar al Comité de
     Seguridad o a la Dirección del Centro
        ↓
PASO 6 — SEGUIMIENTO
   • Incorporar los hallazgos al plan de remediación
   • Verificar, en el ciclo de auditoría siguiente, el cierre
     efectivo de los hallazgos del ciclo anterior
```

---

## 8. GESTIÓN DE HALLAZGOS Y PLAN DE REMEDIACIÓN

### 8.1 Clasificación de severidad de hallazgos

| Severidad           | Criterio                                                                                                                | Plazo de remediación                                                                                                                  |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| Crítico            | Compromiso confirmado o altamente probable de datos personales, o ausencia de un control de seguridad esencial          | Inmediato; activa, cuando corresponda, el procedimiento de gestión de incidentes de seguridad de la Política de Tratamiento de Datos |
| Alto                | Desviación significativa frente a un procedimiento documentado, con potencial de generar un incidente de no corregirse | Días, mediante un plan de acción con responsable y fecha definida, verificado en el ciclo siguiente                                  |
| Medio               | Desviación menor, con oportunidad de mejora e impacto operativo limitado                                               | Semanas, incorporado al plan de mejora ordinario                                                                                       |
| Bajo / Observación | Sugerencia de mejora sin impacto directo sobre la seguridad de la información                                          | Conforme a disponibilidad, registrado para seguimiento histórico                                                                      |

### 8.2 Formato de registro de hallazgos

| N° | Fecha de detección | Auditoría que lo generó | Descripción del hallazgo | Severidad | Activo o proceso afectado | Acción de remediación | Responsable | Fecha objetivo | Estado | Fecha de cierre verificado |
| --- | ------------------- | ------------------------- | ------------------------- | --------- | ------------------------- | ----------------------- | ----------- | -------------- | ------ | -------------------------- |
|     |                     |                           |                           |           |                           |                         |             |                |        |                            |

### 8.3 Reglas de gestión del plan de remediación

1. Todo hallazgo de severidad crítica o alta cuenta, dentro de los cinco (5) días hábiles siguientes a su detección, con un responsable y una fecha objetivo de remediación formalmente asignados.
2. El cierre de un hallazgo es verificado por la instancia auditora y no por quien ejecuta la remediación, en aplicación del principio de independencia.
3. Los hallazgos que no se cierren dentro del plazo objetivo se reportan en la siguiente auditoría programada y, cuando su severidad lo amerite, se escalan al Comité de Seguridad y Privacidad de la Información.

---

## 9. INDICADORES DE GESTIÓN DEL PROGRAMA DE AUDITORÍA

| Indicador                                                                     | Forma de cálculo                                                                                                | Meta                                                                                    |
| ----------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| Cumplimiento del cronograma de auditorías                                    | (Número de auditorías ejecutadas en la fecha programada / número de auditorías programadas) × 100           | Igual o superior al 90%                                                                 |
| Tasa de cierre de hallazgos críticos y altos dentro del plazo                | (Número de hallazgos críticos y altos cerrados en plazo / número total de hallazgos críticos y altos) × 100 | Igual o superior al 95%                                                                 |
| Tiempo promedio de cierre de hallazgos por severidad                          | Promedio de la diferencia entre la fecha de cierre y la fecha de detección, agrupado por nivel de severidad     | Crítico: menos de 5 días · Alto: menos de 30 días · Medio: menos de 90 días       |
| Reducción del nivel de riesgo promedio entre ciclos anuales                  | Comparación del nivel de riesgo promedio de la Matriz de Riesgos entre auditorías anuales consecutivas         | Tendencia decreciente sostenida, conforme al plan de tratamiento de riesgos del sistema |
| Cobertura de capacitación en seguridad y privacidad verificada en auditoría | (Número de roles con capacitación verificada / número total de roles que la requieren) × 100                 | 100% antes de cada auditoría anual                                                     |

---

## 10. ARCHIVO Y CONSERVACIÓN DE EVIDENCIA DE AUDITORÍA

1. **Qué se archiva**: actas de cierre, listas de verificación diligenciadas, extractos de bitácoras utilizados como muestra, registros de hallazgos y de su remediación, e informes anuales integrales.
2. **Dónde se archiva**: la evidencia de auditoría se conserva en el repositorio documental institucional designado por la Dirección del Centro, en coordinación con el área de Gestión Documental, garantizando su disponibilidad para revisiones posteriores y para los entes de control.
3. **Tiempo de conservación**: conforme a las Tablas de Retención Documental del SENA aplicables a los procesos de auditoría y control interno.
4. **Control de acceso a la evidencia**: la evidencia de auditoría se trata como un activo de información de criticidad alta, dado que su alteración podría ocultar hallazgos relevantes; se le aplican controles de acceso equivalentes a los establecidos para las bitácoras de auditoría del sistema.

---

## 11. CALENDARIO CONSOLIDADO — VISTA ANUAL

```
   MES:        E   F   M   A   M   J   J   A   S   O   N   D
   ─────────────────────────────────────────────────────────
   Trimestral  │       ▲           ▲           ▲           ▲   │
   Semestral   │               ▲                       ▲       │
   Anual       │                                           ▲   │
   ─────────────────────────────────────────────────────────

   ▲ = punto de ejecución de la auditoría correspondiente
```

El calendario definitivo es aprobado por el Comité de Seguridad y Privacidad de la Información, procurando que la ejecución de cada auditoría no coincida con los periodos de mayor carga operativa del Centro de Formación.

---

## 12. PLAN DE MANTENIMIENTO DEL CRONOGRAMA

1. **Revisión anual obligatoria**: este cronograma se revisa, como mínimo, en el marco de cada auditoría anual integral, ajustando periodicidades, alcances e indicadores con base en la experiencia del ciclo anterior.
2. **Revisión por evento**: cualquier incidente de seguridad significativo, cambio relevante en la arquitectura del sistema o hallazgo recurrente no detectado oportunamente da lugar a una revisión extraordinaria de este cronograma.
3. **Sincronización con la serie documental**: cualquier modificación al Inventario de Activos de Información, a la Matriz de Riesgos o a la designación de roles y responsabilidades que afecte el alcance o los responsables de las auditorías aquí descritas se incorpora de inmediato a este documento.

---

*Fin del documento — Cronograma de Auditorías Periódicas de Seguridad y Privacidad de la Información — SmartCSET*
