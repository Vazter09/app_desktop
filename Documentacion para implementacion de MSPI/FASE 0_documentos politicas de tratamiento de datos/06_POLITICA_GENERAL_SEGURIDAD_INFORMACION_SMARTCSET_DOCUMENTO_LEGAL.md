# POLÍTICA GENERAL DE SEGURIDAD DE LA INFORMACIÓN

## Sistema SmartCSET — Servicio Nacional de Aprendizaje (SENA)

---

| Campo                                  | Valor                                                                            |
| -------------------------------------- | -------------------------------------------------------------------------------- |
| **Documento N°**                | FASE0-PSI-006                                                                    |
| **Versión**                     | 1.0                                                                              |
| **Fecha de elaboración**        | 2026-06-08                                                                       |
| **Elaborado por**                | Equipo de Desarrollo - SmartCSET                                                 |
| **Estado**                       | Borrador para revisión y aprobación por la Dirección del Centro de Formación |
| **Próxima revisión**           | Anual, o ante cambio normativo o modificación sustancial del sistema            |
| **Clasificación del documento** | Uso institucional — Difusión controlada                                        |

---

> ⚠️ **Nota de gobernanza esencial:** Este documento es la **política raíz del Sistema de Gestión de Seguridad de la Información (SGSI)** de SmartCSET. Todos los demás documentos de seguridad y privacidad del sistema —la Política de Tratamiento de Datos Personales, el Inventario de Activos, la Matriz de Riesgos, los Roles y Responsabilidades, el Cronograma de Auditorías, y los planes técnicos de blindaje— son **desarrollos concretos de los principios y compromisos establecidos aquí**. Sin esta política aprobada, los demás documentos carecen del respaldo de gobernanza institucional que los hace exigibles, auditables y sostenibles en el tiempo. Un auditor de MinTIC, del MIPG o de la Contraloría pedirá este documento como primer punto de verificación del cumplimiento del MSPI. Cada sección marcada con 🔲 requiere validación o complemento por la instancia directiva y jurídica competente antes de su aprobación oficial.

---

---

## 1. OBJETO Y ALCANCE

### 1.1 Objeto

Esta Política tiene por objeto establecer los **principios, compromisos, responsabilidades y directrices generales** que rigen la gestión de la seguridad de la información en el sistema **SmartCSET**, operado por el **Servicio Nacional de Aprendizaje — SENA**, en cumplimiento del Modelo de Seguridad y Privacidad de la Información (MSPI) de MinTIC, la normativa colombiana vigente en materia de seguridad digital y protección de datos, y los estándares internacionales referenciados por dicho modelo.

Esta Política define el **Sistema de Gestión de Seguridad de la Información (SGSI)** aplicable a SmartCSET: su alcance, su estructura de gobernanza, sus objetivos, los principios bajo los cuales opera y los compromisos que asume la organización frente a la protección de la información que gestiona.

### 1.2 Alcance

Esta Política aplica a:

- **Todo el sistema SmartCSET** y los activos de información asociados: base de datos, código fuente, servidores, infraestructura de red, interfaces y módulos funcionales (control de acceso, registro de personas, gestión administrativa, módulos de carga de reportes SENA).
- **Toda la información tratada por SmartCSET**, independientemente de su formato, soporte o estado: datos en reposo (almacenados en base de datos, archivos, copias de seguridad), datos en tránsito (comunicaciones entre clientes y servidor, conexiones a base de datos) y datos en procesamiento.
- **Todo el personal** que interactúa con el sistema: administradores técnicos, usuarios operativos (personal de portería, registro y administración), personal de soporte de la Oficina de TI del SENA, desarrolladores, auditores y cualquier tercero con acceso autorizado.
- **Todos los activos físicos y tecnológicos** que soportan la operación del sistema: servidores, equipos terminales, equipos de red, medios de almacenamiento y el entorno físico donde se alojan.

### 1.3 Lo que esta Política NO cubre

- No sustituye ni reemplaza la **Política de Tratamiento de Datos Personales** (documento FASE0-POL-001), que desarrolla en detalle las obligaciones específicas derivadas de la Ley 1581/2012. Ambas políticas son complementarias: esta Política es el marco general; la Política de Tratamiento de Datos es su aplicación específica al ámbito de los datos personales.
- No es un manual técnico de implementación. Los procedimientos técnicos, configuraciones y controles específicos se documentan en el Plan de Blindaje Institucional y sus entregables técnicos por fase.
- No regula sistemas de información del SENA distintos a SmartCSET, salvo en lo que respecta a la circulación de información entre SmartCSET y dichos sistemas.

---

## 2. MARCO NORMATIVO APLICABLE

Esta Política se fundamenta en las siguientes normas, organizadas de mayor a menor jerarquía:

### 2.1 Constitucional

| Norma                                                  | Contenido relevante                                                                                                                   |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Constitución Política de Colombia, Art. 15** | Derecho fundamental a la intimidad y al buen nombre; base constitucional de la protección de datos personales que gestiona SmartCSET |
| **Constitución Política de Colombia, Art. 23** | Derecho de petición — aplicable a las solicitudes de los Titulares de datos sobre sus derechos ARCO                                 |

### 2.2 Legal

| Norma                                                                               | Contenido relevante para SmartCSET                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| ----------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Ley Estatutaria 1581 de 2012**                                              | Régimen general de protección de datos personales — norma matriz de toda la gestión de información personal en el sistema                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| **Ley 1266 de 2008 (Habeas Data)**                                            | Principios de calidad, veracidad y seguridad de las bases de datos                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| **Ley 1273 de 2009 — "De la Protección de la Información y de los Datos"** | **Norma penal de referencia directa:** tipifica como delitos el acceso abusivo a sistemas informáticos (art. 269A), la interceptación de datos informáticos (art. 269C), el daño informático (art. 269D), el uso de software malicioso (art. 269E), la violación de datos personales (art. 269F), la suplantación de sitios web (art. 269G) y el hurto por medios informáticos (art. 269I). Una brecha de seguridad en SmartCSET puede generar **responsabilidad penal para las personas naturales** involucradas, no solo sanciones administrativas para la entidad. |
| **Ley 1712 de 2014 (Transparencia y Acceso a Información Pública)**         | Obligaciones de las entidades públicas en materia de publicación, clasificación y reserva de información                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| **Ley 594 de 2000 (Ley General de Archivos)**                                 | Marco de gestión documental aplicable a la conservación y disposición final de la información registrada por SmartCSET                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| **Ley 1098 de 2006 (Código de la Infancia y la Adolescencia)**               | Protección reforzada de datos de menores de edad (aprendices del SENA)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |

### 2.3 Reglamentario

| Norma                                                                   | Contenido relevante                                                                                                                                                                                                                                                  |
| ----------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Decreto Único Reglamentario 1074 de 2015, Título 2, Cap. 25** | Reglamentación de la Ley 1581/2012 — autorización del Titular, políticas de tratamiento, ejercicio de derechos                                                                                                                                                   |
| **Decreto Único Reglamentario 1078 de 2015 (DUR-TIC)**           | Marco regulatorio del sector TIC; incluye los lineamientos de Gobierno Digital y el**Modelo de Seguridad y Privacidad de la Información (MSPI)** como instrumento de política pública de obligatorio acatamiento para entidades del Estado                  |
| **Decreto 338 de 2022**                                           | Define las Infraestructuras Críticas Cibernéticas (ICC) y establece la institucionalidad de ciberseguridad nacional; clasifica al sector Educación (al que pertenece el SENA) como sector estratégico; fundamenta la evaluación de SmartCSET como potencial ICC |
| **Decreto 886 de 2014**                                           | Registro Nacional de Bases de Datos (RNBD) ante la SIC                                                                                                                                                                                                               |

### 2.4 Política pública y lineamientos técnicos

| Norma / Lineamiento                                                                  | Contenido relevante                                                                                                                                                                                                                         |
| ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **CONPES 3854 de 2016 — Política Nacional de Seguridad Digital**             | Marco de política pública que establece la gestión de riesgos digitales como responsabilidad de todas las entidades del Estado                                                                                                           |
| **CONPES 3995 de 2020 — Política Nacional de Confianza y Seguridad Digital** | Lineamiento vigente que orienta la postura de ciberseguridad estatal colombiana; exige a las entidades públicas adoptar medidas activas de protección de sus sistemas de información y gestionar sus riesgos digitales de forma continua |
| **MSPI — Modelo de Seguridad y Privacidad de la Información (MinTIC)**       | Marco metodológico de aplicación obligatoria para entidades públicas colombianas; establece el ciclo de vida del SGSI, los 11 ejes de gestión, los roles, los indicadores y los instrumentos de evaluación del estado de seguridad     |
| **ISO/IEC 27001:2022**                                                         | Estándar internacional de referencia del MSPI para el diseño e implementación de Sistemas de Gestión de Seguridad de la Información; sus controles del Anexo A son el catálogo técnico de medidas adoptado por el MSPI               |
| **OWASP Top 10 (edición vigente)**                                            | Referencia técnica de vulnerabilidades críticas en aplicaciones web; insumo directo para la gestión de riesgos técnicos de SmartCSET                                                                                                    |

---

## 3. DEFINICIONES

Para efectos de esta Política, se adoptan las siguientes definiciones:

| Término                               | Definición                                                                                                                                                                                                                       | Aplicación en SmartCSET                                                                                                                                                                                          |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Seguridad de la información** | Preservación de la confidencialidad, integridad y disponibilidad de la información (Tríada CIA); puede incluir también propiedades adicionales como autenticidad, responsabilidad, no repudio y confiabilidad (ISO/IEC 27000) | Protección de todos los datos gestionados por SmartCSET frente a acceso no autorizado, alteración indebida e indisponibilidad                                                                                   |
| **Confidencialidad**             | Propiedad de que la información no esté disponible ni sea divulgada a individuos, entidades o procesos no autorizados                                                                                                           | Los datos de `tab_personas` y `tab_log_ingresos` solo son accesibles para el personal con rol autorizado; la cédula y la fotografía se protegen con cifrado en reposo                                       |
| **Integridad**                   | Propiedad de exactitud y completitud de la información y sus métodos de procesamiento                                                                                                                                           | Las funciones PL/pgSQL garantizan que ningún dato se modifica fuera del flujo autorizado; las columnas de auditoría `usr_insert`, `fec_insert`, `usr_update`, `fec_update` registran toda modificación |
| **Disponibilidad**               | Propiedad de ser accesible y utilizable bajo demanda por una entidad autorizada                                                                                                                                                   | SmartCSET debe estar operativo durante el horario de portería del Centro de Formación; una indisponibilidad afecta directamente la operación del SENA                                                          |
| **SGSI**                         | Sistema de Gestión de Seguridad de la Información — conjunto de políticas, procedimientos, controles, roles y recursos que, tomados en conjunto, gestionan la seguridad de la información de forma sistemática y continua   | El conjunto de documentos, controles técnicos, roles y procesos de auditoría de SmartCSET, articulados por esta Política                                                                                       |
| **Activo de información**       | Cualquier dato, sistema, proceso, persona, hardware o software que tiene valor para la organización desde la perspectiva de la información que porta o procesa                                                                  | Definidos y clasificados en el Inventario de Activos (FASE0-INV-002)                                                                                                                                              |
| **Riesgo de seguridad**          | Posibilidad de que una amenaza explote una vulnerabilidad de un activo y cause un impacto negativo sobre la confidencialidad, integridad o disponibilidad de la información                                                      | Identificados, valorados y priorizados en la Matriz de Riesgos (FASE0-RIE-003)                                                                                                                                    |
| **Control de seguridad**         | Medida que modifica el riesgo — puede ser técnica, administrativa u organizacional                                                                                                                                              | Controles técnicos: cifrado, prepared statements, rate limiting; controles administrativos: esta Política, los roles, el cronograma de auditorías                                                              |
| **Incidente de seguridad**       | Evento —o serie de eventos— que compromete, amenaza o tiene el potencial de comprometer la confidencialidad, integridad o disponibilidad de la información                                                                     | Desde un intento de acceso fallido sistemático hasta una brecha confirmada de datos personales                                                                                                                   |
| **Vulnerabilidad**               | Debilidad de un activo o control que puede ser explotada por una amenaza                                                                                                                                                          | Ausencia de rate limiting, sesiones sin flags de seguridad, funciones PL/pgSQL sin desplegar                                                                                                                      |
| **Amenaza**                      | Causa potencial de un incidente de seguridad no deseado                                                                                                                                                                           | Ataques de fuerza bruta al login, inyección SQL, ransomware, acceso físico no autorizado al servidor                                                                                                            |

---

## 4. PRINCIPIOS RECTORES DEL SGSI

El SGSI de SmartCSET opera bajo los siguientes principios, alineados con el MSPI de MinTIC y con el estándar ISO/IEC 27001:

### 4.1 Tríada CIA — Fundamento de toda decisión de seguridad

Toda decisión técnica, administrativa u organizacional relacionada con la información de SmartCSET se evalúa en función de su impacto sobre los tres pilares de la seguridad de la información:

| Pilar                          | Definición                                                                            | Medidas primarias en SmartCSET                                                                                          |
| ------------------------------ | -------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **Confidencialidad (C)** | La información solo es accesible para quien está autorizado                          | Control de acceso basado en roles, cifrado en reposo de campos sensibles, autenticación con bcrypt, rate limiting      |
| **Integridad (I)**       | La información es exacta y no ha sido alterada por personas o procesos no autorizados | Prepared statements (sin SQL dinámico), validaciones PL/pgSQL, columnas de auditoría en todas las tablas, CSRF tokens |
| **Disponibilidad (D)**   | La información está accesible para los usuarios autorizados cuando la necesitan      | Plan de copias de seguridad, procedimiento de recuperación ante incidentes, continuidad operativa manual como respaldo |

### 4.2 Principio de mínimo privilegio

Ningún usuario, proceso o componente del sistema tiene más permisos de los estrictamente necesarios para cumplir su función. Esto aplica a: usuarios del sistema (roles y menús asignados individualmente en `tab_menu_usuarios`), el usuario de base de datos con el que PHP conecta a PostgreSQL (permisos limitados al esquema de la aplicación, sin DDL), y el acceso físico y lógico a los servidores.

### 4.3 Principio de defensa en profundidad

La seguridad no depende de un único control. SmartCSET implementa múltiples capas de protección de forma que el fallo de un control no comprometa la totalidad del sistema: capa de red (firewall, TLS), capa de aplicación (autenticación, CSRF, headers HTTP), capa de base de datos (prepared statements, funciones PL/pgSQL, cifrado en reposo) y capa organizacional (roles, auditorías, capacitación).

### 4.4 Principio de responsabilidad demostrada (*accountability*)

La organización es capaz de demostrar, ante cualquier auditor o ente de control, que cumple con sus obligaciones en materia de seguridad de la información. Esto implica mantener evidencia documentada de los controles implementados, las auditorías realizadas, los incidentes gestionados y las capacitaciones impartidas.

### 4.5 Principio de mejora continua

El SGSI no es un estado final, sino un ciclo permanente de planificación, implementación, verificación y mejora (ciclo PHVA: Planear-Hacer-Verificar-Actuar). Los hallazgos de auditoría, los incidentes ocurridos y los cambios normativos o tecnológicos alimentan iteraciones sucesivas de mejora del sistema de gestión.

### 4.6 Principio de proporcionalidad

Los controles de seguridad implementados son proporcionales a los riesgos identificados y al contexto operativo del Centro de Formación. No se sobrecarga la operación con controles innecesarios, pero tampoco se omiten controles necesarios por razones de conveniencia operativa.

---

## 5. COMPROMISOS DE LA ALTA DIRECCIÓN

La Dirección del Centro de Formación — SENA, en su calidad de Responsable del Tratamiento y máxima autoridad institucional sobre SmartCSET, asume formalmente los siguientes compromisos:

1. **Aprobar y publicar** esta Política General de Seguridad de la Información, asumiendo la responsabilidad institucional por su cumplimiento.
2. **Asignar los recursos necesarios** para la operación del SGSI: tiempo del personal, acceso a herramientas, apoyo de la Oficina de TI y presupuesto para capacitación y mejoras tecnológicas.
3. **Designar formalmente los roles** de seguridad de la información definidos en el documento FASE0-ROL-004, con nombres, cargos y responsabilidades concretas.
4. **Garantizar la integración** de los requisitos de seguridad de la información en los procesos del Centro de Formación que involucran a SmartCSET: procesos de matrícula, control de acceso, generación de reportes y gestión de personal.
5. **Promover activamente una cultura de seguridad** entre el personal del Centro, liderando con el ejemplo en el cumplimiento de esta Política y de las normas de uso del sistema.
6. **Revisar el desempeño del SGSI** al menos una vez al año, tomando decisiones informadas sobre su mejora a partir de los resultados de auditorías, indicadores de gestión e incidentes ocurridos.
7. **Cumplir y hacer cumplir** la normativa legal colombiana aplicable, asumiendo que el incumplimiento puede acarrear consecuencias jurídicas, económicas, reputacionales y operativas para la entidad y para las personas naturales responsables.

🔲 *Este compromiso debe ser formalizado mediante acto administrativo, resolución o comunicación oficial de la Dirección del Centro de Formación, con fecha y firma.*

---

## 6. ALCANCE DEL SISTEMA DE GESTIÓN DE SEGURIDAD DE LA INFORMACIÓN

### 6.1 Declaración de alcance

El SGSI de SmartCSET cubre la **gestión de seguridad de la información del sistema de registro y control de personal del Centro de Formación SENA**, incluyendo:

- Los procesos de negocio soportados: control de acceso de personas (ingreso/salida), registro de visitantes, aprendices, instructores, funcionarios y contratistas, gestión administrativa de programas y fichas, y generación de reportes institucionales.
- Los activos de información que soportan dichos procesos, conforme al inventario FASE0-INV-002.
- Las ubicaciones físicas donde se procesan o almacenan datos del sistema: sala de portería, oficinas administrativas con acceso al sistema y cuarto de servidores del Centro de Formación.

### 6.2 Exclusiones justificadas

| Elemento excluido                                                       | Justificación                                                                                                                      |
| ----------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| Otros sistemas de información del SENA (SofiaPlus, sistemas centrales) | Están fuera del control directo del Centro de Formación y tienen sus propios SGSI institucionales                                 |
| Dispositivos personales del personal (BYOD)                             | SmartCSET no permite acceso desde dispositivos no autorizados; no aplica                                                            |
| Módulo de IA (si se implementa en el futuro)                           | Requiere evaluación específica conforme al marco NIST AI RMF y al CONPES 4144/2025; se gestionará en una fase posterior del SGSI |

---

## 7. OBJETIVOS DE SEGURIDAD DE LA INFORMACIÓN

Los siguientes objetivos son medibles, revisables anualmente y alineados con la Matriz de Riesgos (FASE0-RIE-003) y el Cronograma de Auditorías (FASE0-AUD-005):

| #    | Objetivo                                                                           | Indicador de cumplimiento                                                                            | Meta                                                                                    | Responsable de medición                           |
| ---- | ---------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- | -------------------------------------------------- |
| O-01 | Proteger la confidencialidad de los datos personales almacenados en SmartCSET      | % de campos sensibles cifrados en reposo; N° de accesos no autorizados detectados                   | 100% de campos sensibles cifrados; 0 accesos no autorizados exitosos                    | Administrador del sistema                          |
| O-02 | Garantizar la integridad de los registros de ingreso/salida                        | N° de registros con inconsistencias detectadas en auditoría                                        | 0 inconsistencias no justificadas por auditoría trimestral                             | Responsable de Seguridad de la Información        |
| O-03 | Mantener la disponibilidad del sistema durante el horario de operación del Centro | % de tiempo de disponibilidad en horario de portería; tiempo de recuperación ante incidentes (RTO) | ≥ 99% de disponibilidad en horario de portería; RTO ≤ 4 horas                        | Oficina TI SENA                                    |
| O-04 | Gestionar los riesgos críticos identificados en la Matriz de Riesgos              | % de riesgos críticos con controles implementados                                                   | 100% de riesgos calificados "Crítico" o "Alto" con al menos un control técnico activo | Administrador del sistema                          |
| O-05 | Garantizar el cumplimiento de la normativa colombiana aplicable                    | N° de hallazgos de incumplimiento normativo en auditoría anual                                     | 0 hallazgos de incumplimiento de Ley 1581, Ley 1273 o MSPI en la auditoría anual       | Oficina Jurídica / Responsable de Seguridad       |
| O-06 | Detectar y responder oportunamente a incidentes de seguridad                       | Tiempo de detección; tiempo de notificación a la SIC cuando aplica                                 | Detección en ≤ 24 horas; notificación a SIC en los plazos legales                    | Equipo de respuesta a incidentes                   |
| O-07 | Capacitar al personal en seguridad de la información                              | % de personal con acceso al sistema que recibió capacitación en el año                            | 100% del personal con acceso capacitado anualmente                                      | Coordinador de Operación del Registro de Personal |

---

## 8. ESTRUCTURA DE GOBERNANZA DEL SGSI

La estructura de gobernanza del SGSI de SmartCSET está detallada en el documento **FASE0-ROL-004 — Designación de Roles y Responsabilidades en Seguridad y Privacidad de la Información**. Esta sección resume los roles clave y su relación con la presente Política.

### 8.1 Jerarquía de gobernanza

```
DIRECCIÓN DEL CENTRO DE FORMACIÓN — SENA
    │  Responsable del Tratamiento / Máxima autoridad institucional
    │  Aprueba esta Política; asigna recursos; lidera el SGSI
    │
    ├── RESPONSABLE DE SEGURIDAD DE LA INFORMACIÓN (RSSI)
    │       Gestiona el SGSI en el día a día; coordina auditorías;
    │       escala incidentes; mantiene la documentación actualizada
    │
    ├── ADMINISTRADOR DEL SISTEMA (Encargado técnico)
    │       Implementa controles técnicos; gestiona accesos; responde
    │       a incidentes técnicos; aplica parches y actualizaciones
    │
    ├── OFICINA JURÍDICA
    │       Valida cumplimiento normativo; representa ante la SIC;
    │       actualiza la Política ante cambios normativos
    │
    ├── OFICINA DE TI DEL SENA
    │       Infraestructura de red y servidores; copias de seguridad;
    │       firewall; acceso físico al cuarto de servidores
    │
    └── OFICINA DE CONTROL INTERNO
            Audita el cumplimiento del SGSI; reporta hallazgos
            a la Dirección; verifica la eficacia de los controles
```

### 8.2 Instrumentos de gobierno del SGSI

| Instrumento                                        | Documento                      | Periodicidad de revisión                     |
| -------------------------------------------------- | ------------------------------ | --------------------------------------------- |
| Política General de Seguridad de la Información  | Este documento (FASE0-PSI-006) | Anual                                         |
| Política de Tratamiento de Datos Personales       | FASE0-POL-001                  | Anual o ante cambio normativo                 |
| Inventario de Activos de Información              | FASE0-INV-002                  | Semestral o ante cambios en el sistema        |
| Matriz de Riesgos de Seguridad                     | FASE0-RIE-003                  | Semestral o ante nuevos riesgos identificados |
| Designación de Roles y Responsabilidades          | FASE0-ROL-004                  | Ante cambios de personal o estructura         |
| Cronograma de Auditorías Periódicas              | FASE0-AUD-005                  | Anual                                         |
| Política de Control de Acceso y Seguridad Física | FASE0-ACC-007                  | Anual                                         |
| Marco de Gestión de Incidentes y Continuidad      | FASE0-INC-008                  | Anual o tras un incidente significativo       |

---

## 9. GESTIÓN DE RIESGOS DE SEGURIDAD DE LA INFORMACIÓN

### 9.1 Enfoque metodológico

SmartCSET adopta un **enfoque de gestión de riesgos basado en el contexto**, conforme al Modelo Nacional de Gestión del Riesgo de Seguridad de la Información de MinTIC (documento MSPI-05) y alineado con la norma ISO/IEC 27005. Este enfoque sigue el ciclo:

```
IDENTIFICAR riesgos  →  VALORAR (probabilidad × impacto)  →  TRATAR (aceptar, mitigar, transferir, evitar)
        ↑                                                                          |
        └──────────────────── MONITOREAR y REVISAR ←──────────────────────────────┘
```

### 9.2 Criterios de aceptación del riesgo

La organización no acepta riesgos que combinen una probabilidad Alta o Muy Alta con un impacto Alto o Muy Alto (zona roja del mapa de calor). Estos riesgos requieren tratamiento activo con controles implementados y verificados antes de considerarlos gestionados. Los detalles del apetito de riesgo, las escalas de valoración y el inventario completo de riesgos están en la **Matriz de Riesgos (FASE0-RIE-003)**.

### 9.3 Ciclo de revisión de riesgos

| Evento desencadenante                                                                      | Acción requerida                                                                |
| ------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------- |
| Auditoría semestral o anual                                                               | Revisión completa de la Matriz de Riesgos                                       |
| Cambio funcional significativo en SmartCSET                                                | Evaluación de impacto en riesgos existentes e identificación de nuevos riesgos |
| Incidente de seguridad                                                                     | Revisión de los riesgos asociados al tipo de incidente ocurrido                 |
| Cambio normativo relevante                                                                 | Evaluación de los riesgos de cumplimiento                                       |
| Publicación de vulnerabilidad crítica en componentes usados (PHP, PostgreSQL, Bootstrap) | Evaluación inmediata del riesgo técnico correspondiente                        |

---

## 10. RESPONSABILIDADES GENERALES POR NIVEL

Esta sección establece las responsabilidades en materia de seguridad de la información para cada nivel de la organización. Las responsabilidades específicas y detalladas por rol se encuentran en el documento FASE0-ROL-004.

### 10.1 Dirección del Centro de Formación

- Aprobar y respaldar institucionalmente esta Política y todas las políticas del SGSI.
- Asegurar que la seguridad de la información sea una prioridad organizacional reflejada en decisiones de recursos y de proceso.
- Rendir cuentas ante entes de control (Contraloría, MinTIC, SIC) sobre el estado del SGSI.

### 10.2 Responsable de Seguridad de la Información (RSSI)

- Coordinar la implementación, operación y mejora del SGSI.
- Mantener actualizados los documentos del SGSI y asegurar su coherencia.
- Reportar el estado del SGSI a la Dirección al menos trimestralmente.
- Escalar oportunamente los incidentes de seguridad que superen los umbrales de severidad definidos.

### 10.3 Administrador técnico del sistema

- Implementar y mantener los controles técnicos de seguridad definidos en los planes de blindaje.
- Gestionar los accesos de usuarios: altas, modificaciones y bajas conforme al principio de mínimo privilegio.
- Aplicar parches de seguridad en los plazos definidos en la Política de Gestión de Activos.
- Documentar los cambios realizados al sistema con suficiente detalle para soportar auditorías.

### 10.4 Usuarios operativos (personal de portería, registro y administración)

- Utilizar SmartCSET exclusivamente para las finalidades institucionales autorizadas.
- Custodiar sus credenciales de acceso: no compartir contraseñas, no dejar sesiones abiertas sin supervisión, bloquear la pantalla al ausentarse del puesto.
- Reportar de forma inmediata cualquier comportamiento inusual del sistema o cualquier situación que pueda constituir un incidente de seguridad.
- Cumplir con la política de contraseñas y las normas de uso del sistema establecidas por el Administrador.

### 10.5 Personal de la Oficina de TI del SENA con acceso de soporte

- Acceder a la infraestructura de SmartCSET solo bajo solicitud formal y con propósito documentado.
- No conservar copias de datos del sistema fuera del entorno autorizado.
- Registrar todas las operaciones realizadas sobre la infraestructura del sistema (base de datos, servidor, red).
- Firmar el acuerdo de confidencialidad correspondiente antes de obtener acceso.

---

## 11. CÓDIGO DE CONDUCTA Y ÉTICA PROFESIONAL EN EL USO DE LA INFORMACIÓN

### 11.1 Principios de conducta

Toda persona con acceso a SmartCSET, independientemente de su rol, nivel jerárquico o vínculo con la entidad (empleado, contratista, aprendiz en práctica, personal de soporte externo), asume el compromiso de:

1. **Usar la información exclusivamente para los fines institucionales autorizados.** La información del sistema no puede ser consultada, copiada, transmitida ni utilizada para propósitos personales, comerciales, políticos o ajenos a la función institucional.
2. **Respetar la confidencialidad de la información a la que accede**, incluso después de finalizado su vínculo con el Centro de Formación o con SmartCSET. La obligación de confidencialidad no cesa con el término del contrato o cargo.
3. **No divulgar información del sistema a personas no autorizadas**, ya sea de forma deliberada o por descuido. Esto incluye conversaciones en entornos públicos, mensajes de texto o correos electrónicos a destinatarios no autorizados, y publicaciones en redes sociales.
4. **Reportar cualquier incidente o sospecha de incidente de seguridad** de forma inmediata, sin intentar resolverlo de forma independiente cuando ello pueda destruir evidencia o agravar el incidente.
5. **No intentar acceder a información o funcionalidades del sistema para las que no se tiene autorización**, aunque existan medios técnicos que pudieran permitirlo. El acceso no autorizado, incluso dentro de la misma red institucional, constituye una conducta sancionable y puede tipificarse como delito conforme a la Ley 1273 de 2009.
6. **Actuar con diligencia en la custodia de los dispositivos y credenciales** a su cargo: no prestar equipos de trabajo, no abandonar sesiones activas sin supervisión, no anotar contraseñas en lugares visibles.

### 11.2 Conflicto de interés en el uso de la información

Cuando un usuario advierte que el uso de la información podría generar un beneficio personal o un perjuicio para un tercero ajeno a la finalidad institucional del sistema, debe:

1. Abstenerse de usar la información para ese propósito.
2. Reportar la situación al RSSI o a la Dirección del Centro.
3. Documentar el reporte para efectos de trazabilidad.

### 11.3 Uso aceptable de los recursos del sistema

| Uso                                                              | Permitido | Condición                                                                                             |
| ---------------------------------------------------------------- | --------- | ------------------------------------------------------------------------------------------------------ |
| Consultar registros de personas para verificar acceso            | ✅        | Solo para personal de portería en ejercicio de su función                                            |
| Generar reportes institucionales para el SENA                    | ✅        | Solo por personal administrativo autorizado, para las finalidades de la Sección 5 de FASE0-POL-001    |
| Acceder al sistema desde equipos no autorizados                  | ❌        | Nunca                                                                                                  |
| Compartir credenciales con otro usuario                          | ❌        | Nunca — cada usuario tiene credenciales individuales e intransferibles                                |
| Exportar o copiar bases de datos fuera del entorno institucional | ❌        | Nunca, salvo copias de seguridad ejecutadas por el Administrador en el marco del procedimiento oficial |
| Instalar software no autorizado en los servidores del sistema    | ❌        | Nunca sin aprobación del Administrador y la Oficina de TI                                             |

---

## 12. CUMPLIMIENTO LEGAL, NORMATIVO Y CONTRACTUAL

### 12.1 Mapa de obligaciones legales de cumplimiento

| Norma                               | Obligación concreta para SmartCSET                                                                                            | Control que la satisface                                                                |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------- |
| **Ley 1581/2012, art. 17(d)** | Guardar seguridad de los datos para impedir su adulteración, pérdida, consulta, uso o acceso no autorizado                   | Controles técnicos del Plan de Blindaje (cifrado, autenticación, rate limiting, CSRF) |
| **Ley 1581/2012, art. 17(n)** | Informar a la SIC cuando se presenten violaciones a los códigos de seguridad                                                  | Procedimiento de incidentes (FASE0-POL-001 Sección 15 + FASE0-INC-008)                 |
| **Ley 1273/2009, art. 269A**  | El acceso abusivo a sistemas informáticos es delito penal — la organización debe tomar medidas para prevenirlo y detectarlo | Rate limiting, logging de intentos, alertas de acceso no autorizado                     |
| **Ley 1273/2009, art. 269F**  | La violación de datos personales es delito penal                                                                              | Cifrado en reposo, control de acceso, políticas de confidencialidad                    |
| **Decreto 338/2022**          | Evaluar si el sistema califica como ICC y, si aplica, registrarse ante COLCERT                                                 | Evaluación documentada en FASE0-INV-002 Sección 12                                    |
| **MSPI MinTIC — Eje 1**      | Gobierno de seguridad: política de seguridad aprobada por la alta dirección                                                  | **Este documento** (política raíz del SGSI SmartCSET)                             |
| **MSPI MinTIC — Eje 2**      | Gestión de riesgos: identificar, evaluar y tratar riesgos de seguridad                                                        | FASE0-RIE-003 + revisiones periódicas; Sección 6 de este documento                    |
| **MSPI MinTIC — Eje 3**      | Gestión de activos: inventariar y clasificar los activos de información                                                       | FASE0-INV-002; Sección 5 de este documento                                             |
| **MSPI MinTIC — Eje 4**      | Seguridad del personal: acuerdos de confidencialidad, formación y desvinculación segura                                       | FASE0-ROL-004; Sección 9 de este documento (cláusulas de confidencialidad)             |
| **MSPI MinTIC — Eje 5**      | Seguridad física: protección del cuarto de servidores y acceso físico controlado                                              | FASE0-ACC-007 Sección 9 (seguridad física del entorno)                                 |
| **MSPI MinTIC — Eje 6**      | Seguridad en comunicaciones y operaciones: TLS, backups, gestión de parches                                                   | FASE1-BLI-001 E8 (hardening de red), E9 (parches), E2 (cifrado)                       |
| **MSPI MinTIC — Eje 7**      | Control de acceso: autenticación, autorización, gestión del ciclo de vida de accesos                                          | FASE0-ACC-007; FASE1-BLI-001 E3 (rate limiting), E4 (sesiones), E5 (CSRF)            |
| **MSPI MinTIC — Eje 8**      | Adquisición, desarrollo y mantenimiento: SDLC seguro y gestión de componentes                                                 | FASE1-BLI-001 E10 (SDLC seguro), E9 (gestión de parches); Sección 10 de este doc      |
| **MSPI MinTIC — Eje 9**      | Gestión de incidentes: detección, respuesta, notificación y lecciones aprendidas                                              | FASE0-INC-008; Sección 14 de este documento                                            |
| **MSPI MinTIC — Eje 10**     | Continuidad del negocio: BCP, DRP, RTO y RPO definidos                                                                       | FASE0-INC-008 Secciones 12-14 (RTO=4h, RPO=24h, DRP en 7 pasos)                      |
| **MSPI MinTIC — Eje 11**     | Cumplimiento legal: Ley 1581, Ley 1273, Ley 1712, CONPES 3995, Decreto 338/2022                                              | Sección 12 de este documento; FASE0-POL-001; FASE0-AUD-005                             |
| **CONPES 3995/2020**          | Las entidades públicas deben adoptar medidas activas de gestión de sus riesgos de seguridad digital                          | SGSI completo de SmartCSET — esta Política y sus documentos complementarios           |

### 12.2 Registro Nacional de Bases de Datos (RNBD)

Conforme al Decreto 886 de 2014, el SENA —como Responsable del Tratamiento— debe registrar las bases de datos de personas naturales ante la Superintendencia de Industria y Comercio (SIC) a través del RNBD. La base de datos `db_smartcset`, que contiene la tabla `tab_personas` y el `tab_log_ingresos`, califica para dicho registro.

🔲 *La Oficina Jurídica del Centro de Formación debe verificar si el SENA ya ha realizado este registro a nivel central y, en caso contrario, iniciar el trámite ante la SIC.*

### 12.3 Notificación de incidentes a entes externos

| Situación                                                         | Ente receptor                                  | Plazo                                                    | Norma                     |
| ------------------------------------------------------------------ | ---------------------------------------------- | -------------------------------------------------------- | ------------------------- |
| Vulneración de datos personales con riesgo para los Titulares     | Superintendencia de Industria y Comercio (SIC) | Conforme al protocolo de notificación de la SIC vigente | Ley 1581/2012, art. 17(n) |
| Incidente informático que configure un delito de la Ley 1273/2009 | Fiscalía General de la Nación / CSIRT-CCIT   | Inmediatamente tras la confirmación                     | Ley 1273/2009             |
| Incidente en sistema que califique como ICC                        | COLCERT — Centro Cibernético Policial        | Según los protocolos del Decreto 338/2022               | Decreto 338/2022          |

---

## 13. CONSECUENCIAS DEL INCUMPLIMIENTO

El incumplimiento de esta Política y de las normas de seguridad que de ella se derivan puede generar consecuencias en los siguientes ámbitos:

### 13.1 Consecuencias disciplinarias

El personal vinculado al SENA (empleados, aprendices en práctica, contratistas) que incumpla esta Política se expone a las medidas disciplinarias establecidas en el régimen disciplinario del SENA, el Código Disciplinario Único (Ley 734 de 2002) o las cláusulas del contrato, según el tipo de vínculo.

### 13.2 Consecuencias civiles

El SENA, como Responsable del Tratamiento, puede ser objeto de sanciones de la Superintendencia de Industria y Comercio por incumplimiento de la Ley 1581/2012, que incluyen multas hasta de 2.000 salarios mínimos mensuales legales vigentes por infracción, y hasta 100 salarios por cada día de mora en el cumplimiento de una instrucción de la SIC (art. 23, Ley 1581/2012).

### 13.3 Consecuencias penales

La Ley 1273 de 2009 tipifica como delitos penales, entre otros:

- **Acceso abusivo a un sistema informático** (art. 269A): prisión de 48 a 96 meses y multa.
- **Violación de datos personales** (art. 269F): prisión de 48 a 96 meses.
- **Hurto por medios informáticos** (art. 269I): prisión de 3 a 8 años.

Estas penas aplican a las **personas naturales** que cometan las conductas, no solo a la entidad. Cualquier funcionario, contratista o tercero que acceda, use, transmita o sustraiga información de SmartCSET sin autorización puede enfrentar responsabilidad penal individual.

### 13.4 Consecuencias reputacionales e institucionales

Una brecha de seguridad en un sistema del SENA que afecte datos de aprendices —especialmente menores de edad— tiene un impacto reputacional severo para el Centro de Formación y para el SENA como institución. Adicionalmente, puede derivar en:

- Suspensión o revocación de la autorización para operar el sistema.
- Auditorías extraordinarias por parte de la Contraloría o el MIPG.
- Exigencia de implementación de controles adicionales bajo supervisión de la SIC.

---

## 14. RELACIÓN CON OTROS DOCUMENTOS DEL SGSI

Esta Política es el documento raíz. Los siguientes documentos la desarrollan y complementan:

| Documento                                                                     | Relación con esta Política                                                                                                |
| ----------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **FASE0-POL-001** — Política de Tratamiento de Datos Personales       | Desarrolla el principio de confidencialidad y los requisitos de la Ley 1581/2012 para los datos personales específicamente |
| **FASE0-INV-002** — Inventario de Activos C-I-D                        | Materializa la Sección 6 (Alcance del SGSI) con el catálogo de activos sobre los que aplica esta Política                |
| **FASE0-RIE-003** — Matriz de Riesgos                                  | Desarrolla la Sección 9 (Gestión de Riesgos) con la identificación, valoración y tratamiento de riesgos específicos    |
| **FASE0-ROL-004** — Roles y Responsabilidades                          | Desarrolla la Sección 8 (Estructura de Gobernanza) y la Sección 10 (Responsabilidades) con el detalle de cada rol         |
| **FASE0-AUD-005** — Cronograma de Auditorías                          | Instrumentaliza el principio de mejora continua (Sección 4.5) y los indicadores de la Sección 7                           |
| **FASE0-ACC-007** — Política de Control de Acceso y Seguridad Física | Desarrolla el principio de mínimo privilegio (Sección 4.2) y los controles del Objetivo O-01                              |
| **FASE0-INC-008** — Marco de Gestión de Incidentes y Continuidad      | Desarrolla el Objetivo O-03 (disponibilidad), la Sección 12.3 (notificaciones) y el Objetivo O-06 (respuesta a incidentes) |
| **Plan de Blindaje Institucional (Fases 1-5)**                          | Implementación técnica y operativa de los controles que satisfacen los objetivos y principios de esta Política           |

---

## 15. VIGENCIA, REVISIÓN Y ACTUALIZACIÓN

1. Esta Política entra en vigencia a partir de su aprobación formal por la Dirección del Centro de Formación y su publicación y socialización al personal involucrado.
2. Esta Política se revisa, como mínimo, **una vez al año**, en el marco de la auditoría anual definida en FASE0-AUD-005.
3. Se realiza una revisión **extraordinaria** cuando ocurra cualquiera de las siguientes situaciones:
   - Cambio normativo relevante (nueva ley, decreto, circular de la SIC o lineamiento de MinTIC).
   - Incidente de seguridad de severidad Alta o Crítica que evidencie necesidad de ajuste.
   - Cambio significativo en el alcance o la arquitectura de SmartCSET.
   - Resultado de auditoría que identifique brechas en la política vigente.
   - Cambio en la estructura organizacional del Centro de Formación que afecte los roles del SGSI.
4. Toda modificación queda registrada en el histórico de versiones del documento, con indicación de la versión, la fecha, los cambios realizados y el motivo. Este histórico es evidencia del principio de responsabilidad demostrada (*accountability*).
5. Las versiones anteriores de esta Política se archivan y conservan como parte del sistema de gestión documental, de forma que siempre sea posible determinar qué versión regía en un momento dado.

---

## 16. APROBACIÓN INSTITUCIONAL

|                  | ELABORÓ | REVISÓ | APROBÓ |
| ---------------- | -------- | ------- | ------- |
| **Nombre** |          |         |         |
| **Cargo**  |          |         |         |
| **Fecha**  |          |         |         |
| **Firma**  |          |         |         |

🔲 *Pendiente de diligenciamiento por las instancias institucionales competentes: Responsable de Seguridad de la Información (elaboró), Oficina Jurídica (revisó) y Dirección del Centro de Formación (aprobó).*

---

*Fin del documento — Política General de Seguridad de la Información — SmartCSET v1.0*
