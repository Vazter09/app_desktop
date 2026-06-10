# INVENTARIO Y CLASIFICACIÓN DE ACTIVOS DE INFORMACIÓN

## Sistema SmartCSET — Servicio Nacional de Aprendizaje (SENA)

### Clasificación según criterios de Confidencialidad – Integridad – Disponibilidad (C-I-D)

---

| Campo                                    | Valor                                                                                                                                                                                                  |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Documento N°**                  | FASE0-INV-002                                                                                                                                                                                          |
| **Versión**                       | 1.0                                                                                                                                                                                                    |
| **Fecha de elaboración**          | 2026-06-07                                                                                                                                                                                             |
| **Elaborado por**                  | Equipo de Desarrollo - SmartCSET                                                                                                                                                                       |
| **Estado**                         | Borrador para revisión y aprobación por la Dirección del Centro de Formación |
| **Próxima revisión**             | Cada vez que se incorpore un nuevo módulo, tabla o componente de infraestructura; revisión integral mínimo anual |
| **Clasificación del documento** | Uso institucional — Difusión controlada |
| **Fundamento normativo principal** | MSPI — documento "04_Inventario y Clasificación de Activos de Información e Infraestructura Crítica Cibernética Nacional"; ISO/IEC 27001 (Anexo A — gestión de activos); Decreto 338/2022 (ICC) |

> Este inventario sigue la metodología de identificación y valoración de activos del **Modelo de Seguridad y Privacidad de la Información (MSPI)** y el estándar **ISO/IEC 27001 (Anexo A.5/A.8 — Gestión de Activos)**. Cada activo se valora en una escala de **1 (Bajo) a 5 (Muy Alto)** para cada uno de los tres criterios C-I-D, y se calcula un **nivel de criticidad consolidado** que determina la prioridad de protección. Esta clasificación es la que alimenta directamente la Matriz de Riesgos Inicial.

---

## 1. OBJETIVO Y METODOLOGÍA

### 1.1 Objetivo

Identificar, describir, clasificar y valorar todos los activos de información involucrados en la operación del sistema SmartCSET, de forma que:

1. Se conozca exactamente qué hay que proteger, dónde está, quién lo custodia y qué tan crítico es.
2. Se establezca la base objetiva sobre la cual se construye la Matriz de Riesgos.
3. Se cumpla con la obligación del MSPI y de ISO/IEC 27001 de mantener un inventario de activos actualizado, con propietarios claramente identificados.
4. Se determine si SmartCSET, o algún componente de su infraestructura, debe considerarse Infraestructura Crítica Cibernética (ICC) conforme al Decreto 338/2022 y la metodología del documento MSPI N° 08 (ver Sección 12).

### 1.2 Metodología aplicada

Se identificaron los activos mediante el análisis directo de:

- La arquitectura documentada del sistema (estructura de carpetas, módulos, base de datos).
- El modelo de datos (tablas principales y sus relaciones).
- Los flujos operativos descritos para los módulos de portería, registro y administración.
- La infraestructura de despliegue descrita (servidor PHP, PostgreSQL, sistema de archivos local).

Cada activo se clasificó en una de siete categorías estándar (Sección 3), se describió, se identificó su propietario/custodio, su ubicación, y se valoró según los tres criterios C-I-D (Sección 2).

### 1.3 Alcance

Este inventario cubre los activos directamente involucrados en la operación de SmartCSET dentro del Centro de Formación. No cubre activos de infraestructura general del SENA que sean ajenos a este sistema (p. ej., la red corporativa completa, otros aplicativos institucionales en su totalidad), salvo en los puntos donde SmartCSET interactúa directamente con ellos (p. ej., generación de reportes que se transfieren a sistemas centrales).

---

## 2. ESCALA DE VALORACIÓN C-I-D

Se utiliza una escala de 1 a 5 para cada criterio, con las siguientes definiciones operativas (adaptadas de la metodología MSPI y de ISO/IEC 27005):

### 2.1 Confidencialidad (C) — "¿Qué tan grave es que esta información sea conocida por quien no debe?"

| Nivel                   | Descripción                                                                                                                                     | Ejemplo de criterio                                                                       |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------- |
| **1 — Muy Baja** | Información pública, su divulgación no genera ningún impacto                                                                                 | Nombre de los módulos del sistema, documentación técnica genérica                     |
| **2 — Baja**     | Información de uso interno sin mayor sensibilidad                                                                                               | Catálogos generales (tipos de documento, departamentos)                                  |
| **3 — Media**    | Información que, de divulgarse, podría generar incomodidad o un impacto operativo menor                                                        | Datos académicos generales (programa de formación, ficha)                               |
| **4 — Alta**     | Información cuya divulgación no autorizada constituye una violación legal directa y/o genera un daño significativo al Titular o a la entidad | Documento de identidad, datos de contacto, credenciales de usuarios                       |
| **5 — Muy Alta** | Información sensible cuya divulgación puede generar discriminación, daño grave a la persona, o consecuencias legales severas para la entidad | Fotografías/datos biométricos, contraseñas (incluso en hash), datos de menores de edad |

### 2.2 Integridad (I) — "¿Qué tan grave es que esta información sea alterada sin autorización?"

| Nivel                   | Descripción                                                                                                                               | Ejemplo de criterio                                                                                                                                         |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1 — Muy Baja** | Una alteración no tiene ningún impacto perceptible                                                                                       | Textos de ayuda, contenido decorativo                                                                                                                       |
| **2 — Baja**     | Una alteración es fácilmente detectable y corregible sin mayor impacto                                                                   | Configuración visual (colores corporativos, logo)                                                                                                          |
| **3 — Media**    | Una alteración puede causar confusión operativa o errores menores                                                                        | Catálogos de referencia (ciudades, tipos de persona)                                                                                                       |
| **4 — Alta**     | Una alteración puede generar decisiones erróneas, reportes incorrectos, o vulnerar derechos de las personas                              | Registros de ingreso/salida, datos de matrícula y fichas                                                                                                   |
| **5 — Muy Alta** | Una alteración puede tener consecuencias legales graves, ocultar responsabilidades, falsificar evidencia institucional o habilitar fraude | Bitácoras de auditoría (`usr_insert`/`fec_insert`), registros usados como prueba ante entes de control, asignación de roles/permisos administrativos |

### 2.3 Disponibilidad (D) — "¿Qué tan grave es que esta información/servicio no esté disponible cuando se necesita?"

| Nivel                   | Descripción                                                                                                                  | Ejemplo de criterio                                                                                          |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| **1 — Muy Baja** | Su ausencia temporal no afecta la operación                                                                                  | Documentación histórica de versiones anteriores                                                            |
| **2 — Baja**     | Su ausencia puede tolerarse por días sin impacto operativo grave                                                             | Reportes históricos ya entregados                                                                           |
| **3 — Media**    | Su ausencia por horas genera molestias pero existen alternativas manuales                                                     | Módulo de configuración del sistema (`admin/configuracion.php`)                                          |
| **4 — Alta**     | Su ausencia interrumpe un proceso misional y obliga a procedimientos de contingencia inmediatos                               | Módulo de registro de personal (control físico de acceso al Centro)                                        |
| **5 — Muy Alta** | Su ausencia paraliza la operación institucional crítica y/o impide el cumplimiento de obligaciones legales con plazos fijos | Base de datos `db_smartcset` completa; generación de reportes oficiales SENA en fechas límite de reporte |

### 2.4 Cálculo de criticidad consolidada

Se utiliza la fórmula estándar recomendada por la metodología MSPI:

```
Criticidad = MAX(C, I, D)
```

> Se utiliza el valor máximo (no el promedio) porque un activo es tan crítico como su dimensión más sensible: un activo con Confidencialidad = 5 e Integridad/Disponibilidad = 2 sigue siendo un activo de criticidad muy alta, ya que basta con que se materialice el riesgo sobre su dimensión más débil para generar un impacto severo. Este criterio es el que recomienda la metodología de valoración de riesgos de MSPI y es consistente con el principio de "eslabón más débil" en seguridad de la información.

| Criticidad consolidada | Rango | Color de referencia |
| ---------------------- | ----- | ------------------- |
| **Muy Alta**     | 5     | 🔴                  |
| **Alta**         | 4     | 🟠                  |
| **Media**        | 3     | 🟡                  |
| **Baja**         | 2     | 🟢                  |
| **Muy Baja**     | 1     | ⚪                  |

---

## 3. CATEGORÍAS DE ACTIVOS IDENTIFICADAS

Conforme a la metodología MSPI / ISO 27001, los activos se agrupan en siete categorías:

| Categoría                                        | Descripción                                                        | Sección de detalle |
| ------------------------------------------------- | ------------------------------------------------------------------- | ------------------- |
| **Información**                            | Datos, bases de datos, documentos, registros                        | Sección 4          |
| **Software / Aplicaciones**                 | Programas, sistemas, código fuente                                 | Sección 5          |
| **Infraestructura Tecnológica (Hardware)** | Servidores, equipos, almacenamiento, redes                          | Sección 6          |
| **Servicios**                               | Servicios internos o tercerizados que soportan la operación        | Sección 7          |
| **Activos Físicos**                        | Instalaciones, dispositivos físicos asociados al control de acceso | Sección 8          |
| **Personas**                                | Roles humanos con acceso a activos de información                  | Sección 9          |
| **Intangibles**                             | Reputación institucional, conocimiento, relaciones de confianza    | Sección 10         |

---

## 4. INVENTARIO DETALLADO — ACTIVOS DE INFORMACIÓN (DATOS)

| ID               | Activo                                                                                                                                               | Descripción / Ubicación técnica                                                                              | Propietario / Custodio                                                                        | C           | I           | D           | Criticidad               |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- | ----------- | ----------- | ----------- | ------------------------ |
| **INF-01** | Datos de identificación de personas (`tab_personas`)                                                                                              | Documento, nombres, tipo de persona, datos de contacto. Tabla principal en `db_smartcset`                     | Propietario: SENA (Centro de Formación). Custodio técnico: Administrador del sistema        | 4           | 4           | 4           | 🟠**Alta (4)**     |
| **INF-02** | Fotografías / datos biométricos capturados en el registro de ingreso                                                                               | Imágenes asociadas al registro de ingreso, gestionadas por `porteria_foto.php`, almacenadas en `files/`/BD | Propietario: SENA. Custodio técnico: Administrador del sistema                               | **5** | 4           | 3           | 🔴**Muy Alta (5)** |
| **INF-03** | Registros de ingreso/salida (`tab_log_ingresos`)                                                                                                   | Histórico de movimientos: persona, fecha/hora, puerta, método de autenticación                               | Propietario: SENA. Custodio técnico: Administrador del sistema                               | 4           | 5           | 4           | 🔴**Muy Alta (5)** |
| **INF-04** | Credenciales de usuarios del sistema (`tab_usuarios` — hashes bcrypt)                                                                             | Usuario, hash de contraseña, indicador de administrador                                                        | Propietario: SENA / Administrador del sistema                                                 | **5** | 5           | 4           | 🔴**Muy Alta (5)** |
| **INF-05** | Bitácoras de auditoría (`usr_insert`, `fec_insert`, `usr_update`, `fec_update` en todas las tablas operativas)                             | Trazabilidad de quién hizo qué y cuándo, en todas las tablas principales                                     | Propietario: SENA. Custodio técnico: Administrador del sistema                               | 3           | **5** | 4           | 🔴**Muy Alta (5)** |
| **INF-06** | Datos académicos de aprendices (programas, fichas, matrículas, juicios de evaluación)                                                             | Tablas relacionadas con gestión de aprendices y reportes SENA                                                  | Propietario: SENA (proceso de Formación Profesional)                                         | 4           | 4           | 4           | 🟠**Alta (4)**     |
| **INF-07** | Reportes oficiales generados (DF-49, DF-51, DF-53, DF-14A, PE-04, Juicios, fichas, matriculados)                                                     | Archivos/datos producidos por los módulos de carga, transferidos a instancias centrales del SENA               | Propietario: SENA. Custodio técnico: Administrador del sistema durante su generación        | 4           | **5** | 4           | 🔴**Muy Alta (5)** |
| **INF-08** | Configuración del sistema (`tab_config_sistema`)                                                                                                  | Fila única: nombre del sistema, colores corporativos, logo, módulos habilitados, tema visual                  | Propietario: SENA / Administrador del sistema                                                 | 2           | 3           | 3           | 🟡**Media (3)**    |
| **INF-09** | Catálogos de referencia (`tab_tipos_persona`, `tab_tipos_docum`, `tab_dptos`, `tab_ciudades`, `tab_metodos_aut`, `tab_entradas_centro`) | Tablas maestras / paramétricas                                                                                 | Propietario: SENA / Administrador del sistema                                                 | 1           | 3           | 3           | 🟡**Media (3)**    |
| **INF-10** | Permisos y asignación de menús por usuario (`tab_menu_usuarios`, `tab_menus`)                                                                  | Define qué puede ver y hacer cada usuario — corazón del modelo RBAC                                          | Propietario: SENA / Administrador del sistema                                                 | 3           | **5** | 4           | 🔴**Muy Alta (5)** |
| **INF-11** | Sesiones activas (`tab_sesiones`)                                                                                                                  | Registro de sesiones de usuarios autenticados                                                                   | Propietario: Administrador del sistema                                                        | 4           | 4           | 3           | 🟠**Alta (4)**     |
| **INF-12** | Código fuente del sistema (PHP, SQL/PL-pgSQL, JS, CSS)                                                                                              | Repositorio del proyecto                                                                                        | Propietario: SENA (como obra realizada para la entidad). Custodio: Desarrollador              | 3           | **5** | 4           | 🔴**Muy Alta (5)** |
| **INF-13** | Documentación técnica y normativa del proyecto (incluyendo esta serie de documentos MSPI)                                                          | Archivos de documentación del proyecto                                                                         | Propietario: SENA / Administrador del sistema                                                 | 2           | 4           | 3           | 🟠**Alta (4)**     |
| **INF-14** | Variables de entorno y secretos (`.env` — credenciales de BD, claves)                                                                             | Archivo `.env` en la raíz del proyecto (excluido del control de versiones)                                   | Propietario: Administrador del sistema                                                        | **5** | **5** | 4           | 🔴**Muy Alta (5)** |
| **INF-15** | Copias de seguridad (backups) de la base de datos                                                                                                    | Esquema de respaldo de `db_smartcset` y de su configuración asociada                                         | Propietario: SENA / Administrador del sistema (o Oficina de TI cuando gestione los respaldos) | 4           | 4           | **5** | 🔴**Muy Alta (5)** |
| **INF-16** | Campos biométricos reservados en el esquema (`tab_personas.val_huella_digital` — BYTEA; `tab_personas.val_patron_facial` — JSONB)                | Columnas previstas para validación biométrica futura. **A la fecha no almacenan datos** (el sistema no captura huella ni patrón facial). Se inventarían porque su activación constituiría tratamiento de datos sensibles biométricos y exige los prerrequisitos de FASE0-POL-001 Sección 8.1 (autorización reforzada, PIA, cifrado) | Propietario: SENA. Custodio técnico: Administrador del sistema                                | **5** | 4           | 2           | 🔴**Muy Alta (5)** — criticidad potencial; sin datos a la fecha |

---

## 5. INVENTARIO DETALLADO — ACTIVOS DE SOFTWARE / APLICACIONES

| ID                | Activo                                                                                                              | Descripción                                                                                                                  | Propietario / Custodio                                       | C           | I           | D           | Criticidad               |
| ----------------- | ------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ | ----------- | ----------- | ----------- | ------------------------ |
| **SOFT-01** | Aplicación SmartCSET (PHP 8+)                                                                                      | Sistema completo: módulos de registro de ingreso/salida, registro de personas, administración, menús                       | SENA / Administrador del sistema                             | 3           | 4           | 4           | 🟠**Alta (4)**     |
| **SOFT-02** | Funciones PL/pgSQL (`database/functions/`)                                                                        | Lógica de negocio crítica e integridad transaccional, organizadas por dominio (acceso, registro de personal, config, carga) | SENA / Administrador del sistema                             | 3           | **5** | 4           | 🔴**Muy Alta (5)** |
| **SOFT-03** | Motor de base de datos PostgreSQL 14+/16+                                                                           | Sistema gestor de base de datos `db_smartcset`                                                                              | SENA / Oficina de TI / Administrador del sistema             | **5** | **5** | **5** | 🔴**Muy Alta (5)** |
| **SOFT-04** | Servidor web PHP (built-in / eventual Apache-Nginx en producción)                                                  | Sirve la aplicación a los usuarios finales                                                                                   | SENA / Oficina de TI / Administrador del sistema             | 3           | 4           | **5** | 🔴**Muy Alta (5)** |
| **SOFT-05** | Scripts de despliegue y mantenimiento (`database/setup_smartcset.sh`, `tools/*.ps1`, `tools/diagnose_bd.php`) | Automatización de instalación, despliegue de funciones, diagnóstico                                                        | Administrador del sistema                                    | 2           | 4           | 3           | 🟠**Alta (4)**     |
| **SOFT-06** | Librerías JS y CSS propias (vanilla JS, sin dependencias externas)                                                 | `js/`, `css/` — comportamiento e interfaz de usuario                                                                     | Administrador del sistema                                    | 1           | 3           | 3           | 🟡**Media (3)**    |
| **SOFT-07** | Bootstrap 5.3 (vía CDN)                                                                                            | Framework de UI de terceros, cargado externamente                                                                             | Tercero (proveedor del CDN) — riesgo de dependencia externa | 1           | 2           | 3           | 🟡**Media (3)**    |

---

## 6. INVENTARIO DETALLADO — ACTIVOS DE INFRAESTRUCTURA TECNOLÓGICA

| ID                | Activo                                                                                           | Descripción                                                                                                             | Propietario / Custodio                                                      | C           | I           | D           | Criticidad               |
| ----------------- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------- | ----------- | ----------- | ----------- | ------------------------ |
| **INFR-01** | Servidor donde corre la aplicación SmartCSET en producción                                     | Servidor de aplicación designado por la Oficina de TI del SENA para el despliegue de SmartCSET                          | Oficina de TI del SENA                                                      | 4           | 4           | **5** | 🔴**Muy Alta (5)** |
| **INFR-02** | Servidor / instancia de base de datos PostgreSQL                                                 | Infraestructura sobre la cual corre `db_smartcset`, con sus correspondientes responsables de administración y parches | Oficina de TI del SENA                                                      | **5** | **5** | **5** | 🔴**Muy Alta (5)** |
| **INFR-03** | Red local / institucional del Centro de Formación                                               | Conectividad entre los puntos de registro de ingreso/salida, las estaciones de trabajo administrativas y el servidor     | Oficina de TI del SENA                                                      | 4           | 4           | **5** | 🔴**Muy Alta (5)** |
| **INFR-04** | Estaciones de trabajo / equipos del módulo de registro                                          | Computadores desde los cuales se opera el módulo de registro de ingreso/salida                                          | Oficina de TI / Coordinación administrativa del Centro                     | 3           | 3           | 4           | 🟠**Alta (4)**     |
| **INFR-05** | Dispositivos de captura (escáneres de documentos / lectores PDF417, cámaras para fotografías) | Hardware periférico usado en el flujo de registro de ingreso/salida                                                     | Coordinación administrativa del Centro                                     | 2           | 3           | 4           | 🟠**Alta (4)**     |
| **INFR-06** | Sistema/infraestructura de respaldo (backups)                                                    | Esquema técnico de respaldo de la base de datos y del código/configuración del sistema                                | A definir formalmente entre la Oficina de TI y el Administrador del sistema | 4           | 4           | **5** | 🔴**Muy Alta (5)** |

---

## 7. INVENTARIO DETALLADO — ACTIVOS DE SERVICIOS

| ID                | Activo                                                                                                                                                   | Descripción                                                                                                                        | Propietario / Custodio              | C | I           | D           | Criticidad               |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------- | - | ----------- | ----------- | ------------------------ |
| **SERV-01** | Servicio de generación y entrega de reportes oficiales SENA                                                                                             | Proceso que produce y transfiere DF-49, PE-04, Juicios, etc. hacia instancias centrales                                             | SENA / Administrador del sistema    | 3 | **5** | 4           | 🔴**Muy Alta (5)** |
| **SERV-02** | Servicio de registro y control de personal                                                                                                               | Proceso operativo diario de registro de ingreso/salida — funcionalidad misional del sistema                                        | SENA / Coordinación administrativa | 3 | 4           | **5** | 🔴**Muy Alta (5)** |
| **SERV-03** | Servicio de soporte y mantenimiento técnico                                                                                                             | Atención de incidencias, despliegue de actualizaciones, corrección de errores                                                     | Administrador del sistema           | 2 | 3           | 4           | 🟠**Alta (4)**     |
| **SERV-04** | CDN de Bootstrap 5.3 (servicio externo)                                                                                                                  | Entrega de librerías de interfaz desde un proveedor externo — dependencia de un tercero para el funcionamiento visual del sistema | Tercero externo                     | 1 | 2           | 3           | 🟡**Media (3)**    |
| **SERV-05** | Servicio de correo electrónico institucional (notificaciones, recuperación de contraseña, canal de atención de la Política de Tratamiento de Datos) | Servicio gestionado por la Oficina de TI del SENA, integrado a los flujos de recuperación de contraseña y atención de Titulares  | Oficina de TI del SENA              | 3 | 3           | 4           | 🟠**Alta (4)**     |

---

## 8. INVENTARIO DETALLADO — ACTIVOS FÍSICOS

| ID               | Activo                                                                                                                             | Descripción                                                                                                                           | Propietario / Custodio                                    | C | I | D           | Criticidad               |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- | - | - | ----------- | ------------------------ |
| **FIS-01** | Puertas / entradas físicas del Centro de Formación (`tab_entradas_centro`)                                                     | Puntos de control de acceso físico modelados en el sistema (1-9 entradas)                                                             | SENA / Coordinación administrativa                       | 1 | 3 | **5** | 🔴**Muy Alta (5)** |
| **FIS-02** | Documentos físicos de soporte (autorizaciones firmadas, formatos de matrícula, soportes de identidad presentados en el registro) | Soportes en papel o digitalizados que respaldan los registros del sistema                                                              | SENA / Coordinación administrativa / Gestión documental | 4 | 4 | 3           | 🟠**Alta (4)**     |
| **FIS-03** | Instalaciones donde se ubican los servidores y equipos                                                                             | Sala de servidores / centro de datos del Centro de Formación, con sus controles de acceso físico, climatización y energía regulada | Oficina de TI del SENA                                    | 3 | 3 | **5** | 🔴**Muy Alta (5)** |

---

## 9. INVENTARIO DETALLADO — ACTIVOS HUMANOS (PERSONAS Y ROLES CON ACCESO)

> Si bien las personas no son "activos" en sentido patrimonial, la metodología MSPI/ISO 27001 exige identificar los roles humanos que tienen acceso a información crítica, porque el factor humano es frecuentemente el eslabón más vulnerable (ingeniería social, error humano, abuso de privilegios). Esta sección se conecta directamente con el documento de Roles y Responsabilidades en Seguridad.

| ID               | Rol                                                                                       | Nivel de acceso a información crítica                                                                          | Riesgo asociado principal                                                                                                                            | Criticidad del rol       |
| ---------------- | ----------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------ |
| **HUM-01** | Administrador del sistema                                                                 | Total: código fuente, base de datos completa, credenciales, infraestructura                                     | Punto único de conocimiento (*bus factor* = 1); compromiso de esta cuenta equivale a compromiso total del sistema                                 | 🔴**Muy Alta (5)** |
| **HUM-02** | Personal operador del módulo de registro de ingreso/salida                               | Alto: ven y registran datos personales y fotografías de cientos de personas diariamente                         | Mayor volumen de interacción humana directa con datos de Titulares; mayor exposición a errores operativos y a ingeniería social                   | 🟠**Alta (4)**     |
| **HUM-03** | Usuarios administrativos (`ind_usuario = TRUE`)                                         | Alto: gestión de usuarios, menús, permisos, configuración del sistema                                         | Abuso de privilegios, escalamiento horizontal/vertical si no hay segregación de funciones                                                           | 🟠**Alta (4)**     |
| **HUM-04** | Personal de la Oficina de TI del SENA (con acceso de soporte/infraestructura)             | Variable — depende del nivel de acceso otorgado a la base de datos y servidores                                 | Acceso externo al equipo de desarrollo directo; requiere acuerdos de confidencialidad formalizados                                                   | 🟠**Alta (4)**     |
| **HUM-05** | Coordinación académica / administrativa (consumidores de reportes generados)            | Medio: reciben y usan reportes que contienen datos personales agregados                                          | Posible manejo inadecuado de los reportes una vez salen del sistema (impresión, envío por correo no cifrado, almacenamiento en equipos personales) | 🟡**Media (3)**    |
| **HUM-06** | Titulares de los datos (visitantes, aprendices, instructores, funcionarios, contratistas) | Ninguno (son objeto, no sujeto activo del tratamiento) — pero son los afectados directos de cualquier incidente | No aplica como "acceso", pero es el universo cuyo derecho está en juego en toda esta serie documental                                               | —                       |

---

## 10. INVENTARIO DETALLADO — ACTIVOS INTANGIBLES

| ID                | Activo                                                        | Descripción                                                                                                                                                        | C  | I           | D  | Criticidad               |
| ----------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -- | ----------- | -- | ------------------------ |
| **INTG-01** | Reputación institucional del SENA / del Centro de Formación | La confianza pública en que la entidad protege adecuadamente los datos de aprendices, instructores y visitantes                                                    | 3  | 4           | — | 🟠**Alta (4)**     |
| **INTG-02** | Confianza de los Titulares en el proceso de registro          | Disposición de las personas a suministrar sus datos sin resistencia, basada en la percepción de seguridad y buen manejo                                           | 3  | 4           | — | 🟠**Alta (4)**     |
| **INTG-03** | Conocimiento técnico acumulado sobre el sistema              | El "saber cómo funciona todo" en torno a la operación, mantenimiento y evolución del sistema                                                                     | — | **5** | 4  | 🔴**Muy Alta (5)** |
| **INTG-04** | Cumplimiento normativo como activo estratégico               | La condición de "entidad cumplidora" frente a auditorías de la SIC, Contraloría, Procuraduría y Control Interno — habilita continuidad operativa sin sanciones | 4  | 4           | — | 🟠**Alta (4)**     |

> **Sobre INTG-03:** la concentración del conocimiento técnico del sistema constituye en sí misma un riesgo de continuidad de alta criticidad (desarrollado en la Matriz de Riesgos como riesgo de "punto único de fallo humano / *bus factor*"). Su mitigación natural es el ejercicio de documentación exhaustiva que constituye esta misma serie de documentos.

---

## 11. ANÁLISIS DE CRITICIDAD CONSOLIDADO — TOP DE ACTIVOS CRÍTICOS

### 11.1 Activos de criticidad "Muy Alta (5)" — requieren protección prioritaria absoluta

| Activo                                                         | Categoría      | Razón principal de su criticidad                                                                                               |
| -------------------------------------------------------------- | --------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| INF-02 — Fotografías / datos biométricos                    | Información    | Dato sensible según Ley 1581/2012; mayor impacto legal y reputacional si se filtra                                             |
| INF-03 — Registros de ingreso/salida                          | Información    | Pilar de la trazabilidad institucional; su alteración compromete la integridad de toda investigación o auditoría             |
| INF-04 — Credenciales de usuarios                             | Información    | Compromiso = acceso total al sistema; objetivo n°1 de cualquier atacante                                                       |
| INF-05 — Bitácoras de auditoría                             | Información    | Su alteración permite ocultar cualquier otro incidente — el registro que debe permanecer inalterable                          |
| INF-07 — Reportes oficiales SENA                              | Información    | Obligación legal de reporte; su pérdida o alteración tiene consecuencias institucionales directas ante la Dirección General |
| INF-10 — Permisos y roles (RBAC)                              | Información    | Control de quién puede hacer qué; su compromiso habilita escalamiento de privilegios general                                  |
| INF-12 — Código fuente                                       | Información    | Activo de propiedad institucional; su pérdida o alteración no autorizada compromete la operación del sistema completo        |
| INF-14 — Variables de entorno /`.env`                       | Información    | Contiene las credenciales de acceso a todos los demás activos del sistema                                                      |
| INF-15 — Copias de seguridad                                  | Información    | Sin un esquema de respaldo confiable, cualquier incidente de integridad o disponibilidad se vuelve irreversible                 |
| SOFT-02 — Funciones PL/pgSQL                                  | Software        | Concentra la lógica de negocio crítica del sistema                                                                            |
| SOFT-03 — Motor PostgreSQL                                    | Software        | Sin él, no existe el sistema; punto único de fallo tecnológico central                                                       |
| SOFT-04 — Servidor web                                        | Software        | Puerta de entrada de todos los usuarios; su caída paraliza toda interacción                                                   |
| INFR-01/02/03/06 — Servidor de aplicación, BD, red, respaldo | Infraestructura | Componentes estructuralmente de criticidad muy alta en cualquier sistema de este tipo                                           |
| SERV-01 — Generación de reportes oficiales                   | Servicio        | Obligación legal con plazos — su falla tiene consecuencias institucionales directas y medibles                                |
| SERV-02 — Registro y control de personal                      | Servicio        | Es la razón de ser operativa de SmartCSET; sin él, el control de acceso vuelve al registro manual                             |
| FIS-01 — Puertas físicas                                     | Físico         | El control de acceso físico es, en última instancia, sobre seguridad de personas — el activo más importante de todos        |
| FIS-03 — Instalaciones de servidores                          | Físico         | Su compromiso físico anula cualquier control lógico implementado a nivel de software                                          |
| HUM-01 — Administrador del sistema                            | Humano          | *Bus factor* = 1; mayor riesgo de continuidad humano identificado                                                             |
| INTG-03 — Conocimiento técnico                               | Intangible      | Activo invisible pero decisivo para la continuidad operativa del sistema                                                        |

### 11.2 Hallazgo principal — esquema de respaldo de información (INF-15 / INFR-06)

La gestión de copias de seguridad (backups) de la base de datos `db_smartcset`, del código fuente y de la configuración del sistema constituye el activo de mayor prioridad de protección de todo este inventario, por las siguientes razones:

- Es el único componente cuya falla, de materializarse (pérdida de datos por falla de hardware, error humano, ransomware, corrupción de base de datos), generaría un daño irreversible — los demás riesgos identificados son graves pero recuperables; este no lo es.
- Sin un esquema de respaldo confiable, cualquier otra medida de seguridad del sistema queda sin sustento ante un evento de pérdida total de información.
- Es, comparativamente, la medida de seguridad de mayor retorno y menor costo de implementación de toda esta iniciativa.

**Lineamientos aplicables al esquema de respaldo:**

1. Implementar un esquema programado de copias de seguridad (`pg_dump` diario o equivalente) con una retención mínima de 30 días, almacenado en una ubicación distinta al servidor de producción.
2. Realizar pruebas periódicas de restauración del respaldo en un entorno de prueba — un respaldo que nunca se ha restaurado exitosamente no constituye un respaldo confiable.
3. Documentar el procedimiento, la frecuencia, la retención y el responsable, registrando evidencia de cada prueba de restauración exitosa.

---

## 12. EVALUACIÓN COMO INFRAESTRUCTURA CRÍTICA CIBERNÉTICA (ICC)

### 12.1 Marco normativo

El Decreto 338 de 2022 y los lineamientos del documento MSPI N° 08 ("Identificación de las Infraestructuras Críticas Cibernéticas" y "Lineamientos para la identificación de Infraestructuras Críticas Cibernéticas V1") establecen una metodología de cinco variables para determinar si un activo, sistema o infraestructura debe clasificarse como ICC, dentro de los catorce sectores estratégicos nacionales — entre los cuales se encuentra explícitamente el sector Educación, al que pertenece el SENA.

### 12.2 Aplicación de las cinco variables a SmartCSET

| Variable de la metodología ICC                                                       | Análisis aplicado a SmartCSET                                                                                                                                             | Valoración                         |
| ------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------- |
| **1. Pertenencia a un sector estratégico nacional**                            | El SENA pertenece al sector Educación, uno de los 14 sectores reconocidos                                                                                                 | Aplica                              |
| **2. Dependencia funcional de tecnología digital**                             | SmartCSET es un sistema digital cuyo control de acceso físico depende completamente de su disponibilidad                                                                  | Aplica                              |
| **3. Impacto de una falla o ataque sobre la prestación del servicio misional** | Una falla afectaría el control de acceso de un Centro de Formación — impacto operativo real, de alcance local/regional                                                  | Aplica de forma parcial/local       |
| **4. Nivel de interconexión con otros sistemas críticos**                     | SmartCSET transfiere reportes hacia sistemas centrales del SENA; existe interdependencia, sin que SmartCSET sea, en sí mismo, un sistema central nacional                 | Interconexión moderada             |
| **5. Volumen e impacto poblacional afectado**                                   | Afecta a la población de un Centro de Formación específico (cientos a miles de personas/día), no a la totalidad de la población atendida por el SENA a nivel nacional | Impacto local/regional, no nacional |

### 12.3 Conclusión

Con base en este análisis, no se considera que SmartCSET, evaluado de forma aislada, deba clasificarse como Infraestructura Crítica Cibernética Nacional, dado que su alcance es local/regional (un Centro de Formación) y no nacional. No obstante:

1. Esto no exime al sistema de aplicar buenas prácticas de seguridad robustas — el sector Educación está identificado como estratégico, y el SENA como entidad puede tener, a nivel de sus sistemas centrales con los cuales SmartCSET se interconecta, una clasificación ICC que imponga requisitos derivados sobre los sistemas periféricos conectados a ellos.
2. Corresponde a la entidad, a través de su Oficina de TI / Seguridad de la Información, en coordinación con el Ministerio de las TIC, formalizar esta determinación mediante el proceso de identificación de ICC descrito en el documento MSPI N° 08, estableciendo si el SENA como entidad —o alguno de los sistemas centrales con los que SmartCSET se interconecta— ya cuenta con dicha clasificación, y si esto impone requisitos derivados sobre SmartCSET.
3. Se adoptan, como buena práctica institucional, los lineamientos de gestión de riesgos de seguridad digital del Decreto 338/2022, dado que su costo de implementación es bajo comparado con el beneficio de estar preparados ante una eventual reclasificación o ante el fortalecimiento de los requisitos del sector Educación a futuro.

---

## 13. MAPA DE FLUJO DE INFORMACIÓN Y PUNTOS DE EXPOSICIÓN

```
                    ┌─────────────────────────────────────────┐
                    │   PUNTO DE EXPOSICIÓN 1: CAPTURA        │
                    │   (registro de ingreso / formularios)   │
                    │   • Documento + foto + datos personales │
                    │   • Riesgo: error humano, dispositivo   │
                    │     comprometido, ingeniería social     │
                    └───────────────────┬─────────────────────┘
                                        │
                                        ▼
                    ┌─────────────────────────────────────────┐
                    │   PUNTO DE EXPOSICIÓN 2: TRANSMISIÓN    │
                    │   (red local del Centro → servidor)     │
                    │   • Riesgo: interceptación si no hay    │
                    │     cifrado en tránsito (HTTPS interno) │
                    └───────────────────┬─────────────────────┘
                                        │
                                        ▼
                    ┌─────────────────────────────────────────┐
                    │   PUNTO DE EXPOSICIÓN 3: ALMACENAMIENTO │
                    │   (PostgreSQL db_smartcset + files/)    │
                    │   • Mayor concentración de activos      │
                    │     críticos (INF-01 a INF-15)          │
                    │   • Riesgo: acceso no autorizado,       │
                    │     ausencia de cifrado en reposo,      │
                    │     fallas en el esquema de respaldo    │
                    └───────────────────┬─────────────────────┘
                                        │
                          ┌─────────────┼──────────────┐
                          ▼             ▼              ▼
              ┌──────────────────┐ ┌──────────┐ ┌──────────────────┐
              │ PUNTO EXPOSICIÓN │ │ PUNTO    │ │ PUNTO EXPOSICIÓN │
              │ 4: CONSULTA      │ │ EXPOS. 5 │ │ 6: TRANSFERENCIA │
              │ OPERATIVA DIARIA │ │ ADMIN /  │ │ DE REPORTES      │
              │ (vista de        │ │ CONFIG   │ │ HACIA EL SENA    │
              │ ingresos del día)│ │ (gestión │ │ CENTRAL          │
              │ • Riesgo: IDOR,  │ │ usuarios,│ │ • Riesgo: fuga   │
              │   exposición     │ │ permisos)│ │   en tránsito,   │
              │   excesiva en UI │ │ • Riesgo:│ │   manejo         │
              │                  │ │ escalada │ │   inadecuado     │
              │                  │ │ privile- │ │   posterior al   │
              │                  │ │ gios     │ │   salir del      │
              │                  │ │          │ │   sistema        │
              └──────────────────┘ └──────────┘ └──────────────────┘
```

> Este mapa constituye la referencia visual base para la construcción de la Matriz de Riesgos: cada "punto de exposición" identificado aquí corresponde, de forma natural, a uno o varios escenarios de riesgo evaluados formalmente allí.

---

## 14. PLAN DE MANTENIMIENTO DEL INVENTARIO

Un inventario de activos que no se actualiza deja de ser útil y genera una falsa sensación de control. Se establecen las siguientes reglas de mantenimiento:

1. **Actualización por evento**: cada vez que se incorpore un nuevo módulo, tabla, integración externa o cambio significativo de infraestructura, este inventario se actualiza antes de poner el cambio en producción.
2. **Revisión integral periódica**: revisión completa del inventario, como mínimo, una vez al año, o ante cualquier hallazgo de auditoría que sugiera la existencia de activos no identificados.
3. **Versión y control de cambios**: se mantiene un histórico de versiones de este documento, registrando qué activo se agregó, modificó o eliminó, cuándo y por qué — evidencia directa de *accountability* ante el MSPI y ante ISO 27001.
4. **Vínculo con la Matriz de Riesgos**: cualquier cambio en este inventario que modifique la valoración C-I-D de un activo dispara una revisión correspondiente en la Matriz de Riesgos — los dos documentos se mantienen siempre sincronizados.
5. **Responsable de mantenimiento**: el Administrador del Sistema, con respaldo de una designación institucional formal que dé continuidad a esta función más allá de la persona que la ejerza en un momento dado.

---

|  | ELABORÓ | REVISÓ | APROBÓ |
|---|---|---|---|
| **Nombre** | | | |
| **Cargo** | | | |
| **Fecha** | | | |
| **Firma** | | | |

🔲 *Pendiente de diligenciamiento por las instancias institucionales competentes: Administrador del sistema (elaboró), Responsable de Seguridad de la Información (revisó) y Dirección del Centro de Formación (aprobó).*

---

*Fin del documento — Inventario y Clasificación de Activos de Información C-I-D — SmartCSET v1.0*
