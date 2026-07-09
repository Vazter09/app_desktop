# App de Escritorio SGI — SmartCSET

**Última actualización:** 2026-07-09 (tarde) | **Estado:** ✅ OPERATIVA — biometría con foto de enrolamiento real end-to-end

Cliente de escritorio (Python + Tkinter, cero dependencias de terceros en
esta fase) para el módulo SGI (portería) de SmartCSET. No tiene BD propia
ni login propio — habla por HTTPS contra el backend real de SmartCSET con
el mismo login de usuario/contraseña que la web.

**Cliente HTTP puro:** urllib (stdlib), sin requests ni deps externas. TLS validation
activo en producción (`verify_tls=True` siempre). Mismo usuario `porteria` que la web.

Reglas y arquitectura completas: [`REGLAS_APP_ESCRITORIO_SGI.md`](REGLAS_APP_ESCRITORIO_SGI.md) (validado post-implementación 2026-07-09).
Mockups visuales (HTML de referencia, copia literal del look real): [`mockups/`](mockups/).

## Estado actual

- ✅ Login real (usuario/contraseña, sesión PHP + cookie) — reutiliza
  `/routers/auth/v1/login.php` tal cual, sin token de dispositivo.
- ✅ Dashboard "Inicio" real — sidebar/topbar navegables de verdad, KPIs
  (ingresos/salidas de hoy, personas dentro ahora), acciones rápidas,
  actividad reciente.
- ✅ Registro de ingreso — listado real + diálogo "Nuevo ingreso"
  (consultar persona → registrar), probado end-to-end contra la BD real.
- ✅ Registro de salida — listado real + diálogo "Nueva salida", probado
  end-to-end.
- ✅ Entradas — listado real de puertas; crear/eliminar reutiliza los
  endpoints reales (el servidor exige admin, igual que la web).
- ✅ Datos estadísticos — placeholder "en construcción", igual que en la
  web real (esa página tampoco está implementada ahí).
- ✅ Suite de pruebas automatizadas (`app/tests/`) contra el backend
  real, sin mocks — ver sección "Tests" abajo.
- ✅ Backend de biometría facial — `tab_enrolamiento_facial` (pgvector
  `VECTOR(128)`, índice HNSW) + `fun_guardar_enrolamiento_facial` /
  `fun_identificar_persona_por_rostro` + endpoints
  `porteria/v1/biometria/{enrolar,identificar}.php`, probados end-to-end
  contra el servidor de laboratorio (`192.168.1.71`, el que usa `.env`
  hoy): ciclo enrolar → identificar → registrar ingreso automático
  (metodo_aut=4) → identificar de nuevo → registrar salida automático,
  con auditoría real `usr_insert = porteria`. La validación contra el
  servidor institucional real (10.5.213.103) documentada el 2026-07-09
  cubría el ciclo sin foto — la extensión con foto (ver debajo) todavía
  no se ha vuelto a validar ahí, solo en laboratorio.
- ✅ Foto de enrolamiento — **Opción A (2026-07-09):** el servidor
  guarda el archivo, la app cachea localmente.
  - Enrolar: el modal captura el último frame de cámara → JPG → base64
    → se envía junto con el vector a `biometria/enrolar.php`.
  - Servidor: `BiometriaPhotoService` valida MIME real (`finfo`,
    whitelist JPEG/PNG/WebP) y guarda en
    `frontend/web/public/uploads/biometria/{id_persona}/{id_persona}_{primer_nombre}.jpg`;
    la ruta relativa queda en `tab_enrolamiento_facial.ruta_foto_enrolamiento`.
  - Identificar: `identificar.php` lee esa ruta y devuelve la foto en
    base64 junto con los datos de la persona — **es la foto real del
    enrolamiento, no un frame nuevo capturado en el momento** (bug
    corregido el 2026-07-09: el modal mostraba por error la captura en
    vivo en lugar de la guardada; la prioridad ahora es
    servidor-primero, frame local solo como fallback si no hay foto
    guardada).
  - App: cachea la foto descargada en `app_desktop/app/images/{id}_{nombre}.jpg`
    (no versionado, ver `.gitignore` de esa carpeta).
  - **Pendiente explícito, decisión institucional diferida:** cifrado en
    reposo de las fotos (MSPI E2) — hoy quedan como JPG planos en
    filesystem, igual que el resto de datos de personas en el sistema.
    Se resuelve en el SENA, no en este ciclo de desarrollo.
- ✅ Modal de confirmación de identificación (`ui/identification_confirmation_modal.py`,
  nuevo 2026-07-09) — se abre automáticamente al identificar con éxito,
  antes de registrar nada. Layout de 3 columnas: foto de enrolamiento
  (izquierda) + datos personales (centro: documento, tipo, entrada,
  ficha, programa) + huella dactilar (derecha, **placeholder — feature
  sin desarrollar todavía**). Botones: Registrar / Ver detalles
  (placeholder) / Cancelar. Cumple E1 (confirmación visual antes de
  registrar) y E4 (aprobación explícita del operario).
- ✅ Motor biométrico (`motor/embeddings.py`) — YuNet (detección) + SFace
  (embedding, **128 dims**) del repositorio oficial `opencv_zoo`,
  vendorizados en `motor/models/`, corren dentro del mismo proceso
  reutilizando OpenCV (ya cargado para la cámara, sin dependencia nueva).
  Dimension corregida de 512 → 128 (2026-07-09, antes de tener datos reales).
- ✅ Modal "Reconocimiento facial" — cámara real en vivo + "Enrolar"
  (documento + rostro → `biometria/enrolar.php`, ahora con foto) +
  "Identificar" (rostro → `biometria/identificar.php` → abre el modal
  de confirmación descrito arriba → al aprobar, decide ingreso/salida
  reutilizando `ingreso/salida consultar.php`, registra con
  `id_metodo_aut=4` — **Bug 19 corregido (2026-07-09): whitelist de metodo_aut
  ahora incluye valor 4 en parse_captura_service.php**).
- 🔲 Verificación con persona real frente a cámara — pendiente porque
  este entorno de desarrollo no tiene a nadie físicamente frente al
  dispositivo de video; **la mecánica de detección/inferencia y el ciclo
  completo de negocio ya están probados con vectores simulados
  (`tests/test_smartcset_client.py`, incluye foto sintética válida).**
- 🔲 Separar el motor en un proceso HTTPS local aparte (diseño original,
  REGLAS_APP_ESCRITORIO_SGI.md §5.2) — hoy corre en el mismo proceso
  porque no agrega una dependencia nueva que aislar; queda como
  endurecimiento futuro (Fase 2), no como incumplimiento silencioso.
- ✅ TLS validado contra certificado institucional real — el diseño nunca
  desactiva verificación (`verify_tls=True` siempre). Validado contra
  servidor institucional 10.5.213.103 en la sesión del 2026-07-09 (antes
  de agregar la foto) con certificado SAN correcto
  (`basicConstraints=CA:FALSE`, `extendedKeyUsage=serverAuth`).

### Lección operativa de esta sesión (aridad de funciones PL/pgSQL)

Al agregar el 4º parámetro a `fun_guardar_enrolamiento_facial`, un
`CREATE OR REPLACE` sin más dejó **dos funciones sobrecargadas viviendo
a la vez** en la BD (3-arg vieja + 4-arg nueva) — el mismo patrón de
error ya documentado como lección en `CLAUDE.md`. Se corrigió agregando
un `DROP FUNCTION IF EXISTS` explícito de la firma vieja dentro del
propio archivo `.sql` (idempotente, no rompe instalaciones limpias que
nunca tuvieron la firma vieja) y verificando en la BD real que solo
quede una firma. La migración `add_ruta_foto_enrolamiento.sql` fue
agregada a `database/setup_smartcset.sh` en el punto correcto (junto a
las otras 2 migraciones de `tab_enrolamiento_facial`, antes del array
`FUNCS`) — sin esto, una instalación limpia nueva no tendría la columna
de foto.

## Requisitos

- Python 3.11+ con Tkinter (`python3-tk` en distros que lo separan del
  intérprete base).
- Webcam conectada (la app la detecta sola — prueba los primeros índices
  de video del equipo y usa el primero que entregue un frame real).
- El backend de SmartCSET accesible por HTTPS (en esta fase de
  desarrollo: `https://localhost/smartcset`, con el código PHP corriendo
  local vía Apache y la base de datos en el servidor remoto de
  laboratorio — ver `HANDOFF.md` del proyecto principal).

## Ejecutar

```bash
cd app_desktop/app
python3 main.py
```

Con **cualquier** Python del sistema (3.11+) alcanza — no hace falta
crear ni activar el `.venv` a mano. `bootstrap.py` lo hace por su
cuenta: si `.venv/` no existe, lo crea e instala `requirements.txt` la
primera vez (tarda unos segundos, solo una vez), y luego siempre
re-ejecuta el proceso con ese intérprete antes de importar nada que
necesite `opencv-python` — así `python3 main.py` es el único comando
que hay que recordar, siempre. `.venv/` nunca se versiona (ver
`.gitignore`); es la única dependencia de terceros de toda la app
(captura de cámara + motor biométrico, sección 4/5.1 de las reglas) —
todo lo demás sigue siendo stdlib puro.

Al primer arranque también se crea `app_config.json` (no versionado)
con la URL del servidor. Editarlo ahí si el servidor cambia — la app
nunca pregunta la URL en pantalla de login (ver sección 7.2 de las
reglas).

**Usuario de prueba:** `porteria` / `Porteria2026!` (prellenado en el
campo de usuario).

## Tests

Suite `unittest` que golpea el backend real (sin mocks, misma regla que
`scripts/test_seguridad/` del proyecto principal) usando el mismo
`SmartcsetClient` de producción — cada test limpia sus propios datos,
incluyendo la carpeta de fotos que haya quedado en
`frontend/web/public/uploads/biometria/{documento}/`.

```bash
cd app_desktop/app/tests
python3 -m unittest test_smartcset_client.py -v
```

**13/13 PASS** (verificado 2026-07-09 contra el servidor de laboratorio
de `.env`). Incluye 3 tests nuevos de foto de enrolamiento:
- `test_enrolar_con_foto_guarda_ruta_y_se_recupera_al_identificar` —
  ciclo completo, verifica `ruta_foto_enrolamiento` en BD y que
  `identificar.php` devuelva `foto_base64` no vacío.
- `test_enrolar_sin_foto_no_rompe_identificacion` — congruencia: sin
  foto, `foto_base64` debe venir `None`, no lanzar excepción.
- `test_enrolar_foto_invalida_es_rechazada` — E6: base64 que no
  decodifica a una imagen real debe ser rechazado por
  `BiometriaPhotoService`, no guardado silenciosamente.

Requiere que el backend esté accesible en `SMARTCSET_BASE_URL` (por
defecto `https://localhost/smartcset`) y `psql` en el PATH (para limpiar
datos de prueba y cerrar sesiones colgadas entre corridas, igual que
`common.py` del proyecto principal).

## Estructura

```
app_desktop/
├── REGLAS_APP_ESCRITORIO_SGI.md   ← arquitectura y reglas (leer primero)
├── HANDOFF.md                      ← estado consolidado + roadmap (leer segundo)
├── mockups/                        ← HTML de referencia visual
└── app/
    ├── main.py                     ← punto de entrada
    ├── bootstrap.py                 ← auto-activa .venv/, detecta cambios en
    │                                   requirements.txt por hash y reinstala
    ├── config.py                   ← AppConfig (URL preconfigurada)
    ├── smartcset_client.py         ← cliente HTTP (urllib + cookiejar) +
    │                                   caché local de fotos (images/)
    ├── requirements.txt            ← opencv-python-headless + numpy + Pillow
    ├── .venv/                      ← entorno virtual local, no versionado
    ├── images/                     ← caché local de fotos descargadas
    │                                   ({id}_{nombre}.jpg, no versionado)
    ├── tests/                      ← suite automatizada (ver arriba)
    │   ├── common.py                — incluye limpieza de uploads/biometria/
    │   └── test_smartcset_client.py
    ├── motor/
    │   ├── embeddings.py            ← detección + embedding facial (YuNet+SFace)
    │   └── models/                  ← ONNX vendorizados (ver models/README.md)
    └── ui/
        ├── theme.py                ← colores reales (tab_config_sistema)
        ├── camera.py                ← detección + captura de cámara real
        ├── facial_modal.py          ← modal "Reconocimiento facial"
        │                                (captura foto, envía a enrolar/identificar)
        ├── identification_confirmation_modal.py
        │                            ← modal de confirmación (foto + datos +
        │                                huella placeholder), nuevo 2026-07-09
        ├── login_view.py
        ├── shell.py                ← sidebar + topbar + navegación real
        └── pages/
            ├── inicio.py
            ├── ingreso.py
            ├── salida.py
            ├── entradas.py
            └── placeholder.py
```

### Backend tocado por esta app (fuera de `app_desktop/`)

```
backend/services/porteria/biometria_photo_service.php   ← guarda/lee fotos en filesystem
backend/routers/porteria/v1/biometria/enrolar.php        ← recibe + guarda foto
backend/routers/porteria/v1/biometria/identificar.php     ← devuelve foto guardada
backend/core/prepare.php                                  ← statement con 4 params
database/functions/porteria/fun_guardar_enrolamiento_facial.sql  ← DROP firma vieja + CREATE 4-arg
database/migrations/add_ruta_foto_enrolamiento.sql        ← columna nueva, en setup_smartcset.sh
frontend/web/public/uploads/biometria/                    ← fotos reales guardadas (no versionado)
```
