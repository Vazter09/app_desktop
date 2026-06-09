# DESIGNACIÓN DE ROLES Y RESPONSABILIDADES EN SEGURIDAD Y PRIVACIDAD DE LA INFORMACIÓN

## Sistema SmartCSET — Servicio Nacional de Aprendizaje (SENA)

---

| Campo                                          | Valor                                                                                                                                                                                                        |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Documento N°**                        | FASE0-ROL-004                                                                                                                                                                                                |
| **Versión**                             | 1.0                                                                                                                                                                                                          |
| **Fecha de elaboración**                | 2026-06-07                                                                                                                                                                                                   |
| **Elaborado por**                        | Equipo de Desarrollo - SmartCSET                                                                                                                                                                             |
| **Estado**                               | Borrador para revisión y aprobación por la Dirección del Centro de Formación                                                                                                                             |
| **Próxima revisión**                   | Anual, o ante cambio de personal en roles críticos o cambio en el alcance del sistema                                                                                                                       |
| **Clasificación del documento**         | Uso institucional — Difusión controlada                                                                                                                                                                    |
| **Fundamento normativo / metodológico** | MSPI — documento "02_Roles y Responsabilidades"; ISO/IEC 27001 (cláusula 5 — Liderazgo, Anexo A.6 — Organización de la seguridad de la información); Modelo Integrado de Planeación y Gestión (MIPG) |
| **Insumos directos**                     | Política y Tratamiento de Datos Personales — SmartCSET; Inventario de Activos de Información C-I-D — SmartCSET; Matriz de Riesgos Inicial — SmartCSET                                                   |

---

---

## 1. OBJETIVO Y ENFOQUE

### 1.1 Objetivo

Establecer la estructura de roles y responsabilidades en materia de seguridad y privacidad de la información para el sistema SmartCSET, que:

1. Defina con claridad quién asume cada obligación, control y riesgo identificado en los documentos de Política de Tratamiento de Datos, Inventario de Activos y Matriz de Riesgos.
2. Atienda de forma estructural el riesgo de dependencia de una sola persona (*bus factor* = 1) identificado en la Matriz de Riesgos como uno de los más críticos.
3. Cumpla con la exigencia del MSPI y de ISO/IEC 27001 de que la seguridad de la información cuente con roles claramente definidos, con autoridad, recursos y rendición de cuentas.

### 1.2 Importancia de esta designación

Una estructura de roles formalmente designada permite que:

- Exista un responsable identificable ante cualquier evento relacionado con la seguridad de la información.
- Existan personas con autoridad institucional para tomar decisiones de seguridad (aprobar excepciones, autorizar inversiones, decidir ante un incidente).
- El conocimiento y la responsabilidad del sistema dejen de concentrarse en una sola persona.
- La entidad pueda demostrar ante la SIC, la Contraloría y el Control Interno que cuenta con una estructura de gobernanza de seguridad de la información.

---

## 2. PRINCIPIOS DE DISEÑO DE LA ESTRUCTURA DE ROLES

La estructura que se presenta a continuación se construyó aplicando los siguientes principios, tomados de la metodología MSPI y de las buenas prácticas de ISO/IEC 27001 (Anexo A.6):

1. **Realismo institucional**: la estructura reconoce que SmartCSET opera con recursos humanos limitados. La mayoría de los roles se asumen como responsabilidades adicionales formalizadas de cargos ya existentes en el Centro de Formación, sin que sea necesario crear nuevas plazas.
2. **Segregación de funciones donde sea posible, y mitigación explícita donde no lo sea**: se identifican los puntos donde, por restricciones de recursos, una misma persona deba asumir roles que idealmente estarían separados, y se establecen controles compensatorios concretos (Sección 7).
3. **Trazabilidad hacia los documentos de la serie**: cada rol se vincula explícitamente con obligaciones, activos o riesgos ya identificados en los documentos previos.
4. **Progresividad**: se distingue entre roles de designación inmediata y roles cuya formalización plena puede ser progresiva, conforme la entidad avance en la madurez de su modelo de seguridad.

---

## 3. ESTRUCTURA DE GOBERNANZA — VISTA GENERAL

```
                    ┌──────────────────────────────────────┐
                    │     DIRECCIÓN DEL CENTRO DE          │
                    │     FORMACIÓN (Responsable           │
                    │     institucional último)            │
                    └───────────────┬──────────────────────┘
                                    │  designa y respalda
                    ┌───────────────┴──────────────────────┐
                    │                                       │
        ┌───────────▼────────────┐          ┌─────────────▼─────────────┐
        │  COMITÉ / INSTANCIA DE  │          │   OFICINA JURÍDICA /      │
        │  SEGURIDAD Y PRIVACIDAD │◄────────►│   PROTECCIÓN DE DATOS     │
        │  DE LA INFORMACIÓN      │          │   (asesoría y validación  │
        │  (gobierno y decisión)  │          │   normativa permanente)   │
        └───────────┬─────────────┘          └───────────────────────────┘
                    │  coordina y supervisa
        ┌───────────┴─────────────────────────────────────────┐
        │                                                       │
┌───────▼────────────┐  ┌─────────────────────┐  ┌────────────▼───────────┐
│  RESPONSABLE DE    │  │  ADMINISTRADOR DEL  │  │  COORDINADOR DE        │
│  SEGURIDAD DE LA   │◄─┤  SISTEMA SmartCSET  │─►│  OPERACIÓN DEL         │
│  INFORMACIÓN       │  │  (Encargado técnico │  │  REGISTRO DE PERSONAL  │
│  (rol institucional│  │  del tratamiento)   │  │  (supervisión operativa│
│  — gobierno)       │  │                     │  │  diaria)               │
└────────────────────┘  └──────────┬──────────┘  └────────────┬───────────┘
                                    │                           │
                         ┌──────────▼──────────┐    ┌──────────▼───────────┐
                         │  RESPALDO TÉCNICO /  │    │  OPERADORES DEL      │
                         │  SEGUNDO PERFIL      │    │  REGISTRO DE         │
                         │  (mitigación bus     │    │  PERSONAL (usuarios  │
                         │  factor)             │    │  finales del sistema)│
                         └──────────────────────┘    └──────────────────────┘
```

> Esta estructura no implica necesariamente nuevas contrataciones: la mayoría de estos roles se asignan como responsabilidades adicionales formalizadas a cargos y dependencias ya existentes en el Centro de Formación.

---

## 4. CATÁLOGO DETALLADO DE ROLES INSTITUCIONALES

### 4.1 Responsable del Tratamiento / Máxima Autoridad Institucional

| Aspecto                     | Detalle                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| --------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Asignación**       | Dirección del Centro de Formación (o quien delegue formalmente mediante acto administrativo)                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| **Fundamento**        | Es quien tiene la autoridad institucional para decidir sobre las finalidades del tratamiento, aprobar políticas, asignar recursos y representar a la entidad ante la SIC y otros entes de control — la figura de "Responsable del Tratamiento" de la Ley 1581 de 2012                                                                                                                                                                                                                                                                                                |
| **Responsabilidades** | • Aprobar formalmente la Política de Tratamiento de Datos y sus actualizaciones `<br>`• Designar al Responsable de Seguridad de la Información y demás roles que requieran acto administrativo `<br>`• Asignar los recursos necesarios para la ejecución de las medidas de seguridad `<br>`• Representar a la entidad ante la SIC, la Contraloría y demás entes de control en materia de seguridad y privacidad de la información del sistema `<br>`• Aprobar el tratamiento de los riesgos de nivel Extremo identificados en la Matriz de Riesgos |

### 4.2 Comité / Instancia de Seguridad y Privacidad de la Información

| Aspecto                            | Detalle                                                                                                                                                                                                                                                                                                                                                                                                         |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Conformación**            | Instancia colegiada integrada por: Dirección del Centro, Responsable de Seguridad de la Información, Administrador del Sistema, un delegado de la Oficina Jurídica, y un delegado de Control Interno (cuando aplique)                                                                                                                                                                                        |
| **Fundamento**               | Las decisiones relevantes en materia de seguridad de la información (aprobación de políticas, tratamiento de riesgos altos, revisión de incidentes) se adoptan de forma colegiada, combinando visión jurídica, técnica, operativa y directiva                                                                                                                                                            |
| **Responsabilidades**        | • Revisar y aprobar la Política de Tratamiento de Datos, el Inventario de Activos y la Matriz de Riesgos, y sus actualizaciones periódicas `<br>`• Revisar el avance de las medidas de fortalecimiento de seguridad institucional `<br>`• Decidir sobre el tratamiento de riesgos de nivel Alto y Extremo `<br>`• Servir como instancia de escalamiento ante incidentes de seguridad significativos |
| **Periodicidad de reunión** | Trimestral durante las fases de implementación; semestral en fase de operación estable                                                                                                                                                                                                                                                                                                                        |

### 4.3 Responsable de Seguridad de la Información

| Aspecto                                                          | Detalle                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Asignación**                                            | Perfil designado por la Dirección, con conocimientos afines a TI y gestión de riesgos — distinto de quien ejerce el rol de Administrador del Sistema                                                                                                                                                                                                                                                                                                                  |
| **Distinción frente al rol de Administrador del Sistema** | El Responsable de Seguridad de la Información ejerce una función de gobierno y supervisión (define lineamientos, evalúa riesgos, exige cumplimiento), mientras que el Administrador del Sistema ejerce una función técnica y operativa (implementa, configura, opera). Esta separación garantiza una verificación independiente de que los controles técnicos se apliquen efectivamente — un elemento central de la segregación de funciones (ver Sección 7) |
| **Responsabilidades**                                      | • Liderar el mantenimiento del Inventario de Activos y la Matriz de Riesgos `<br>`• Supervisar la implementación de los controles técnicos de seguridad `<br>`• Reportar periódicamente al Comité de Seguridad sobre el estado de los riesgos y controles `<br>`• Coordinar la respuesta ante incidentes de seguridad `<br>`• Promover la cultura de seguridad y privacidad mediante capacitaciones y actividades de sensibilización                   |

### 4.4 Punto de Contacto para Consultas y Reclamos de Titulares

| Aspecto                     | Detalle                                                                                                                                                                                                                                                                                                                                    |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Asignación**       | Persona o área de atención al ciudadano/aprendiz del Centro, capacitada en el procedimiento correspondiente de la Política de Tratamiento de Datos                                                                                                                                                                                      |
| **Fundamento**        | La Ley 1581 de 2012 exige que el Titular pueda identificar fácilmente un canal para ejercer sus derechos. Este rol se apoya en una estructura de atención que el Titular ya conoce                                                                                                                                                       |
| **Responsabilidades** | • Recibir, radicar y dar trámite a las consultas y reclamos conforme al procedimiento establecido en la Política de Tratamiento de Datos `<br>`• Mantener la bitácora institucional de consultas y reclamos `<br>`• Escalar al Responsable de Seguridad de la Información y/o a la Oficina Jurídica los casos que lo requieran |

### 4.5 Oficina Jurídica / Coordinación de Protección de Datos

| Aspecto                     | Detalle                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Asignación**       | Dependencia jurídica institucional del SENA (Regional / Dirección General, según corresponda)                                                                                                                                                                                                                                                                                                                                                                           |
| **Fundamento**        | Esta dependencia resuelve de forma definitiva los aspectos de la Política de Tratamiento de Datos que requieren validación o complemento jurídico                                                                                                                                                                                                                                                                                                                       |
| **Responsabilidades** | • Validar y complementar jurídicamente la Política de Tratamiento de Datos `<br>`• Resolver los aspectos jurídicos pendientes identificados durante la formalización de la serie documental de la Fase 0 `<br>`• Representar a la entidad en los trámites ante la SIC relacionados con el tratamiento de datos de SmartCSET `<br>`• Revisar y aprobar los textos de autorización, avisos de privacidad y demás piezas documentales con efectos jurídicos |

---

## 5. CATÁLOGO DETALLADO DE ROLES TÉCNICOS Y OPERATIVOS

### 5.1 Administrador del Sistema SmartCSET (Encargado del Tratamiento — rol técnico)

| Aspecto                          | Detalle                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Asignación**            | Desarrollador / Administrador del sistema SmartCSET                                                                                                                                                                                                                                                                                                                                                                                                                    |
| **Naturaleza del rol**     | Encargado del Tratamiento en términos de la Ley 1581 de 2012: ejecuta materialmente el tratamiento técnico de los datos por cuenta del Responsable                                                                                                                                                                                                                                                                                                                   |
| **Responsabilidades**      | • Implementar y mantener los controles técnicos de seguridad `<br>`• Custodiar técnicamente las bases de datos, el código fuente, las credenciales y la infraestructura de aplicación `<br>`• Ejecutar y verificar las copias de seguridad `<br>`• Reportar al Responsable de Seguridad de la Información sobre el estado de los controles técnicos y los incidentes detectados `<br>`• Mantener actualizada la documentación técnica del sistema |
| **Formalización del rol** | El ejercicio de este rol se respalda mediante el instrumento institucional correspondiente (contrato, acto administrativo o acuerdo de confidencialidad y tratamiento de datos) que lo reconozca formalmente como Encargado del Tratamiento en los términos de la Ley 1581 de 2012, dejando constancia de sus funciones, límites y respaldo institucional                                                                                                            |

### 5.2 Respaldo Técnico / Segundo Perfil

| Aspecto                                         | Detalle                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Propósito**                            | Constituye la mitigación estructural directa del riesgo de dependencia de una sola persona: si quien opera el sistema no está disponible por cualquier motivo, la entidad debe conservar la capacidad de operar, mantener y recuperar su propio sistema de registro y control de personal                                                                                                                                                                                                                                                                                                 |
| **Esquema de implementación progresiva** | **Nivel inicial:** un perfil de la Oficina de TI del Centro/Regional actúa como contacto de continuidad documentado, recibiendo la documentación técnica completa y apoyando, en caso de necesidad, con base en los procedimientos documentados. `<br>` **Nivel intermedio:** participación periódica de una persona de TI en mantenimientos, despliegues y revisiones, como acompañamiento parcial. `<br>` **Nivel consolidado:** formación de un segundo perfil con capacidad de operar el sistema de forma autónoma, eliminando estructuralmente el riesgo |
| **Responsabilidades**                     | • Recibir y mantener actualizada copia de la documentación técnica `<br>`• Participar periódicamente en actividades de mantenimiento y despliegue `<br>`• Servir como punto de continuidad ante una ausencia imprevista del Administrador del Sistema                                                                                                                                                                                                                                                                                                                             |

### 5.3 Coordinador de Operación del Registro de Personal

| Aspecto                     | Detalle                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Asignación**       | Coordinación administrativa o de bienestar del Centro de Formación, responsable funcional de la operación diaria del módulo de registro de ingreso/salida                                                                                                                                                                                                                                                                                                                                                   |
| **Fundamento**        | Es quien tiene autoridad funcional sobre el personal que opera el módulo en el día a día — el actor que traduce las medidas de seguridad documentadas en práctica operativa real                                                                                                                                                                                                                                                                                                                           |
| **Responsabilidades** | • Supervisar el cumplimiento operativo de los procedimientos de registro, incluyendo la correcta obtención de las autorizaciones de los Titulares `<br>`• Reportar anomalías operativas al Administrador del Sistema y al Responsable de Seguridad de la Información `<br>`• Coordinar la capacitación del personal operador en manejo de datos personales y procedimientos de seguridad `<br>`• Gestionar, junto con Talento Humano, la revocación oportuna de accesos ante cambios de personal |

### 5.4 Operadores del Registro de Personal (usuarios finales del sistema)

| Aspecto                                                          | Detalle                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Asignación**                                            | Personal operador del módulo de registro de ingreso/salida                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| **Responsabilidades en materia de seguridad y privacidad** | • Aplicar correctamente el procedimiento de obtención de autorización del Titular antes de capturar sus datos, incluyendo el bloque diferenciado para datos sensibles (fotografías)`<br>`• Proteger sus credenciales de acceso al sistema `<br>`• Reportar de inmediato cualquier anomalía, intento de acceso indebido, o situación sospechosa al Coordinador de Operación correspondiente `<br>`• Tratar la información de los Titulares con la confidencialidad y el cuidado exigidos por la Política de Tratamiento de Datos |
| **Mecanismo de incorporación**                            | Estas responsabilidades se incorporan formalmente en los perfiles de funciones existentes y en los procesos de inducción y capacitación del personal                                                                                                                                                                                                                                                                                                                                                                                            |

### 5.5 Personal de la Oficina de TI del SENA con acceso de soporte/infraestructura

| Aspecto                     | Detalle                                                                                                                                                                                                                                                                                                                                                |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Asignación**       | Personal de soporte de infraestructura designado conforme a la estructura de TI del SENA a nivel regional/nacional                                                                                                                                                                                                                                     |
| **Fundamento**        | Constituye un actor externo al equipo directo de SmartCSET que puede tener acceso técnico a los servidores, la base de datos o la infraestructura de respaldo; su vínculo se formaliza mediante un acuerdo de confidencialidad y tratamiento de datos                                                                                                |
| **Responsabilidades** | • Cumplir las obligaciones de confidencialidad y tratamiento seguro de la información a la que tenga acceso por razón de soporte técnico `<br>`• Coordinar con el Administrador del Sistema cualquier intervención sobre la infraestructura que soporta SmartCSET `<br>`• Reportar cualquier incidente detectado durante labores de soporte |

---

## 6. MATRIZ RACI CONSOLIDADA POR PROCESO

Convención: **R**esponsable (ejecuta) · **A**probador/*Accountable* (responde por el resultado) · **C**onsultado (aporta antes de decidir) · **I**nformado (se entera del resultado)

| Proceso / Actividad                                               | Dirección del Centro   | Comité de Seguridad | Responsable de Seg. de la Info. | Administrador del Sistema | Oficina Jurídica | Coordinador de Operación | Punto de Contacto Titulares | Oficina de TI SENA |
| ----------------------------------------------------------------- | ----------------------- | -------------------- | ------------------------------- | ------------------------- | ----------------- | ------------------------- | --------------------------- | ------------------ |
| Aprobación de la Política de Tratamiento de Datos               | **A**             | C                    | C                               | C                         | **R**       | I                         | I                           | I                  |
| Mantenimiento del Inventario de Activos                           | I                       | C                    | **A**                     | **R**               | I                 | C                         | —                          | C                  |
| Mantenimiento de la Matriz de Riesgos                             | I                       | **A**          | **R**                     | C                         | C                 | C                         | —                          | C                  |
| Tratamiento de riesgos de nivel Alto/Extremo                      | **A**             | **R**          | **R**                     | C                         | C                 | I                         | —                          | C                  |
| Implementación de controles técnicos de seguridad               | I                       | I                    | **A**                     | **R**               | —                | I                         | —                          | C                  |
| Atención de consultas y reclamos de Titulares                    | I                       | I                    | C                               | C                         | C                 | I                         | **R**                 | —                 |
| Gestión de incidentes de seguridad — detección y contención   | I                       | I                    | **A**                     | **R**               | I                 | C                         | I                           | C                  |
| Gestión de incidentes — notificación a la SIC (cuando proceda) | **A**             | C                    | **R**                     | C                         | **R**       | I                         | I                           | I                  |
| Capacitación y sensibilización del personal                     | I                       | C                    | **A**                     | C                         | C                 | **R**               | C                           | —                 |
| Revocación de accesos por desvinculación/cambio de rol          | I                       | I                    | C                               | **R**               | I                 | **A**               | —                          | C                  |
| Revisión periódica de la serie documental                       | C                       | **A**          | **R**                     | C                         | C                 | I                         | I                           | I                  |
| Designación formal de roles de seguridad                         | **A**/**R** | C                    | —                              | I                         | C                 | I                         | I                           | I                  |

---

## 7. SEGREGACIÓN DE FUNCIONES (SoD) — ANÁLISIS DE CONFLICTOS POTENCIALES

### 7.1 Fundamento del análisis

La segregación de funciones (*Segregation of Duties* — SoD) es uno de los principios de control interno verificados con mayor frecuencia por las auditorías de seguridad y de la Contraloría: busca que ninguna persona tenga, por sí sola, el control completo de un proceso crítico de principio a fin. En estructuras con recursos limitados como la del Centro de Formación, es razonable que existan conflictos de SoD; lo determinante es que la entidad los identifique de forma proactiva y establezca controles compensatorios, según se documenta a continuación.

### 7.2 Conflictos identificados y controles compensatorios

| Conflicto identificado                                                                                                                                          | Por qué constituye un conflicto de SoD                                                                                                                   | Control compensatorio                                                                                                                                                                                                                                                                                                                                                                                               |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| El Administrador del Sistema desarrolla, despliega y administra el sistema, y podría también ejercer funciones de Responsable de Seguridad de la Información | Quien construye e implementa los controles no debería, sin supervisión adicional, ser quien evalúa si esos controles son suficientes                   | (a) El Responsable de Seguridad de la Información es una persona o instancia distinta del Administrador del Sistema; (b) el Comité de Seguridad ejerce de forma colegiada la función de revisión independiente; (c) las revisiones periódicas de seguridad incluyen, cuando sea posible, una mirada externa (Oficina de Control Interno o un tercero)                                                          |
| El Administrador del Sistema tiene acceso técnico total a la base de datos, incluyendo las tablas de auditoría que registran sus propias acciones             | Quien tiene la capacidad técnica de alterar los registros es la misma persona cuyas acciones esos registros deben poder verificar de forma independiente | (a) Implementación de protecciones técnicas adicionales sobre las tablas de auditoría (mecanismos de solo adición, replicación a almacenamiento de solo lectura, alertas ante modificaciones anómalas); (b) almacenamiento de las copias de seguridad en una ubicación que el Administrador no pueda alterar retroactivamente por sí solo, sirviendo como testigo independiente de la integridad histórica |
| Quien designa y supervisa al Responsable de Seguridad podría coincidir con la persona cuyas decisiones ese Responsable debe poder cuestionar                   | El rol de gobierno de seguridad pierde efectividad sin independencia real frente a quien lo designa                                                       | El Comité de Seguridad, al ser una instancia colegiada con participación de la Oficina Jurídica y, cuando aplique, de Control Interno, introduce voces adicionales en la toma de decisiones, constituyendo en sí mismo un control compensatorio estructural                                                                                                                                                     |

### 7.3 Conclusión del análisis de SoD

Los conflictos identificados son propios de la realidad de recursos del Centro de Formación y cuentan con controles compensatorios concretos para cada uno de ellos. Esta sección constituye, por sí sola, evidencia de gestión proactiva del modelo de gobernanza de seguridad de SmartCSET ante cualquier instancia de auditoría.

---

## 8. PLAN DE TRANSICIÓN Y RESPALDO — MITIGACIÓN DEL RIESGO DE "PUNTO ÚNICO DE FALLO HUMANO"

> Esta sección desarrolla, de forma operativa, la mitigación del riesgo de mayor criticidad estructural identificado en la Matriz de Riesgos (dependencia de una sola persona) y del activo de conocimiento técnico identificado en el Inventario de Activos.

### 8.1 Diagnóstico de la situación

A la fecha de este documento, el Administrador del Sistema concentra:

- El conocimiento completo de la arquitectura, el código fuente y la base de datos.
- La capacidad operativa de mantener, corregir y desplegar el sistema.
- El acceso técnico a credenciales, infraestructura y configuraciones críticas.

El nivel de documentación generado para el sistema demuestra un compromiso activo con mitigar este riesgo. No obstante, constituye una realidad estructural que la entidad debe resolver institucionalmente, dado que ningún nivel de compromiso individual elimina el riesgo de que esa persona, en algún momento, no esté disponible por razones ajenas a su control.

### 8.2 Plan de mitigación en tres niveles

**Nivel 1 — Documentación exhaustiva**

- Mantener actualizada toda la documentación técnica del sistema y sus procedimientos.
- Documentar explícitamente los procedimientos de recuperación ante contingencias: cómo restaurar un respaldo, cómo reiniciar servicios, cómo diagnosticar fallas comunes, dónde están las credenciales críticas y cómo acceder a ellas en una emergencia mediante un procedimiento seguro (p. ej., un esquema de "sobre cerrado" o un gestor de secretos institucional).

**Nivel 2 — Designación de un contacto de respaldo documentado**

- Identificar, dentro de la Oficina de TI del Centro/Regional, una persona que reciba copia de la documentación técnica y sirva como punto de continuidad en caso de emergencia.
- Establecer un protocolo simple: ante una indisponibilidad imprevista del Administrador del Sistema, esta persona sabe a quién contactar, dónde está la documentación, y qué pasos seguir mientras se resuelve la situación.

**Nivel 3 — Formación de un segundo perfil operativo**

- Formación progresiva de una segunda persona capaz de operar el sistema de forma autónoma — la medida que elimina, en lugar de solo reducir, el riesgo estructural.
- Esta formación se desarrolla de forma progresiva: participación en mantenimientos programados, acompañamiento en despliegues, rotación parcial de responsabilidades.

### 8.3 Indicador de éxito de esta mitigación

> El indicador de que este riesgo se gestiona correctamente es que, ante una eventual indisponibilidad del Administrador del Sistema, la entidad pueda continuar operando su sistema de registro y control de personal sin interrupción ni pérdida de información, apoyándose en la documentación y los respaldos existentes.

---

## 9. REQUISITOS DE COMPETENCIA, FORMACIÓN Y SENSIBILIZACIÓN POR ROL

| Rol                                                                      | Competencias / formación                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | Periodicidad de actualización                                                                                                                               |
| ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Dirección del Centro / Comité de Seguridad                             | Sensibilización ejecutiva sobre el marco MSPI, la Ley 1581 de 2012, y los riesgos y beneficios de las medidas de fortalecimiento de seguridad institucional                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | Anual, o ante cambios normativos relevantes                                                                                                                  |
| Responsable de Seguridad de la Información                              | Formación en gestión de riesgos de seguridad de la información (ISO/IEC 27001/27005, NIST), conocimiento del marco MSPI y de la Ley 1581 de 2012                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | Anual, y ante cada actualización significativa del marco normativo                                                                                          |
| Administrador del Sistema                                                | Actualización en buenas prácticas de seguridad de aplicaciones web (OWASP), seguridad de bases de datos PostgreSQL, y los lineamientos técnicos de seguridad del sistema                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | Continua                                                                                                                                                     |
| Coordinador de Operación / Operadores del Registro de Personal          | Capacitación práctica en: (a) procedimiento correcto de obtención de autorización de Titulares, incluyendo el bloque de datos sensibles; (b) manejo confidencial de la información que observan a diario; (c) identificación y reporte de situaciones sospechosas (phishing, ingeniería social, anomalías técnicas); (d) tratamiento diferenciado y reforzado de datos de aprendices menores de edad (NNA) — identificación del titular menor, verificación de la autorización del representante legal, y respeto de su derecho a ser escuchado, conforme a la Ley 1098 de 2006 y a la sección correspondiente de la Política de Tratamiento de Datos | Inducción al ingresar al rol, con refuerzo semestral dado el alto volumen de interacción directa con Titulares, datos sensibles y población menor de edad |
| Coordinación Académica (gestión de matrículas y datos de aprendices) | Capacitación específica en el procedimiento de identificación de aprendices menores de edad y en el flujo de autorización reforzada del representante legal (consentimiento informado, verificación documental, registro de la constancia del derecho del menor a ser escuchado), en coordinación con la Oficina Jurídica                                                                                                                                                                                                                                                                                                                                     | Inducción al ingresar al rol, con refuerzo anual y ante cada actualización del procedimiento de matrícula                                                 |
| Punto de Contacto para Titulares                                         | Capacitación específica en el procedimiento de consultas y reclamos, manejo de plazos legales, y registro adecuado en la bitácora institucional                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | Inducción al ingresar al rol, con refuerzo anual                                                                                                            |
| Oficina Jurídica / Protección de Datos                                 | Actualización permanente en jurisprudencia y doctrina de la SIC sobre protección de datos personales                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | Continua (inherente al rol)                                                                                                                                  |

---

## 10. PROCEDIMIENTO DE DESIGNACIÓN FORMAL

```
PASO 1 — Socialización de la serie documental completa de la Fase 0
   • Presentar los documentos de Política de Tratamiento de Datos, Inventario de
     Activos, Matriz de Riesgos y este documento de Roles a la Dirección del Centro
        ↓
PASO 2 — Designación de los roles de mayor urgencia
   • Ratificar al Responsable del Tratamiento (Sección 4.1)
   • Vincular formalmente a la Oficina Jurídica (Sección 4.5)
        ↓
PASO 3 — Designación de los roles de urgencia alta
   • Designar al Responsable de Seguridad de la Información (Sección 4.3)
   • Constituir el Comité de Seguridad y Privacidad (Sección 4.2)
   • Designar el Punto de Contacto para Titulares (Sección 4.4)
   • Iniciar el esquema de Respaldo Técnico (Sección 5.2)
        ↓
PASO 4 — Formalización del rol del Administrador del Sistema como Encargado del
   Tratamiento (Sección 5.1), mediante el instrumento que la Oficina Jurídica
   determine apropiado (contrato, acto administrativo, acuerdo de confidencialidad)
        ↓
PASO 5 — Incorporación de las responsabilidades de seguridad y privacidad en los
   perfiles de funciones existentes (Coordinador de Operación, Operadores — Sección 5.3/5.4)
        ↓
PASO 6 — Primera sesión de capacitación y sensibilización con todos los roles
   designados (Sección 9)
        ↓
PASO 7 — Primera sesión formal del Comité de Seguridad: revisión y aprobación
   de la Política de Tratamiento de Datos, el Inventario de Activos y la
   Matriz de Riesgos
```

---

## 11. PLAN DE MANTENIMIENTO Y REVISIÓN DE LA ESTRUCTURA DE ROLES

1. **Revisión ante cambios de personal**: cualquier cambio en las personas que ocupan estos roles (renuncia, traslado, nueva contratación) dispara de inmediato: (a) la actualización de este documento, (b) la ejecución del procedimiento de transición/empalme correspondiente, y (c) la revisión de los accesos asociados.
2. **Revisión integral periódica**: revisión completa de la estructura de roles, como mínimo, una vez al año, o ante cambios significativos en la estructura organizacional del Centro de Formación o en el alcance del sistema SmartCSET.
3. **Evaluación de efectividad**: el Comité de Seguridad evalúa periódicamente si la estructura de roles está funcionando en la práctica — si el Comité se reúne, si las consultas de Titulares se atienden dentro de los plazos, si el Respaldo Técnico mantiene actualizada su documentación.
4. **Sincronización con los demás documentos de la serie**: cualquier cambio en los riesgos, los activos o las obligaciones que implique nuevas responsabilidades se refleja en este documento, y viceversa.

---

|                  | ELABORÓ | REVISÓ | APROBÓ |
| ---------------- | -------- | ------- | ------- |
| **Nombre** |          |         |         |
| **Cargo**  |          |         |         |
| **Fecha**  |          |         |         |
| **Firma**  |          |         |         |

🔲 *Pendiente de diligenciamiento por las instancias institucionales competentes: Administrador del sistema (elaboró), Responsable de Seguridad de la Información (revisó) y Dirección del Centro de Formación (aprobó).*

---

*Fin del documento — Designación de Roles y Responsabilidades en Seguridad y Privacidad de la Información — SmartCSET v1.0*
