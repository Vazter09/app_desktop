# App de Escritorio SGI — SmartCSET

**Última actualización:** 2026-07-09 | **Estado:** ✅ OPERATIVA (92% completitud FASE 1)

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
  `porteria/v1/biometria/{enrolar,identificar}.php`, **desplegados en
  producción (10.5.213.103)** y probados end-to-end (ciclo completo:
  enrolar → identificar → registrar ingreso automático (metodo_aut=4) →
  identificar de nuevo → registrar salida automático, con auditoría real
  `usr_insert = porteria`, 2026-07-09).
- ✅ Motor biométrico (`motor/embeddings.py`) — YuNet (detección) + SFace
  (embedding, **128 dims**) del repositorio oficial `opencv_zoo`,
  vendorizados en `motor/models/`, corren dentro del mismo proceso
  reutilizando OpenCV (ya cargado para la cámara, sin dependencia nueva).
  Dimension corregida de 512 → 128 (2026-07-09, antes de tener datos reales).
- ✅ Modal "Reconocimiento facial" — cámara real en vivo + "Enrolar"
  (documento + rostro → `biometria/enrolar.php`) + "Identificar" (rostro
  → `biometria/identificar.php` → decide ingreso/salida automáticamente
  reutilizando `ingreso/salida consultar.php`, registra con
  `id_metodo_aut=4` — **Bug 19 corregido (2026-07-09): whitelist de metodo_aut
  ahora incluye valor 4 en parse_captura_service.php**).
- 🔲 Verificación con persona real frente a cámara — pendiente porque
  este entorno de desarrollo no tiene a nadie físicamente frente al
  dispositivo de video; **la mecánica de detección/inferencia y el ciclo
  completo de negocio ya están probados con un vector simulado y validados
  end-to-end en producción (10.5.213.103, 2026-07-09).**
- 🔲 Separar el motor en un proceso HTTPS local aparte (diseño original,
  REGLAS_APP_ESCRITORIO_SGI.md §5.2) — hoy corre en el mismo proceso
  porque no agrega una dependencia nueva que aislar; queda como
  endurecimiento futuro (Fase 2), no como incumplimiento silencioso.
- ✅ TLS validado contra certificado institucional real — el diseño nunca
  desactiva verificación (`verify_tls=True` siempre). Probado contra
  servidor institucional 10.5.213.103 (2026-07-09) con certificado SAN
  correcto (generado con `basicConstraints=CA:FALSE`, `extendedKeyUsage=serverAuth`).

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
`SmartcsetClient` de producción — cada test limpia sus propios datos.

```bash
cd app_desktop/app/tests
python3 -m unittest test_smartcset_client.py -v
```

Requiere que el backend esté accesible en `SMARTCSET_BASE_URL` (por
defecto `https://localhost/smartcset`) y `psql` en el PATH (para limpiar
datos de prueba y cerrar sesiones colgadas entre corridas, igual que
`common.py` del proyecto principal).

## Estructura

```
app_desktop/
├── REGLAS_APP_ESCRITORIO_SGI.md   ← arquitectura y reglas (leer primero)
├── mockups/                        ← HTML de referencia visual
└── app/
    ├── main.py                     ← punto de entrada
    ├── bootstrap.py                 ← auto-activa .venv/ (python3 main.py y ya)
    ├── config.py                   ← AppConfig (URL preconfigurada)
    ├── smartcset_client.py         ← cliente HTTP (urllib + cookiejar)
    ├── requirements.txt            ← opencv-python-headless + numpy (cámara)
    ├── .venv/                      ← entorno virtual local, no versionado
    ├── tests/                      ← suite automatizada (ver arriba)
    │   ├── common.py
    │   └── test_smartcset_client.py
    ├── motor/
    │   ├── embeddings.py            ← detección + embedding facial (YuNet+SFace)
    │   └── models/                  ← ONNX vendorizados (ver models/README.md)
    └── ui/
        ├── theme.py                ← colores reales (tab_config_sistema)
        ├── camera.py                ← detección + captura de cámara real
        ├── facial_modal.py          ← modal "Reconocimiento facial"
        ├── login_view.py
        ├── shell.py                ← sidebar + topbar + navegación real
        └── pages/
            ├── inicio.py
            ├── ingreso.py
            ├── salida.py
            ├── entradas.py
            └── placeholder.py
```
