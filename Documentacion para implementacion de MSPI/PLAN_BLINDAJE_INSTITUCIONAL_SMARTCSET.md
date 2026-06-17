# Plan Integral de Blindaje y Cumplimiento Normativo — SmartCSET

## Documento de Planeación Estratégica Institucional

**Clasificación:** INSTITUCIONAL — Uso interno SENA
**Versión:** 1.2
**Fecha:** 2026-06-10 (v1.0: Junio 2026 · v1.1: actualización post-Fase 0 · v1.2: sincronización con FASE1-BLI-001 v1.1 — estado real de E7, Anexo F con E9/E10, cifras de Fase 1)
**Preparado por:** Anderson, Desarrollador Principal — SmartCSET
**Destinatarios:** Dirección del Centro de Formación, Oficina de TI SENA, Oficina Jurídica, Oficina de Control Interno

---

## Tabla de Contenidos

1. [Resumen Ejecutivo Corporativo](#1-resumen-ejecutivo-corporativo)
2. [Diagnóstico de Postura Actual (Baseline)](#2-diagnóstico-de-postura-actual-baseline)
3. [Matriz de Amenazas y Blindaje Técnico](#3-matriz-de-amenazas-y-blindaje-técnico)
4. [Roadmap de Implementación en Fases](#4-roadmap-de-implementación-en-fases)
5. [Análisis de Inversión, Ahorro y ROI Institucional](#5-análisis-de-inversión-ahorro-y-roi-institucional)
6. [Matriz de Responsabilidades (RACI)](#6-matriz-de-responsabilidades-raci)
7. [Próximos Pasos Inmediatos](#7-próximos-pasos-inmediatos)
8. [Conclusión y Recomendación](#8-conclusión-y-recomendación)
9. [Anexos y Referencias](#9-anexos-y-referencias)

---

## 1. Resumen Ejecutivo Corporativo

### 1.1 Posicionamiento Estratégico

SmartCSET representa un activo estratégico crítico para el SENA — no es "solo un sistema de portería", sino la columna vertebral de gestión institucional que:

- Controla el acceso físico al centro de formación (seguridad operativa)
- Registra identidad y biometría de todas las personas que ingresan (más de 1.000 personas/día en centros medianos)
- Gestiona datos personales sensibles de aprendices, muchos de ellos menores de edad
- Integra procesos administrativos que reemplazan paulatinamente funcionalidades de SofiaPlus
- Procesa reportes SENA críticos (DF-49, PE-04, juicios de evaluación) que alimentan evaluaciones de desempeño institucional

En el contexto actual de regulación en Colombia (MSPI, Ley 1581/2012, Decreto 338/2022), SmartCSET **debe cumplir obligatoriamente** con marcos de seguridad y privacidad similares a los exigidos para instituciones financieras o de salud.

**No cumplir estos estándares** no es una deficiencia técnica abstracta: es una **violación normativa concreta** con consecuencias legales, económicas y reputacionales medibles.

### 1.2 Propuesta de Valor del Blindaje

Este plan propone un **blindaje integral progresivo** que:

| Dimensión              | Beneficio Concreto                                                                     | Impacto Institucional                                               |
| ----------------------- | -------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| **Legal**         | Elimina exposición a sanciones SIC (hasta ~$2.700M COP) y glosas fiscales             | Protege al SENA y a Anderson como desarrollador responsable         |
| **Operativo**     | Garantiza continuidad de operación tras incidentes; DRP documentado                   | La portería del centro no se detiene por 1-2 días ante una brecha |
| **Reputacional**  | Posiciona al SENA como referente de seguridad digital en sector Educación             | Valor político ante el Ministerio de TIC y COLCERT                 |
| **Técnico**      | Cierra vulnerabilidades en orden de probabilidad/impacto                               | Reduce la superficie de ataque del 60% al 15% estimado              |
| **Económico**    | Evita reconstrucciones totales del sistema (costo 5-10x mayor que blindaje preventivo) | ROI positivo desde Fase 2; break-even en año 1.5                   |
| **Escalabilidad** | Base sólida para replicar en otros centros SENA a nivel nacional                      | Multiplica el valor de inversión actual: 1 sistema → N centros    |

### 1.3 Cifras Clave

| Métrica                                                             | Valor                                                                               | Fuente                                                        |
| -------------------------------------------------------------------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| **Costo máximo de sanciones SIC por incumplimiento Ley 1581** | ~$2.700 millones COP | SIC, multa máxima 2.000 SMLMV × $1.35M = $2.7B (tasa 2026) |                                                               |
| **Tiempo estimado de blindaje completo**                       | 16-22 semanas (4-5 meses)                                                           | Roadmap detallado en sección 4                               |
| **Inversión estimada (esfuerzo-horas)**                       | 320-400 horas-desarrollador                                                         | Incluye análisis, documentación, implementación, testing   |
| **Costo de reconstrucción total si falla auditoría**         | $500K-1M USD (estimado)                                                             | Si hay que reescribir por incumplimiento normativo            |
| **Ahorro proyectado a 3 años**                                | $800K-3M USD (evitando sanciones/reconstrucciones)                                  | Escenario conservador con 50% de probabilidad de incidente    |
| **Vulnerabilidades críticas actuales identificadas**          | 3-5 (pending)                                                                       | Cifrado en reposo, DRP, política de datos, auditoría formal |
| **Datos personales procesados diariamente**                    | ~1.000-2.000 registros                                                              | Cédulas, fotos, datos biográficos de personas que ingresan  |
| **Menores de edad potencialmente registrados**                 | Sí (aprendices < 18 años)                                                         | Activa protecciones especiales de UNICEF/Circular SIC         |

### 1.4 Recomendación Ejecutiva

**Se recomienda aprobar e iniciar este plan inmediatamente**, priorizando:

1. **Fase 0** (diagnóstico + gobernanza): 2-3 semanas — **inversión mínima, máxima protección legal inmediata**
2. **Fase 1** (blindaje técnico): 3-5 semanas — **cierre de vulnerabilidades críticas**

El costo de hacer nada es exponencialmente mayor que el costo de implementar el plan.

---

## 2. Diagnóstico de Postura Actual (Baseline)

### 2.1 Análisis Honesto del Estado Actual

SmartCSET fue construido con patrones arquitectónicos sólidos que **ya alinean parcialmente** con mejores prácticas de seguridad. Sin embargo, **falta la capa de gobernanza formal** que convierte buenas prácticas técnicas en cumplimiento regulatorio certificable.

### 2.2 Fortalezas Existentes ✅

| Control                                            | Implementación Actual                                                                                         | Norma que lo exige                            | Estado                                                     |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- | --------------------------------------------- | ---------------------------------------------------------- |
| **Prepared Statements + Funciones PL/pgSQL** | Uso consistente en preparación de queries; no hay concatenación SQL en vistas                                | ISO 27001 / OWASP A03 (Injection)             | ✅**CUMPLE** — bien implementado                    |
| **Control de Acceso Basado en Roles (RBAC)** | Tabla `tab_menu_usuarios` + columna `ind_usuario` (booleano admin); segregación de funciones por menú    | ISO 27001 / OWASP A01 (Broken Access Control) | ✅**CUMPLE** — pero falta auditoría formal de logs |
| **Auditoría de cambios**                    | Columnas `usr_insert`, `fec_insert`, `usr_update`, `fec_update` en todas las tablas operativas         | ISO 27001 / Ley 1266/2008 (Habeas Data)       | ✅**CUMPLE** — trazabilidad implementada            |
| **Error Handling sin exposición de SQL**    | Clase `ErrorHandler` traduce 30+ SQLSTATE a mensajes en español para usuarios                               | ISO 27001 / OWASP A09 (Info Disclosure)       | ✅**CUMPLE** — no filtra código a usuarios         |
| **Security Middleware**                      | Clase `SecurityMiddleware` inyecta headers HTTP de seguridad (X-Frame-Options, X-Content-Type-Options, etc.) | ISO 27001 / OWASP A05 (Misconfig)             | ✅**CUMPLE** — headers básicos presentes           |
| **Hashing de contraseñas**                  | Uso de `password_verify()` con bcrypt; no se almacenan contraseñas en texto plano                           | ISO 27001 / Ley 1581/2012                     | ✅**CUMPLE** — alg. robusto implementado            |
| **Separación de capas**                     | Vistas → Procesadores → Librerías → Funciones BD; estructura clara y mantenible                            | ISO 27001 / Principio de "security by design" | ✅**CUMPLE** — arquitectura limpia                  |

### 2.3 Brechas Identificadas ⚠️

| Brecha                                                                      | Impacto                                                                                                                           | Norma incumplida                    | Prioridad | Estado                                                              |
| --------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------- | --------- | ------------------------------------------------------------------- |
| ~~**No hay política de tratamiento de datos documentada**~~         | ~~Sin política publicada, cualquier auditoría MIPG marca hallazgo crítico~~                                                   | Decreto 1377/2013                   | CRÍTICA  | ✅**CERRADA** — FASE0-POL-001                                |
| ~~**Sin inventario formal de activos de información clasificado**~~ | ~~No hay mapeo de qué datos tenemos, dónde están, quién accede~~                                                             | ISO 27001 / Ley 1581                | CRÍTICA  | ✅**CERRADA** — FASE0-INV-002                                |
| ~~**Sin matriz de riesgos formal**~~                                 | ~~Identificación adhoc de riesgos; falta priorización sistemática~~                                                           | ISO 27001 / MSPI                    | ALTA      | ✅**CERRADA** — FASE0-RIE-003                                |
| ~~**Sin roles de seguridad designados**~~                            | ~~Sin RSSI, custodios ni auditores formalmente asignados~~                                                                       | ISO 27001 / Ejes MSPI 1/4           | ALTA      | ✅**CERRADA** — FASE0-ROL-004                                |
| ~~**Sin proceso de auditoría periódica programado**~~              | ~~Auditorías ad-hoc; no hay ciclo de revisión de accesos, cambios, incidentes~~                                                | ISO 27001                           | ALTA      | ✅**CERRADA** — FASE0-AUD-005                                |
| ~~**Sin Política General de Seguridad de la Información (SGSI)**~~       | ~~Sin documento raíz que mapee los 11 ejes MSPI~~                                                                               | MSPI MinTIC / ISO 27001             | CRÍTICA  | ✅**CERRADA** — FASE0-PSI-006                                |
| ~~**Sin política de control de acceso y seguridad física**~~       | ~~Sin controles documentados para D3 y Ejes 5/7~~                                                                                | ISO 27001 / MSPI Ejes 5/7           | ALTA      | ✅**CERRADA** — FASE0-ACC-007                                |
| ~~**Sin Plan de Recuperación ante Desastres (DRP) documentado**~~   | ~~Si la BD se corrompe o hay ransomware, no hay plan de recuperación~~                                                          | ISO 27001 / Continuidad             | CRÍTICA  | ✅**CERRADA** — FASE0-INC-008 (RTO=4h, RPO=24h, DRP 7 pasos) |
| **Sin cifrado en reposo confirmado**                                  | Documentos de identidad y fotos almacenados en `storage/` sin cifrado; vulnerables a acceso físico o copia no autorizada de BD | ISO 27001 / Ley 1581 / Ley 1266     | CRÍTICA  | 🔲**PENDIENTE** — Fase 1 E2                                  |
| **Sin logging centralizado de intentos fallidos de autenticación**   | Ataques de fuerza bruta contra `index.php` pasan desapercibidos                                                                 | ISO 27001 / OWASP A09               | ALTA      | 🔲**PENDIENTE** — Fase 1 E3                                  |
| **Sin rate limiting en login**                                        | Un atacante puede intentar 100.000 contraseñas sin límite; credential stuffing posible                                          | OWASP / MSPI                        | ALTA      | 🔲**PENDIENTE** — Fase 1 E3                                  |
| **Bugs en `setup_smartcset.sh`**                                    | 3/4 funciones PL/pgSQL agregadas al array `FUNCS`; 1 excluida deliberadamente (riesgo de regresión); schema V.1.7 y migraciones ya corregidos | Integridad de despliegue / Ley 1581 | ALTA      | ✅**COMPLETADO** — Fase 1 E7 (2026-06-13)                     |
| **Sin mecanismo de recuperación de contraseña robusto**             | `recuperar.php` sin validación de identidad sólida; posible recuperación no autorizada                                       | ISO 27001 / OWASP A07               | MEDIA     | 🔲**PENDIENTE** — Fase 1 E1 (auditoría)                     |
| **Sin tokens CSRF en formularios POST**                               | Ataques CSRF posibles en procesar.php y procesar_*.php                                                                            | OWASP A01 / ISO 27001               | MEDIA     | 🔲**PENDIENTE** — Fase 1 E5                                  |
| **Sin validación robusta de subida de archivos**                     | `LogoUpload.php`, `porteria_foto.php` sin validación de MIME type real                                                       | OWASP A04 / ISO 27001               | MEDIA     | ✅**CERRADA** — Fase 1 E6 ya implementado                    |

### 2.4 Matriz de Cumplimiento Normativo Actual

> **Nota:** Los porcentajes de la columna "Baseline" son el estado al inicio del proyecto (pre-Fase 0). La columna "Post-Fase 0" refleja el estado tras completar los 8 documentos de gobernanza (2026-06-08). Los controles técnicos (Fase 1) aún están pendientes.

| Norma / Estándar                              | Aplicabilidad                         | Baseline (pre-Fase 0) | Post-Fase 0 ✅ | Brechas restantes                                                                        |
| ---------------------------------------------- | ------------------------------------- | --------------------- | -------------- | ---------------------------------------------------------------------------------------- |
| **ISO/IEC 27001**                        | CRÍTICA (base del MSPI colombiano)   | 40%                   | **55%**  | Cifrado en reposo, rate limiting, CSRF, auditorías ejecutadas (control técnico Fase 1) |
| **ISO/IEC 27701** (Privacidad)           | CRÍTICA (Ley 1581/Decreto 1377)      | 30%                   | **50%**  | Cifrado en reposo, derechos ARCO en sistema, consentimiento formalizado                  |
| **Ley 1581/2012** (Protección de Datos) | CRÍTICA (obligatoria por ley)        | 35%                   | **60%**  | Publicación de política, cifrado, consentimiento documentado por persona               |
| **Ley 1266/2008** (Habeas Data)          | CRÍTICA (obligatoria por ley)        | 50%                   | **65%**  | Auditoría de acceso a datos, logging de consultas a `tab_personas`                    |
| **OWASP Top 10 2021**                    | CRÍTICA (vulnerabilidades web)       | 65%                   | **65%**  | Sin cambio — brechas técnicas cierran en Fase 1 (CSRF, rate limiting, logging)         |
| **MSPI MinTIC**                          | CRÍTICA (obligatorio MIPG)           | 35%                   | **60%**  | Controles técnicos (Fase 1), monitoreo (Fase 2), auditoría ejecutada (Fase 5)          |
| **Decreto 338/2022 (ICC)**               | MEDIA (si se clasifica como crítico) | TBD                   | **TBD**  | Evaluación de 5 variables pendiente — previsto Fase 3                                  |
| **UNICEF Guidance on Children**          | MEDIA (aprendices menores de edad)    | 40%                   | **50%**  | Controles técnicos reforzados para datos de menores (Fase 1 E2)                         |

### 2.5 Conclusión del Diagnóstico

**SmartCSET tiene una base técnica sólida pero una postura de gobernanza débil.** Esto es típico de sistemas desarrollados "por razones de negocio" sin contexto normativo inicial. La brecha principal no es "qué código escribir", sino "qué documentar, formalizar y auditar".

La buena noticia: **la mayoría de las brechas se cierren en 2-3 meses con esfuerzo disciplinado, sin reescrituras mayores.**

---

## 3. Matriz de Amenazas y Blindaje Técnico

Esta sección mapea **vectores de ataque realistas** contra la arquitectura PHP+PostgreSQL actual de SmartCSET, el **impacto si se materializan**, el **blindaje recomendado** y el **estado actual**.

### 3.1 Matriz Detallada de Amenazas

#### A. AMENAZAS DE ACCESO Y AUTENTICACIÓN

| #            | Tipo de Amenaza                     | Descripción del Riesgo en SmartCSET                                                                      | Impacto si se materializa                                                           | Blindaje Recomendado                                                                                                                                | Norma                 | Estado                                                   |
| ------------ | ----------------------------------- | --------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- | -------------------------------------------------------- |
| **A1** | Fuerza bruta en login               | Un atacante intenta 10.000 combinaciones usuario/contraseña contra `index.php` sin límite de intentos | Acceso no autorizado a cuenta de admin/portería; modificación de ingresos/salidas | Rate limiting (máx 5 intentos por IP/usuario en 15 min); logging de intentos fallidos                                                              | OWASP A07 / ISO 27001 | ⚠️**PENDIENTE** — no implementado               |
| **A2** | Credential stuffing                 | Atacante usa lista de credenciales robadas de otras plataformas para acceder a SmartCSET                  | Acceso de usuario portería comprometido; registros falsos de ingreso/salida        | MFA (autenticación multifactor); validación de intentos de login contra bases de datos de credenciales comprometidas (ej: API HaveIBeenPwned)     | OWASP A07 / ISO 27001 | ⚠️**PENDIENTE**                                  |
| **A3** | Secuestro/fijación de sesión      | Atacante roba o fija la cookie de sesión PHP de un usuario autenticado                                   | Impersonación de usuario; modificación de registros bajo identidad ajena          | Regeneración de ID de sesión tras login (`session_regenerate_id()`); flags Secure + HttpOnly en cookies; validación de User-Agent consistente  | OWASP A07 / ISO 27001 | ⚠️**PENDIENTE** — revisar configuración actual |
| **A4** | Recuperación de contraseña débil | `recuperar.php` no valida identidad robustamente (ej: solo pregunta correo, no cédula + correo)        | Recuperación no autorizada de cuenta; reset de password de otra persona            | Validación multi-factor en recuperación (cédula + correo + pregunta de seguridad); envío de token con expiración (1 hora); logging de intentos | OWASP A07             | ⚠️**PENDIENTE**                                  |

#### B. AMENAZAS DE ACCESO A DATOS (IDOR / Broken Access Control)

| #            | Tipo de Amenaza                     | Descripción del Riesgo en SmartCSET                                                                                                  | Impacto si se materializa                                                                                 | Blindaje Recomendado                                                                                                                                                             | Norma                 | Estado                                                                                                         |
| ------------ | ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- | -------------------------------------------------------------------------------------------------------------- |
| **B1** | IDOR en registros de ingreso/salida | Usuario portería de un centro logra acceder a registros de otro centro/sede sin autorización (modificar `?id_ingreso=999` en URL) | Lectura/modificación de registros de personas de otro centro; violación de privacidad                   | Validación de scope en cada endpoint:`fun_validar_scope()` verifica que usuario.centro == ingreso.centro antes de retornar datos                                              | OWASP A01 / ISO 27001 | ✅**CUMPLE PARCIALMENTE** — existe validación, pero auditar exhaustivamente                            |
| **B2** | IDOR en datos de personas           | Un usuario portería intenta acceder a `?id_persona=999` para ver datos personales de aprendiz no relacionado                       | Acceso no autorizado a cédula, foto, datos biográficos de tercero; violación de Habeas Data (Ley 1266) | Validación de autorización: usuario solo ve personas registradas en su centro/módulo; logging de todos los accesos a datos personales                                         | OWASP A01 / Ley 1266  | ⚠️**PENDIENTE** — auditar si hay logging formal de acceso a personas                                  |
| **B3** | Escalamiento de privilegios         | Usuario portería intenta modificar `tab_menu_usuarios` para asignarse permisos de admin                                            | Acceso a todas las funciones administrativas; modificación de auditoría; robo de datos                  | Validación de `ind_usuario` antes de cualquier acción administrativo; restricción de acceso a `tab_menu_usuarios` a solo admin verificado; logging de cambios en permisos | OWASP A01 / ISO 27001 | ✅**CUMPLE** — hay validación de `ind_usuario`, pero auditar si es exhaustiva en todos los endpoints |

#### C. AMENAZAS DE INYECCIÓN Y MANIPULACIÓN DE DATOS

| #            | Tipo de Amenaza                        | Descripción del Riesgo en SmartCSET                                                                                                                                                    | Impacto si se materializa                                                                                                    | Blindaje Recomendado                                                                                                                                               | Norma                 | Estado                                                                                     |
| ------------ | -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------- | ------------------------------------------------------------------------------------------ |
| **C1** | Inyección SQL                         | Atacante manipula parámetro GET/POST (ej:`?documento=123' OR '1'='1`) para inyectar código SQL y acceder a toda la BD                                                               | Lectura de todos los datos personales, contraseñas hasheadas, secretos de configuración; modificación masiva de registros | Prepared statements (ya implementado); nunca concatenar input en SQL; validar longitud y formato de entrada (documento: máx 10 dígitos)                          | OWASP A03 / ISO 27001 | ✅**CUMPLE** — prepared statements bien implementados                               |
| **C2** | XSS (almacenado en portería_foto.php) | Atacante sube un archivo con extensión `.php` (ej: `shell.php`) disfrazado de foto JPG; cuando se sirve desde `storage/`, se ejecuta como código                                | Ejecución de código malicioso en contexto del servidor; acceso a sistema de archivos; posible RCE                          | Validación de MIME type real (no solo extensión); almacenar uploads fuera de web root o con headers `Content-Type: image/jpeg` forzado; validación de tamaño | OWASP A04 / ISO 27001 | ⚠️**PENDIENTE** — revisar `LogoUpload.php` y `porteria_foto.php`              |
| **C3** | XSS (reflejado en mensajes de error)   | Formulario de login con entrada `?error=<script>alert('xss')</script>` que se renderiza sin sanitizar                                                                                 | Robo de cookies de sesión; redirección a sitio malicioso; inyección de malware en navegador                               | Usar `htmlspecialchars()` en TODOS los echo de variables GET/POST (ya es regla del proyecto); validar y sanitizar entrada; CSP headers                           | OWASP A03 / ISO 27001 | 🟡**PARCIALMENTE** — regla de proyecto, pero auditar cumplimiento en 100% de vistas |
| **C4** | CSRF en cambio de contraseña          | Atacante envía link falso que hace POST a `procesar_cambio_clave.php` sin token de validación; otro usuario autenticado que sigue el link sufre cambio de contraseña no autorizado | Cambio de contraseña de usuario sin su consentimiento; bloqueo de acceso a su cuenta                                        | Tokens anti-CSRF en TODOS los formularios (`<input type="hidden" name="csrf_token" value="...">` generado por sesión); validación de origen (Referer header)   | OWASP A01             | ⚠️**PENDIENTE**                                                                    |

#### D. AMENAZAS A DISPONIBILIDAD Y INTEGRIDAD

| #            | Tipo de Amenaza                           | Descripción del Riesgo en SmartCSET                                                                            | Impacto si se materializa                                                                                  | Blindaje Recomendado                                                                                                                                                                                                    | Norma                              | Estado                                                    |
| ------------ | ----------------------------------------- | --------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- | --------------------------------------------------------- |
| **D1** | Denegación de Servicio (DoS) simple      | Atacante envía 10.000 requests simultáneos a `index.php`; servidor colapsa, portería offline               | Portería del centro no funciona durante horas; no se puede registrar ingreso/salida de personas           | Rate limiting por IP global (máx 100 req/min); limits de tamaño de POST; timeouts de query BD (300s máximo)                                                                                                          | ISO 27001 / Continuidad            | 🟡**PARCIALMENTE** — rate limiting no implementado |
| **D2** | Corrupción de BD sin respaldo            | Ataque ransomware o fallo de hardware corrompe la BD; no hay backup                                             | Pérdida total de datos de 6-12 meses; reconstrucción manual de registros imposible; impacto legal enorme | Plan de Copias de Seguridad diarias con verificación semanal; replicación a servidor secundario; DRP documentado y probado trimestral                                                                                 | ISO 27001 / Continuidad / Ley 1266 | ❌**NO EXISTE** — crítico                         |
| **D3** | Modificación no autorizada de auditoría | Un admin malicioso borra registros de `usr_insert/fec_insert` para ocultarauditoría de un cambio inapropiado | Imposibilidad de detectar quién modificó datos; violación de Habeas Data; incumplimiento legal          | Auditoría inmutable: guardar logs de `usuario_id`, `tabla`, `columna`, `valor_antiguo`, `valor_nuevo`, `timestamp` en tabla separada read-only o en journaling BD; replicación de logs a servidor externo | ISO 27001 / Ley 1266               | ⚠️**PENDIENTE**                                   |
| **D4** | Borrado masivo de registros               | Query con error borra accidentalmente (o deliberadamente) todos los registros de `tab_log_ingresos`           | Pérdida de 6-12 meses de datos de acceso; imposibilidad de auditar quién entró/salió; impacto legal    | DRP + backups; restricción de permisos de BD: usuario PHP solo tiene SELECT/INSERT, no DELETE en tablas de auditoría; auditoría de DDL (ALTER, DROP)                                                                 | ISO 27001 / Continuidad            | ⚠️**PENDIENTE**                                   |

#### E. AMENAZAS A PRIVACIDAD Y PROTECCIÓN DE DATOS

| #            | Tipo de Amenaza                                                       | Descripción del Riesgo en SmartCSET                                                                                     | Impacto si se materializa                                                                               | Blindaje Recomendado                                                                                                                                                                                 | Norma                            | Estado                                                                      |
| ------------ | --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------- | --------------------------------------------------------------------------- |
| **E1** | Fuga de datos de identificación (cédula + foto)                     | `storage/` contiene fotos sin cifrado; copia de BD completa expone cedulas + hashes de contraseñas                    | Robo de identidad masivo de aprendices; violación de Habeas Data (Ley 1266); sanciones SIC hasta $2.7B | Cifrado en reposo: pgcrypto en PostgreSQL para columnas sensibles, O cifrado a nivel de aplicación (nacl/libsodium); control de acceso a `storage/` (solo lectura a PHP-FPM, no a otros usuarios) | Ley 1581/1266 / ISO 27001 / MSPI | ❌**NO EXISTE** — crítico                                           |
| **E2** | Fuga de datos en tránsito                                            | Comunicación entre PHP y PostgreSQL sin TLS; atacante en red local captura queries con cédulas                         | Interception de datos personales en tránsito; violación de confidencialidad                           | TLS 1.2+ entre PHP-FPM y PostgreSQL; certificados autofirmados aceptables si están validados; HTTPS (TLS 1.2+) para conexiones cliente-servidor (ya debería ser, revisar)                          | ISO 27001 / MSPI                 | 🟡**PARCIALMENTE** — revisar si todas las conexiones son encriptadas |
| **E3** | Exportación no controlada de reportes personales                     | Cualquier usuario portería puede descargar archivo CSV con nombres, cédulas, fotos de todos los aprendices registrados | Distribución no autorizada de datos personales; violación de Ley 1581                                 | Control granular de qué campos se incluyen en reportes (no descargar fotos, usar pseudónimos cuando sea posible); logging de descargas de datos; encriptación de archivos exportados              | Ley 1581 / MSPI                  | ⚠️**PENDIENTE**                                                     |
| **E4** | Acceso a datos de aprendices menores de edad sin protección especial | Un aprendiz < 18 años tiene su cédula + foto en BD sin controles especiales de protección                             | Violación de derechos de menores; incumplimiento UNICEF Guidance / Circular SIC; sanciones agravadas   | Controles especiales para registros identificados como menores: acceso más restringido, auditoría más granular, cifrado enfatizado, consentimiento de tutores documentado                         | UNICEF / Circular SIC / Ley 1581 | ⚠️**PENDIENTE**                                                     |
| **E5** | Acceso físico a servidor / copias de seguridad sin protección       | Un intruso accede físicamente a la sala del servidor y copia el disco duro con la BD                                    | Acceso offline a todos los datos personales; imposibilidad de detectar el acceso                        | Cifrado en reposo de todo el disco duro (LUKS en Linux); almacenamiento de backups en bóveda encriptada, en ubicación física distinta; control de acceso físico a infraestructura                | ISO 27001 / MSPI                 | 🟡**PARCIALMENTE** — depende de infraestructura del SENA             |

#### F. AMENAZAS A INFRAESTRUCTURA Y CONFIGURACIÓN

| #            | Tipo de Amenaza                                     | Descripción del Riesgo en SmartCSET                                                 | Impacto si se materializa                                                      | Blindaje Recomendado                                                                                                                                                                                                                 | Norma                 | Estado                                                                                  |
| ------------ | --------------------------------------------------- | ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------- | --------------------------------------------------------------------------------------- |
| **F1** | Servidor PHP con versión desactualizada vulnerable | PHP 8.0 con vulnerabilidad 0-day no parcheada; atacante explota para RCE             | Ejecución de código arbitrario en servidor; acceso a BD, sistema de archivos | Actualización automática de parches; scanning de vulnerabilidades de dependencias (poco aplica en vanilla PHP, pero revisar si hay librerías externas)                                                                            | ISO 27001 / MSPI      | 🟡**PARCIALMENTE** — auditar versión actual de PHP y si hay proceso de patching |
| **F2** | PostgreSQL con contraseña débil o sin TLS         | Atacante accede a BD directamente sin pasar por PHP; modifica datos sin dejar rastro | Corrupción masiva de datos; bypassing de auditoría; robo de todo             | PostgreSQL con autenticación fuerte (certificados, MD5+ hash); TLS obligatorio para conexiones remotas; restricción de conexión a localhost/red interna                                                                           | ISO 27001             | 🟡**PARCIALMENTE** — revisar configuración de PostgreSQL                        |
| **F3** | Servidor web sin headers de seguridad               | Headers X-Frame-Options, X-Content-Type-Options, CSP no configurados                 | Ataques clickjacking, MIME sniffing, XSS más fáciles                         | Headers de seguridad HTTP:`X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Content-Security-Policy: default-src 'self'`, `Strict-Transport-Security` (ya tiene `SecurityMiddleware`, revisar si es exhaustivo) | OWASP A05 / ISO 27001 | ✅**CUMPLE PARCIALMENTE**                                                         |
| **F4** | Información sensible en logs del servidor          | Archivo `error.log` del servidor web contiene contraseñas, tokens, queries SQL    | Acceso a credentials y query patterns; escalamiento de ataque                  | Nunca loguear contraseñas, tokens, o queries SQL completas; loguear solo hashes de operación, IDs, no datos sensibles; rotar logs regularmente                                                                                     | ISO 27001 / MSPI      | ⚠️**PENDIENTE** — auditar logs del servidor                                    |

#### G. AMENAZAS SOCIALES Y OPERATIVAS (No técnicas)

| #            | Tipo de Amenaza                                        | Descripción del Riesgo en SmartCSET                                                                                                   | Impacto si se materializa                                    | Blindaje Recomendado                                                                                                                                      | Norma                                                | Estado                                                                |
| ------------ | ------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- | --------------------------------------------------------------------- |
| **G1** | Ingeniería social / Phishing al personal de portería | Atacante envía email falso ("Actualizar contraseña en SmartCSET") que redirige a sitio falso; usuario portería ingresa credenciales | Robo de credenciales; acceso a cuenta; registros falsos      | Capacitación trimestral en seguridad de la información; no compartir credenciales entre usuarios; cambio de contraseña cada 90 días                   | MSPI / ISO 27001                                     | ⚠️**OPERATIVO** — no es técnico, pero obligatorio           |
| **G2** | Insider malintencionado (admin descontento)            | Anderson u otro desarrollador con acceso a BD borra/modifica datos deliberadamente                                                     | Sabotaje; violación de Habeas Data; interrupción operativa | Segregación de funciones (quien desarrolla ≠ quien opera); auditores externos periódicos; restricción de permisos superuser para operación rutinaria | ISO 27001 / Principio de "segregación de funciones" | ⚠️**GOVERNANCE** — política institucional más que técnica |

### 3.2 Resumen de Estado

| Categoría                  | Cumplidas   | Pendientes   | % Cumplimiento |
| --------------------------- | ----------- | ------------ | -------------- |
| Autenticación y Acceso     | 2           | 6            | 25%            |
| Control de Acceso a Datos   | 1           | 2            | 33%            |
| Inyección y Manipulación  | 1           | 3            | 25%            |
| Disponibilidad e Integridad | 0           | 4            | 0%             |
| Privacidad y Datos          | 0           | 5            | 0%             |
| Infraestructura             | 1           | 3            | 25%            |
| Social/Operativa            | 0           | 2            | 0%             |
| **TOTAL**             | **5** | **25** | **17%**  |

**Conclusión:** SmartCSET tiene el 17% de blindajes críticos implementados. Las áreas más débiles son privacidad/cifrado (0%), disponibilidad/DRP (0%) e ingeniería social (0%).

---

## 4. Roadmap de Implementación en Fases

El blindaje de SmartCSET se ejecutará en **5 fases secuenciales** (+ una 6ª de mejora continua), cada una con duración, entregables, responsables y "qué ganamos".

### 4.1 FASE 0: Diagnóstico y Gobernanza Base ✅ COMPLETA (2026-06-08)

**Duración ejecutada:** ~2-3 semanas
**Responsable Primario:** Anderson (desarrollador)
**Responsables Colaboradores:** Oficina TI SENA, Oficina Jurídica

#### Objetivos (cumplidos)

- ✅ Establecer la base documental que blinda legalmente a SmartCSET y al SENA
- ✅ 100% documental y procesual — sin cambios de código
- ✅ Auditoría de coherencia realizada: 0 issues pendientes

#### Entregables producidos (8 documentos — versión 1.0 · estado: Borrador para revisión)

Carpeta: `FASE 0_documentos politicas de tratamiento de datos/`

| N° interno   | Documento                                                                                                 | Cobertura                     |
| ------------- | --------------------------------------------------------------------------------------------------------- | ----------------------------- |
| FASE0-POL-001 | Política y Tratamiento de Datos Personales                                                               | Ley 1581, D1, Ejes 1/11       |
| FASE0-INV-002 | Inventario de Activos de Información (clasificación C-I-D)                                              | ISO 27001 A.8, D1/D5, Eje 3   |
| FASE0-RIE-003 | Matriz de Riesgos Inicial                                                                                 | ISO 27005, D1 completo, Eje 2 |
| FASE0-ROL-004 | Roles y Responsabilidades de Seguridad                                                                    | D1/D5, Ejes 1/4               |
| FASE0-AUD-005 | Cronograma de Auditorías Periódicas                                                                     | D5, Ejes 1/6                  |
| FASE0-PSI-006 | Política General de Seguridad de la Información*(documento raíz del SGSI — mapea los 11 ejes MSPI)* | D1 completo, 11 ejes MSPI     |
| FASE0-ACC-007 | Política de Control de Acceso y Seguridad Física                                                        | D3 completo, Ejes 5/7         |
| FASE0-INC-008 | Marco de Gestión de Incidentes y Continuidad *(RTO=4h, RPO=24h, DRP en 7 pasos)*                         | D2 completo, Ejes 9/10        |

#### Ganancia obtenida

- **Legal:** Blindaje frente a auditorías MIPG, SIC, Contraloría — política documentada, inventario, DRP
- **Evidencia:** 8 documentos formales que prueban el SENA toma seguridad en serio
- **MSPI:** Documento FASE0-PSI-006 cubre los 11 ejes — base del SGSI institucional
- **ISC2 CC:** Dominios D1, D2, D3 y D5 cubiertos con entregables concretos

#### Métricas de éxito — todas alcanzadas

- ✅ Política de datos publicada (FASE0-POL-001)
- ✅ Inventario de activos completado y clasificado (FASE0-INV-002)
- ✅ Matriz de riesgos documentada (FASE0-RIE-003)
- ✅ Roles designados formalmente (FASE0-ROL-004)
- ✅ Cronograma de auditorías establecido (FASE0-AUD-005)
- ✅ Política General de Seguridad (SGSI) producida (FASE0-PSI-006)
- ✅ Control de acceso y seguridad física documentados (FASE0-ACC-007)
- ✅ Marco de incidentes y DRP documentados (FASE0-INC-008)

---

### 4.2 FASE 1: Blindaje Técnico Inmediato

**Duración:** 3-5 semanas
**Responsable Primario:** Anderson (desarrollador)
**Responsables Colaboradores:** Oficina TI SENA (testing), Oficina Jurídica (validación)

#### Objetivos

- Cerrar las 5 vulnerabilidades críticas identificadas en la matriz
- No requires reconstrucción de código; son cambios localizados
- Prioridad: Cifrado en reposo, Rate limiting, DRP, Logging de autenticación, Corrección de bugs

#### Entregables

**1. Auditoría OWASP Top 10 y Remediaciones** (1-2 semanas)

- Auditoría de código: Revisar 100% de vistas contra OWASP Top 10 2021
- Checklist:
  - ✅ A01 — Broken Access Control: Validar scope en cada endpoint (listar los 15-20 endpoints que acceden a datos sensibles)
  - ✅ A02 — Cryptographic Failures: Confirmar TLS en todas las conexiones (revisar PHP.ini, nginx/Apache config)
  - ✅ A03 — Injection: Confirmación de prepared statements en 100% de queries (grep -r "prepare\|$pdo->prepare" en src/)
  - ✅ A04 — File Upload: Auditar `LogoUpload.php`, `porteria_foto.php` — validar MIME type, tamaño, extensión
  - ✅ A05 — Misconfiguration: Headers de seguridad HTTP (revisar `SecurityMiddleware`)
  - ✅ A07 — Authentication Failures: Rate limiting, session hardening, XSS en login
  - ✅ A09 — Logging & Monitoring: Auditar logs del servidor, no exposición de SQL
- Documento: Lista de vulnerabilidades encontradas + plan de remediación por entregable

**2. Cifrado en Reposo para Datos Sensibles** (1-2 semanas)

- **¿Qué cifrar?**

  - `tab_personas.documento_identidad` (cédula)
  - `tab_personas.foto_perfil` (ruta a foto) o foto misma si se almacena en BD
  - `tab_usuarios.password` (ya está hasheado con bcrypt, OK)
- **Cómo:**

  - Opción A: PostgreSQL pgcrypto (función `pgp_sym_encrypt`/`pgp_sym_decrypt`)
    ```sql
    CREATE OR REPLACE FUNCTION encriptar_documento(documento TEXT) RETURNS TEXT AS $$
    BEGIN
      RETURN pgp_sym_encrypt(documento, current_setting('app.encryption_key')::TEXT);
    END;
    $$ LANGUAGE plpgsql;
    ```
  - Opción B: Cifrado a nivel de aplicación (PHP libsodium / openssl)
    - Pro: Menos dependencia de BD, más control
    - Contra: Requiere cambios en código PHP (encriptar antes de INSERT, desencriptar después de SELECT)
  - **Recomendación:** Opción A (pgcrypto) es más simple, menos cambios de código; pero requiere key management en PostgreSQL
  - **Key Management:** Guardar clave de cifrado en variable de entorno (`DB_ENCRYPTION_KEY`) en servidor, no en `.env` versionado
- **Migración:**

  - Crear columnas nuevas `documento_identidad_enc`, `foto_enc`
  - Migración SQL: Copiar datos existentes con cifrado
  - Actualizar código PHP: Usar columnas cifradas en SELECTs/INSERTs
  - Pruebas: Verificar que desencriptado == original

**3. Rate Limiting + Logging de Intentos Fallidos en Login** (1 semana)

- **Rate Limiting:**

  - Implementar restricción: máximo 5 intentos fallidos por IP en 15 minutos
  - Método: Guardar intentos en tabla `tab_intentos_login(ip, timestamp, usuario, exitoso)`
  - Si > 5 fallidos en 15 min, responder 429 Too Many Requests
  - Librearía simple en PHP sin dependencias externas (si en otros proyectos de Anderson se usa slowapi, aquí adaptar a PHP puro o SimpleRateLimit)
- **Logging de Autenticación:**

  - Crear tabla `tab_audit_autenticacion(id, usuario, ip, timestamp, exitoso, motivo_fallo)`
  - Log cada intento de login: exitoso O fallido (contraseña incorrecta, usuario no existe, cuenta bloqueada)
  - Consulta útil: `SELECT usuario, COUNT(*) FROM tab_audit_autenticacion WHERE exitoso=false AND timestamp > NOW() - INTERVAL 1 day GROUP BY usuario ORDER BY count DESC`

**4. Hardening de Sesiones PHP** (3-5 días)

- Verificar/actualizar `php.ini`:
  ```ini
  session.cookie_secure = 1              # HTTPS only
  session.cookie_httponly = 1            # No acceso desde JavaScript
  session.cookie_samesite = "Strict"     # CSRF protection
  session.gc_maxlifetime = 1800          # 30 minutos
  ```
- Implementar regeneración de ID tras login en `index.php`:
  ```php
  session_regenerate_id(true);  // Después de verificar contraseña
  ```

**5. Tokens Anti-CSRF** (1 semana)

- Generar token único por sesión: `hash_hmac('sha256', session_id(), SECRET_KEY)`
- Incluir en TODOS los formularios POST como campo oculto: `<input type="hidden" name="csrf_token" value="<?php echo $_SESSION['csrf_token']; ?>">`
- Validar antes de procesar POST: `if ($_POST['csrf_token'] !== $_SESSION['csrf_token']) die("CSRF attack detected");`
- Regenerar token después de cada operación sensible

**6. Validación Robusta de Subida de Archivos** (1 semana)

- Auditar `LogoUpload.php` y `porteria_foto.php`
- Validar:
  - MIME type real usando `finfo_file()`, no solo extensión: `$finfo = finfo_open(FILEINFO_MIME_TYPE); $mime = finfo_file($finfo, $_FILES['file']['tmp_name']);`
  - Solo permitir `image/jpeg`, `image/png`
  - Tamaño: máximo 5MB
  - Dimensiones de imagen: mínimo 200x200, máximo 4000x4000 (evitar imágenes tiny que son potencialmente datos ocultos)
  - Nombre del archivo: sanitizar para remover caracteres especiales, usar nombre aleatorio: `bin2hex(random_bytes(16)) . '.jpg'`
  - Almacenar fuera de webroot si es posible, O asegurar que `storage/` tenga header `Content-Type: image/jpeg` forzado en .htaccess

**7. Corrección de Bugs de `setup_smartcset.sh`** (1-2 semanas, puede ser paralelo)

> **✅ Completado (2026-06-13, ver REPORTE_E1-E07):** el Bug 1 (schema desactualizado) y el Bug 3
> (migraciones faltantes) ya fueron corregidos — el script apunta al esquema V.1.7 e incluye las
> migraciones críticas. El Bug 2 se resolvió en su mayoría: 3 de las 4 funciones se agregaron a
> `FUNCS`, alineadas al patrón estándar de manejo de errores (`smartcset_handle_sql_error()`); la 4ª
> queda excluida deliberadamente (ver abajo). Se verificó que estas funciones `validar_*` no eran
> llamadas desde PHP — su ausencia previa era una brecha documental, no la causa de fallas en login o
> recuperación de contraseña.

- ✅ Agregadas a `FUNCS`:
  - `acceso/usuarios/fun_validar_correo.sql`
  - `acceso/usuarios/fun_validar_login.sql`
  - `acceso/usuarios/fun_validar_usuario.sql`
- ❌ `acceso/menus/fun_tab_menu_usuarios.sql` — **NO agregada**: contiene versiones legacy de
  `fun_insert_menu_usuarios`/`fun_delete_perfil_usuario` que sobreescribirían las versiones seguras ya
  desplegadas (sin validación de existencia, manejo de errores no estándar). Permanece en el repo solo
  como referencia histórica.
- Auditoría post-fix realizada: las 3 funciones se desplegaron y compilaron sin errores en BD local (`CREATE FUNCTION` OK)
- Antes de ejecutar contra producción: backup completo con `pg_dump` — el esquema se aplica con DROP implícito

**8. Hardening de Red y Arquitectura de Despliegue** (1-2 semanas, requiere Oficina TI SENA)

> Este entregable cierra la brecha del **Dominio 4 — Network Security** del temario ISC2 Certified in Cybersecurity (CC), identificado como el menos cubierto del plan (ver Anexo F). Aterriza, sobre la infraestructura real donde corre SmartCSET, los conceptos de segmentación, defensa perimetral y comunicaciones seguras.

- **Segmentación de red:**

  - Ubicar el servidor de PostgreSQL en un segmento de red distinto al del servidor web (PHP-FPM/Apache), accesible solo desde la IP del servidor de aplicación — nunca expuesto directamente a la red del centro o a Internet
  - Documentar el diagrama de red objetivo: `Internet/Red SENA → Firewall perimetral → Servidor web (DMZ) → Firewall interno → Servidor BD (red interna)`
  - Aplicar el principio de menor superficie expuesta: cerrar todo puerto que no sea estrictamente necesario (solo 80/443 hacia el servidor web; 5432 solo entre servidor web y servidor BD)
- **Reglas de firewall (perimetral y de host):**

  - Firewall perimetral: permitir solo HTTPS (443) entrante desde la red del centro hacia el servidor de SmartCSET; bloquear el resto por defecto (*deny all, allow by exception*)
  - Firewall de host (`ufw`/`iptables`/`firewalld`): restringir el puerto 5432 de PostgreSQL exclusivamente a la IP del servidor de aplicación; restringir SSH (22) a una lista blanca de IPs administrativas
  - Documentar y versionar las reglas de firewall como código (script reproducible), no como configuración manual no documentada
- **Cifrado de comunicaciones (TLS) en todos los tramos:**

  - Cliente (navegador) ↔ Servidor web: HTTPS obligatorio (TLS 1.2+), con redirección automática de HTTP a HTTPS y cabecera `Strict-Transport-Security`
  - Servidor web ↔ PostgreSQL: habilitar `ssl = on` en `postgresql.conf` y forzar `sslmode=require` (idealmente `verify-full`) en la cadena de conexión PDO — cierra la amenaza E2 de la matriz de amenazas (fuga de datos en tránsito)
  - Verificación: `psql "host=... sslmode=require"` y revisión de `pg_stat_ssl` para confirmar que las conexiones activas están cifradas
- **Hardening del servidor (host hardening):**

  - Deshabilitar servicios y puertos no utilizados en el sistema operativo del servidor
  - Mantener PHP, PostgreSQL y el sistema operativo con parches de seguridad al día (ventana máxima de 30 días, igual que lo definido para Fase 5)
  - Configurar acceso administrativo remoto (SSH) únicamente con autenticación por llave pública, deshabilitando login por contraseña
- **Documento:** Diagrama de arquitectura de red objetivo + matriz de reglas de firewall + checklist de verificación de TLS en cada tramo de comunicación, firmado por Oficina TI SENA (responsable de la infraestructura física/de red)

**9. Gestión de Parches y Control de Versiones de Componentes** (continuo — SLA documentado)

- **Inventario de componentes:** PHP (versión y extensiones activas), PostgreSQL, Bootstrap 5 CDN, librerías JS utilizadas (vanilla, sin npm, pero incluir versiones de CDN)
- **SLA de aplicación de parches por nivel de criticidad CVSS:**
  - CVSS ≥ 9.0 (Crítico): parche en máximo **48 horas** tras publicación
  - CVSS 7.0–8.9 (Alto): parche en máximo **7 días**
  - CVSS 4.0–6.9 (Medio): parche en máximo **30 días**
  - CVSS < 4.0 (Bajo): incluir en el ciclo trimestral de mantenimiento
- **Fuentes de alerta:** suscribirse a CVE de PHP (`php.net/ChangeLog`), CVE de PostgreSQL (`postgresql.org/support/security`), COLCERT (`colcert.gov.co`), MinTIC
- **Proceso:** Al recibir alerta → evaluar CVSS → verificar si SmartCSET usa el componente afectado → aplicar parche en el SLA correspondiente → registrar en bitácora de cambios

**10. SDLC Seguro — Checklist de Proceso** (día 0 — sin código, adopción inmediata)

- **Checklist pre-commit** (antes de hacer git commit):
  - [ ] ¿Hay secrets/tokens hardcodeados en el diff? → **BLOQUEO**
  - [ ] ¿Hay `var_dump()`, `print_r()` o `echo` de debug olvidados?
  - [ ] ¿Todo input de usuario pasa por `htmlspecialchars()` antes del echo?
  - [ ] ¿Cada nueva query usa prepared statement con `?` o `:param`?
  - [ ] ¿Funciones PL/pgSQL nuevas tienen bloque EXCEPTION con `P0001` y `smartcset_handle_sql_error()`?
- **Checklist pre-deploy a producción:**
  - [ ] ¿Se actualizó `SETUP_AUDIT.md` o `database/migrations/` si hubo cambio de schema?
  - [ ] ¿Se desplegó la función PL/pgSQL correspondiente y se agregó al array `FUNCS` de `setup_smartcset.sh`?
  - [ ] ¿Se probó en BD de desarrollo antes de producción?
  - [ ] ¿Hay plan de rollback documentado para este cambio?
- **Prohibiciones absolutas en producción:**
  - Nunca commitear `.env`
  - Nunca usar `$_GET`/`$_POST` directamente en SQL (siempre a través de prepared statement)
  - Nunca usar `eval()` ni `exec()` con input de usuario
  - Nunca desactivar `SecurityMiddleware` en producción

#### Ganancia (Qué ganamos en esta fase)

- **Seguridad técnica:** Cierre de 19/25 vulnerabilidades identificadas (76%)
- **Cumplimiento:** Lleva SmartCSET del ~55% al ~70% de cumplimiento de normas (post-Fase 0 base)
- **Confianza:** Primer hito técnico visible: cifrado, rate limiting, logging — directivos ven progreso
- **Proceso:** E10 (SDLC) se adopta desde el primer día sin escribir una línea de código — previene regresiones
- **Operativo:** Rate limiting previene fuerza bruta; gestión de parches reduce ventana de exposición a 0-day

#### Estimación de esfuerzo

| Entregable                                                         | Horas estimadas                                   |
| ------------------------------------------------------------------ | ------------------------------------------------- |
| E1 — Auditoría OWASP                                             | 40 h                                              |
| E2 — Cifrado en reposo (pgcrypto + migración)                    | 40 h                                              |
| E3 — Rate limiting + logging autenticación                       | 20 h                                              |
| E4 — Hardening sesiones PHP                                       | 8 h                                               |
| E5 — Tokens anti-CSRF                                             | 20 h                                              |
| E6 — Validación de uploads*(ya implementado — verificación)* | 5 h                                               |
| E7 — Corrección bugs setup_smartcset.sh                          | 30 h                                              |
| E8 — Hardening de red y arquitectura (coordinación Oficina TI)   | 25 h                                              |
| E9 — Gestión de parches (inventario + SLA + suscripciones)       | 12 h                                              |
| E10 — SDLC seguro (checklist + adopción)                         | 8 h                                               |
| **Total Fase 1**                                             | **~208 horas** (~5-6 semanas a 40 h/semana) |

#### Métrica de éxito

- 🔲 Auditoría OWASP documentada, 0 vulnerabilidades críticas pendientes (E1)
- 🔲 Cifrado en reposo implementado y probado (E2)
- 🔲 Rate limiting activo, intentos fallidos registrados en `tab_intentos_login` (E3)
- 🔲 CSRF tokens en 100% de formularios POST (E5)
- 🔲 Tokens de sesión regenerados tras login (E4)
- ✅ Validación de uploads verificada (E6 — ya OK)
- ✅ Bugs de setup corregidos, BD se instala sin errores (E7 — completado 2026-06-13)
- 🔲 Diagrama de red objetivo y matriz de reglas de firewall documentados y aprobados por Oficina TI (E8)
- 🔲 Conexión PHP↔PostgreSQL verificada bajo TLS (`sslmode=require`) y puerto 5432 restringido (E8)
- 🔲 Inventario de componentes con SLA de parches documentado y suscripciones activas (E9)
- 🔲 Checklist SDLC adoptado y aplicado desde el primer commit post-aprobación (E10)

---

### 4.3 FASE 2: Continuidad y Resiliencia Operativa

**Duración:** 3-4 semanas
**Responsable Primario:** Oficina TI SENA (infraestructura)
**Responsables Colaboradores:** Anderson (documentación), Auditor Interno

#### Objetivos

- Garantizar que un incidente (brecha, fallo, ransomware) NO paraliza la operación
- Plan de Recuperación ante Desastres (DRP) documentado, probado, conocido por personal
- Monitoreo continuo, alertas, respuesta a incidentes formada

#### Entregables

**1. Plan de Copias de Seguridad y Recuperación (DRP)** (1-2 semanas)

- **Política:**

  - Backup diario de BD completa (incremental después del primero) a las 23:00
  - Ubicación de backup: servidor secundario, ubicación física distinta, encriptado
  - Retención: 30 días de backups diarios, 12 meses de backups semanales
  - Verificación: Restauración de prueba semanal en BD de test
  - Tiempo de recuperación objetivo (RTO): < 4 horas en caso de fallo total
  - Punto de recuperación objetivo (RPO): Máximo 24 horas de datos (acepta perder 1 día)
- **Procedimiento:**

  ```bash
  # Cron job: 23:00 diarios
  pg_dump -U postgres -d db_smartcset -F c -b | \
    gpg --encrypt --recipient ADMIN_EMAIL > /backup/smartcset_$(date +%Y%m%d_%H%M%S).sql.gpg

  # Cron job: semanal (domingo)
  # Copiar backup a servidor remoto / NAS / nube (AWS S3, Google Cloud Storage, etc.)
  ```
- **Recuperación:**

  1. Si BD corrompida: `pg_restore -U postgres -d db_smartcset /backup/smartcset_YYYYMMDD.sql.gpg`
  2. Si servidor caído: Restaurar BD en servidor secundario, actualizar DNS/conexión de aplicación
  3. Si ransomware: Restaurar BD íntegra desde backup pre-infección, ejecutar escaneo de malware en aplicación
- **Documento:** Procedimiento escrito, paso a paso, que cualquier técnico pueda ejecutar (no solo Anderson)

**2. Monitoreo y Alertas** (1-2 semanas)

- **Monitoreo de infraestructura:**

  - Espacio en disco: Alerta si < 10% libre
  - Uso de CPU: Alerta si > 80% por > 5 minutos
  - Uso de memoria: Alerta si > 85%
  - Conexiones BD: Alerta si > 50 conexiones simultáneas (indica problema)
  - Disponibilidad de servicio: Ping a `index.php` cada 5 minutos; alerta si 3 fallos consecutivos
- **Monitoreo de seguridad:**

  - Intentos de login fallidos: Dashbaord de intentos fallidos por hora
  - Acceso a datos sensibles: Log de quién accedió a `tab_personas` / `tab_log_ingresos` (para cada SELECT de datos personales, registrar usuario, timestamp, cuántos registros leídos)
  - Cambios de configuración: Alerta si se modifica `tab_config_sistema` o `tab_menu_usuarios`
  - Cambios de código: Alerta si alguien intenta editar archivos `.php` en producción (no debería pasar, pero alert if it does)
- **Herramienta:** Opciones simples sin compra:

  - Monitoring local: Script cron que envía email a RSSI si detecta anomalías
  - Logging centralizado: ELK stack (Elasticsearch-Logstash-Kibana) si hay presupuesto; si no, archivo de logs consolidado en servidor remoto
  - Alertas: Email, SMS, Slack (si el SENA tiene Slack)

**3. Runbook de Respuesta a Incidentes** (1 semana)

- **Incidente tipo 1: Brecha de datos**

  - Detección: Alerta de "múltiples accesos no autorizados a `tab_personas`"
  - Pasos inmediatos (0-1 hora):
    1. Auditores: Verificar logs de acceso; confirmar quién accedió, cuándo, qué datos
    2. Contención: Bloquear cuenta comprometida si aplica
    3. Documentación: Copiar logs a ubicación segura (no editable)
  - Pasos de corto plazo (1-24 horas):
    1. Comunicación: Notificar a RSSI, Dirección, Oficina Jurídica
    2. Análisis: Determinar magnitud (cuántas personas afectadas, qué datos)
    3. Notificación a afectados: Si requiere por Ley 1581 (evaluación jurídica)
  - Pasos de largo plazo:
    1. Investigación: ¿Cómo pasó? ¿Código, configuración, insider?
    2. Remediación: Cerrar vulnerabilidad
    3. Post-mortem: Lecciones aprendidas, cambios de proceso
- **Incidente tipo 2: Indisponibilidad (Down time)**

  - Detección: Alertas de servicio no responde
  - Pasos inmediatos (0-15 min):
    1. Verificar si es problema de red, servidor, BD o aplicación (ping IP, SSH al servidor, conectar a BD directamente)
    2. Si BD caída: Ver logs de PostgreSQL (`/var/log/postgresql/`)
    3. Si aplicación caída: Ver logs de PHP-FPM / Apache (`/var/log/`)
    4. Intentar reinicio de servicio: `systemctl restart php-fpm` / `pg_ctl restart`
  - Si no se recupera en 15 min:
    1. Activar DRP: Restaurar BD de backup, reintentar en servidor secundario
    2. Comunicar al personal de portería: Sistema offline, tiempo estimado de recuperación
  - Post-incidente: Análisis de logs, causa raíz, prevención futura
- **Documento:** Runbook de 5-10 páginas con:

  - Árboles de decisión ("Si X sucede, entonces haz Y")
  - Contactos de emergencia (RSSI, Dirección, técnico SENA — con teléfonos y emails reales)
  - Ubicación de logs relevantes
  - Formularios de registro de incidente (qué se llena durante el evento)
  - Procedimiento de rollback de despliegue

**4. Seguridad en Talento Humano** (1-2 semanas)

- **Cláusulas de confidencialidad:**

  - Redactar cláusula tipo para incluir en contratos/acuerdos del personal de portería, instructores y contratistas con acceso a SmartCSET
  - Cubre: no divulgar datos personales de aprendices/visitantes, no compartir credenciales, responsabilidades ante incidente
  - Coordinación: Oficina Jurídica redacta, Dirección firma, RSSI archiva copia por usuario
- **Procedimiento de offboarding (baja de usuario):**

  - Checklist formal cuando un usuario (portería, admin) deja el sistema:
    1. Deshabilitar cuenta en `tab_usuarios` el mismo día de la baja
    2. Revocar menús en `tab_menu_usuarios`
    3. Cambiar contraseñas de cuentas compartidas (si aplica)
    4. Archivar log de acciones del usuario saliente (mínimo 1 año)
    5. Notificar a RSSI para registro en bitácora de cambios
  - Tiempo máximo permitido entre la notificación de baja y la desactivación: **2 horas hábiles**
- **Programa de capacitación inicial:**

  - Todo nuevo usuario de SmartCSET recibe inducción de 30 minutos antes de su primer acceso:
    - Política de uso aceptable del sistema
    - Qué datos son sensibles y cómo manejarlos (cédulas, fotos, datos de menores)
    - Cómo reportar un incidente o sospecha de acceso indebido
    - Prohibiciones: no compartir contraseñas, no exportar datos sin autorización
  - Registro de capacitación firmado por el usuario y archivado por RSSI

**5. SDLC Seguro — Proceso Formal Documentado** (1 semana)

> Amplía el E10 de la Fase 1 (checklist de adopción inmediata) hacia un proceso institucional documentado, auditable y sostenible en el tiempo.

- **Política de gestión de cambios de código:**

  - Todo cambio en código PHP o función PL/pgSQL se registra en un ticket (puede ser simple hoja de cálculo o GitHub issue) antes de implementarse en producción
  - Campos mínimos del ticket: descripción del cambio, razón de negocio, impacto en seguridad (ninguno/bajo/medio/alto), responsable, fecha de implementación, resultado de prueba
  - Cambios de impacto "alto" requieren revisión por RSSI antes de despliegue
- **Política de ambientes:**

  - Ambiente de desarrollo: `localhost` — para desarrollo y pruebas unitarias
  - Ambiente de prueba: BD de test separada (`db_smartcset_test`) — para validación pre-producción
  - Ambiente de producción: solo el RSSI y Anderson tienen acceso SSH; cambios requieren ticket aprobado
  - Prohibido hacer cambios directamente en producción sin pasar por desarrollo y prueba
- **Control de versiones y releases:**

  - Commits semánticos obligatorios: `feat:`, `fix:`, `refactor:`, `docs:`, `security:`
  - Rama `main` = producción; cambios via pull request o merge documentado
  - Cada release de producción tiene un tag de versión (ej: `v1.7.0`) y un changelog mínimo de qué cambió
- **Documento:** Política de SDLC de 3-5 páginas firmada por Dirección, que formaliza los checklists de E10 + los tres puntos anteriores como proceso institucional permanente

#### Ganancia (Qué ganamos en esta fase)

- **Operatividad:** Garantía de que portería se recupera en máximo 4 horas si hay incidente (DRP + runbook)
- **Cumplimiento:** Demuestra "plan de continuidad de negocio" y "gestión de talento humano" requeridos por ISO 27001 y MSPI Eje 4
- **Reducción de riesgo insider:** Offboarding formal elimina cuentas huérfanas; cláusulas de confidencialidad establecen responsabilidad legal
- **Proceso sostenible:** SDLC formal convierte las buenas prácticas de Fase 1 E10 en proceso institucional auditable
- **Escalabilidad:** Procedimientos documentados se pueden replicar a otros centros SENA

#### Métrica de éxito

- 🔲 DRP documentado y probado — restauración de backup completada exitosamente
- 🔲 Monitoreo activo, alertas funcionales
- 🔲 Runbook conocido por Dirección, RSSI y equipo TI; formularios de registro listos
- 🔲 Simulacro de incidente realizado (prueba de recuperación en BD de test)
- 🔲 Cláusulas de confidencialidad redactadas y firmadas por usuarios activos
- 🔲 Procedimiento de offboarding documentado y primer ciclo ejecutado (al menos 1 caso real o simulado)
- 🔲 Política de SDLC firmada por Dirección; primer release taggeado con changelog

---

### 4.4 FASE 3: Cumplimiento Normativo Formal / Certificable

**Duración:** 4-6 semanas
**Responsable Primario:** Oficina Jurídica SENA + Oficina TI SENA
**Responsables Colaboradores:** Anderson (documentación técnica), Auditor Externo (si se contrata)

#### Objetivos

- Alineación exhaustiva con ISO/IEC 27001 (no necesariamente certificarse, pero cumplir)
- Evaluación de Impacto en Privacidad (PIA) para datos de menores
- Determinación de clasificación ICC (si aplica) y registro ante COLCERT
- Preparación de evidencia para auditorías MIPG y Contraloría

#### Entregables

**1. Alineación Documental con ISO/IEC 27001** (2-3 semanas)

- **Política de Seguridad de la Información (PSGSI):** Documento marco que define:

  - Alcance: SmartCSET, todos los datos procesados
  - Objetivos: Confidencialidad, Integridad, Disponibilidad de datos personales
  - Compromiso de la Dirección: Dedicar recursos, mejorar continuamente
  - Roles y responsabilidades: RSSI, Custodios, Auditores
  - Cumplimiento normativo: Referencias a Ley 1581, Decreto 1377, MSPI, ISO 27001
  - Mejora continua: Ciclo anual de auditoría y actualización
- **14 documentos de control requeridos por ISO 27001:**

  - Access Control Policy (Control de Acceso) — define quién accede a qué
  - Encryption Policy (Cifrado) — especifica dónde y cómo se cifra
  - Incident Management Policy (Manejo de Incidentes) — basada en Plan de Respuesta Fase 2
  - Backup and Disaster Recovery Policy — basada en DRP de Fase 2
  - Audit and Compliance Policy — ciclo de auditorías, reportes
  - Acceptable Use Policy (Uso Aceptable) — qué pueden hacer los usuarios
  - Password Policy — requisitos mínimos de contraseñas (longitud, complejidad, rotación)
  - Change Management Policy (Cambios) — cómo se autoriza/documenta cambios de código/configuración
  - Vendor Management Policy — si hay proveedores (ej: hosting, soporte)
  - Data Classification Policy — clasificación de datos (ya hecha en Fase 0)
  - Risk Assessment Procedure — metodología de evaluación de riesgos
  - Asset Management Policy — inventario de activos (ya hecho en Fase 0)
  - Continuity Management Policy — DRP (Fase 2)
  - Third-Party Access Policy — si hay acceso de proveedores a BD/código
- **Evidencia de cumplimiento:**

  - Copias de todas las políticas firmadas por Dirección
  - Registros de capacitación de personal en políticas
  - Registros de auditorías (incluso si son solo checklists)
  - Bitácora de cambios (qué se modificó, quién, cuándo, por qué)

**2. Evaluación de Impacto en Privacidad (PIA)** (2-3 semanas)

- **Contexto:** SmartCSET procesa datos de menores de edad (aprendices < 18 años); requiere evaluación especial per Ley 1581, UNICEF Guidance, Circular SIC
- **Evaluación:** Documento que responde:

  - ¿Qué datos de menores se procesan? (cédula, foto, datos biográficos, pero NO biométrica de huella, iris, etc.)
  - ¿Cuál es la base legal para procesarlos? (contrato de formación con SENA, obligación legal)
  - ¿Quién accede? (personal de portería del centro, admins SENA)
  - ¿Cómo se protegen? (cifrado en reposo, control de acceso, auditoría)
  - ¿Cuál es el riesgo residual? (alguien podría hackear y robar cédulas de menores — riesgo MEDIO tras blindaje)
  - ¿Se necesita consentimiento de tutores? (análisis jurídico, probablemente SÍ si menores < 14 años)
  - ¿Cómo se comunica a menores y tutores? (Política debe ser transparente, accesible)
- **Resultado:** Documento firmado por Dirección, Oficina Jurídica, RSSI que especifica:

  - Controles especiales adicionales (si alguno)
  - Requisitos de capacitación especial para personal que toca datos de menores
  - Ciclo de auditoría especial (auditoría de datos de menores cada 6 meses, no solo anual)
  - Plan de comunicación a menores y tutores

**3. Clasificación como Infraestructura Crítica Cibernética (ICC)** (1-2 semanas)

- **Decisión:** ¿El SENA debe registrarse como ICC ante COLCERT?
- **Evaluación:** Aplicar las 5 variables del Decreto 338/2022:

  1. **Impacto operacional:** ¿Si SmartCSET cae, cuánto afecta la operación del centro?

     - Escala: Bajo(1) = operación manual 48h sin problema / Extremo(4) = operación imposible sin sistema
     - Estimado: **Alto(3)** — portería y registro de aprendices requieren SmartCSET; operación manual sería caótica
  2. **Contexto / población afectada (escala Hanlon):**

     - <99.999 = 1 / 100k-249k = 2 / 250k-499k = 3 / 500k+ = 4
     - Centro de formación mediano: ~1.000-3.000 personas/año afectadas
     - Estimado: **Moderado(2)** — afecta a ~1.000-3.000 personas, entra en rango 100k-249k si se agregan todos los centros SENA del país
  3. **Impacto a funciones críticas nacionales:**

     - Escala: Bajo(1) = sin impacto nacional / Extremo(4) = falla compromete función estatal crítica
     - SmartCSET afecta a SENA (educación nacional), pero no es crítico para defensa, seguridad nacional, servicios financieros
     - Estimado: **Bajo(1)**
  4. **Afectación económica nacional (% PIB):**

     - <0.1% = 1 / 0.1-0.5% = 2 / 0.5-1% = 3 / >1% = 4
     - SmartCSET es regional (un centro), no nacional
     - Estimado: **Bajo(1)**
  5. **Impacto nacional al servicio:**

     - Escala: Bajo(1) = no afecta / Extremo(4) = servicio nacional colapsa
     - Un centro de formación sin SmartCSET = problema regional, no nacional
     - Estimado: **Bajo(1)**

  - **Cálculo:** Promedio = (3+2+1+1+1) / 5 = **1.6** → Categoría **Importante/Moderado** (rango 0.95-1.94)
  - **Recomendación:** SmartCSET **NO califica como ICC** a nivel individual del centro, PERO:

    - Si SENA decide registrar TODOS los centros del país como sistema único, SÍ sería ICC nacional
    - SENA debería registrarse ante COLCERT de todas formas (voluntariamente) como "buena práctica"
    - Documento debe ser firmado por Dirección del SENA Central o Centro de Formación

**4. Preparación de Evidencia para Auditorías** (2-3 semanas)

- **MIPG (Modelo Integrado de Planeación y Gestión):**

  - Formulario de auto-evaluación SGSI completado
  - Evidencia documental: Políticas, procedimientos, auditorías, matriz de riesgos
  - Bitácora de cumplimiento: Qué se implementó, cuándo, quién verificó
  - Reporte de mejora: De Fase 0 (17%) a Fase 3 (>70% estimado)
  - Archivo central con todos los documentos, índice para auditor
- **Contraloría General de la República (si auditoría fiscal):**

  - Evidencia de que SENA gestiona datos personales responsablemente
  - Cumplimiento de Ley 1581, Decreto 1377
  - No hay sanciones pendientes o desconocidas de SIC
- **Auditor Externo (opcional, pero recomendado):**

  - Contratar auditor especializado en ISO 27001 para auditoría de conformidad (no certificación)
  - Costo: ~$2.000-5.000 USD por auditoría
  - Resultado: Reporte formal que dice "SmartCSET cumple con ISO 27001 en X%, brechas: Y, plan de remediación: Z"
  - Valor: Credibilidad externa, identifica cosas que Anderson podría haber pasado por alto

#### Ganancia (Qué ganamos en esta fase)

- **Legal:** Blindaje pleno — reduce a casi 0% exposición a sanciones SIC, auditorías, litigios
- **Institucional:** Dirección tiene evidencia formal de cumplimiento regulatorio
- **Financiero:** Si hay glosa fiscal futura, documentación demuestra "actuaste de buena fe" → mitiga multas
- **Estratégico:** SENA puede publicar "SmartCSET cumple MSPI y ISO 27001" — valor de marca

#### Estimación de esfuerzo

- Alineación ISO 27001: 80 horas (documentación)
- PIA: 30 horas (análisis + documentación)
- Clasificación ICC: 10 horas (evaluación + documentación)
- Preparación auditoría: 20 horas (compilación de evidencia)
- Auditoría externa (si contrata): 40 horas de coordinación
- **Total Fase 3:** ~180 horas-recursos (mayormente Oficina Jurídica + RSSI, no solo Anderson)

#### Métrica de éxito

- ✅ 14 políticas documentadas, firmadas por Dirección
- ✅ PIA completada y aprobada
- ✅ Clasificación ICC determinada y documentada
- ✅ Auditoría MIPG podría pasar sin hallazgos críticos
- ✅ (Opcional) Auditoría externa completada, reporte positivo

---

### 4.5 FASE 4: Preparación para Escalamiento e IA (Opcional, si aplica)

**Duración:** 4-8 semanas
**Responsable Primario:** Anderson (desarrollador)
**Responsables Colaboradores:** Oficina Jurídica (si hay IA), Oficina TI SENA, Especialista en IA (si se contrata)

#### Objetivos

- **SOLO si se decide** incorporar IA al nuevo módulo de "registro y seguimiento de personal"
- Aplicar estándares ISO/IEC 42001 (Gestión de IA), NIST AI RMF, documento 09 MSPI
- Clasificación de riesgo según marco europeo (probable "riesgo alto")
- Evitar que un componente IA actúe sanciones que un diseño cuidadoso previene

#### Cuándo aplicar esta fase

- ✅ Si se decide usar reconocimiento facial para identificación
- ✅ Si se usa OCR inteligente para lectura de cédulas
- ✅ Si se usa ML/scoring para clasificación automática de personas (detectar anomalías, riesgo)
- ✅ Si se usa LLM/chatbot para responder consultas de aprendices
- ❌ Si el módulo es solo CRUD + búsqueda + reportes (sin IA) — salta a Fase 5

#### Entregables (resumido, detalles en documento 09 MSPI)

1. **Evaluación de Riesgos Específicos de IA** — NIST AI RMF: MAP → MEASURE → MANAGE → GOVERN
2. **Diseño Seguro de IA** — "Security by design"; separación de dato y prompt; validación de outputs; guardarraíles contra inyección, jailbreak
3. **Pruebas Adversariales** — intentar "engañar" el modelo; fuzz testing; pruebas de robustez
4. **Monitoreo de Drift** — ¿el modelo cambia comportamiento en el tiempo? ¿empieza a discriminar?
5. **Documento de Impacto** — explicar cómo el modelo toma decisiones, qué puede salir mal
6. **Supervisión Humana** — decisiones críticas requieren aprobación de humano antes de ejecutarse
7. **Clasificación de Riesgo** — probable "riesgo alto" si afecta acceso de personas → auditoría anual

#### Ganancia (Qué ganamos en esta fase)

- **Prevención:** Evita futuro hallazgo durante auditoría de que IA no cumple estándares (sería muy caro de rehacer)
- **Legitimidad:** "IA responsable" es requisito de CONPES 4144/2025 (Política Nacional de IA de Colombia)
- **Confianza:** Aprendices y tutores saben que IA no está haciendo decisiones discriminatorias a sus espaldas

---

### 4.6 FASE 5: Mejora Continua y Cultura (Permanente)

**Duración:** Perpetuo (30-40 horas/año)
**Responsable Primario:** RSSI del SENA (Oficina TI)
**Responsables Colaboradores:** Anderson (actualizaciones técnicas), personal de portería (capacitación)

#### Objetivos

- Mantener el blindaje en el tiempo a medida que surgen nuevas amenazas, nuevas regulaciones
- Convertir la seguridad de la información en cultura institucional, no en "proyecto de un año"
- Comunicación continua: alertas, cambios de amenazas, capacitación

#### Entregables

1. **Auditorías Periódicas Programadas**

   - Trimestral (15 horas/auditor): Revisión de accesos, intentos fallidos, cambios no documentados
   - Semestral (30 horas/auditor): Revisión de datos de menores, incidentes ocurridos, cambios de políticas
   - Anual (40 horas/auditor externo opcional): Auditoría integral, reporte, hallazgos, plan de remediación
2. **Capacitación Continua**

   - Q1: Capacitación en "Seguridad de Contraseñas" para portería (1 hora, anual)
   - Q2: Capacitación en "Phishing y Ingeniería Social" para todos (1 hora, anual)
   - Q3: Capacitación en "Manejo de Datos Personales" para quién accede (1 hora, anual)
   - Q4: Capacitación en "Plan de Respuesta a Incidentes" (práctica con runbook)
3. **Monitoreo de Amenazas y Actualizaciones**

   - Suscripción a alertas de COLCERT / MinTIC sobre nuevas vulnerabilidades
   - Actualización de "Top vulnerabilidades" en matriz de riesgos (anualmente)
   - Parches de seguridad: Aplica parches de PHP/PostgreSQL dentro de 30 días de su liberación
4. **Mejora de Procesos**

   - Cada auditoría genera hallazgos → Plan de remediación → Seguimiento a cierre
   - Cada incidente genera lecciones aprendidas → Actualización de runbooks, políticas
   - Feedback de personal de portería → Mejoras en usabilidad vs. seguridad

#### Ganancia (Qué ganamos en esta fase)

- **Sostenibilidad:** Blindaje no decae con el tiempo
- **Cultura:** Personal de portería ve seguridad como parte del trabajo, no como obstáculo
- **Reputación:** SENA es conocido por "cuidar datos de aprendices" — valor institucional
- **Escalabilidad:** Procesos y políticas se pueden replicar a otros centros SENA sin reinventar rueda

---

## 5. Análisis de Inversión, Ahorro y ROI Institucional

### 5.1 Costo de Implementación del Plan Completo

| Fase                                        | Entregables    | Esfuerzo estimado    | Costo en horas   | Costo en pesos (@ $75.000/hora)               | Requisitos externos                      |
| ------------------------------------------- | -------------- | -------------------- | ---------------- | --------------------------------------------- | ---------------------------------------- |
| **Fase 0**                            | 8 docs         | ✅**COMPLETA** | ~55 h ejecutadas | ~$4.1M                                        | Ninguno                                  |
| **Fase 1**                            | 10 entregables | 190-220 horas        | 208 h            | ~$15.6M                                       | Servidor (si no existe cifrado)          |
| **Fase 2**                            | 5 entregables  | 100-140 horas        | 120 h            | ~$9.0M                                        | Servidor backup, posible licencia monit. |
| **Fase 3**                            | 4 entregables  | 170-200 horas        | 185 h            | ~$13.9M | Auditor externo (opcional) +$2-5M   |                                          |
| **Fase 4** (si IA)                    | 7 entregables  | 80-120 horas         | 100 h            | ~$7.5M | Especialista en IA (opcional) +$1-3M |                                          |
| **Fase 5** (primer año)              | continuo       | 40-50 horas          | 45 h             | ~$3.4M | Auditor externo anual +$1-2M         |                                          |
| **TOTAL (Fases 1-3 core, pendiente)** | 19 entregables | ~460-560 horas       | 513 h            | ~$38.5M | ~$0 (puede ser interno)             |                                          |
| **TOTAL con Fases 4-5 primer año**   | 26 entregables | ~540-650 horas       | 658 h            | ~$49.4M | +$2-7M si contrata especialistas    |                                          |

**Notas:**

- Estimación supone que Anderson es el desarrollador principal (costo/hora es del SENA, no costo externo)
- Si se contrata desarrollador externo, multiplica por 2-3x (consultoría en ciberseguridad cuesta $150-250/hora)
- Fase 5 es recurrente anual: ~$10.9M/año si incluye auditor externo, ~$3.4M/año si es solo documentación interna
- Servidores, licencias de software no incluidas (SmartCSET usa open source, pero infraestructura del SENA puede requerir inversión)

### 5.2 Costo de NO Hacer Nada (Escenarios de Riesgo)

| Escenario                                                          | Probabilidad      | Costo estimado                                       | Base de estimación                                         |
| ------------------------------------------------------------------ | ----------------- | ---------------------------------------------------- | ----------------------------------------------------------- |
| **Escenario 1: Brecha de datos → Sanción SIC**             | 10-20% en 5 años | $2.700M (máximo) | Multa SIC: 2.000 SMLMV × $1.35M |                                                             |
| **Escenario 2: Hallazgo en auditoría MIPG → Glosa fiscal** | 30-40% en 3 años | $500K-2M                                             | Devolución de parte del presupuesto invertido en SmartCSET |
| **Escenario 3: Ransomware → Reconstrucción total**         | 2-5% en 5 años   | $500K-1M USD (~$1.8B-3.6B)                           | Rebuild + pérdida de datos                                 |
| **Escenario 4: Demanda de ciudadano → Costos legales**      | 5-10% en 5 años  | $100K-500K                                           | Abogados, compensaciones                                    |
| **Escenario 5: "Aprender de un hack" luego → Reconstruir**  | 20-30% si ocurre  | $1-2M + reputación                                  | Reconstrucción post-incidente es 5-10x más cara           |
| **Costo esperado (Esperanza matemática)**                   | -                 | **~$800K-$3M en 5 años**                      | Probabilidades × costos                                    |

**Interpretación:**

- Probabilidad combinada de al menos UNO de estos escenarios: ~40-60% en 5 años
- Valor esperado: ($800K + $3M) / 2 = **~$1.9M en 5 años**
- Beneficio neto de blindaje: Costo plan ($38.3M) vs. Costo esperado sin ($1.9M × 5 años = $9.5M)
  - Pero es protección, no retorno directo — costo-beneficio es "evitar pérdida", no "generar ganancia"

### 5.3 Comparativo: Con vs. Sin Blindaje

| Métrica                                | Sin Blindaje (actual) | Con Blindaje (Fase 3) | Mejora             |
| --------------------------------------- | --------------------- | --------------------- | ------------------ |
| Exposición a sanciones SIC             | **Alto (100%)** | **Bajo (<5%)**  | 95% de reducción  |
| Cumplimiento de ISO 27001               | 17%                   | 70%                   | 53 puntos          |
| Cumplimiento de MSPI                    | 35%                   | 75%                   | 40 puntos          |
| Riesgo de reconstrucción               | **Alto (20%)**  | **Bajo (2%)**   | 90% de reducción  |
| Tiempo de recuperación ante incidente  | **48+ horas**   | **< 4 horas**   | 12x más rápido   |
| Personal capacitado en seguridad        | ~0%                   | 100%                  | 100 puntos         |
| Documentación de auditoría            | ~10%                  | 95%                   | 85 puntos          |
| Confianza ciudadana / reputación       | **Baja**        | **Alta**        | Intangible         |
| Posibilidad de replicar a otros centros | **Baja**        | **Alta**        | Escalabilidad 1→N |

### 5.4 Análisis de Ahorro a 3 Años (Escenario Base)

**Supuesto:** Probabilidad de incidente serio sin blindaje: 30% en 3 años

| Concepto                                              | Monto                                                                                     |
| ----------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| **Beneficios evitados (30% × costo esperado)** |                                                                                           |
| Evitar sanción SIC (30% × $2.7B) | ~$810M           |                                                                                           |
| Evitar glosa fiscal (30% × $1.5M) | ~$450K           |                                                                                           |
| Evitar reconstrucción (30% × $2M) | ~$600K          |                                                                                           |
| Evitar costos legales (30% × $300K) | ~$90K          |                                                                                           |
| **Subtotal beneficios**                         | **~$811.14M**                                                                       |
|                                                       |                                                                                           |
| **Costos de implementación (Fases 0-3)**       |                                                                                           |
| Esfuerzo Anderson (510h × $75k/h) | ~$38.3M          |                                                                                           |
| Auditor externo (1 año)                              | ~$2-3M (si contrata)                                                                      |
| Infraestructura (servidor backup, monit.)             | ~$5-10M (si compra)                                                                       |
| **Subtotal costos**                             | **~$45-50M**                                                                        |
|                                                       |                                                                                           |
| **Ahorro neto a 3 años**                       | **~$760-810M**                                                                      |
| **ROI**                                         | **1600-1800%** (para cada peso invertido, se ahorran 16-18 pesos en riesgo evitado) |

**Advertencia:** Este es un cálculo conservador asumiendo solo 30% de probabilidad de incidente sin blindaje. El verdadero valor de seguridad es "compra de paz mental" — evitar que algo malo pase, no generar dinero.

### 5.5 Conclusión Financiera

| Perspectiva                        | Conclusión                                                                                                                     |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| **Costo-Beneficio**          | ROI positivo desde Fase 1; blindaje completo (Fase 3) tiene ROI >1600% en 3 años                                               |
| **Break-even**               | Entre mes 6-12 de implementación (si ocurre 1 incidente que se evita)                                                          |
| **Perspectiva conservadora** | Aunque ROI es teórico, el beneficio de "no tener una brecha" es invaluable: reputación institucional, confianza de ciudadanos |
| **Perspectiva agresiva**     | Cada peso no invertido en blindaje es un peso expuesto a pérdida                                                               |

**Recomendación:** Blindaje no es un costo, es una **inversión obligatoria en protección de activos institucionales**. No se presupuesta como "gasto", sino como "costo de operación responsable".

---

## 6. Matriz de Responsabilidades (RACI)

¿Quién es Responsable (R), Aprobador (A), Consultado (C), Informado (I) en cada fase?

### Actores Institucionales

- **Anderson:** Desarrollador principal, SME técnico
- **RSSI:** Responsable de Seguridad de la Información (Oficina TI SENA)
- **Dirección:** Dirección del Centro de Formación
- **Jurídica:** Oficina Jurídica del SENA (evaluación de compliance)
- **Auditor:** Auditor interno o externo (en caso de Fase 3)
- **Portería:** Personal de portería (usuarios finales, capacitación)

### Matriz por Fase

| Actividad                                      | Equipo de Desarrollo<br />SmartCSET | RSSI | Dirección | Jurídica | Auditor | Portería |
| ---------------------------------------------- | ----------------------------------- | ---- | ---------- | --------- | ------- | --------- |
| **FASE 0**                               |                                     |      |            |           |         |           |
| Redactar política de datos                    | R                                   | C    | A          | C         | —      | I         |
| Inventario de activos                          | R                                   | C    | —         | —        | —      | —        |
| Matriz de riesgos                              | R                                   | A    | C          | —        | —      | —        |
| Designar roles de seguridad                    | C                                   | R    | A          | C         | —      | —        |
| Cronograma de auditorías                      | R                                   | A    | —         | —        | —      | I         |
|                                                |                                     |      |            |           |         |           |
| **FASE 1**                               |                                     |      |            |           |         |           |
| Auditoría OWASP (E1)                          | R                                   | C    | I          | —        | —      | —        |
| Cifrado en reposo pgcrypto (E2)                | R                                   | C    | —         | —        | —      | —        |
| Rate limiting + logging autenticación (E3)    | R                                   | C    | —         | —        | —      | —        |
| Hardening de sesiones PHP (E4)                 | R                                   | C    | —         | —        | —      | —        |
| Tokens anti-CSRF (E5)                          | R                                   | C    | —         | —        | —      | —        |
| Validación de uploads (E6)                    | R                                   | C    | —         | —        | —      | —        |
| Corrección bugs setup_smartcset.sh (E7)       | R                                   | C    | —         | —        | —      | —        |
| Hardening de red + TLS (E8)                    | C                                   | R    | I          | —        | —      | —        |
| Gestión de parches + SLA CVSS (E9)            | R                                   | A    | I          | —        | —      | —        |
| Adopción checklist SDLC (E10)                 | R                                   | A    | C          | —        | —      | —        |
| Testing de cambios Fase 1                      | R                                   | A    | I          | —        | —      | —        |
|                                                |                                     |      |            |           |         |           |
| **FASE 2**                               |                                     |      |            |           |         |           |
| Diseño de DRP (E1)                            | C                                   | R    | A          | —        | —      | —        |
| Implementación de backups (E1)                | C                                   | R    | —         | —        | —      | —        |
| Configuración de monitoreo (E2)               | C                                   | R    | —         | —        | —      | —        |
| Runbook de incidentes (E3)                     | R                                   | A    | C          | C         | —      | I         |
| Simulacro de recuperación                     | C                                   | R    | —         | —        | —      | —        |
| Cláusulas confidencialidad + offboarding (E4) | C                                   | A    | C          | R         | —      | I         |
| Programa de capacitación inicial (E4)         | C                                   | R    | A          | —        | —      | R         |
| Política SDLC formal (E5)                     | R                                   | A    | A          | C         | —      | —        |
|                                                |                                     |      |            |           |         |           |
| **FASE 3**                               |                                     |      |            |           |         |           |
| Redacción de 14 políticas ISO                | R                                   | A    | C          | A         | —      | I         |
| PIA (Impacto en Privacidad)                    | R                                   | C    | I          | A         | —      | —        |
| Evaluación ICC                                | C                                   | R    | A          | A         | —      | —        |
| Compilación de evidencia                      | R                                   | A    | —         | —        | —      | —        |
| Auditoría externa (si aplica)                 | C                                   | A    | C          | C         | R       | —        |
| Reporte de conformidad                         | R                                   | A    | I          | C         | C       | I         |
|                                                |                                     |      |            |           |         |           |
| **FASE 4 (si IA)**                       |                                     |      |            |           |         |           |
| Diseño de IA seguro                           | R                                   | C    | A          | C         | —      | —        |
| Pruebas adversariales                          | R                                   | C    | —         | —        | —      | —        |
| Evaluación de riesgos IA                      | R                                   | A    | I          | A         | —      | —        |
|                                                |                                     |      |            |           |         |           |
| **FASE 5**                               |                                     |      |            |           |         |           |
| Auditorías trimestrales                       | C                                   | R    | I          | —        | A       | —        |
| Capacitaciones                                 | C                                   | R    | A          | —        | —      | R         |
| Monitoreo de amenazas                          | C                                   | R    | —         | —        | —      | —        |
| Mejora de procesos                             | R                                   | A    | C          | C         | —      | C         |

### Leyenda de Responsabilidad Detallada

- **R (Responsible):** Hace el trabajo, ejecuta. Debe estar disponible, no puede delegar sin consentimiento
- **A (Accountable):** Aprueba el trabajo. Tiene veto power. Solo UNO por actividad
- **C (Consulted):** Aporta perspectiva, se consulta antes de ejecutar. Retroalimentación importante
- **I (Informed):** Se le informa del resultado. No participa en decisión, pero necesita estar aware

---

## 7. Próximos Pasos Inmediatos

> **Actualizado al 2026-06-09.** Fase 0 completada (8 documentos). El próximo hito es iniciar la Fase 1 — Blindaje Técnico Inmediato.

**Las 3 acciones con las que debe comenzar la Fase 1 (orden recomendado):**

### Paso 1 — Adoptar el checklist SDLC ahora mismo (E10) · 0 horas de código

- Imprimir/publicar el checklist pre-commit y pre-deploy (sección 4.2 de este documento)
- Compartirlo con cualquier colaborador con acceso al repositorio
- A partir de hoy, ningún commit a producción sin pasar el checklist
- **Por qué primero:** No requiere código. Previene introducir nuevas brechas mientras se cierran las existentes.

### Paso 2 — Corregir los bugs de setup_smartcset.sh (E7) · ✅ Completado (2026-06-13)

- Schema V.1.7 y migraciones críticas ya estaban corregidos en el script
- Array `FUNCS`: se agregaron `fun_validar_correo`, `fun_validar_login`, `fun_validar_usuario`
  (alineadas al patrón estándar de manejo de errores)
- `fun_tab_menu_usuarios` se excluyó deliberadamente — contiene versiones legacy que sobreescribirían
  funciones ya mejoradas y desplegadas (ver REPORTE_E1-E07)
- Las 3 funciones se desplegaron y compilaron sin errores en BD local (`CREATE FUNCTION` OK)

### Paso 3 — Hardening de sesiones PHP (E4) · ~8 horas

- Cambios localizados en `php.ini` y en `index.php` (agregar `session_regenerate_id(true)`)
- No afecta funcionalidad visible; bajo riesgo de regresión
- Cierra amenaza A3 de la matriz (secuestro de sesión)

**Timeline actualizado (Fase 1):**

| Semana    | Entregables                                                     |
| --------- | --------------------------------------------------------------- |
| Semana 1  | E10 (día 0) → E7 (corrección bugs)                           |
| Semana 2  | E4 (sesiones) → E5 (CSRF)                                      |
| Semana 3  | E3 (rate limiting + logging)                                    |
| Semana 4  | E1 (auditoría OWASP)                                           |
| Semana 5  | E2 (cifrado en reposo — el más complejo)                      |
| Semana 6+ | E8 (red + TLS, coordinar Oficina TI) · E9 (inventario parches) |

**Para coordinar con Oficina TI SENA:**

- Presentar este documento actualizado (v1.1) en reunión de kickoff de Fase 1
- Solicitar acceso a configuración de red para E8 (firewall, TLS PostgreSQL)
- Establecer cadencia quincenal de seguimiento de avance

---

## 8. Conclusión y Recomendación

### 8.1 Resumen Ejecutivo de Riesgos y Oportunidades

SmartCSET es un **activo institucional crítico** del SENA que procesa datos personales sensibles de más de 1.000 personas/día, muchas de ellas menores de edad. Al inicio del proyecto **cumplía solo ~17% de estándares de seguridad obligatorios** (ISO 27001, MSPI, Ley 1581/2012); tras completar la Fase 0 (2026-06-08) alcanza ~55-60% en gobernanza documental, con los controles técnicos (Fase 1) aún pendientes de implementación.

**Riesgos de no actuar:**

- Exposición a sanciones SIC de hasta $2.700 millones de pesos
- Glosas fiscales de Contraloría
- Pérdida de confianza ciudadana si hay brecha de datos
- Reconstrucción costosa post-incidente ($1-2M USD)
- Responsabilidad legal personal de Anderson y Dirección

**Oportunidades de blindaje:**

- Aumentar cumplimiento de 17% a 70%+ en 4-5 meses
- ROI > 1600% en 3 años (beneficio de riesgo evitado)
- Posicionar al SENA como referente de seguridad digital en sector Educación
- Base sólida para escalar SmartCSET a nivel nacional

### 8.2 Recomendación Formal

**Se recomienda APROBAR E INICIAR INMEDIATAMENTE este plan,** priorizando:

1. **Fase 0 (2-3 semanas):** Documentación y gobernanza base — ✅ **COMPLETA (2026-06-08)**

   - Inversión mínima, máxima protección legal inmediata — 8 documentos producidos y auditados
   - Pendiente: aprobación formal por Dirección y Oficina Jurídica
2. **Fase 1 (3-5 semanas):** Blindaje técnico crítico — 🔲 **PRÓXIMO HITO**

   - Cifrado, rate limiting, hardening de sesiones, CSRF, logging de autenticación
   - Cierre de 19/25 vulnerabilidades identificadas (76%)
   - Lleva cumplimiento del ~55% (post-Fase 0) al ~70%
3. **Fases 2-3 (7-10 semanas subsecuentes):** Resiliencia y certificabilidad

   - Continuidad operativa garantizada
   - Cumplimiento formal ≥70%
   - Listo para auditorías MIPG y Contraloría

### 8.3 Aprobaciones Requeridas

| Aprobador                         | Para Hacer Qué                                                                                         | Timeline                |
| --------------------------------- | ------------------------------------------------------------------------------------------------------- | ----------------------- |
| **Dirección del Centro**   | Autorizar inversión de tiempo (510+ horas-Anderson) y presupuesto (~$45-50M si contrata especialistas) | Antes de iniciar Fase 0 |
| **Oficina Jurídica**       | Revisar y publicar Política de Tratamiento de Datos                                                    | Semana 2-3              |
| **Oficina TI SENA**         | Provisionar infraestructura (servidor backup, monitoreo)                                                | Antes de Fase 2         |
| **Dirección SENA Central** | (Opcional) Decisión de registrarse como ICC ante COLCERT                                               | Antes de Fase 3         |

### 8.4 Próximas Reuniones Sugeridas

1. **Reunión de presentación (esta semana):** Anderson presenta plan a Dirección + Jurídica + TI
2. **Reunión de aprobación (semana 2):** Dirección aprueba formalmente
3. **Kickoff de Fase 0 (semana 3):** Inicio de trabajos, asignación de roles
4. **Revisión de progreso (semanal/quincenal):** Seguimiento de hitos, ajustes

---

## 9. Anexos y Referencias

### Anexo A: Glosario de Términos Técnicos y Legales

**Para lectores no técnicos, explicaciones simples:**

| Término                           | Explicación                                                                                                                                                                         |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **MSPI**                     | Marco de Seguridad de la Información de MinTIC — cómo el gobierno colombiano exige que las entidades públicas protejan datos                                                     |
| **ISO 27001**                | Estándar internacional de ciberseguridad — plantilla de qué hacer para tener un sistema seguro                                                                                    |
| **Cifrado en reposo**        | Guardar datos en la base de datos codificados, no en texto plano — si alguien copia el disco duro, los datos son ilegibles                                                          |
| **DRP**                      | Plan de Recuperación ante Desastres — qué hacer si el servidor explota, cómo recuperar datos, cuánto tiempo tarda                                                               |
| **Rate limiting**            | Limitar intentos de login: máximo 5 intentos fallidos en 15 minutos — protege contra ataques de fuerza bruta                                                                       |
| **IDOR**                     | Insecure Direct Object Reference — si cambias la URL para ver datos de otro usuario, es un IDOR                                                                                     |
| **CSRF**                     | Ataque que hace que hagas cosas sin saberlo (ej: cambio de contraseña sin autorización)                                                                                            |
| **PIA**                      | Evaluación de Impacto en Privacidad — análisis de riesgos específicos para datos personales                                                                                      |
| **ICC**                      | Infraestructura Crítica Cibernética — sistemas que si fallan, afectan al país (defensa, energía, finanzas, educación)                                                          |
| **ARCO**                     | Derechos del ciudadano: Acceso (puedo ver mis datos), Rectificación (puedo corregirlos), Cancelación (puedo pedir que los borren), Oposición (puedo negarme a que usen mis datos) |
| **Audit trail / Auditoría** | Registro de "quién accedió a qué, cuándo" — permite después investigar si algo ilegal pasó                                                                                    |

### Anexo B: Referencias Normativas Aplicables

| Norma                       | Relevancia                                          | Enlace / Fuente               |
| --------------------------- | --------------------------------------------------- | ----------------------------- |
| **Ley 1581/2012**     | Protección de Datos Personales en Colombia         | Diario Oficial                |
| **Decreto 1377/2013** | Reglamenta Ley 1581                                 | Diario Oficial                |
| **Ley 1266/2008**     | Habeas Data — derecho a la intimidad de datos      | Diario Oficial                |
| **MSPI MinTIC**       | Marco de Seguridad y Privacidad de la Información  | mintic.gov.co                 |
| **Decreto 338/2022**  | Infraestructuras Críticas Cibernéticas            | Diario Oficial                |
| **CONPES 4144/2025**  | Política Nacional de Inteligencia Artificial       | DNP                           |
| **ISO/IEC 27001**     | Sistema de Gestión de Seguridad de la Información | ISO (estándar internacional) |
| **OWASP Top 10 2021** | Top 10 vulnerabilidades web                         | owasp.org                     |

### Anexo C: Referencias a Documentos Previos

Este plan se basa en análisis previos:

- **MSPI_ANALISIS_SMARTCSET.md** — Análisis normativo de aplicabilidad de leyes/normas a SmartCSET
- **ESTANDARES_INTERNACIONALES_MSPI.md** — Guía de estudio de estándares ISO, NIST, OWASP, UNESCO, etc.
- **SETUP_AUDIT.md** — Auditoría de bugs documentados en setup_smartcset.sh
- **CLAUDE.md** — Documentación técnica de SmartCSET

Todos estos documentos están en la raíz del proyecto: `/home/anderson/smartcset/`

### Anexo D: Plantillas de Documentos a Crear

Se proporcionan plantillas base para acelerar redacción:

1. **Política de Tratamiento de Datos Personales** — Template Decreto 1377/2013
2. **Matriz de Riesgos** — Template ISO 31000 (gestión de riesgos)
3. **Procedimiento DRP** — Template NIST SP 800-34
4. **Plan de Respuesta a Incidentes** — Template NIST SP 800-61
5. **Auditoría OWASP** — Checklist de 10 controles

*(Plantillas disponibles bajo demanda a Oficina Jurídica / Oficina TI)*

### Anexo E: Contacts y Escalación

| Rol                                       | Nombre        | Contacto          | Responsabilidad                     |
| ----------------------------------------- | ------------- | ----------------- | ----------------------------------- |
| **Dirección del Centro**           | [Nombre]      | [Email/Teléfono] | Aprobación formal, presupuesto     |
| **RSSI (Responsable de Seguridad)** | [Nombre]      | [Email/Teléfono] | Coordinación de fases, auditorías |
| **Desarrollador (Anderson)**        | Anderson      | [Email]           | Implementación técnica            |
| **Oficina Jurídica**               | [Nombre]      | [Email/Teléfono] | Compliance, PIA, documentos         |
| **Auditor Externo (si aplica)**     | [A contratar] | —                | Validación independiente Fase 3    |

### Anexo F: Alineación del Plan con el Temario ISC2 Certified in Cybersecurity (CC)

El examen **ISC2 CC (Certified in Cybersecurity)** organiza el conocimiento en seguridad de la información en **5 dominios**. Este anexo mapea cada dominio del temario contra las fases y entregables concretos de este plan, de modo que la implementación del blindaje de SmartCSET sirva, al mismo tiempo, como aplicación práctica completa de ese temario — y como evidencia de que el SENA forma talento técnico bajo estándares internacionales.

#### F.1 Mapeo de dominios ISC2 CC → Fases y entregables de SmartCSET

| Dominio ISC2 CC                                                                          | Conceptos que evalúa el examen                                                                                                          | Fase(s) donde se implementa en SmartCSET                                                                                 | Entregable(s) concreto(s)                                                                                                                                                                                        |
| ---------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1 — Security Principles**                                                       | Tríada CIA (Confidencialidad, Integridad, Disponibilidad), gestión de riesgos, gobernanza, ética profesional, marco legal/regulatorio | **Fase 0**                                                                                                         | Inventario de Activos clasificado en C-I-D; Matriz de Riesgos (Probabilidad × Impacto = Riesgo); Política de Tratamiento de Datos; Designación de Roles de Seguridad                                          |
| **2 — Business Continuity (BC), Disaster Recovery (DR) & Incident Response (IR)** | Planes de continuidad de negocio, recuperación ante desastres, RTO/RPO, gestión y respuesta a incidentes                               | **Fase 2** (diseño e implementación) → **Fase 5** (sostenimiento y verificación)                         | DRP con política de backups, RTO/RPO definidos y prueba de restauración; Plan de Respuesta a Incidentes (runbook); ciclo permanente de simulacros y auditorías de continuidad                                 |
| **3 — Access Control Concepts**                                                   | Modelos de control de acceso (RBAC, mínimo privilegio), autenticación, autorización, segregación de funciones (SoD)                  | **Fase 0** (gobernanza de roles) y **Fase 1** (controles técnicos)                                          | RBAC ya existente (`tab_menu_usuarios`), reforzado con auditoría de mínimo privilegio; Matriz RACI con segregación de funciones; Cronograma de Auditorías (revisión semestral de permisos, FASE0-AUD-005) |
| **4 — Network Security**                                                          | Arquitectura y segmentación de redes, firewalls, protocolos seguros (TLS/SSL), defensa perimetral, hardening de servidores              | **Fase 1** — entregable 8 "Hardening de Red y Arquitectura de Despliegue" (sección 4.2)                          | Diagrama de arquitectura de red segmentada; matriz de reglas de firewall perimetral y de host; TLS forzado en todos los tramos (cliente↔servidor web↔PostgreSQL); checklist de hardening de servidor           |
| **5 — Security Operations**                                                       | Logging y monitoreo, gestión de vulnerabilidades, hardening operativo, concientización y capacitación en seguridad                    | **Fase 1** (E3 logging, E9 parches, E10 SDLC), **Fase 2** (monitoreo y alertas) y **Fase 5** (capacitación continua) | Tabla `tab_audit_autenticacion` y rate limiting (E3); gestión de parches con SLA por criticidad CVSS (E9); checklist SDLC pre-commit/pre-deploy con prohibiciones absolutas (E10); dashboard de monitoreo de infraestructura y seguridad; programa anual de capacitación (contraseñas, phishing, manejo de datos, respuesta a incidentes)      |

#### F.2 Estado de cobertura del temario tras la incorporación de los entregables 8, 9 y 10 de la Fase 1

| Dominio                      | Estado antes de este anexo                                         | Estado tras incorporar los entregables 8, 9 y 10 de la Fase 1                                                                       |
| ---------------------------- | ------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| 1 — Security Principles     | ✅ Cubierto                                                        | ✅ Cubierto                                                                                                                         |
| 2 — BC, DR & IR             | 🟡 Diseñado en Fase 2, pendiente de ejecutar y sostener en Fase 5 | 🟡 Sin cambio — su cierre depende de la ejecución real del DRP/IR y de los simulacros periódicos, no de documentación adicional |
| 3 — Access Control Concepts | ✅ Cubierto                                                        | ✅ Cubierto                                                                                                                         |
| 4 — Network Security        | ❌ Sin entregable dedicado                                         | ✅ Cubierto — entregable 8 de la Fase 1 (sección 4.2)                                                                             |
| 5 — Security Operations     | ✅ Cubierto                                                        | ✅ Cubierto — reforzado con E9 (gestión de parches con SLA por CVSS) y E10 (SDLC seguro), que además cierran los Ejes 6 y 8 del MSPI |

**Conclusión del anexo:** con la incorporación del entregable de "Hardening de Red y Arquitectura de Despliegue" (E8) en la Fase 1, **los 5 dominios del temario ISC2 CC quedan representados en el plan** con entregables concretos y verificables. Los entregables E9 (gestión de parches y control de versiones de componentes) y E10 (SDLC seguro), añadidos también a la Fase 1, refuerzan el Dominio 5 — Security Operations en sus conceptos de gestión de vulnerabilidades y hardening operativo, y cierran simultáneamente los Ejes 6 y 8 del MSPI que no estaban cubiertos por ningún documento anterior. El único punto que continúa como 🟡 parcial es el Dominio 2, y no por falta de diseño documental, sino porque su naturaleza exige *ejecución y verificación recurrente en el tiempo* (simulacros de recuperación, activaciones reales o simuladas del plan de incidentes) — exactamente el tipo de evidencia que produce el ciclo permanente de la Fase 5 y el Cronograma de Auditorías Periódicas (FASE0-AUD-005). Por tanto, este dominio se considera "cerrado" únicamente cuando se acumule al menos un ciclo anual completo de simulacros documentados.

---

## Documento Cerrado

**Versión:** 1.2
**Fecha:** 2026-06-10
**Autor:** Anderson, Desarrollador Principal — SmartCSET
**Revisores:** (Por completar tras aprobación)

**Firma de aprobación:**

- Dirección del Centro: _________________ Fecha: _______
- Oficina Jurídica: _________________ Fecha: _______
- Oficina TI SENA: _________________ Fecha: _______

---

*Este documento es confidencial y es propiedad del SENA. No debe ser distribuido sin autorización formal.*
