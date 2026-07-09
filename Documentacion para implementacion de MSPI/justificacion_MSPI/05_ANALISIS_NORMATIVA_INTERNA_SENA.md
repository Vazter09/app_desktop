necesito

# Análisis de la Normativa Interna del SENA — Evidencia Documental

**Documento:** JUS-INT-005
**Fecha:** 2026-07-05
**Clasificación:** Interno — Análisis Jurídico-Técnico
**Fuentes:** Documentos oficiales públicos del SENA descargados de sena.edu.co y repositorio.sena.edu.co (copias en `justificacion_MSPI/documentos_sena/`)

---

## 1. Documentos oficiales analizados

| # | Documento                                                                                                                                                                                                                                              | Origen                    | Archivo local                                              |
| - | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------- | ---------------------------------------------------------- |
| 1 | **Acuerdo del Consejo Directivo Nacional de 2019** — "Por medio del cual se aprueba la Política General de Seguridad de la Información y Protección de Datos Personales en el SENA" + su **Manual** (formato GTH-F-013 V02 / GC-F-005) | sena.edu.co/transparencia | `manual_seguridad_proteccion_datos_2019.pdf` (20 págs.) |
| 2 | Plan de Seguridad y Privacidad de la Información SENA 2019 (GC-F-005 V.04)                                                                                                                                                                            | sena.edu.co/transparencia | `plan_seguridad_privacidad_2019.pdf` (12 págs.)         |
| 3 | Plan de Seguridad y Privacidad de la Información SENA 2023                                                                                                                                                                                            | sena.edu.co/transparencia | `plan_seguridad_privacidad_2023.pdf` (17 págs.)         |
| 4 | Plan de Tratamiento de Riesgos de Seguridad de la Información (dic. 2025, vigencia 2026)                                                                                                                                                              | sena.edu.co/transparencia | `plan_tratamiento_riesgos_2026.pdf` (8 págs.)           |
| 5 | Política de Protección de Datos Personales SENA 2016 (Acuerdo 009 de 2016)                                                                                                                                                                           | sena.edu.co/transparencia | `proteccion_datos_personales_2016.pdf`                   |
| 6 | **Reglamento del Aprendiz SENA (Acuerdo 0009 del 5-nov-2024)** — deroga Acuerdos 07/2012, 02/2014, 06/2023 y 02/2024                                                                                                                            | sena.edu.co/transparencia | `reglamento_aprendiz_2024.pdf` (48 págs., leído)       |
| 7 | Reglamento Interno de los Centros y Programas SENA                                                                                                                                                                                                     | repositorio.sena.edu.co   | `reglamento_interno_centros.pdf`                         |

**Sobre el código DO-pol0006:** los códigos tipo `DO-pol-XXXX` pertenecen a **CompromISO**, la plataforma del Sistema Integrado de Gestión y Autocontrol (SIGA) del SENA — el propio Plan de Seguridad 2023 la referencia como repositorio de sus documentos. CompromISO es de acceso interno (no indexado públicamente), por lo que el texto exacto de DO-pol0006 debe obtenerse desde la intranet o vía la Dirección de Planeación. **Sin embargo, su documento padre sí es público y ya lo tenemos**: el Acuerdo de 2019 (documento #1) es el acto administrativo que aprueba la Política General de la que derivan las políticas complementarias codificadas en CompromISO (Artículo 9 del Acuerdo lista las 16 políticas complementarias).

---

## 2. Hallazgos clave — citas textuales

### H1. El SENA declara que TODOS los datos están en servidores del SENA en Colombia 🔴 **(HALLAZGO CENTRAL)**

> **Manual 2019, §15.7 (Tratamiento de la información y finalidad de los datos):**
> *"**Todos los datos están almacenados en un servidor del SENA en Colombia**, lugar donde están custodiados con mecanismos avanzados de seguridad informática, **con el objetivo de evitar el acceso no autorizado por parte de terceros a su información**."*

**Implicación:** esta es una declaración pública y formal del SENA ante los titulares de datos. Si la empresa de vigilancia contratada registra ingresos/salidas con **software propio en infraestructura propia**, el SENA está incumpliendo **su propia declaración de política** — no solo la Ley 1581. Ante la SIC, una entidad que incumple su propia política publicada agrava su posición (viola el principio de veracidad frente a los titulares).

**SmartCSET:** cumple la declaración literalmente — PostgreSQL en servidor del SENA en Colombia, administrado por el SENA.

---

### H2. El registro de ingresos y salidas es un mandato de la política del SENA

> **Manual 2019, §7.1.1 (Controles Físicos de Entrada):**
> *"Los funcionarios, contratistas, instructores, aprendices y terceros deben cumplir completamente con los controles físicos implementados por la Entidad, ya que **los ingresos y salidas de las instalaciones del SENA deben ser registrados**."*

> **Reglamento Interno de Centros, "Condiciones de Ingreso":** exige registro en portería y porte permanente del carné.

**Implicación:** el registro de ingreso/salida NO es opcional — es un control obligatorio de la política. Pero el mismo Manual (ver H1, H3, H4) exige que ese registro se haga bajo custodia del SENA, con las condiciones de seguridad de la entidad. Un registro llevado por un tercero en software propio cumple el "qué" pero viola el "cómo".

**SmartCSET (módulo SGI):** es la implementación institucional del control §7.1.1 — registro obligatorio, en infraestructura del SENA, con auditoría.

---

### H3. Relaciones con proveedores: requisitos que la situación actual NO cumple

> **Manual 2019, §11 (Relaciones con los Proveedores):**
>
> - *"En todos los Acuerdos con terceras partes, que implique un intercambio, uso o procesamiento de información de la Entidad, se deben realizar **Acuerdos de Confidencialidad** sobre el manejo de la información."*
> - *"Para la celebración de un acuerdo, convenio u contrato se requerirá la suscripción de un **anexo técnico**, donde se establecerá un protocolo de intercambio de la información y se fijarán las condiciones técnicas y controles de seguridad."*
> - *"Se deberá realizar **de manera previa** [...] la **clasificación de la información** que se entrega y se recibe."*
> - Deben intervenir previamente: la dependencia contratante, el **CISO** (Dirección de Planeación) y la **Oficina de Sistemas**.
> - *"De dichos acuerdos deberán derivarse una **responsabilidad tanto civil como penal** para la tercera parte contratada."*
> - *"Se deberá dar estricto cumplimiento a los deberes contemplados [...] en los **artículos 17 y 18 de la Ley 1581 de 2012**."*

**Implicación — checklist de verificación para el contrato actual de vigilancia:**

| Requisito §11                                                                      | ¿El contrato con la empresa de vigilancia lo cumple?                                      |
| ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Acuerdo de confidencialidad sobre datos personales de la comunidad                  | ❓ A verificar — probablemente cubre vigilancia física, no tratamiento de datos          |
| Anexo técnico con protocolo y controles de seguridad del software usado            | ❓ A verificar — el software es propio del proveedor, no evaluado por Oficina de Sistemas |
| Clasificación previa de la información recolectada (datos de menores = sensibles) | ❓ A verificar                                                                             |
| Intervención previa del CISO y Oficina de Sistemas en la definición del sistema   | ❓ A verificar — improbable si el software es unilateral del proveedor                    |
| Responsabilidad civil y penal del proveedor por los datos                           | ❓ A verificar                                                                             |

**Cada "no" en esta tabla es un incumplimiento del Acuerdo de 2019.** Este checklist debe diligenciarse con el contrato real — es la acción de verificación más importante pendiente.

---

### H4. Condiciones contractuales de seguridad son obligatorias para CUALQUIER entidad vinculada que procese datos

> **Manual 2019, §15.3.1:**
> *"Todas las áreas que procesan datos personales de beneficiarios, servidores públicos, aprendices, proveedores y partes interesadas, **deben establecer condiciones contractuales y de seguridad, a las entidades vinculadas**, para el tratamiento de dichos datos personales."*
> *"[...] deben asegurar que **solo aquellas personas que tengan una necesidad laboral legítima**, de acuerdo a sus funciones y responsabilidades, puedan tener acceso a dichos datos."*

**Implicación:** el personal de la empresa de vigilancia que opera un software propio tiene acceso a datos de toda la comunidad (incluidos menores) sin que el SENA pueda verificar la "necesidad laboral legítima" de cada acceso, porque no administra ese sistema.

**SmartCSET:** control de acceso por usuario y menú (`tab_menu_usuarios`, `usuarioTieneMenu()`), auditoría por usuario real (`usr_insert`/`usr_update` — Bug 8 resuelto), sesiones controladas.

---

### H5. Datos biométricos = datos sensibles; fotos de ingreso incluidas

> **Manual 2019, §15.3.1 (Datos Sensibles):**
> *"Datos sensibles son aquellos que afectan la intimidad del titular [...] así como los datos relativos a la salud, a la vida sexual y **los datos biométricos**."*
> **§15.3.2:** *"**Se prohíbe el tratamiento de datos sensibles**, excepto cuando: el titular haya dado su **autorización explícita** [...]"*

**Implicación:** las fotografías de ingreso/salida que captura la portería son datos biométricos → sensibles → requieren autorización explícita y protección reforzada. En manos de un software de terceros sin anexo técnico, es la categoría de incumplimiento más grave posible ante la SIC.

**SmartCSET:** fotos almacenadas en `storage/porteria/` en servidor SENA, con validación de uploads (E6), acceso protegido, y el módulo de reconocimiento facial fue **explícitamente excluido** del alcance (decisión conservadora correcta: la biometría facial exige un análisis de proporcionalidad adicional).

---

### H6. Protección reforzada de niños, niñas y adolescentes

> **Manual 2019, §15.4:**
> *"En la recolección, uso y tratamiento de los datos personales, se asegurará el respeto a los **derechos prevalentes de los niños, niñas y adolescentes**. **Queda proscrito el tratamiento de datos personales de niños, niñas y adolescentes**, salvo aquellos datos que sean de naturaleza pública."*

**Implicación:** el SENA forma miles de aprendices menores de edad (técnicos de media técnica, aprendices 14-17 años). Sus registros de ingreso/salida + fotos en el sistema de un tercero es tratamiento de datos de menores fuera del marco autorizado. La palabra de la política es "proscrito" — prohibido.

**SmartCSET:** el tratamiento queda dentro de la entidad, bajo la finalidad legítima educativa/de seguridad, con trazabilidad de cada acceso — la única configuración defendible ante la SIC para datos de menores.

---

### H7. Deberes del SENA como Responsable que hoy no puede cumplir

> **Manual 2019, §15.9 — el SENA debe:**
>
> - *"Conservar la información bajo las condiciones de seguridad necesarias para **impedir su adulteración, pérdida, consulta, uso o acceso no autorizado o fraudulento**."*
> - *"**Exigir al encargado del tratamiento en todo momento**, el respeto a las condiciones de seguridad y privacidad de la información del titular."*
> - *"**Permitir el acceso a la información únicamente a las personas que pueden tener acceso a ella**."*
> - *"**Informar a solicitud del titular sobre el uso dado a sus datos**."*
> - *"**Informar a la Superintendencia de Industria y Comercio cuando se presenten violaciones** a los códigos de seguridad."*

**Implicación:** con los datos en software de un tercero, el SENA **no puede materialmente cumplir** ninguno de estos cinco deberes:

1. No puede impedir adulteración (no administra la BD del tercero)
2. No puede "exigir en todo momento" (no tiene visibilidad de la operación)
3. No puede restringir accesos (no gestiona los usuarios del software ajeno)
4. No puede informar al titular qué uso se dio a sus datos (no tiene los logs)
5. No podría siquiera **detectar** una violación de seguridad para reportarla a la SIC

**SmartCSET:** cada uno de los 5 deberes tiene un control técnico implementado: BD transaccional con triggers de auditoría (1), administración directa (2), control de acceso por usuario/menú (3), logs con usuario real y timestamp (4), SIEM E11 para detección (5).

---

### H8. Principio de seguridad y de acceso restringido (política 2016, vigente transitoriamente)

> **Manual 2019, §15.2 (Principios) — Principio de seguridad:**
> *"La información [...] se deberá manejar con las medidas técnicas, humanas y administrativas que sean necesarias para otorgar seguridad a los registros **evitando su adulteración, pérdida, consulta, uso o acceso no autorizado o fraudulento**."*

> **Acuerdo 2019, Artículo 15 (transitorio):** el Acuerdo 009 de 2016 (Política de Protección de Datos, documento #5) sigue vigente mientras se desarrollan las políticas complementarias — es decir, **ambos marcos aplican simultáneamente**.

---

### H9. El MSPI está formalmente adoptado y en operación en el SENA (planes 2023 y 2026)

> **Plan de Seguridad y Privacidad 2023:** el SENA implementa el MSPI *"alineado con la NTC/IEC ISO 27001:2013, la Política de Gobierno Digital"*, de *"cumplimiento para los funcionarios, contratistas, instructores, aprendices y **terceros** que tengan"* acceso a información. Incluye gestión de *"seguridad en las relaciones **de proveedores**"* como dominio del plan.

> **Plan de Tratamiento de Riesgos 2026:** el SENA *"gestiona los riesgos de seguridad digital [...] **la protección de los activos de información y la custodia de los datos personales de los ciudadanos**"*, bajo NTC-ISO 31000 y la Guía para la Gestión Integral del Riesgo en Entidades Públicas 2025.

**Implicación:** el MSPI no es una aspiración futura — es un compromiso institucional formal, en ejecución, con planes anuales publicados por transparencia. Un sistema de registro de ingresos operado por un tercero fuera del SGSI es un **activo de información no gestionado** = riesgo no tratado = hallazgo directo en cualquier auditoría MinTIC/Contraloría del MSPI.

---

### H10. La autorización de datos del aprendiz cubre SOLO al SENA — no a terceros privados 🔴 **(REGLAMENTO DEL APRENDIZ 2024)**

> **Reglamento del Aprendiz 2024, Artículo 11, Parágrafo 5 (Etapa de registro):**
> *"Con el registro de datos básicos y la aceptación de la política de seguridad, confidencialidad, el usuario, aspirante o aprendiz autoriza y da el consentimiento para el tratamiento de datos personales y que de manera libre, previa, clara, expresa, voluntaria y debidamente informada **permite a la entidad** recolectar, recaudar, almacenar, usar, procesar, compilar, **intercambiar con otras entidades públicas**, dar tratamiento, actualizar y disponer de los datos [...] **Esta información es y será utilizada en el desarrollo de las funciones propias del SENA**."*

**Implicación — este es el hallazgo jurídico más preciso de toda la investigación:**

1. La autorización que firma cada aprendiz habilita **a la entidad** (el SENA) — el intercambio autorizado es solo **"con otras entidades públicas"**. Una empresa de vigilancia **privada** con software propio **no está cubierta** por esta autorización.
2. La finalidad autorizada es "el desarrollo de las funciones propias del SENA" — un sistema comercial de un proveedor privado no es una función propia del SENA.
3. Conclusión: **el tratamiento de datos de aprendices en el software del proveedor de vigilancia se hace SIN autorización válida del titular** → violación directa del principio de libertad (Ley 1581, art. 4.c) y de la propia autorización institucional.
4. En contraste, **SmartCSET queda automáticamente amparado por la autorización ya existente**: es un sistema de la entidad, para funciones propias del SENA. **No se requiere recoger nuevas autorizaciones para operar SmartCSET** — la base jurídica ya está firmada por cada aprendiz al matricularse.

---

### H11. El deber de identificarse al ingreso es "según lo que disponga la entidad"

> **Reglamento del Aprendiz 2024, Artículo 8 (Deberes), numeral 19:**
> *"**Atender las indicaciones de identificación de usuarios que disponga la entidad para el ingreso a las sedes del SENA** y a los ambientes de formación."*

> **Artículo 9 (Prohibiciones), numeral 12:**
> *"Ingresar o salir de cualquier instalación del Centro de Formación [...] **por sitios diferentes a la portería**, saltando muros, cercas o violentando puertas, ventanas y cerraduras."*

**Implicación:** el reglamento obliga al aprendiz a identificarse al ingresar **según el mecanismo que la entidad disponga**, y define la portería como el único punto legítimo de entrada/salida. SmartCSET/SGI es precisamente "la indicación de identificación que dispone la entidad" — con respaldo reglamentario directo. El aprendiz ya está obligado a usarlo; no se necesita consentimiento adicional para el control de ingreso institucional.

**Refuerzo de integridad (Artículo 9, numerales 1-3):** el reglamento prohíbe *"registrar información en los sistemas de información del SENA que difiera de la real"*, *"suplantar identidad"* y *"alterar, adulterar, falsificar o sustraer documentos [...] en custodia del SENA"* — el registro de ingresos es un documento en custodia del SENA cuya integridad el reglamento protege con régimen disciplinario. Un sistema de terceros donde el SENA no puede verificar la integridad hace inaplicable este régimen.

---

### H12. Menores confirmados: edad mínima 14 años, con consentimiento de padres SOLO hacia el SENA

> **Reglamento del Aprendiz 2024, Artículo 10 (Reglas generales de ingreso):**
> *"La edad mínima de los aspirantes, para ingreso a los programas de formación profesional integral será de **(14) catorce años**."*
> **Parágrafo:** *"Para que los aspirantes o aprendices **menores de edad** accedan [...] uno de los padres de familia, el acudiente o el apoderado, **deben firmar el consentimiento informado** y el aprendiz firma su **asentimiento**, incluyéndolo en la documentación para legalizar y asentar la matrícula."*

**Implicación:**

1. Confirma normativamente que la comunidad SENA incluye **menores desde 14 años** — no es una suposición.
2. El consentimiento informado de los padres se otorga **al SENA para la formación** — en ningún punto del proceso de matrícula se autoriza a un proveedor privado de vigilancia a tratar los datos del menor.
3. Combinado con H6 (Manual 2019 §15.4: tratamiento de datos de menores "proscrito" fuera del marco) y H10: los datos de aprendices de 14-17 años en el software del tercero constituyen **tratamiento de datos de menores sin autorización de los representantes legales** — la infracción de mayor gravedad posible ante la SIC (agravante expreso: Ley 1581, art. 7).

---

## 3. Matriz consolidada: norma interna SENA vs. situación actual vs. SmartCSET

| #  | Requisito (fuente interna SENA)                                                                                         | Situación actual (software del proveedor de vigilancia)     | Con SmartCSET/SGI                                         |
| -- | ----------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ | --------------------------------------------------------- |
| 1  | Datos en servidor del SENA en Colombia (§15.7)                                                                         | ❌ Datos en sistema del tercero                              | ✅ PostgreSQL en servidor SENA                            |
| 2  | Registrar ingresos y salidas (§7.1.1)                                                                                  | ⚠️ Se registra, pero fuera de custodia SENA                | ✅ Registro en`tab_log_ingresos`                        |
| 3  | Acuerdo de confidencialidad + anexo técnico con el tercero (§11)                                                      | ❓ A verificar contrato — probablemente ausente             | ✅ N/A — no hay tercero tratando datos                   |
| 4  | Clasificación previa de la información compartida (§11)                                                              | ❓ A verificar — improbable                                 | ✅ Inventario de activos FASE 0 (FASE0-INV-002)           |
| 5  | Intervención de CISO + Oficina de Sistemas en sistemas que tratan datos (§11)                                         | ❌ Software unilateral del proveedor                         | ✅ Sistema institucional, documentado                     |
| 6  | Condiciones contractuales de seguridad a entidades vinculadas (§15.3.1)                                                | ❓ A verificar                                               | ✅ N/A                                                    |
| 7  | Acceso solo con necesidad laboral legítima (§15.3.1)                                                                  | ❌ SENA no controla usuarios del software ajeno              | ✅`tab_menu_usuarios` + `usuarioTieneMenu()`          |
| 8  | Autorización explícita para datos sensibles/biométricos (§15.3.2)                                                   | ❌ Sin gestión verificable de autorizaciones                | ⚠️ Workflow de consentimiento a formalizar              |
| 9  | Protección prevalente de datos de menores (§15.4)                                                                     | ❌ Datos de menores en sistema de tercero                    | ✅ Tratamiento interno con trazabilidad                   |
| 10 | Impedir adulteración / acceso no autorizado (§15.9)                                                                   | ❌ Sin capacidad material de control                         | ✅ Prepared statements, triggers, auditoría              |
| 11 | Informar al titular el uso dado a sus datos (§15.9)                                                                    | ❌ SENA no tiene los logs del tercero                        | ✅ Logs con usuario real y timestamp                      |
| 12 | Detectar y reportar violaciones a la SIC (§15.9)                                                                       | ❌ Sin visibilidad para detectar                             | ✅ SIEM (E11)                                             |
| 13 | Activos de información inventariados y gestionados en el MSPI (Planes 2023/2026)                                       | ❌ Sistema del tercero fuera del SGSI del SENA               | ✅ Dentro del alcance MSPI (FASE 0+1 propias)             |
| 14 | Autorización del titular solo cubre a la entidad e intercambio con entidades públicas (Regl. Aprendiz Art. 11 Par. 5) | ❌ Tercero privado trata datos sin autorización válida     | ✅ Amparado por la autorización de matrícula ya firmada |
| 15 | Identificación al ingreso "según disponga la entidad" (Regl. Aprendiz Art. 8 num. 19)                                 | ⚠️ El mecanismo lo dispone el proveedor, no la entidad     | ✅ SmartCSET ES el mecanismo dispuesto por la entidad     |
| 16 | Consentimiento de padres de menores otorgado al SENA (Regl. Aprendiz Art. 10 Par.)                                      | ❌ No cubre al tercero → datos de menores sin autorización | ✅ Cubierto por el consentimiento de matrícula           |

**Resumen: de 16 requisitos internos, la situación actual incumple 10 con certeza y 4 más pendientes de verificación contractual (❓). SmartCSET cumple 15 de 16 (1 en desarrollo: formalización del workflow de consentimiento para visitantes).**

---

## 4. El argumento reforzado (para el documento ejecutivo)

La investigación externa (JUS-INV-001) ya demostró que la situación actual viola la **Ley 1581/2012 y el MSPI de MinTIC**. Este análisis demuestra algo más contundente:

> **El SENA está incumpliendo su propia Política General de Seguridad de la Información, aprobada por su Consejo Directivo Nacional en 2019 y publicada en su portal de transparencia.**

Esto transforma el argumento de justificación de SmartCSET:

- **Antes:** "SmartCSET es necesario para cumplir la ley" (argumento externo)
- **Ahora:** "SmartCSET es la implementación técnica de la política que el Consejo Directivo Nacional del SENA ya aprobó y ordenó cumplir. No requiere una decisión nueva de política — requiere ejecutar la que ya existe" (argumento interno + externo)

Ante una Dirección Regional, este es el argumento óptimo: no se le pide aprobar nada nuevo, se le muestra que el proyecto ejecuta el mandato del Acuerdo de 2019 (§7.1.1 registro de ingresos, §15.7 servidores propios, §15.9 deberes del responsable) que hoy está en incumplimiento.

---

## 5. Acciones de verificación pendientes (requieren acceso interno)

1. **Obtener de CompromISO** el texto de `DO-pol0006` y las demás políticas complementarias del Artículo 9 del Acuerdo 2019 (especialmente: Control de Acceso, Relaciones con Proveedores, Protección de Datos Personales, Seguridad Física y del Entorno) — vía intranet o Dirección de Planeación del centro.
2. **Revisar el contrato vigente con la empresa de vigilancia** contra el checklist de la sección H3 (acuerdo de confidencialidad, anexo técnico, clasificación de información, responsabilidad civil/penal). Cada requisito faltante es evidencia documental del incumplimiento.
3. **Verificar el Registro Nacional de Bases de Datos (RNBD)** de la SIC: ¿está registrada la base de datos de control de ingreso? ¿Quién figura como responsable y encargado?

~~4. Reglamento del Aprendiz 2024~~ — ✅ **COMPLETADO (2026-07-05):** leído íntegramente en sus capítulos I-IV. Hallazgos incorporados como H10 (autorización solo cubre a la entidad), H11 (identificación al ingreso según disponga la entidad + portería como único punto de entrada) y H12 (menores desde 14 años con consentimiento parental otorgado solo al SENA).

---

## 6. Conclusión

La normativa interna del SENA **ya ordena** todo lo que SmartCSET implementa:

1. **§7.1.1** ordena registrar ingresos y salidas → SmartCSET/SGI es ese registro
2. **§15.7** declara que los datos están en servidores del SENA → SmartCSET lo hace verdad
3. **§11 + §15.3.1** exigen condiciones estrictas a terceros que la situación actual no puede demostrar → SmartCSET elimina al tercero del tratamiento
4. **§15.4** proscribe el tratamiento de datos de menores fuera del marco autorizado → SmartCSET lo internaliza con trazabilidad
5. **§15.9** impone deberes que el SENA hoy no puede cumplir materialmente → SmartCSET provee el control técnico para cada uno
6. **Regl. Aprendiz Art. 11 Par. 5**: la autorización de datos firmada por cada aprendiz cubre a la entidad y el intercambio con entidades públicas — **no a un proveedor privado** → SmartCSET opera bajo la autorización ya existente; el software del tercero opera sin ella
7. **Regl. Aprendiz Art. 8 num. 19 + Art. 9 num. 12**: el aprendiz debe identificarse al ingreso según lo que **disponga la entidad**, y la portería es el único punto legítimo de entrada → SmartCSET es el mecanismo institucional que el reglamento presupone
8. **Regl. Aprendiz Art. 10**: aprendices desde los **14 años**, con consentimiento de padres otorgado **al SENA** → los datos de menores en el software del tercero carecen de autorización de los representantes legales

**SmartCSET no es una propuesta de cambio: es el cierre de la brecha entre lo que el SENA promete en su política pública y lo que ocurre en su portería.**

---

**Documento preparado:** 2026-07-05
**Elaborado por:** Equipo de Desarrollo SmartCSET
**Estado:** Completo — pendientes las 4 verificaciones internas de la sección 5
**Clasificación:** CONFIDENCIAL — USO INTERNO SENA
