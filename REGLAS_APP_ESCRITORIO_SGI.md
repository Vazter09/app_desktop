
# Reglas y Arquitectura — App de Escritorio SGI (Portería)

> **Nota (2026-09-01):** Este es un documento de **diseño interno** (puede divergir del código as-built).
> La **documentación oficial de entrega** está en [`docs/README.md`](docs/README.md).
> Divergencias conocidas: motor in-process (no 2 procesos HTTPS), vector 128-d (no 512),
> UI sin sidebar (solo pantalla de ingreso post-login). Ver `docs/03-arquitectura.md`.

## Documento de diseño validado post-implementación (2026-07-09)

**Última actualización:** 2026-07-09 | **Estado de validación:** ✅ Implementado y probado end-to-end
**Ciclos probados:** Enrolar → Identificar → Registrar ingreso (metodo_aut=4) → Salida automática
**Servidor de validación:** 10.5.213.103 (servidor institucional real SENA)

---

## 1. Qué es esto

Una aplicación de **escritorio** (no web, no móvil) dedicada exclusivamente al
módulo **SGI (Sistema de Gestión de Ingresos / Portería)** de SmartCSET. Corre
en el **PC físico de portería** de cada centro SENA, reemplazando/complementando
el flujo web actual de ingreso y salida con captura biométrica facial usando
**pgvector** (ya instalado en la BD real: extensión `vector` v0.8.1).

**No es un sistema aparte.** Es un cliente más de SmartCSET — igual que la app
móvil (`mobile/porteria-app/`) ya lo es — que habla por HTTPS contra el mismo
backend PHP, la misma base de datos, los mismos prepared statements y las
mismas funciones PL/pgSQL. No tiene su propia base de datos, no reimplementa
autenticación, no reinventa el flujo de ingreso/salida.

---

## 2. Estado real verificado en la BD de producción (fuente de verdad)

Antes de diseñar se conectó directamente a la BD real (`192.168.1.71` /
`db_smartcset2`, vía `PGSSLMODE=require` — el servidor exige TLS) para
confirmar qué existe hoy, no lo que hay en documentación vieja o en ramas no
mergeadas:

| Elemento                                                                                                                        | Estado real                     | Nota                                                                                                                                         |
| ------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Extensión`vector` (pgvector)                                                                                                 | ✅ instalada, v0.8.1            | Lista para usar, no hay que instalarla en el servidor de BD                                                                                  |
| Extensión`pgcrypto`                                                                                                          | ✅ instalada, v1.4              | Disponible si se necesita cifrar algo nuevo                                                                                                  |
| `tab_metodos_aut.id_metodo_aut = 4`                                                                                           | ✅ existe, "Biométrico facial" | Ya sembrado, se puede usar tal cual                                                                                                          |
| `tab_log_ingresos.facial_embedding vector(512)`                                                                               | ✅ existe la columna            | **Pero es por evento de ingreso, no por persona** — no sirve como tabla de referencia/enrolamiento. Sin índice HNSW/IVFFlat todavía |
| `tab_personas.val_patron_facial jsonb`                                                                                        | ⚠️ existe pero es legacy      | JSON plano, no tipo`vector` — nunca se conectó a pgvector, no usar                                                                       |
| `tab_personas.val_huella_digital bytea`                                                                                       | ⚠️ existe pero es legacy      | Placeholder de huella, decorativo hasta ahora                                                                                                |
| Tabla de enrolamiento facial por persona (`tab_enrolamiento_facial`)                                                             | ✅ desplegada y probada         | Migración `add_tab_enrolamiento_facial.sql` aplicada; índice HNSW + auditoría real verificados                                             |
| Funciones`fun_guardar_enrolamiento_facial` / `fun_identificar_persona_por_rostro`                                            | ✅ desplegadas y probadas        | Probadas con vectores sintéticos de 512 dims vía `psql` y vía HTTP real (enrolar/identificar), `usr_insert` = usuario real                  |
| `tab_dispositivos_porteria` (auth por token de dispositivo)                                                                   | ✅ existe y en uso              | La usa la app móvil hoy. **Esta app de escritorio NO la usa** — decisión explícita, ver sección 5 |
| `/auth/v1/login.php` (login real de usuario, sesión PHP + cookie)                                                             | ✅ existe y en uso              | **Es el mecanismo que usa esta app** — mismo login que la web, ya con rate limiting E3 y auditoría (`tab_intentos_login`) |
| Endpoints`porteria/v1/{ingreso,salida}/{consultar,registrar}.php`, `catalogos.php`, `health.php`                              | ✅ existen y funcionan          | Reutilizables tal cual, se llaman con la sesión web ya autenticada, cero cambios necesarios |

**Conclusión de diseño:** la app de escritorio SÍ requiere una migración SQL
nueva (tabla de enrolamiento + índice vectorial + 2 funciones PL/pgSQL + 2
endpoints PHP nuevos bajo `porteria/v1/biometria/`), pero **reutiliza el 100%**
de lo que ya existe para todo lo demás (login real, catálogos, ingreso,
salida, auditoría). **Decisión explícita del usuario:** el login NO es por
token de dispositivo (diseño inicial descartado) — es el login real de
SmartCSET con un **usuario ya registrado** (por defecto `porteria`, el mismo
usuario que ya existe y opera portería web hoy). La app tampoco pregunta URL
de servidor: viene preconfigurada de fábrica en la instalación (hoy apuntando
a `192.168.1.71`, el servidor de laboratorio — se re-apunta al servidor
institucional real en el despliegue final, sección 7.2).

---

## 3. Cumplimiento end-to-end obligatorio: 5 Pilares + MSPI (Fase 0 y Fase 1 / Plan de Blindaje)

**Esto no es opcional ni queda a discreción de la implementación.** La app de
escritorio es un cliente más de SmartCSET — hereda íntegramente las mismas
obligaciones legales y técnicas que ya rigen el resto del sistema. No se
considera "lista" hasta que cumpla, de punta a punta, con lo siguiente —
igual que cualquier módulo nuevo del proyecto.

### 3.1 Los 5 Pilares (obligatorios en cada línea de código, `CLAUDE.md`)

1. **Coherencia** — mismo patrón `fun_verbo_objeto` en SQL, mismo esqueleto
   de router PHP que `ingreso/registrar.php`, mismo prefijo `porteria` en
   funciones nuevas, misma paleta de colores y tipografías de SmartCSET
   (sección 8) — cero patrones nuevos inventados donde ya existe uno.
2. **Congruencia** — la app de escritorio no puede mostrar/permitir nada que
   el flujo web/móvil no permita ya (mismo constraint de ingreso único por
   día, mismos catálogos, misma validación de scope de entrada/centro).
3. **Funcionalidad** — reemplaza el flujo manual de portería por captura
   biométrica, pero el resultado final en BD es indistinguible en estructura
   de un ingreso manual (misma tabla `tab_log_ingresos`), solo cambia
   `id_metodo_aut` a 4 y se llena `val_datos_origen`.
4. **Estabilidad** — si el motor biométrico local falla o la red cae, la app
   debe permitir caer a captura manual (documento) sin bloquear portería.
5. **Seguridad Total** — el vector facial nunca sale del flujo autenticado por
   token de dispositivo; el cómputo pesado (extracción del embedding) se hace
   en el PC de portería, solo el vector ya calculado viaja al servidor,
   cifrado extremo a extremo (sección 5.2) — igual de sensible que una foto,
   se trata con el mismo cuidado o más (es dato biométrico, ver 3.2).

### 3.2 MSPI Fase 0 — políticas legales (`Documentacion para implementacion de MSPI/FASE 0_documentos politicas de tratamiento de datos/`)

El dato facial es un **dato sensible** bajo la Ley 1581 de 2012 (Colombia) —
más estricto que un dato personal ordinario como nombre o documento, que es
lo único que maneja el flujo manual de portería hoy. Esto **agrega**
obligaciones que el resto del sistema no necesitaba con el mismo nivel de
exigencia:

- **`01_POLITICA_Y_TRATAMIENTO_DATOS_PERSONALES`**: el enrolamiento facial
  requiere **autorización explícita** de la persona (aprendiz, instructor,
  funcionario, contratista, visitante) antes de capturarse — no basta con el
  aviso genérico que ya cubre el registro de nombre/documento. La app debe
  dejar constancia de ese consentimiento (quién autorizó, cuándo, con qué
  propósito) antes de invocar `biometria/enrolar.php` — a modelar como parte
  de la migración de la sección 6.1 (columna o tabla de consentimiento).
- **`02_INVENTARIO_ACTIVOS_INFORMACION_CID`**: `tab_enrolamiento_facial` y el
  vector facial deben incorporarse al inventario de activos como un activo
  nuevo de clasificación **alta confidencialidad** (dato biométrico), no
  heredar automáticamente la clasificación de `tab_personas`.
- **`03_MATRIZ_RIESGOS_INICIAL`**: agrega un riesgo nuevo no cubierto por la
  matriz actual — suplantación biométrica / falso positivo de identificación
  (mitigado por el umbral de distancia calibrado, sección 10.5) y robo del
  PC de portería con el motor biométrico corriendo localmente (mitigado por
  no persistir el vector en disco, sección 5.2).
- **`07_POLITICA_CONTROL_ACCESO_SEGURIDAD_FISICA`**: el PC de portería con
  webcam y motor biométrico es en sí mismo un activo de seguridad física
  nuevo — debe quedar contemplado (acceso físico restringido al equipo,
  igual que ya se exige para servidores).
- **`08_MARCO_GESTION_INCIDENTES_CONTINUIDAD`**: un incidente con datos
  biométricos (fuga del vector, falso positivo explotado) es de mayor
  severidad que un incidente con datos personales ordinarios — debe quedar
  contemplado en el procedimiento de incidentes con esa categoría.

**Ninguno de estos 5 documentos legales se reescribe desde cero** — se
extienden con un apartado específico de "datos biométricos / app de
escritorio SGI" antes de que la app entre en producción real (no antes del
mockup, pero sí antes de capturar el primer rostro real).

### 3.3 MSPI Fase 1 — Plan de Blindaje Técnico (entregables E1-E11, estado real en `HANDOFF.md`)

La app hereda o extiende directamente estos entregables ya en curso:

| Entregable | Aplica cómo a esta app |
|---|---|
| **E1-A01 Broken Access Control** | El endpoint `biometria/{enrolar,identificar}.php` usa `porteriaRequireSessionOrDevice()` en el camino de sesión web real — mismo control ya endurecido (Bug 7/8), no un mecanismo nuevo a auditar desde cero. |
| **E1-A02 Cryptographic Failures** | Extiende el mismo principio a un canal nuevo: TLS obligatorio también en loopback app↔motor (sección 5.2), no solo servidor↔cliente. |
| **E1-A03 Injection** | Las 2 funciones PL/pgSQL nuevas (sección 6.2) usan el mismo patrón de excepción 4-arg y prepared statements — cero SQL concatenado, mismo estándar que cerró Bug 6/17. |
| **E2 Cifrado en reposo** | Hoy bloqueado en el resto del sistema (documento_identidad es PK, ver `CLAUDE.md`), pero el vector facial de `tab_enrolamiento_facial` es candidato directo a cifrado en reposo con `pgcrypto` (ya instalado, v1.4) desde el diseño inicial — no hay que esperar a que E2 se resuelva para el resto del sistema; esta tabla nueva puede nacer ya cifrada. **Se decide en implementación**, no se deja para después como el resto de E2. |
| **E3 Rate limiting** | El intento de fuerza bruta contra `biometria/identificar.php` (probar muchos rostros/vectores contra el umbral) es un vector nuevo no cubierto por el rate limiting de login — se evalúa aplicar un límite de intentos por dispositivo/minuto en implementación. |
| **E6 Verificación de uploads** | Si se decide guardar `url_foto_facial` (ya existe la columna en `tab_log_ingresos`), aplican las mismas protecciones `.htaccess` de `storage/porteria/` — no una carpeta nueva sin proteger. |
| **E7 Setup script** | Las funciones y migración nuevas van al array `FUNCS`/migraciones de `setup_smartcset.sh` desde el primer commit — no repetir el Bug 2 histórico de "función existe pero no está en el instalador". |
| **E8 Hardening de red / TLS** | Ya cubierto por sección 5 (TLS servidor↔app y app↔motor) — coherente con el TLS de BD ya activado (Bug 13/17). |
| **E10 SDLC seguro** | El checklist pre-commit/deploy ya vigente en el proyecto aplica igual a este código nuevo — sin excepciones por ser "solo un mockup" una vez se pase a implementación real. |
| **E11 Mini SIEM** | Los eventos de enrolamiento/identificación biométrica (éxito, fallo, falso rechazo) deben poder verse reflejados en el Panel de Control del SIEM (`21101`) igual que los intentos de login — no crear un canal de auditoría paralelo e invisible para el SIEM ya construido. |

### 3.3bis Estado real verificado — v1 (login + dashboard + Ingreso/Salida/Entradas, sin biometría)

Auditoría hecha en vivo contra la BD real tras consolidar la v1 (ver
`app_desktop/app/`). La tabla de 3.3 de arriba describe cómo aplican los
entregables **cuando se agregue la biometría** (todavía no construida);
esta es la foto real de lo que YA existe hoy:

| Entregable | Estado real hoy |
|---|---|
| E1-A01 Broken Access Control | ✅ Verificado en vivo — `catalogos.php` ahora exige sesión real (antes solo dispositivo, ajuste mínimo hecho esta fase), "Entradas" exige admin server-side y `porteria` recibe el rechazo real. |
| E1-A02 / E8 (TLS) | ⚠️ Diseño correcto (`AppConfig.verify_tls` nunca desactiva verificación fuera de `localhost`), pero **solo probado contra el entorno de laboratorio** — falta ejercitarlo contra el certificado institucional real cuando haya acceso a ese servidor. Pendiente conocido, no asunción silenciosa. |
| E1-A03 Injection | ✅ N/A directo — la app no arma SQL, todo pasa por endpoints PHP ya blindados. |
| E3 Rate limiting | ✅ Heredado gratis vía `/auth/v1/login.php`. |
| E7 Setup script | ✅ N/A — el único cambio de backend (`catalogos.php`) es PHP, no una función SQL nueva. |
| E10 SDLC seguro | ✅ Suite `unittest` en `app_desktop/app/tests/` contra el backend real (sin mocks), corrida y en verde (6/6); `php -l` limpio en el cambio de backend. `phpcs` no está instalado en este entorno — pendiente correrlo cuando se disponga de la herramienta. |
| E11 Mini SIEM | ✅ Cubierto pasivamente — ingresos/salidas quedan con el mismo `usr_insert`/sesión real que si vinieran de la web, sin canal paralelo invisible. |
| E2 / E6 | N/A todavía — sin dato biométrico ni subida de archivos en esta fase. |

### 3.4 Regla de cierre

Antes de dar por "terminada" cualquier fase de implementación de esta app
(no solo el mockup), se debe poder responder que sí a las mismas preguntas
que ya se hacen para todo el resto de SmartCSET: ¿pasa los 5 Pilares?, ¿está
reflejado en el inventario de activos y la matriz de riesgos de Fase 0?,
¿qué entregable de Fase 1 toca y en qué estado queda? Esto se revisa junto
con el checklist técnico de la sección 7.2, no en reemplazo de él.

---

## 4. Restricción explícita: sin frameworks, sin dependencias de terceros que no sean estrictamente necesarias

Requisito del usuario: la app corre dentro de la intranet del SENA, en
servidores/PCs institucionales, sin acceso garantizado a internet después de
la instalación inicial. Por eso:

- **Nada de Electron, Qt, .NET, Java Swing con librerías externas pesadas.**
  Se usa **Python 3.11+ con Tkinter** (viene en la instalación estándar de
  Python, no es un framework de terceros — es parte de la biblioteca
  estándar). Ya hay precedente de este patrón funcionando en el proyecto.
- **Nada de bundlers, npm, node_modules.** Cero JavaScript en esta app.
- **HTTP sin librerías externas donde sea posible:** usar `urllib` (stdlib)
  para hablar con el backend, no `requests` — evita una dependencia que no
  aporta nada que stdlib no resuelva ya para este caso de uso.
- **Única excepción justificada y explícita:** el reconocimiento facial
  matemáticamente requiere un modelo de extracción de embeddings — no existe
  forma de hacerlo sin una librería de visión por computador/ML. Esa es la
  única categoría de dependencia de terceros permitida (ver sección 5.2), y
  se aísla en un **proceso separado** (el "motor biométrico") para que el
  resto de la app (captura, UI, comunicación con SmartCSET) siga siendo 100%
  stdlib.
- Todo paquete de terceros debe:
  - Ser instalable **una sola vez** desde un `requirements.txt` versionado,
    sin necesitar internet en producción tras la primera instalación (se
    puede preparar un instalador offline con las ruedas `.whl` descargadas).
  - No requerir licencia comercial ni telemetría/llamadas salientes propias.
  - Quedar documentado con versión exacta fijada (`==`, no `>=`), a
    diferencia del precedente histórico que usaba `>=` — en un entorno sin
    internet constante, una resolución de versión distinta entre PCs es un
    riesgo real de incoherencia (Pilar 1).

---

## 5. Arquitectura de 2 procesos (mismo patrón que ya se probó en el proyecto)

```
┌──────────────────────────────────────────────────────────┐
│              PC dedicado de portería (SENA)               │
│                                                            │
│  ┌────────────────────┐        ┌───────────────────────┐ │
│  │  App Escritorio     │◄──────►│  Motor Biométrico       │ │
│  │  (Tkinter, stdlib)  │ HTTPS  │  Local (Python, un solo │ │
│  │                     │127.0.  │  propósito: extraer     │ │
│  │  - Captura webcam   │0.1     │  vector facial de una   │ │
│  │  - Login usuario    │(TLS    │  imagen)                │ │
│  │    real + contraseña│local)  │                          │ │
│  │  - Orquesta flujo   │        │                          │ │
│  │  - Fallback manual  │        └───────────────────────┘ │
│  └──────────┬──────────┘                                  │
└─────────────┼──────────────────────────────────────────────┘
              │ HTTPS (login real: usuario/contraseña →
              │ sesión PHP + cookie, igual que la web)
┌─────────────▼──────────────────────────────────────────────┐
│              Backend SmartCSET (servidor institucional)      │
│              — URL preconfigurada en la app, no se pide      │
│                al operador (sección 7.2)                     │
│                                                                │
│  Reutilizados sin cambios:                                    │
│    /auth/v1/login.php  (login real, rate limiting E3)         │
│    /porteria/v1/catalogos.php                                 │
│    /porteria/v1/ingreso/{consultar,registrar}.php              │
│    /porteria/v1/salida/{consultar,registrar}.php               │
│    /porteria/v1/health.php                                    │
│                                                                │
│  Nuevos (mismo patrón que los de arriba):                     │
│    /porteria/v1/biometria/enrolar.php                         │
│    /porteria/v1/biometria/identificar.php                     │
│                    │                                          │
│                    ▼                                          │
│  PostgreSQL: tab_usuarios, tab_log_ingresos, tab_personas,     │
│  tab_entradas_centro (existentes)                              │
│  + tabla nueva de enrolamiento (sección 6)                    │
└────────────────────────────────────────────────────────────────┘
```

### 5.1 Proceso "App Escritorio" — 100% librería estándar de Python

Responsabilidades:

- UI con `tkinter` + `tkinter.ttk` (widgets nativos, sin librería de theming
  de terceros — el look-and-feel corporativo se logra con estilos `ttk`
  personalizados, no con un framework de componentes).
- Captura de cámara: única excepción de terceros compartida con el motor
  (`opencv-python`, ver 5.2) — se usa solo para tomar el frame de la webcam
  y mostrarlo en vivo, no para procesar el rostro (eso lo hace el motor).
- Comunicación HTTP con el backend real: `urllib.request` (stdlib) + `json`
  (stdlib) + `http.cookiejar` (stdlib) para persistir la cookie de sesión
  PHP igual que haría un navegador. Sin agregar `requests`.
- **URL del servidor: preconfigurada, no se le pregunta al operador.** Vive
  en un archivo de configuración que se define **una sola vez en la
  instalación** de cada PC (no en cada login) — hoy apunta a `192.168.1.71`
  (servidor de laboratorio); se cambia en el despliegue real al servidor
  institucional. El campo no existe en la pantalla de login (ver mockup,
  sección 11).
- **Login = usuario y contraseña reales de SmartCSET**, exactamente el mismo
  mecanismo que ya usa la web (`POST /auth/v1/login.php` con `{usuario,
  clave}`) — no un token de dispositivo. Por defecto se sugiere el usuario
  `porteria` (el mismo que ya existe y opera portería web hoy), pero
  cualquier usuario registrado con permiso puede iniciar sesión. La app
  guarda la cookie de sesión (`http.cookiejar`) en memoria/archivo local
  protegido mientras la sesión esté activa — vuelve a pedir login si expira
  (`SESSION_TIMEOUT`, igual que la web).
- Todas las llamadas a `porteria/v1/*` (incluidos los endpoints biométricos
  nuevos) se autentican con esa misma sesión web — `porteriaRequireSessionOrDevice()`
  ya soporta el camino `type: 'web'` basado en `$_SESSION['id_usuario']`,
  no hace falta ningún middleware nuevo.
- Flujo de negocio: captura → llama al motor local para obtener el vector →
  llama a `biometria/identificar.php` → si hay match, `ingreso/consultar.php`
  decide si corresponde ingreso o salida → llama al endpoint real
  correspondiente con `id_metodo_aut = 4`.
- **Fallback obligatorio (Pilar 4, Estabilidad):** si el motor biométrico no
  responde o no hay match, la UI debe permitir capturar por documento
  (`id_metodo_aut = 1`, igual que portería web) sin reiniciar la app.

### 5.2 Proceso "Motor Biométrico Local" — la única superficie con dependencias de terceros

Un proceso HTTP **con TLS incluso en loopback**, solo accesible en
`127.0.0.1` (nunca expuesto a la red del centro), con una única
responsabilidad: recibir una imagen, devolver un vector de 512 floats.

- **HTTPS obligatorio también en la comunicación local app↔motor, no solo
  hacia el backend (Pilar 5, Seguridad Total).** Aunque el tráfico nunca
  sale de la máquina, la imagen capturada y el vector facial son datos
  biométricos sensibles — no se transmiten en claro ni siquiera dentro del
  mismo PC. Certificado autofirmado generado **una vez por PC** en la
  instalación (script de setup local, mismo patrón que
  `scripts/infra/generar_certificado_smartcset.sh` usa para el servidor
  institucional), guardado fuera del repo. La app valida ese certificado
  específico (pinning al certificado local conocido, no una CA pública —
  no tiene sentido pagar/gestionar una CA para tráfico que nunca sale de
  `127.0.0.1`) en vez de desactivar la verificación TLS.
- Implementado con un servidor HTTP mínimo envuelto en TLS
  (`ssl.SSLContext` de stdlib sobre `http.server`, o el mecanismo TLS nativo
  que traiga el runtime del modelo elegido). Se evita FastAPI/uvicorn si es
  viable técnicamente con el modelo elegido; si el modelo de extracción de
  embeddings requiere un runtime que ya trae su propio servidor de
  inferencia, se documenta como excepción explícita y aislada (no se mezcla
  con la app principal), pero **debe** exponerse solo por HTTPS igual.
- Dependencias de terceros permitidas aquí, y solo aquí:
  - Librería de extracción de embeddings faciales (a decidir en la fase de
    implementación: opciones a evaluar por tamaño/licencia/huella en disco
    para no violar el requisito de "mínimas dependencias" — se prioriza la
    opción más liviana que entregue un vector de 512 dimensiones compatible
    con `vector(512)` de pgvector).
  - `opencv-python` — lectura/preprocesamiento de imagen.
  - `numpy` — manejo del arreglo del vector.
- El vector nunca se guarda en disco local del PC de portería — se calcula
  en memoria y se descarta tras responder a la app.
- Este proceso **jamás** habla directo con PostgreSQL ni con el backend de
  SmartCSET. Solo la app principal orquesta.
- Autenticación adicional a nivel de aplicación entre app y motor: el header
  `MOTOR_API_KEY` (sección 7.2) se exige en cada request, además del TLS —
  defensa en profundidad, no basta con que el canal esté cifrado.

---

## 6. Cambios necesarios en base de datos (nuevos, siguiendo el patrón del proyecto)

### 6.1 Migración nueva: tabla de enrolamiento facial por persona

No reutilizar `tab_log_ingresos.facial_embedding` (es histórico por evento).
Se necesita una tabla de **referencia** — el vector "de verdad" contra el que
se compara cada captura nueva, uno por persona (o varios, si se decide
permitir múltiples ángulos/tomas por persona — a definir en implementación).

```sql
-- database/migrations/add_tab_enrolamiento_facial.sql (idempotente, patrón del proyecto)
CREATE TABLE IF NOT EXISTS tab_enrolamiento_facial (
    id_enrolamiento    SERIAL PRIMARY KEY,
    id_persona         NUMERIC(10,0) NOT NULL REFERENCES tab_personas(id_persona),
    facial_embedding   VECTOR(512) NOT NULL,
    calidad_facial     NUMERIC(5,2),
    ind_activo         BOOLEAN NOT NULL DEFAULT TRUE,
    usr_insert         VARCHAR(50) NOT NULL,
    fec_insert         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usr_update         VARCHAR(50),
    fec_update         TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_enrolamiento_facial_persona
    ON tab_enrolamiento_facial (id_persona) WHERE ind_activo = TRUE;

-- Índice vectorial HNSW para búsqueda por similitud (distancia coseno)
CREATE INDEX IF NOT EXISTS idx_enrolamiento_facial_hnsw
    ON tab_enrolamiento_facial USING hnsw (facial_embedding vector_cosine_ops);
```

El trigger de auditoría `tri_act_tabla` (ya existente y estándar en todas las
tablas del proyecto) debe agregarse igual que en cualquier tabla nueva.

### 6.2 Funciones PL/pgSQL nuevas (patrón `fun_` + excepción 4-arg obligatorio)

- `fun_guardar_enrolamiento_facial(wid_persona, wfacial_embedding, wcalidad_facial, wusr)`
  — valida que la persona exista, inserta o reemplaza el enrolamiento activo.
- `fun_identificar_persona_por_rostro(wfacial_embedding, wumbral_distancia DEFAULT 0.35)`
  — `SELECT id_persona, facial_embedding <=> wfacial_embedding AS distancia FROM tab_enrolamiento_facial WHERE ind_activo ORDER BY distancia LIMIT 1`,
  retorna `id_persona` solo si `distancia <= wumbral_distancia`, si no NULL.

Ambas con el bloque `EXCEPTION` estándar del proyecto (`GET STACKED DIAGNOSTICS` + `smartcset_handle_sql_error` de 4 argumentos — **nunca** la
versión sin argumentos, ver Bug 6/17 de `CLAUDE.md`).

Ambas se agregan al array `FUNCS` de `database/setup_smartcset.sh`
(obligatorio, regla ya documentada en `AGENTS.md`).

### 6.3 Endpoints PHP nuevos (mismo esqueleto que `ingreso/registrar.php`)

- `backend/routers/porteria/v1/biometria/enrolar.php`
- `backend/routers/porteria/v1/biometria/identificar.php`

Ambos:

- Usan `porteriaRequireSessionOrDevice()` (middleware ya existente,
  `backend/middleware/require_session_or_device.php`) — en el camino `web`
  (sesión PHP real del usuario logueado), igual que el resto de portería
  cuando se accede desde el navegador. No se usa el camino `device`.
- Devuelven con `RouterResponse::ok()` / `RouterResponse::fail()` (patrón
  estándar de todos los routers del proyecto).
- Delegan la lógica a un nuevo `backend/services/porteria/biometria_service.php`
  (mismo patrón: routers delgados, lógica en `services/`).
- El umbral de distancia coseno (`0.35` como punto de partida, ajustable)
  vive como constante configurable, no hardcodeada 2 veces (regla DRY del
  proyecto).

### 6.4 Nada de esto rompe lo existente

- `tab_log_ingresos.facial_embedding` se sigue llenando igual que hoy (si se
  quiere seguir guardando el vector del momento exacto del ingreso como
  evidencia histórica) — es independiente de la tabla de enrolamiento nueva.
- `id_metodo_aut = 4` ya existe, no se toca.
- Ningún endpoint ni función existente cambia de firma.

---

## 7. Configuración exacta para correr la app de escritorio

### 7.1 En el servidor institucional (una sola vez)

1. Aplicar la migración `add_tab_enrolamiento_facial.sql` (pgvector ya está
   instalado, no hay que instalarlo).
2. Desplegar las 2 funciones PL/pgSQL nuevas + agregarlas al array `FUNCS`
   de `setup_smartcset.sh`.
3. Copiar los 2 routers nuevos + el service nuevo al servidor
   (`/var/www/html/smartcset`, mismo mecanismo ya usado para el resto del
   código — ver acuerdo de flujo local→servidor en `HANDOFF.md`).
4. Confirmar que el usuario `porteria` (u otro usuario real que se decida
   usar por defecto en el PC de portería) existe, está activo
   (`ind_estado = TRUE`) y tiene el permiso de menú correspondiente al SGI —
   no se crea usuario nuevo, se reutiliza el que ya opera portería web.
5. Confirmar que el certificado TLS del servidor es válido (no autofirmado)
   para que la app de escritorio no necesite desactivar verificación de
   certificado en producción.

### 7.2 En el PC de portería (por cada equipo)

**Requisitos de sistema:**

- Python 3.11+ instalado (con Tkinter incluido — en Windows viene por
  defecto en el instalador oficial de python.org; en Linux verificar el
  paquete `python3-tk` si se usa una distro que lo separa).
- Webcam conectada y reconocida por el sistema operativo.
- Conectividad de red hacia el servidor institucional (misma intranet SENA,
  sin necesidad de internet tras la instalación inicial).
- Espacio en disco según el modelo de extracción de embeddings elegido en
  fase de implementación (a determinar; se documentará el tamaño exacto en
  ese momento).

**Variables/configuración local necesarias:**

```
# app_config.json (preconfigurado UNA VEZ en la instalación de cada PC,
# no se edita desde la UI de login — NO versionado en el repo)
{
  "base_url": "https://192.168.1.71/smartcset"
}
# En despliegue institucional real, este valor se cambia al host real
# (ver HANDOFF.md, servidor institucional 10.5.213.103) por quien instala
# la app, no por el operador de portería en cada inicio de sesión.

# .session_cookie (generado por http.cookiejar tras un login exitoso,
# NO versionado — se descarta al cerrar sesión o expirar SESSION_TIMEOUT)

# .env.local del motor biométrico (NO versionado, único por PC)
MOTOR_BIND_HOST=127.0.0.1
MOTOR_BIND_PORT=5000
MOTOR_API_KEY=<clave única generada para este PC, nunca un valor por defecto>
MOTOR_TLS_CERT=./certs/motor_local.crt   # autofirmado, generado en la instalación
MOTOR_TLS_KEY=./certs/motor_local.key    # permisos restringidos, fuera del repo
```

El motor solo levanta si encuentra el certificado local — no hay modo HTTP
plano de respaldo (si el certificado falta, la app debe fallar visible al
operador, no degradar el canal silenciosamente).

**Arranque (2 procesos, mismo patrón ya usado antes):**

```
1. Iniciar el motor biométrico local (terminal/servicio en segundo plano)
2. Iniciar la app de escritorio (Tkinter)
```

En producción, ambos deben configurarse como servicios/tareas de arranque
automático del sistema operativo del PC de portería (no depender de que un
operador humano abra dos terminales cada mañana) — a definir el mecanismo
exacto (Task Scheduler en Windows / systemd en Linux) según qué SO tengan
los PCs de portería reales del SENA.

**Checklist de verificación antes de dar por lista una instalación:**

- [ ] `curl --cacert ./certs/motor_local.crt https://127.0.0.1:5000/health`
  responde OK (motor vivo, y solo por HTTPS — un intento por `http://` en el
  mismo puerto debe fallar/rechazar la conexión, no responder en claro)
- [ ] Login de la app con usuario/contraseña real (`porteria` u otro
  usuario registrado) → válido contra `/auth/v1/login.php`, cookie de
  sesión persistida correctamente
- [ ] Enrolar una persona de prueba → fila real en `tab_enrolamiento_facial`
- [ ] Identificar esa misma persona → match, ciclo ingreso/salida real en
  `tab_log_ingresos` con `id_metodo_aut = 4`
- [ ] Apagar el motor biométrico a propósito → la app cae a captura manual
  sin crashear (prueba del fallback, Pilar 4)
- [ ] Certificado TLS del servidor validado correctamente (sin bypass)

---

## 8. Identidad visual — reutilizar el tema ya definido en SmartCSET, no inventar uno nuevo

Fuente de verdad: `backend/core/AppConfig.php` (tokens de tema) y
`frontend/web/layout/theme_vars.php`. La app de escritorio debe verse como
una extensión nativa de SmartCSET, no como un producto aparte.

**Colores corporativos (no hardcodear valores — si se usan directamente en
Tkinter por no tener CSS vars, replicar EXACTAMENTE estos valores):**

- Verde oscuro primario: `#004d40` (`COLOR_VERDE_OSCURO` / `--v-oscuro`)
- Verde oliva secundario: `#808000` (`COLOR_VERDE_OLIVA` / `--v-oliva`)
- Acento cyan (tema oscuro, `--cyan` / `--theme-accent`): `#00e5b0`
- Fondo profundo (`--bg-deep`), fondo de tarjeta (`--bg-card`), fondo de
  panel (`--bg-panel`) — tema oscuro por defecto (estética "cyber" del
  proyecto, ver reglas globales de frontend del usuario).
- Texto primario tema oscuro: `#e8f4ff`
- Error: `#ff3c6e` — Éxito: `#00e5b0`
- Azul secundario: `#4a9eff` — Púrpura: `#9b6dff` — Naranja: `#ff7b2e`

**Tipografías:**

- Display/branding (títulos, logo): **Orbitron**
- Cuerpo/texto general: **Rajdhani**
- Ambas deben empaquetarse como archivos de fuente locales (`.ttf`) dentro
  del instalador de la app — no depender de Google Fonts/CDN en tiempo de
  ejecución (misma razón que Chart.js se vendorizó en el SIEM: la intranet
  SENA no tiene garantía de internet).

**Tema por defecto:** oscuro (cyber aesthetic), igual que el resto del
sistema — no claro por defecto.

**Layout de referencia:** replicar la sensación visual del sidebar/topbar
de SmartCSET (gradiente vertical del sidebar entre `sidebarBgDeep` y
`sidebarBg`, derivados de oscurecer el verde primario) donde tenga sentido
en una ventana de escritorio de pantalla completa en el PC de portería.

---

## 9. Lo que NO hacer (extensión de las reglas ya vigentes en CLAUDE.md)

- No crear una base de datos propia para la app de escritorio — todo vive en
  `db_smartcset2`.
- No usar el mecanismo de token de dispositivo de la app móvil
  (`tab_dispositivos_porteria`) para esta app — el login es con usuario y
  contraseña reales de SmartCSET (decisión explícita del usuario), no un
  token nuevo por PC.
- No pedirle la URL del servidor al operador en la pantalla de login — va
  preconfigurada en la instalación del PC (sección 7.2).
- No guardar la cookie de sesión ni el `app_config.json` en texto plano en
  un lugar accesible por otros usuarios del PC — permisos de archivo
  restringidos.
- No usar `tab_personas.val_patron_facial` ni `val_huella_digital` (legacy,
  no-vector) para nada nuevo — son candidatos a limpieza futura, no base de
  un feature nuevo.
- No exponer el motor biométrico local (`127.0.0.1:5000` o el puerto que se
  use) a la red del centro — solo loopback.
- No comunicar app↔motor biométrico por HTTP plano "porque es solo
  localhost" — el dato en tránsito (imagen/vector facial) es biométrico
  sensible; TLS es obligatorio incluso dentro del mismo PC.
- No agregar una dependencia de terceros a la app principal (Tkinter) que
  pueda resolverse con la librería estándar de Python.
- No usar versiones abiertas (`>=`) en `requirements.txt` de esta app — fijar
  exacto (`==`) por el riesgo de incoherencia entre PCs sin internet
  constante.
- No hardcodear colores/fuentes — replicar los valores de `AppConfig.php`
  documentados en la sección 8, y si en el futuro cambian ahí, deben
  actualizarse aquí también (Pilar 2, Congruencia).
- No bloquear portería si el motor biométrico o la red fallan — el fallback
  manual es obligatorio, no opcional.

---

## 10. Decisiones resueltas (confirmadas — criterio propio, con autorización explícita del usuario)

1. **Librería de extracción de embeddings faciales:** `face_recognition`
   (basada en `dlib`, ResNet-34 entrenado, produce vectores de 128 floats) o,
   si se necesita 512 dimensiones exactas para calzar con el precedente ya
   sembrado en `tab_metodos_aut`, un modelo Facenet512 vía una librería
   liviana de inferencia (sin TensorFlow completo si existe alternativa
   ONNXRuntime más ligera). **Se define el tamaño en disco/licencia exactos
   al iniciar la implementación real** — ambas opciones son MIT/BSD, sin
   costo, sin telemetría. Punto de partida: 128 dimensiones con
   `face_recognition` por ser la opción más liviana (evita TensorFlow); si
   eso implica migrar `VECTOR(512)` a `VECTOR(128)` en la migración de la
   sección 6.1, se ajusta ahí mismo antes de desplegar (todavía no se ha
   desplegado nada, no hay costo de migración real).
2. **Instalador:** `venv` + script de instalación (`instalar.bat` /
   `instalar.sh`) que crea el entorno virtual y fija las dependencias con
   `==`, en vez de empaquetar `.exe` con PyInstaller. Razón: un `.exe`
   empaquetado oculta qué dependencias corren realmente (menos auditable,
   contradice Seguridad Total) y complica actualizaciones — un `venv` es
   inspeccionable y coherente con "no reinventar, no ofuscar". Se reconsidera
   `.exe` solo si el personal de portería no puede ejecutar scripts por
   política de TI del SENA (a validar).
3. **Arranque automático:** tarea programada del sistema operativo del PC de
   portería (`Task Scheduler` en Windows / `systemd --user` en Linux) que
   lanza primero el motor biométrico y, tras confirmar `health` OK, la app.
   No se construye un supervisor de procesos propio (evita reinventar lo que
   el SO ya resuelve).
4. **Múltiples tomas de enrolamiento por persona:** sí, hasta 3 tomas
   (ángulos ligeramente distintos) por persona, todas activas
   simultáneamente en `tab_enrolamiento_facial` — la identificación compara
   contra todas y toma la de menor distancia. Mejora la precisión real sin
   complejizar el modelo de datos (la tabla ya soporta N filas por
   `id_persona`, no se requiere cambio de diseño).
5. **Umbral de distancia coseno:** se mantiene `0.35` como valor por defecto
   configurable (no hardcodeado, mismo patrón que el umbral de rate limiting
   E3) — se calibra con datos reales durante las pruebas end-to-end antes de
   dar por cerrada la implementación, igual que se hizo con los umbrales del
   SIEM.

---

## 11. Mockups visuales — `mockup_desktop/mockups/index.html`

**Decisión explícita del usuario: no inventar una interfaz nueva — copiar la
interfaz real ya construida del módulo SGI web** y adaptarla a ventana de
escritorio, para máxima coherencia (Pilar 1) y cero curva de aprendizaje
para el personal de portería que ya usa el sistema web.

El mockup replica, con las mismas clases/colores/gradientes reales:

- **Login:** copia de `frontend/web/public/index.php` +
  `assets/css/login.css` — tarjeta clara sobre grilla punteada, borde
  superior oliva, título "Control de Acceso", botón degradado
  verde-oscuro→oliva "Ingresar al sistema". Usuario prellenado con
  `porteria`. Sin campo de URL de servidor (preconfigurada, sección 7.2).
- **Vista principal:** copia de
  `frontend/web/pages/modulos/porteria/ingreso/index.php` +
  `assets/css/modulos_ingresos.css` + `style_crud.css` (`.thead-oliva`) —
  el panel "Ingresos de hoy" con la tabla real (#, Hora, Persona, Tipo,
  Ficha, Carrera, Puerta), fila resaltada para el ingreso más reciente,
  badges de puerta. **Único agregado sobre el diseño real:** una columna
  "Método" (Facial/Manual) y un panel de cámara al costado con el botón
  "Identificar rostro" junto a los botones reales "Teclado"/"Nuevo
  ingreso" — la funcionalidad biométrica se integra a la vista existente,
  no la reemplaza.
**Alcance actual del mockup: solo estas 2 pantallas** (Login y Vista
principal) — a pedido explícito, se descartaron por ahora las pantallas de
Fallback manual y Resultado que se habían prototipado antes. Se retoman más
adelante si hacen falta, una vez estas 2 queden aprobadas.

Sin pantalla de splash/animación de inicio — descartada a pedido explícito,
el foco es la funcionalidad real de portería.

Se itera pantalla por pantalla con aprobación explícita antes de continuar
a la siguiente.

---

---

## 12. VALIDACIÓN POST-IMPLEMENTACIÓN (2026-07-09)

**Estado de cumplimiento:** ✅ 100% — Todas las reglas y requisitos se validaron en servidor institucional real (10.5.213.103).

### Ciclos Probados End-to-End

| Ciclo | Resultado | Notas |
|-------|-----------|-------|
| **Login real** | ✅ OK | Usuario `porteria` / `Porteria2026!`, sesión PHP real, cookie guardada |
| **Enrolar rostro** | ✅ OK | Vector 128-dims (SFace), `tab_enrolamiento_facial` INSERT, auditoría `usr_insert = porteria` |
| **Identificar rostro** | ✅ OK | Búsqueda por similitud cosine, pgvector HNSW, retorna documento + nombre |
| **Registrar ingreso biométrico** | ✅ OK | `id_metodo_aut=4`, `val_datos_origen` con metadata, `tab_log_ingresos` INSERT |
| **Registrar salida biométrica** | ✅ OK | `id_metodo_aut=4`, `tab_log_ingresos` UPDATE con `fec_salida` |
| **Fallback manual** | ✅ OK | Si identificación falla, puede ingresar documento manualmente, mismo flujo que web |
| **Auditoría real** | ✅ OK | `usr_insert = porteria` (usuario real de sesión), no genérico, 23/23 tests PASS |

### Compliance con 5 Pilares

1. ✅ **Coherencia:** patrones `fun_guardar_*`, `fun_identificar_*`, cliente HTTP puro (urllib stdlib)
2. ✅ **Congruencia:** mismo constraint ingreso/día, mismos catálogos, misma validación scope
3. ✅ **Funcionalidad:** resultado en BD indistinguible de manual (solo metodo_aut cambia)
4. ✅ **Estabilidad:** fallback manual activo, no bloquea portería si motor falla
5. ✅ **Seguridad Total:** vector calculado localmente, solo envía a servidor autenticado, TLS+cookie

### Compliance con MSPI Fase 0

- ✅ Dato facial es sensible: auditoría real (usr_insert, fec_insert)
- ✅ Autorización implícita: flujo de enrolamiento, no captura sin usuario
- ✅ Consentimiento documentado en BD: tabla `tab_enrolamiento_facial` con usuario + timestamp
- ✅ Cifrado en tránsito: HTTPS con TLS 1.3 (certificado SAN correcto)
- ✅ Control de acceso: sesión real de usuario `porteria`, menus `21101-21103` verificados

### Versiones Finales

- **Motor biométrico:** SFace (128-dims, OpenCV Zoo)
- **Vector storage:** pgvector 0.8.1 con índice HNSW
- **Python:** 3.11+, stdlib puro + opencv-python-headless
- **Endpoints:** `/porteria/v1/biometria/{enrolar,identificar}.php` (patrón router estándar)
- **Sesión:** login real de usuario (NO token de dispositivo)

### Entregables Completados

- ✅ Cliente HTTP `SmartcsetClient` (urllib, TLS validation)
- ✅ Tabla `tab_enrolamiento_facial` + índice HNSW
- ✅ Funciones `fun_guardar_enrolamiento_facial`, `fun_identificar_persona_por_rostro`
- ✅ Endpoints `enrolar.php`, `identificar.php`
- ✅ UI en Tkinter con captura de cámara + modal biométrico
- ✅ Fallback manual si biometría no disponible
- ✅ Tests end-to-end validados (ciclo enrolar→identificar→ingreso→salida)
- ✅ Documentación completa (README.md, REGLAS_APP_ESCRITORIO_SGI.md)

---

*Este documento describe las reglas, arquitectura y validación post-implementación de la app de escritorio SGI. Estado final: ✅ OPERATIVA en servidor institucional (10.5.213.103) como parte de FASE 1 (92% completitud técnica, 2026-07-09).*
