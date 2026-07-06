# Justificación de Módulos — SGA (Administrativo) y SAA (Aprendiz)
**Documento:** JUS-MOD-006
**Fecha:** 2026-07-05
**Clasificación:** CONFIDENCIAL — Dirección Institucional
**Propósito:** Extender la justificación legal-estratégica de SmartCSET (docs. 01-05, centrados en el SGI) a los otros dos sistemas de la plataforma: SGA y SAA
**Documentos base:** `01_INVESTIGACION_NORMATIVA` (marco externo), `05_ANALISIS_NORMATIVA_INTERNA_SENA` (hallazgos H1-H12), `03_JUSTIFICACION_ESTRATEGICA` (modelo de decisión)

---

## 1. Arquitectura de SmartCSET — Tres Sistemas

SmartCSET se organiza en tres sistemas (árbol de menús institucional, migración `reorganizacion_menus_tres_abuelos.sql`):

| Sistema | id_menu | Módulos | Estado |
|---|---|---|---|
| **SGI — Ingresos** | `10` | Entradas, registro de ingreso, registro de salida, datos estadísticos | ✅ **Operativo** |
| **SGA — Administrativo** | `20` | Instructores, aprendices, rutas, programas, novedades (llamados/comités), fichas del instructor, personas, reportes SENA (DF-49, DF-53, DF-14A, PE-04, DF-51, juicios), administración (usuarios, menús, accesos, auditoría de sesiones), configuración, **SIEM** (`211`) | ⚙️ **Parcialmente operativo** (listados, fichas, reportes, SIEM, administración ✅ · disciplinario, certificaciones, rutas en construcción) |
| **SAA — Aprendiz** | `30` | Biblioteca, gimnasio, bienestar | 🔲 **En construcción** |

**La justificación de los docs. 01-05 cubre el SGI** (el módulo con el problema legal vivo: el proveedor de vigilancia). Este documento justifica los otros dos.

---

## 2. El Marco Legal Común Ya Está Construido

Los fundamentos de los docs. 01 y 05 **aplican a los tres sistemas por igual** — no hay que rehacerlos:

| Fundamento | Fuente | Aplica a |
|---|---|---|
| SENA = Responsable del tratamiento | Acuerdo 2019, Art. 12 | SGI + SGA + SAA |
| Datos en servidores del SENA en Colombia | Manual 2019 §15.7 (H1) | SGI + SGA + SAA |
| Datos académicos y biométricos = sensibles; protección reforzada | Manual 2019 §15.3.1 (H5) | SGI + SGA + SAA |
| Datos de menores: tratamiento fuera del marco = proscrito | Manual 2019 §15.4 (H6); menores desde 14 años (H12) | SGI + SGA + SAA |
| Deberes del responsable: integridad, acceso restringido, informar al titular, detectar violaciones | Manual 2019 §15.9 (H7) | SGI + SGA + SAA |
| **La autorización firmada por el aprendiz ampara los sistemas de la entidad** para funciones propias del SENA | Regl. Aprendiz 2024, Art. 11 Par. 5 (H10) | **SGI + SGA + SAA — ninguno requiere autorizaciones nuevas de aprendices** |
| Sistemas gestionados dentro del SGSI/MSPI institucional | Planes MSPI 2023/2026 (H9) | SGI + SGA + SAA |

**Lo que cambia entre módulos es el argumento central**, porque el problema que cada uno resuelve es distinto:

- **SGI:** *sacar al tercero* — soberanía de datos (docs. 01-05)
- **SGA:** *trazabilidad y debido proceso académico* — este documento, sección 3
- **SAA:** *bienestar como derecho reglamentario* — este documento, sección 4

---

## 3. Justificación del SGA — Sistema de Gestión Administrativa

### 3.1 El problema que resuelve

Los procesos académico-administrativos **a nivel de centro** (asistencia diaria, retardos, ausencias con excusa, llamados de atención, comités, novedades de deserción/aplazamiento, seguimiento de fichas) hoy se llevan de forma dispersa: planillas de papel, archivos Excel personales de cada instructor, mensajes de WhatsApp. Esto reproduce, **dentro del SENA**, los mismos riesgos que motivaron el SGI frente al tercero:

| Riesgo (matriz doc. 02) | Cómo se manifiesta en lo académico hoy |
|---|---|
| R2 — Auditoría débil | Nadie puede responder "¿quién registró esta inasistencia y cuándo?" — el Excel del instructor no tiene trazabilidad |
| R3 — Integridad no verificable | Una planilla o un Excel se edita sin dejar rastro; un llamado de atención en papel se pierde o se altera |
| R5 — Derechos de titulares | Ante un reclamo del aprendiz ("yo sí asistí"), no hay registro íntegro que permita responder en 10 días hábiles |

### 3.2 Anclaje normativo específico del SGA

**a) El Reglamento del Aprendiz exige registros que hoy no tienen soporte íntegro:**

- **Art. 8 num. 5:** el aprendiz debe *"asistir con puntualidad a todas las actividades"* — la asistencia/retardo es un hecho con consecuencias disciplinarias que exige registro fiel (SGA: asistencia por ficha, `fun_verify_retardo_aprendiz`)
- **Arts. 28-30:** incumplimiento justificado/injustificado y **deserción** se determinan a partir de inasistencias acumuladas — sin registro íntegro y fechado, la deserción es indefendible ante un recurso del aprendiz
- **Art. 5 num. 10:** derecho al **debido proceso** *"en los procesos administrativos y disciplinarios"* — el Capítulo V (régimen de faltas, Arts. 39-53) exige que llamados de atención, medidas formativas y sanciones tengan soporte documental verificable. Un proceso disciplinario basado en un Excel editable es jurídicamente frágil
- **Art. 5 num. 11:** derecho a *"ser notificado de las novedades académicas, administrativas o disciplinarias"* — requiere que la novedad exista como registro trazable
- **Art. 8 num. 4:** el aprendiz mantiene sus datos *"en el sistema de gestión académica administrativa"* **de la entidad** — el SGA es un sistema de la entidad; el Excel personal de un instructor no lo es

**b) El Manual 2019 exige lo que el SGA implementa:**

- **§8.4 (Registro y Seguimiento de Eventos):** los sistemas de información deben registrar eventos y permitir seguimiento — el SGA lo cumple con columnas de auditoría (`usr_insert`, `fec_insert`, `usr_update`, `fec_update`) y el trigger `fun_act_tabla` con usuario real (`app.usuario`)
- **§15.3.1:** los datos académicos de menores son sensibles → acceso *"solo con necesidad laboral legítima"* — el SGA lo implementa con permisos por menú (`tab_menu_usuarios`): el instructor ve **sus** fichas (menú `20601`), no todas
- **§8.7 / §14 (auditorías internas):** el módulo **SIEM** (`211`, entregable E11 de FASE 1) y la auditoría de sesiones (`20905`) son la implementación directa del ciclo de auditoría del MSPI

**c) Reportes SENA (menú `208`):** las cargas DF-49, DF-53, DF-14A, PE-04, DF-51 y juicios evaluativos procesan información institucional que ya existe en los aplicativos nacionales. El SGA la ingiere para gestión local **con trazabilidad de quién cargó qué y cuándo** — hoy ese procesamiento se hace en Excel sin ningún control.

### 3.3 Precisión estratégica obligatoria: SGA complementa a Sofía Plus, no lo reemplaza

Esta es la primera objeción que hará cualquier Dirección y debe responderse de frente:

> **Sofía Plus es y seguirá siendo el sistema nacional de gestión académica del SENA** (matrícula, juicios evaluativos oficiales, certificación). El SGA de SmartCSET opera en la capa que Sofía Plus **no cubre**: la operación diaria del centro — asistencia por sesión, retardos capturados en portería (integración con SGI), llamados de atención, comités, seguimiento local de fichas y el procesamiento auditado de los reportes que el propio SENA emite. Los datos oficiales fluyen **desde** los reportes institucionales (DF-49, PE-04, juicios) **hacia** el SGA, nunca al revés.

Esto además refuerza el argumento: la información que el SGA administra **ya es del SENA** — el módulo solo le da la custodia técnica (integridad, trazabilidad, acceso controlado) que el Manual 2019 exige y que el Excel no puede dar.

### 3.4 Integración SGI → SGA (por qué van juntos)

El valor de cumplimiento se multiplica al integrarse: el registro de ingreso en portería (SGI) alimenta automáticamente la asistencia y retardos del aprendiz (SGA, `fun_verify_retardo_aprendiz` invocada desde `fun_registrar_ingreso_manual`). Un solo hecho — el aprendiz cruza la portería — produce dos registros consistentes y auditados. Separar los sistemas (o dejar uno en manos de terceros/Excel) rompe esa cadena de integridad.

---

## 4. Justificación del SAA — Sistema de Atención al Aprendiz

### 4.1 Qué es y su estado

Portal de servicios al aprendiz: **biblioteca, gimnasio y bienestar** (menús `301`-`303`). Los tres módulos están **en construcción** — este apartado justifica su desarrollo, no una operación existente.

### 4.2 Anclaje normativo

- **Regl. Aprendiz 2024, Art. 5 num. 6 (derecho):** *"Disfrutar de los beneficios del **plan nacional integral de bienestar al aprendiz** de su Centro de Formación, orientado a promover su permanencia y certificación"* — el bienestar no es un servicio opcional: es un **derecho reglamentario** cuya gestión genera datos que deben tratarse con las mismas garantías
- **Regl. Aprendiz 2024, Art. 5 num. 1:** la inducción incluye conocer *"el plan nacional integral de bienestar al aprendiz"*
- **Manual 2019 §15.3.1:** los datos que estos servicios generan pueden incluir **datos de salud** (gimnasio: aptitud física; bienestar: atenciones psicosociales) — datos **sensibles** por definición legal (Ley 1581 Art. 5), con la protección más alta
- **Manual 2019 §7.1.1:** el control de acceso a espacios (biblioteca, gimnasio) es extensión natural del control de ingreso ya justificado para el SGI

### 4.3 El argumento preventivo (por qué justificarlo ahora)

A diferencia del SGI (problema vivo) y el SGA (proceso sin trazabilidad), el SAA es **cumplimiento por diseño**: construir estos servicios dentro de SmartCSET desde el día uno evita repetir el error que originó todo — que cada servicio (el gimnasio con su planilla, la biblioteca con su software aparte, bienestar con archivos sueltos) improvise su propio registro de datos personales fuera del SGSI. Cada sistema paralelo que nace fuera es un futuro hallazgo de auditoría; cada uno que nace dentro hereda automáticamente: servidor SENA (H1), auditoría (§8.4), acceso por menú (§15.3.1), amparo de la autorización existente (H10).

**Prioridad:** menor que SGA. Se desarrolla en fases posteriores, pero **dentro** de la plataforma.

---

## 5. Matriz de Cumplimiento por Sistema

| Requisito normativo | SGI | SGA | SAA (diseño) |
|---|---|---|---|
| Datos en servidor SENA Colombia (§15.7, H1) | ✅ | ✅ | ✅ heredado |
| Registro de ingresos/salidas (§7.1.1, H2) | ✅ | ✅ (retardos vía integración) | ✅ (acceso a espacios) |
| Sin terceros tratando datos (§11, H3) | ✅ elimina al proveedor | ✅ elimina Excel/papel sin custodia | ✅ evita sistemas paralelos |
| Acceso solo con necesidad legítima (§15.3.1, H4) | ✅ | ✅ permisos por menú/ficha | ✅ heredado |
| Datos sensibles protegidos (§15.3.2, H5) | ✅ fotos | ✅ académicos/disciplinarios | ✅ salud (máxima protección) |
| Menores bajo marco autorizado (§15.4, H6/H12) | ✅ | ✅ | ✅ |
| Deberes del responsable ejecutables (§15.9, H7) | ✅ | ✅ | ✅ |
| Auditoría/SIEM dentro del MSPI (§8.4, H9) | ✅ | ✅ SIEM es submenú del SGA | ✅ heredado |
| Amparado por autorización existente (Art. 11 Par. 5, H10) | ✅ | ✅ | ✅ |
| Debido proceso disciplinario (Regl. Cap. V) | — | ✅ **argumento central** | — |
| Bienestar como derecho (Regl. Art. 5.6) | — | — | ✅ **argumento central** |

---

## 6. Conclusión y Recomendación

1. **El marco legal de los docs. 01-05 cubre a los tres sistemas** — la autorización existente (H10), la soberanía (H1) y los deberes del responsable (H7) no distinguen módulos.
2. **SGA se justifica por debido proceso y trazabilidad académica:** el Reglamento del Aprendiz exige registros íntegros para asistencia, deserción y régimen disciplinario que hoy viven en Excel/papel. Presentarlo siempre como **complemento de Sofía Plus a nivel de centro**, nunca como reemplazo.
3. **SAA se justifica por diseño preventivo:** el bienestar es un derecho reglamentario (Art. 5.6) y sus datos (incluida salud) deben nacer dentro del SGSI, no en sistemas improvisados.
4. **Orden de prioridad recomendado:** SGI (operativo, presentación 29 de julio) → SGA (completar módulos en construcción) → SAA (fases posteriores).

---

**Documento preparado:** 2026-07-05
**Elaborado por:** Equipo de Desarrollo SmartCSET
**Estado:** Completo — SGA/SAA justificados sobre el marco probatorio del doc. 05
**Clasificación:** CONFIDENCIAL — USO INTERNO SENA
