# MARCO DE GESTIÓN DE INCIDENTES DE SEGURIDAD Y CONTINUIDAD OPERATIVA

## Sistema SmartCSET — Servicio Nacional de Aprendizaje (SENA)

---

| Campo                                  | Valor                                                                                         |
| -------------------------------------- | --------------------------------------------------------------------------------------------- |
| **Documento N°**                | FASE0-INC-008                                                                                 |
| **Versión**                     | 1.0                                                                                           |
| **Elaborado por**                | Equipo de Desarrollo - SmartCSET                                                              |
| **Estado**                       | Borrador para revisión y aprobación por la Dirección del Centro de Formación              |
| **Próxima revisión**           | Anual, o de forma inmediata tras cualquier incidente significativo o ejercicio de simulación |
| **Clasificación del documento** | Uso institucional — Difusión controlada                                                     |

---

> ⚠️ **Nota de gobernanza esencial:** Un sistema de información puede estar perfectamente asegurado en el papel —con todos los controles técnicos y las políticas correctas— y aun así sufrir incidentes. Los incidentes no son la excepción: son inevitables. La diferencia entre una organización que absorbe un incidente con impacto mínimo y una que experimenta una crisis irreversible no está en haber evitado el incidente, sino en **qué tan rápido detecta que algo está ocurriendo, qué tan ordenadamente responde y qué tan bien recupera la operación normal**. Este Marco establece, para SmartCSET, las definiciones, roles, procedimientos y criterios de decisión que permiten enfrentar cualquier incidente de seguridad de la información de forma estructurada, reproducible y auditable. Es requisito del MSPI de MinTIC (Ejes 9 y 10), de la norma ISO/IEC 27001 (Annex A, controles 5.24 a 5.28) y del temario ISC2 CC (Dominio 2 — Business Continuity, Disaster Recovery & Incident Response). Cada sección marcada con 🔲 requiere validación o complemento por la instancia directiva antes de su aprobación oficial.

---

---

## 1. OBJETO Y ALCANCE

### 1.1 Objeto

Este Marco tiene por objeto establecer los **principios, roles, procedimientos y criterios** que rigen la gestión de incidentes de seguridad de la información del sistema SmartCSET y la continuidad de su operación ante cualquier perturbación significativa —ya sea de origen técnico (falla de hardware, error de software, brecha de seguridad) o de origen externo (corte de energía, desastre natural, acto deliberado)— con el fin de minimizar el impacto sobre la operación del Centro de Formación SENA y sobre los datos personales bajo custodia del sistema.

### 1.2 Alcance

Este Marco aplica a:

- **Todo evento que afecte o pueda afectar** la confidencialidad, integridad o disponibilidad de SmartCSET, de su base de datos o de los datos personales que almacena.
- **Todos los actores con roles en la respuesta**: Administrador del sistema, Responsable de Seguridad de la Información (RSSI), personal de la Oficina de TI del SENA, Dirección del Centro de Formación, personal operativo (portería, registro) y terceros de soporte.
- **Todas las fases del ciclo de vida de un incidente**: detección, clasificación, contención, erradicación, recuperación y cierre con lecciones aprendidas.
- **Los mecanismos de continuidad** que garantizan que, ante una interrupción, la operación del Centro puede mantenerse o recuperarse en los tiempos objetivo definidos en este documento.

### 1.3 Relación con otros documentos

| Documento de referencia                    | Qué aporta a este Marco                                                                                                                            |
| ------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| FASE0-RIE-003 — Matriz de Riesgos         | Define los escenarios de riesgo que pueden materializarse en incidentes; este Marco es la respuesta operativa a la materialización de esos riesgos |
| FASE0-ACC-007 — Control de Acceso         | Define los controles preventivos; los incidentes de acceso no autorizado activan este Marco                                                         |
| FASE0-AUD-005 — Cronograma de Auditorías | Los simulacros de este Marco se integran en el calendario de auditorías                                                                            |
| FASE0-POL-001 — Tratamiento de Datos      | Los incidentes que afectan datos personales activan obligaciones legales adicionales de notificación (Ley 1581/2012)                               |

---

## 2. MARCO NORMATIVO APLICABLE

| Norma                                               | Contenido relevante                                                                                                                                                 |
| --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Ley 1581 de 2012, art. 17(f)**              | El Responsable del tratamiento debe adoptar medidas para proteger los datos personales y notificar a la SIC ante violaciones de seguridad que afecten los titulares |
| **Decreto 1377 de 2013 (reglamentario)**      | Obliga a implementar medidas técnicas y administrativas para proteger los registros y prevenir su adulteración, pérdida o acceso no autorizado                   |
| **Ley 1273 de 2009, art. 269I**               | Tipifica el hurto de información contenida en sistemas informáticos; la gestión de incidentes permite preservar evidencia para acciones legales                  |
| **MSPI MinTIC — Eje 9**                      | Las entidades deben tener un proceso formal de gestión de incidentes: identificación, clasificación, respuesta, cierre y lecciones aprendidas                    |
| **MSPI MinTIC — Eje 10**                     | Las entidades deben garantizar la continuidad de sus servicios de información críticos y tener un Plan de Continuidad del Negocio (PCN)                           |
| **ISO/IEC 27001:2022 — Annex A, 5.24–5.28** | Planificación de respuesta a incidentes, evaluación y decisión, respuesta, análisis post-incidente, recopilación de evidencias                                 |
| **CONPES 3995 de 2020**                       | Establece la obligación de reportar incidentes cibernéticos significativos al ColCERT/CSIRT del Gobierno Nacional                                                 |
| **FASE0-PSI-006**                             | Política General de Seguridad de la Información — Objetivo O-03 (resiliencia operativa) y Sección 7 (gestión de incidentes) se desarrollan en este Marco       |

---

## 3. DEFINICIONES Y TAXONOMÍA DE INCIDENTES

### 3.1 Definiciones base

| Término                                            | Definición                                                                                                                                                                                                    | Ejemplo en SmartCSET                                                                  |
| --------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| **Evento de seguridad**                       | Cualquier ocurrencia identificada en un sistema, red o servicio que indique que una política de seguridad ha podido ser violada o que un control de seguridad ha fallado; puede o no convertirse en incidente | Cinco intentos fallidos de login desde una IP desconocida                             |
| **Incidente de seguridad**                    | Evento de seguridad que ha causado, o tiene alta probabilidad de causar, un impacto negativo en las operaciones del negocio, los activos o los datos personales                                                | Acceso no autorizado confirmado a la consola de administración                       |
| **Brecha de datos personales**                | Incidente que resulta en la destrucción, pérdida, alteración, divulgación no autorizada o acceso no autorizado a datos personales transmitidos, almacenados o tratados de otra manera                      | Exportación no autorizada de la tabla `tab_personas` con datos de cédulas y fotos |
| **Tiempo de Recuperación Objetivo (RTO)**    | Tiempo máximo tolerable para que un sistema esté completamente operativo después de una interrupción                                                                                                       | SmartCSET: 4 horas (ver Sección 12.2)                                                |
| **Punto de Recuperación Objetivo (RPO)**     | Máxima pérdida de datos tolerable medida en tiempo (hasta qué punto en el pasado se pueden recuperar los datos)                                                                                             | SmartCSET: 24 horas (ver Sección 12.2)                                               |
| **Continuidad operativa**                     | Capacidad de la organización para continuar entregando los servicios críticos a niveles aceptables tras un incidente perturbador                                                                             | Control de acceso al Centro mediante registro manual si SmartCSET está caído        |
| **Plan de recuperación ante desastre (DRP)** | Documento y procedimiento que describe cómo restaurar sistemas de TI críticos tras un desastre                                                                                                               | Procedimiento de restauración de BD PostgreSQL desde backup (Sección 14)            |

### 3.2 Taxonomía de incidentes

| Categoría                                   | Descripción                                                                                            | Ejemplos concretos en SmartCSET                                                                                                                              |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **CAT-1: Acceso no autorizado**        | Acceso confirmado o altamente probable al sistema, BD o servidor por parte de alguien sin autorización | Login exitoso con credenciales de otra persona; acceso SSH no planificado; consulta masiva de BD sin justificación                                          |
| **CAT-2: Malware / Código malicioso** | Presencia confirmada o sospechada de software malicioso en la infraestructura de SmartCSET              | Ransomware en el servidor; webshell PHP subido explotando una vulnerabilidad de carga de archivos; script minero                                             |
| **CAT-3: Disponibilidad / DoS**        | Interrupción significativa de la disponibilidad del sistema                                            | Sistema caído por sobrecarga de requests; servidor web no responde; PostgreSQL no inicia                                                                    |
| **CAT-4: Integridad de datos**         | Modificación no autorizada o inesperada de datos del sistema                                           | Registros de ingreso/salida alterados; datos de personas modificados sin trazabilidad; tablas corrompidas                                                    |
| **CAT-5: Fuga de datos personales**    | Exposición, extracción o divulgación no autorizada de datos personales almacenados en SmartCSET      | Volcado de `tab_personas` con cédulas y fotos; reporte con datos sensibles enviado a destinatario equivocado                                              |
| **CAT-6: Falla de infraestructura**    | Falla de hardware, energía, red o sistema operativo que interrumpe el servicio                         | Disco duro del servidor averiado; corte de energía sin UPS; falla del switch de red; sistema operativo corrupto                                             |
| **CAT-7: Error humano con impacto**    | Acción involuntaria del personal que causa pérdida, corrupción o exposición de datos                | Eliminación accidental de registros en BD; restauración de backup sobre datos más recientes; envío de listado con datos personales por correo equivocado |
| **CAT-8: Vulnerabilidad explotada**    | Explotación confirmada o probable de una vulnerabilidad técnica de SmartCSET                          | SQLi contra un formulario; CSRF exitoso; RCE a través de carga de archivos; bypass de autenticación                                                        |

---

## 4. CLASIFICACIÓN DE INCIDENTES POR SEVERIDAD

| Nivel        | Nombre      | Criterio                                                                                                                                                                                                            | Ejemplos                                                                                                                       | Tiempo de respuesta inicial                                  |
| ------------ | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------ |
| **P1** | 🔴 Crítico | El sistema SmartCSET está completamente inaccesible para los usuarios, O se ha confirmado o es altamente probable una brecha de datos personales masiva, O hay evidencia de acceso no autorizado activo y en curso | Sistema caído en horas punta; ransomware detectado; acceso remoto no autorizado al servidor; fuga masiva de datos de personas | **Inmediato** — dentro de los 30 minutos de detectado |
| **P2** | 🟠 Alto     | El sistema tiene degradación significativa de funcionalidad, O hay evidencia de compromiso de una cuenta de usuario, O se detectó acceso no autorizado a datos de un subconjunto de personas                      | Módulo de portería no responde; cuenta de administrador comprometida; 50 registros de personas accedidos sin autorización   | **2 horas**                                            |
| **P3** | 🟡 Medio    | Funcionalidad reducida o incidentes de menor impacto que no afectan la operación crítica de control de acceso                                                                                                     | Error en módulo de reportes; backup fallido una vez; 5 intentos de login fallidos desde IP nueva                              | **8 horas** (dentro de la jornada laboral)             |
| **P4** | 🟢 Bajo     | Evento menor, anomalía o sospecha sin impacto operativo confirmado                                                                                                                                                 | Mensaje de error inusual en log; usuario que olvidó su contraseña repetidamente; comportamiento inesperado de interfaz       | **48 horas**                                           |

---

## 5. CICLO DE VIDA DE LA GESTIÓN DE INCIDENTES

El ciclo de vida de un incidente en SmartCSET consta de cinco fases secuenciales que se ejecutan para cada incidente confirmado o altamente probable:

```
┌─────────────────────────────────────────────────────────────────┐
│  FASE 1        FASE 2          FASE 3       FASE 4     FASE 5   │
│  Detección  →  Clasificación → Contención → Errad. /  → Post-  │
│  e ident.      y escalada                   Recup.     incidente│
└─────────────────────────────────────────────────────────────────┘
     ↑                                                      │
     └──────── Lecciones aprendidas → Mejora preventiva ───┘
```

Cada fase produce **documentación obligatoria** que forma el expediente del incidente (ver Sección 10.2 — Ficha de Incidente).

---

## 6. FASE 1 — DETECCIÓN E IDENTIFICACIÓN

### 6.1 Fuentes de detección

Un incidente de SmartCSET puede detectarse a través de las siguientes fuentes. Todo el personal debe conocerlas y saber a quién reportar lo que detecta:

| Fuente                                                   | Señal típica de incidente                                                                                                                       | Quién la detecta habitualmente                          |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| **Alertas del sistema**                            | Múltiples intentos de login fallidos registrados en `tab_intentos_login`; errores `500` inusuales en log del servidor web                    | Sistema automático (cuando alertas estén configuradas) |
| **Observación directa del personal de portería** | "El sistema no carga", "mi contraseña ya no funciona", "veo registros que yo no hice"                                                            | Personal de portería en turno                           |
| **Observación del Administrador**                 | Queries SQL inusuales en log de PostgreSQL; archivos PHP nuevos o modificados en el servidor; consumo anormal de CPU/memoria/disco                | Administrador del sistema                                |
| **Auditoría periódica**                          | Al revisar `tab_log_ingresos`, se detectan registros con timestamps sospechosos o usuarios que ya no existen                                    | Administrador del sistema en revisión trimestral        |
| **Reporte externo**                                | Un usuario reporta haber recibido una alerta de su banco sobre uso de sus datos; una entidad externa identifica datos del SENA en una filtración | Personal externo, Dirección                             |
| **Herramientas de monitoreo**                      | Alertas del sistema operativo del servidor (si están configuradas)                                                                               | Sistema automático                                      |

### 6.2 Regla básica: reportar antes de actuar

Ante cualquier señal de posible incidente, la primera acción es **notificar**, no intentar resolver por cuenta propia. Una persona bien intencionada que intenta "arreglar" un incidente sin protocolo puede destruir evidencia forense valiosa, agravar el daño o tomar acciones contraproducentes.

**¿A quién reportar?**

| Situación                                                     | Contacto primario                                              | Contacto de respaldo                                   |
| -------------------------------------------------------------- | -------------------------------------------------------------- | ------------------------------------------------------ |
| Durante horario laboral                                        | Administrador del sistema                                      | RSSI                                                   |
| Fuera de horario                                               | 🔲 Definir número de contacto de emergencia del Administrador | 🔲 Definir número de emergencia de la Oficina TI SENA |
| Si el Administrador es parte del incidente o está inaccesible | RSSI directamente                                              | Dirección del Centro de Formación                    |

### 6.3 Información mínima al reportar

Quien detecta el incidente documenta o comunica:

1. ¿Qué observó exactamente? (descripción concreta, no interpretación)
2. ¿Cuándo lo detectó? (fecha y hora exacta o aproximada)
3. ¿Desde qué lugar o equipo lo detectó?
4. ¿Qué hizo antes de reportar? (para saber si se alteró algo)
5. ¿El incidente sigue activo o se detuvo?

---

## 7. FASE 2 — CLASIFICACIÓN Y ESCALADA

El Administrador del sistema —o quien reciba el reporte inicial— realiza la clasificación del incidente dentro de los tiempos de respuesta definidos en la Sección 4.

### 7.1 Criterios de clasificación

Evaluar las tres dimensiones:

| Dimensión                  | Preguntas clave                                                                                                                       |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Alcance**           | ¿Cuántos usuarios afectados? ¿Cuántos registros de personas expuestos? ¿Es un módulo o el sistema completo?                     |
| **Impacto actual**    | ¿El sistema está operativo? ¿Hay pérdida o corrupción de datos confirmada? ¿Hay acceso no autorizado activo?                    |
| **Impacto potencial** | Si no se actúa ahora, ¿en cuánto tiempo empeora? ¿Hay riesgo de propagación? ¿Hay riesgo de pérdida irreversible de evidencia? |

### 7.2 Criterios de escalada

| Nivel del incidente      | A quién se escala                           | Cuándo                                                           |
| ------------------------ | -------------------------------------------- | ----------------------------------------------------------------- |
| **P1 — Crítico** | Administrador + RSSI + Dirección del Centro | Inmediatamente, en paralelo, por el canal más rápido disponible |
| **P2 — Alto**     | Administrador + RSSI                         | Dentro de las 2 horas de detección                               |
| **P3 — Medio**    | Administrador (gestión directa)             | Dentro de la jornada laboral                                      |
| **P4 — Bajo**     | Administrador (registro y seguimiento)       | En la próxima jornada                                            |

**Escalar a ColCERT / CSIRT del Gobierno:** Todo incidente P1 de categoría CAT-1, CAT-2, CAT-5 o CAT-8 debe reportarse también al Centro Cibernético Policial y al ColCERT (CONPES 3995/2020). La notificación no implica admitir responsabilidad; es una obligación de entidades que operan sistemas de información pública.

🔲 **Datos de contacto que deben completarse:**

- Correo y teléfono del Administrador del sistema: ___________________
- Correo y teléfono del RSSI: ___________________
- Correo y teléfono de la Dirección del Centro: ___________________
- Correo de reporte al ColCERT: csirtgob@mintic.gov.co
- Correo de reporte al Centro Cibernético Policial: caivirtual@correo.policia.gov.co

---

## 8. FASE 3 — CONTENCIÓN

La contención busca **detener o limitar la propagación del incidente** mientras se prepara la erradicación definitiva. Es la fase de mayor exigencia técnica y la que más depende de la velocidad de decisión.

### 8.1 Principio de contención: preservar evidencia mientras se limita el daño

Toda acción de contención debe equilibrar dos objetivos que pueden estar en tensión:

- **Limitar el daño presente y futuro** (desconectar, bloquear, aislar)
- **Preservar la evidencia** (no borrar logs, no apagar abruptamente si hay rastros en memoria)

Regla general: si el incidente está activo (acceso en curso, malware ejecutándose), **la prioridad es detenerlo**, aunque se pierda algo de evidencia. Si el incidente ya terminó (acceso histórico detectado en auditoría), **la prioridad es preservar evidencia** antes de limpiar.

### 8.2 Acciones de contención por tipo de incidente

| Tipo de incidente                                  | Acciones de contención inmediata                                                                                                                                                                                                                | Precauciones de evidencia                                                                                                                     |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| **Acceso no autorizado activo (CAT-1)**      | Revocar la sesión/token comprometido; desactivar el usuario afectado en SmartCSET (`ind_estado = FALSE`); si el acceso es a nivel servidor, bloquear la IP en el firewall; si es una cuenta privilegiada, cambiar contraseñas de servicio    | Antes de revocar: capturar screenshot de `tab_sesiones` y `tab_intentos_login`; exportar logs del servidor web de las últimas 24h        |
| **Malware detectado (CAT-2)**                | Aislar el servidor de la red (desconectar interfaz de red o bloquear en switch); NO apagar el servidor (puede haber evidencia en memoria); notificar a la Oficina TI para análisis forense                                                      | No ejecutar ningún programa nuevo en el servidor hasta que el análisis esté completo                                                       |
| **Sistema caído / DoS (CAT-3)**             | Identificar si el origen es interno (falla de BD, error de aplicación) o externo (flood de requests); reiniciar servicios solo si se descarta origen malicioso; aplicar rate limiting de emergencia a nivel de firewall si el origen es externo | Capturar logs del servidor web y de PostgreSQL antes de reiniciar servicios                                                                   |
| **Integridad de datos comprometida (CAT-4)** | Identificar el alcance de los registros afectados; suspender las operaciones de escritura hasta entender el vector; NO ejecutar `UPDATE` o `DELETE` correctivos hasta tener el backup identificado                                           | Exportar dump de las tablas afectadas con timestamp                                                                                           |
| **Fuga de datos personales (CAT-5)**         | Revocar todos los accesos externos y temporales; si hay una API o endpoint expuesto, deshabilitarlo; si hay archivos exportados sin autorización, identificar dónde están y revocar acceso a ellos                                            | Preservar logs de acceso a las tablas afectadas; documentar exactamente qué datos y de quiénes fueron expuestos para la notificación legal |
| **Falla de infraestructura (CAT-6)**         | Activar el protocolo de continuidad operativa (registro manual — ver Sección 12.3); notificar a la Oficina TI; evaluar si hay backups disponibles para recuperación                                                                           | Documentar el estado del sistema al momento de la falla                                                                                       |

---

## 9. FASE 4 — ERRADICACIÓN Y RECUPERACIÓN

### 9.1 Erradicación

Una vez contenido el incidente, la erradicación elimina la causa raíz:

| Causa raíz              | Acción de erradicación                                                                                                                                                                        |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Cuenta comprometida      | Cambiar contraseña de la cuenta afectada; revisar y revocar todas las sesiones activas del usuario; analizar qué hizo el atacante con esa cuenta                                              |
| Vulnerabilidad explotada | Aplicar el parche o mitigación de la vulnerabilidad específica (ver procedimientos de la Fase 1 del Plan de Blindaje Técnico); verificar que no existen vectores similares en otros módulos |
| Malware                  | Limpiar archivos maliciosos identificados; reinstalar la aplicación desde fuente limpia si el alcance del malware no está completamente acotado; cambiar todas las credenciales del servidor  |
| Error de configuración  | Corregir la configuración errónea; verificar que no existen configuraciones similares en otros componentes                                                                                    |
| Error humano             | Revertir los datos al estado pre-error (desde backup identificado); capacitar al personal en el procedimiento correcto                                                                          |

### 9.2 Verificación antes de recuperar el servicio

Antes de restablecer el servicio al estado normal, verificar:

- [ ] La causa raíz ha sido eliminada o mitigada con un control compensatorio.
- [ ] No existen evidencias de presencia remanente del atacante (puertas traseras, cuentas adicionales creadas, crons maliciosos).
- [ ] Los datos críticos están íntegros (comparar checksums si se realizó dump de evidencia).
- [ ] Los logs del sistema están disponibles y completos para el análisis post-incidente.
- [ ] La Dirección y el RSSI han dado aprobación para restablecer el servicio.

### 9.3 Recuperación gradual

Para incidentes P1 y P2, el restablecimiento del servicio se hace de forma gradual:

1. Restablecer acceso solo al Administrador del sistema (verificación interna).
2. Restablecer acceso a usuarios operativos críticos (personal de portería en turno).
3. Verificar operación normal durante al menos 30 minutos antes de abrir el acceso completo.
4. Monitorear activamente los logs durante las primeras 24 horas post-recuperación.

---

## 10. FASE 5 — ACTIVIDADES POST-INCIDENTE

### 10.1 Reunión de lecciones aprendidas

Dentro de los **5 días hábiles** siguientes al cierre del incidente, el Administrador del sistema convoca una reunión con el RSSI y, para incidentes P1/P2, con la Dirección del Centro, para responder formalmente:

1. ¿Qué ocurrió exactamente? (cronología detallada)
2. ¿Cómo se detectó? ¿Cuánto tiempo tardó la detección? ¿Por qué no se detectó antes?
3. ¿Qué acciones de contención funcionaron? ¿Cuáles no?
4. ¿Cuál fue la causa raíz técnica y cuál fue la causa raíz organizacional?
5. ¿Qué controles preventivos hubieran evitado el incidente?
6. ¿Qué controles detectivos hubieran acortado el tiempo de detección?
7. ¿Hay cambios necesarios en este Marco o en otras políticas de seguridad?

### 10.2 Ficha de incidente — registro obligatorio

Todo incidente confirmado (P1 a P3) debe quedar documentado en una Ficha de Incidente con los siguientes campos:

| Campo                                                          | Descripción                                                                                   |
| -------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| **ID del incidente**                                     | Formato: INC-AAAA-NNN (ej: INC-2026-001)                                                       |
| **Fecha y hora de detección**                           |                                                                                                |
| **Fecha y hora de cierre**                               |                                                                                                |
| **Categoría**                                           | CAT-1 a CAT-8                                                                                  |
| **Severidad**                                            | P1 a P4                                                                                        |
| **Descripción del incidente**                           | Qué ocurrió, qué datos/sistemas afectados, alcance                                          |
| **Cronología de respuesta**                             | Detección → Clasificación → Contención → Erradicación → Recuperación (con timestamps) |
| **Causa raíz**                                          | Técnica y organizacional                                                                      |
| **Personas afectadas (si aplica)**                       | Cuántas personas, qué datos, si se notificó a la SIC                                        |
| **Acciones de contención ejecutadas**                   |                                                                                                |
| **Acciones de erradicación ejecutadas**                 |                                                                                                |
| **Estado de recuperación**                              | Plena / Parcial (con descripción de qué queda pendiente)                                     |
| **Lecciones aprendidas**                                 |                                                                                                |
| **Controles nuevos o mejorados derivados del incidente** |                                                                                                |
| **Elaborado por**                                        | Nombre, cargo, fecha                                                                           |
| **Revisado por**                                         | RSSI, fecha                                                                                    |

Las fichas de incidente se almacenan bajo custodia del RSSI con acceso restringido, por un período mínimo de 5 años.

---

## 11. ÁRBOL DE DECISIÓN — INCIDENTES DE DATOS PERSONALES

Cuando un incidente involucra datos personales de las personas registradas en SmartCSET, aplican obligaciones adicionales de la Ley 1581 de 2012:

```
¿El incidente afectó datos personales almacenados en SmartCSET?
    │
    ├── NO → Gestionar como incidente técnico normal (Fases 1-5)
    │
    └── SÍ
         │
         ├── ¿Los datos fueron accedidos/expuestos fuera del SENA?
         │       │
         │       ├── NO (exposición solo interna, sin fuga externa)
         │       │       → Documentar en Ficha de Incidente
         │       │       → Notificar internamente a la Dirección
         │       │       → Reforzar controles preventivos
         │       │
         │       └── SÍ (fuga externa confirmada o probable)
         │               │
         │               ├── NOTIFICAR A LA SIC ← Obligatorio (art. 17f Ley 1581)
         │               │   Plazo: tan pronto como sea posible (máximo 15 días hábiles
         │               │   desde la confirmación, según criterio conservador)
         │               │   Canal: https://www.sic.gov.co (formulario de incidente)
         │               │   Incluir: naturaleza del incidente, datos afectados,
         │               │   medidas tomadas, datos de contacto
         │               │
         │               └── ¿El incidente involucra datos de menores de edad?
         │                       │
         │                       └── SÍ → Prioridad máxima en la notificación a la SIC
         │                               (protección reforzada de menores — Ley 1581, art. 7)
         │
         └── ¿Los datos fueron destruidos o corrompidos de forma irreversible?
                 │
                 └── SÍ → Evaluar impacto sobre derechos del titular
                         → Documentar y notificar a la Dirección
                         → Evaluar notificación a titulares afectados
```

---

## 12. CONTINUIDAD OPERATIVA — OBJETIVOS Y ESTRATEGIA

### 12.1 Definición de servicios críticos

| Servicio                                            | Criticidad  | Justificación                                                                                                                                     |
| --------------------------------------------------- | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Registro de ingreso de personas al Centro** | 🔴 Crítico | Sin este registro, el Centro no puede controlar quién entra a sus instalaciones — impacto directo en seguridad física del personal y aprendices |
| **Registro de salida de personas**            | 🔴 Crítico | Sin este registro, no hay trazabilidad de las personas presentes en las instalaciones ante una emergencia                                          |
| **Consulta de personas registradas**          | 🟠 Alto     | Permite verificar identidad de personas ante ingreso; puede operarse con registro manual temporal                                                  |
| **Módulo de administración del sistema**    | 🟡 Medio    | Solo lo usa el Administrador; no afecta la operación de portería si está temporalmente no disponible                                            |
| **Módulo de reportes**                       | 🟡 Medio    | No es operativo en tiempo real; puede diferirse durante una interrupción                                                                          |

### 12.2 Objetivos de recuperación

| Parámetro                                                 | Valor objetivo | Justificación                                                                                                                                                                                                                |
| ---------------------------------------------------------- | -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **RTO (Tiempo de Recuperación Objetivo)**           | 4 horas        | La operación del Centro puede sostenerse con registro manual por un máximo de 4 horas sin impacto institucional significativo; más allá de ese tiempo, el impacto en la gestión de personal y visitantes se vuelve grave |
| **RPO (Punto de Recuperación Objetivo)**            | 24 horas       | La pérdida máxima tolerable es un día de registros de ingreso/salida; registros más antiguos son recuperables desde los backups diarios                                                                                   |
| **MTPD (Tiempo Máximo de Perturbación Tolerable)** | 48 horas       | Más allá de 48 horas sin SmartCSET operativo, el Centro debe activar proceso de recuperación de emergencia con apoyo externo de la Oficina TI del SENA a nivel regional                                                    |

### 12.3 Procedimiento de operación de contingencia (registro manual)

Cuando SmartCSET no está disponible y se activa el modo de contingencia:

**Materiales de contingencia** (deben existir físicamente en el puesto de portería):

- [ ] 🔲 Formato impreso de registro manual de ingresos (fecha, hora, nombre, tipo de documento, número, tipo de persona, destino, hora de salida)
- [ ] 🔲 Formato impreso de registro manual de salidas
- [ ] 🔲 Al menos 50 copias de cada formato, almacenadas en sobre sellado en el cajón de portería
- [ ] 🔲 Bolígrafo de repuesto

**Procedimiento:**

1. El personal de portería activa el registro manual usando los formatos impresos.
2. Cada formato impreso lleva fecha, turno y nombre del operador de portería.
3. Los formatos usados se conservan en carpeta identificada con la fecha.
4. Cuando SmartCSET se restablezca, el Administrador del sistema ingresa los registros del período de contingencia al sistema, marcándolos con el campo de observación: "INGRESADO POR CONTINGENCIA — Registro manual del [fecha]".
5. Los formatos impresos se archivan físicamente por un mínimo de 1 año como evidencia del período de contingencia.

---

## 13. PLAN DE COPIAS DE SEGURIDAD

### 13.1 Política de backups

| Parámetro                                     | Valor                                                                                                                                                                                                 |
| ---------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Frecuencia mínima**                   | Diaria (backup completo de la base de datos PostgreSQL)                                                                                                                                               |
| **Horario**                              | Durante horas de baja actividad: entre las 02:00 y las 04:00 horas                                                                                                                                    |
| **Tipo de backup**                       | Dump completo con `pg_dump` en formato custom (`-Fc`) — permite restauración selectiva por tabla si es necesario                                                                                |
| **Retención**                           | 7 backups diarios + 4 backups semanales (primer día de la semana) + 3 backups mensuales (primer día del mes)                                                                                        |
| **Almacenamiento primario**              | 🔲 Disco externo o NAS en el Centro de Formación, separado físicamente del servidor                                                                                                                 |
| **Almacenamiento secundario (off-site)** | 🔲 Copia adicional en ubicación física diferente al Centro, o en servicio de almacenamiento en nube cifrada                                                                                         |
| **Cifrado del backup**                   | Los archivos de backup se cifran con `gpg --symmetric --cipher-algo AES256` antes de almacenarse; la contraseña de cifrado del backup se custodia por la Dirección del Centro separada del backup |

### 13.2 Procedimiento de backup diario

```bash
# Comando de backup (ejecutado por cron o tarea programada)
FECHA=$(date +%Y%m%d_%H%M%S)
ARCHIVO_BACKUP="/ruta/backups/smartcset_${FECHA}.pgdump"

pg_dump \
  -h localhost \
  -U smartcset_user \
  -d db_smartcset \
  -Fc \
  --no-password \
  -f "${ARCHIVO_BACKUP}"

# Cifrar el backup
gpg --batch --yes \
  --symmetric \
  --cipher-algo AES256 \
  --passphrase-file /etc/smartcset/backup_key.txt \
  "${ARCHIVO_BACKUP}"

# Eliminar el dump sin cifrar
rm "${ARCHIVO_BACKUP}"

# Verificar que el archivo cifrado existe y tiene tamaño razonable
ls -lh "${ARCHIVO_BACKUP}.gpg"
```

🔲 **Pendiente de implementación con la Oficina TI SENA:** configurar el cron, definir la ruta de almacenamiento y establecer el proceso de sincronización al almacenamiento secundario.

### 13.3 Verificación periódica de backups

Un backup que nunca se ha verificado es un backup que no existe. La verificación debe ser:

| Tipo de verificación                              | Frecuencia | Procedimiento                                                                                                                                                        |
| -------------------------------------------------- | ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Verificación de existencia e integridad** | Semanal    | Confirmar que el backup de los últimos 7 días existe y el tamaño es razonable (no significativamente menor que el día anterior sin razón)                       |
| **Prueba de restauración completa**         | Trimestral | Restaurar el backup más reciente en una BD de test separada; verificar que las tablas principales existen, tienen datos y las funciones PL/pgSQL están desplegadas |
| **Prueba de restauración selectiva**        | Semestral  | Restaurar una tabla específica (ej:`tab_personas`) desde el backup en la BD de test; comparar conteo de registros con el sistema productivo                       |

Toda prueba de restauración se documenta: fecha, backup restaurado, resultado, responsable.

---

## 14. PROCEDIMIENTO DE RECUPERACIÓN ANTE DESASTRE

### 14.1 Escenario: pérdida total del servidor

Si el servidor que aloja SmartCSET es destruido o irrecuperable (falla de disco total, siniestro físico, ransomware con cifrado de todos los archivos):

```
PASO 1 — ACTIVAR CONTINGENCIA MANUAL (inmediato)
   Notificar al personal de portería que usen el registro manual
   (Sección 12.3). Estimar tiempo de recuperación y comunicarlo.
        ↓
PASO 2 — PROVISIONAR NUEVO SERVIDOR (primeras 2 horas)
   Instalar SO Linux en hardware disponible o en VM.
   Instalar PostgreSQL 14+ y PHP 8.1+ con extensión pdo_pgsql.
   Copiar el código de SmartCSET desde el repositorio git o desde
   el backup de código fuente.
        ↓
PASO 3 — RESTAURAR LA BASE DE DATOS (primeras 3 horas)
   Identificar el backup más reciente (ver retención en Sección 13.1).
   Descifrar el backup:
     gpg --batch --decrypt \
       --passphrase-file /ruta/backup_key.txt \
       smartcset_FECHA.pgdump.gpg \
       > smartcset_FECHA.pgdump
   
   Crear la BD y restaurar:
     createdb -U postgres db_smartcset
     pg_restore -U postgres -d db_smartcset smartcset_FECHA.pgdump
        ↓
PASO 4 — CONFIGURAR EL ENTORNO (primera parte de la hora 4)
   Copiar/recrear el archivo .env con las variables de entorno
   (las credenciales se recuperan del gestor de contraseñas o del
   documento custodiado por la Dirección — ver Sección 6.4 de
   la Política de Control de Acceso, FASE0-ACC-007).
   Verificar permisos del directorio de la aplicación.
   Verificar acceso a public/uploads/ y storage/.
        ↓
PASO 5 — VERIFICACIÓN FUNCIONAL (última parte de la hora 4)
   Acceder al sistema con credenciales de administrador.
   Registrar un ingreso de prueba y verificar que aparece en la lista.
   Verificar que los registros históricos recuperados del backup son visibles.
   Confirmar que el número de registros en BD coincide con los esperados.
        ↓
PASO 6 — INGRESAR REGISTROS DE CONTINGENCIA
   Ingresar en el sistema los registros manuales capturados durante
   el período de contingencia (Sección 12.3).
        ↓
PASO 7 — COMUNICACIÓN Y DOCUMENTACIÓN
   Comunicar a la Dirección y al RSSI que el sistema está recuperado.
   Documentar el incidente con Ficha de Incidente (Sección 10.2).
   Identificar causa raíz del desastre para prevención futura.
```

### 14.2 Escenario: corrupción de datos en BD

Si los datos en la base de datos están corruptos o han sido modificados maliciosamente:

1. **NO ejecutar ninguna operación DML** (INSERT, UPDATE, DELETE) hasta que el alcance de la corrupción esté delimitado.
2. Exportar dump de las tablas afectadas con timestamp como evidencia.
3. Identificar el backup más reciente anterior a la corrupción (revisar timestamps de los registros afectados vs. fechas de backup).
4. Restaurar las tablas afectadas desde el backup en la BD de test para validar que el backup tiene los datos correctos.
5. Restaurar las tablas en producción desde el backup validado.
6. Reconciliar las diferencias entre el backup y el estado más reciente antes de la corrupción (usando los registros de transacciones si están disponibles).

---

## 15. COMUNICACIONES DURANTE UNA CRISIS

### 15.1 Principio: comunicación oportuna y veraz

Durante un incidente, la comunicación inadequada puede:

- Alarmar innecesariamente al personal y usuarios
- Dañar la reputación institucional si la información errónea sale al exterior
- Comprometer la investigación si se revelan detalles tácticos prematuramente

La comunicación se gestiona bajo el principio de **necesidad de saber**: cada audiencia recibe la información que necesita para cumplir su rol, ni más ni menos.

### 15.2 Plantillas de comunicación

**Comunicación interna — incidente detectado (P1/P2)**

> _"A las [hora], se detectó un [tipo de incidente] que afecta [alcance]. El sistema [está/no está] disponible temporalmente. El equipo está trabajando en la resolución. El tiempo estimado de restablecimiento es [tiempo]. Mientras tanto, [instrucción de contingencia]. Se comunicarán novedades en [frecuencia]. Cualquier observación adicional repórtela a [contacto]."_

**Comunicación interna — incidente resuelto**

> _"El incidente [ID] ha sido resuelto. El sistema SmartCSET está disponible con normalidad desde las [hora]. El total de [tiempo] de interrupción fue de [duración]. Se realizará un análisis de causas y mejoras preventivas. Gracias por la comprensión durante el período de contingencia."_

**Comunicación a la SIC (brecha de datos personales)**

La notificación formal a la Superintendencia de Industria y Comercio (SIC) se realiza a través del formulario oficial disponible en www.sic.gov.co. El documento debe incluir:

- Descripción de la naturaleza del incidente
- Categorías y número aproximado de registros afectados
- Categorías y número aproximado de titulares afectados
- Medidas adoptadas para hacer frente al incidente
- Datos de contacto del Responsable del Tratamiento

---

## 16. PRUEBAS Y SIMULACROS

Un plan de respuesta a incidentes que nunca se ha probado es un plan que fallará cuando más se necesite. Las pruebas son obligatorias en el calendario definido en el Cronograma de Auditorías (FASE0-AUD-005):

| Tipo de prueba                              | Periodicidad | Qué se verifica                                                                                                                                                                                                                 | Responsable                                            |
| ------------------------------------------- | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| **Prueba de restauración de backup** | Trimestral   | El backup más reciente se restaura en BD de test; se verifica integridad y completitud                                                                                                                                          | Administrador del sistema                              |
| **Revisión documental del plan**     | Semestral    | Verificar que los contactos de escalada están actualizados; que el procedimiento de contingencia manual tiene los materiales disponibles; que la ficha de incidente está en blanco y lista para usar                           | Administrador del sistema + RSSI                       |
| **Simulacro de incidente**            | Anual        | Simular un incidente de categoría P2 (ej: acceso no autorizado detectado); activar el ciclo de vida completo (detección → clasificación → contención simulada → post-incidente); medir tiempos de respuesta vs. objetivos | RSSI dirige; Administrador y personal clave participan |
| **Prueba de contingencia manual**     | Anual        | Verificar físicamente que los formatos impresos están disponibles, legibles y en cantidad suficiente; que el personal de portería conoce el procedimiento                                                                     | Administrador del sistema + personal de portería      |

Cada prueba o simulacro produce un **informe de resultado** que documenta: qué se probó, qué funcionó, qué falló, acciones correctivas y fecha de cierre.

---

## 17. RESPONSABILIDADES

| Rol                                                          | Responsabilidades en gestión de incidentes y continuidad                                                                                                                                                                                                        |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Dirección del Centro de Formación**                | Aprobar este Marco; garantizar los recursos para implementar los mecanismos de continuidad (backups, formatos de contingencia, UPS); recibir notificación inmediata de incidentes P1; autorizar la comunicación externa ante brechas de datos personales       |
| **Responsable de Seguridad de la Información (RSSI)** | Supervisar el cumplimiento de este Marco; coordinar la respuesta a incidentes P1 y P2; custodiar las fichas de incidente; dirigir los simulacros anuales; reportar al ColCERT/SIC cuando aplique                                                                 |
| **Administrador del sistema**                          | Ejecutar la respuesta técnica a incidentes; gestionar el proceso de backup y recuperación; mantener actualizados los materiales de contingencia; realizar pruebas de restauración trimestrales; documentar incidentes en la Ficha                             |
| **Oficina de TI del SENA**                             | Apoyar la recuperación de infraestructura ante desastres; implementar y mantener los controles de red y energía (UPS, firewall); proporcionar hardware de respaldo si el servidor falla; coordinarse con el Administrador del sistema durante la recuperación |
| **Personal operativo (portería, registro)**           | Reportar inmediatamente cualquier anomalía al Administrador del sistema; ejecutar el procedimiento de contingencia manual cuando se les indique; preservar los formatos de contingencia completos y legibles                                                    |
| **Todo el personal con acceso**                        | Reportar de inmediato cualquier incidente que detecten; no intentar resolver incidentes por cuenta propia; cooperar con la investigación post-incidente                                                                                                         |

---

## 18. VIGENCIA, REVISIÓN Y ACTUALIZACIÓN

1. Este Marco entra en vigencia a partir de su aprobación formal por la Dirección del Centro de Formación.
2. Se revisa **anualmente** como parte de la auditoría anual definida en FASE0-AUD-005, o de forma inmediata tras:
   - Un incidente de seguridad P1 o P2 que revele deficiencias en el Marco.
   - Un simulacro que muestre tiempos de respuesta significativamente superiores a los objetivos.
   - Cambios en la infraestructura tecnológica de SmartCSET.
   - Cambios normativos relevantes (nueva reglamentación de la Ley 1581, actualización del MSPI).
3. Se mantiene un histórico de versiones con indicación de los cambios y su motivación.

---

## 19. APROBACIÓN INSTITUCIONAL

|                  | ELABORÓ | REVISÓ | APROBÓ |
| ---------------- | -------- | ------- | ------- |
| **Nombre** |          |         |         |
| **Cargo**  |          |         |         |
| **Fecha**  |          |         |         |
| **Firma**  |          |         |         |

🔲 *Pendiente de diligenciamiento por las instancias institucionales competentes: Administrador del sistema (elaboró), Responsable de Seguridad de la Información (revisó) y Dirección del Centro de Formación (aprobó).*

---

*Fin del documento — Marco de Gestión de Incidentes de Seguridad y Continuidad Operativa — SmartCSET v1.0*
