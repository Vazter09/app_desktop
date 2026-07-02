# HANDOFF — App Desktop de Reconocimiento Biométrico

> **Propósito:** trazabilidad de la app de escritorio de reconocimiento facial
> que se usa en un PC independiente de portería para registrar ingreso/salida.
> **Última actualización:** 2026-07-02 (sesión 2 — integración real con SmartCSET)
> **Estado global:** ✅ Integrada de verdad con el backend real de SmartCSET
> (auth, BD, funciones, endpoints de ingreso/salida). Falta probar la app
> Tkinter completa con cámara real (bloqueado aquí por falta de entorno gráfico/cámara).

---

## 1. Qué es

App de escritorio (Python + Tkinter + OpenCV) que corre en un **PC de portería**
para **enrolar** personas (capturar rostro) e **identificarlas** contra la base
de datos real de SmartCSET, registrando el ingreso/salida real en
`tab_log_ingresos` con `id_metodo_aut = 4` ("Biométrico facial").

**Ubicación:** `reconocimientio_facial/` (ojo: el nombre de la carpeta raíz
tiene un typo — falta la "o" antes de "facial" — no se renombró para no romper
referencias, documentado aquí para quien busque la carpeta).

### Arquitectura actual (2 procesos, sin PHP local)

```
┌─ app_desktop.py (Tkinter + OpenCV) ─ captura cámara, login, orquesta
│     │ HTTP local :5000                  │ HTTPS (Bearer token dispositivo)
│     ▼                                   ▼
├─ motor_biometrico.py (FastAPI local)    Backend real SmartCSET
│  extrae vector facial 512d (Facenet512)  /device/validate.php
│                                          /biometria/{enrolar,identificar}.php
│                                          /ingreso|salida/{consultar,registrar}.php
│                                                   │
│                                                   ▼
│                                          PostgreSQL: tab_biometria_facial,
│                                          tab_log_ingresos, tab_personas...
```

**Cambio clave respecto a la sesión anterior:** se eliminó por completo la capa
PHP standalone (`controlador_biometrico.php`, `config_postgresql.php`, servidor
embebido en `:8080`, `schema_biometria.sql`). Ya no hay conexión directa a BD ni
credenciales en la app — todo pasa por HTTPS al backend real de SmartCSET,
autenticado con el mismo mecanismo de **token de dispositivo** que usa la app
móvil de portería (`mobile/porteria-app/`).

---

## 2. Estructura actual de la carpeta

```
reconocimientio_facial/
├── HANDOFF_APP_DESKTOP.md         ← este archivo
├── WhatsApp Image 2026-07-01 at 4.56.51 PM.jpeg   ← mockup/captura de la UI
└── Desktop/
    ├── app_desktop.py             ← app principal: login, captura, enrolar/identificar
    ├── smartcset_client.py        ← ⭐ NUEVO: cliente HTTP contra el backend real
    ├── config_desktop.py          ← ⭐ NUEVO: persistencia local (URL + token)
    ├── motor_biometrico.py        ← motor IA FastAPI (Facenet512, sin cambios)
    ├── motor_biometrico_desktop.py← launcher del motor (sin cambios)
    ├── config_motor_desktop.py    ← config del motor (sin cambios)
    ├── requirements_desktop.txt   ← deps Python (sin `requests`: se usa urllib)
    ├── DESKTOP_README.md          ← reescrito con la arquitectura real
    ├── build_exe.bat              ← ajustado (ya no requiere PHP)
    ├── iniciar_motor_python_desktop.bat ← ajustado (API key vía env var)
    ├── detener_servicios.bat      ← ajustado (quitado el chequeo de :8080)
    └── .venv/                     ← entorno Python local (gitignored, se regenera)
```

**Eliminados en esta sesión** (ya no aplican): `controlador_biometrico.php`,
`config_postgresql.php`, `schema_biometria.sql` (reemplazado por
`database/migrations/add_tab_biometria_facial.sql` +
`database/functions/porteria/fun_{guardar_biometria_facial,identificar_persona_por_rostro}.sql`
en el repo principal de SmartCSET).

---

## 3. Trabajo realizado en esta sesión (2026-07-02, sesión 2)

### A) Backend SmartCSET — reuso real, cero reinvención
Se investigó a fondo el sistema de auth por **token de dispositivo** que ya usa
la app móvil de portería (`backend/middleware/require_session_or_device.php`,
`backend/routers/porteria/_lib/{Auth,DeviceToken}.php`,
`tab_dispositivos_porteria`) y se reusó tal cual — no se escribió ningún
mecanismo de login nuevo del lado del servidor.

**Nuevo en el repo principal SmartCSET:**
- `database/migrations/add_tab_biometria_facial.sql` — tabla enlazada por
  `id_persona` (FK a `tab_personas`, no por "cédula" suelta como el prototipo)
  + pgvector + índice HNSW + trigger de auditoría `tri_act_tabla` (antes el
  prototipo no tenía auditoría real).
- `database/functions/porteria/fun_guardar_biometria_facial.sql` (antes
  `sp_guardar_registro_biometrico`) y
  `fun_identificar_persona_por_rostro.sql` — renombradas a la convención
  `fun_` del proyecto, patrón de excepción 4-arg estándar.
- `id_metodo_aut = 4` ("Biométrico facial") agregado a `tab_metodos_aut`
  (seed) + caso `worigen_txt = 'biometrico'` en `fun_registrar_ingreso_manual`.
- `backend/routers/porteria/v1/biometria/{enrolar,identificar}.php` — mismo
  esqueleto que `ingreso/registrar.php`, exigen auth de tipo `device`.
- `backend/services/porteria/biometria_service.php` — umbral de distancia
  coseno (`0.35`) para decidir match/no-match; reusa
  `porteriaFotoRedimensionar()` de `foto_service.php` para la foto de
  enrolamiento.
- **Bug preexistente encontrado y corregido**:
  `backend/services/porteria/parse_captura_service.php::accesoDocumentoDesdePost()`
  solo dejaba pasar `id_metodo_aut` 1 o 3 (manual/barras), cualquier otro valor
  —incluido el nuevo 4— caía silenciosamente a "manual". Se agregó
  `ACCESO_METODO_BIOMETRICO = 4` a la lista blanca (sin tocar el
  comportamiento existente de QR/barras/manual).

### B) App de escritorio — recorte y reconexión
- Eliminados: servidor PHP embebido, `config_postgresql.php` (credenciales de
  BD en claro), `.venv/` del repo (2.5GB — nunca debió versionarse, ahora en
  `.gitignore`).
- `smartcset_client.py` (nuevo): cliente HTTP con `urllib` (sin dependencia
  nueva) — `validar_dispositivo`, `enrolar`, `identificar`, `consultar_acceso`,
  `registrar_ingreso`, `registrar_salida`. Además `extraer_vector_local()`,
  que sigue llamando al motor Facenet512 **local** (127.0.0.1:5000) — el
  cómputo de IA se queda en el PC de portería, solo el vector ya calculado
  viaja al servidor central.
- `config_desktop.py` (nuevo): persiste `base_url` + `device_token` en
  `.device_config.json` local (gitignored, nunca en el repo).
- **Login real agregado**: al primer arranque, diálogo pide URL de SmartCSET +
  token de 6 caracteres, valida contra `/device/validate.php` (igual que la
  app móvil). Si falla, pide de nuevo; si el operador cancela, la app no abre.
- **Botón "Identificar" nuevo**: captura → vector local → `identificar()` →
  si hay match, `consultar_acceso()` decide ingreso o salida automáticamente
  y llama al endpoint real correspondiente con `metodo_aut=4` y la foto.
- El requisito de "huella simulada" para habilitar el enrolamiento se quitó
  (la huella sigue siendo decorativa/simulada en la UI, pero ya no bloquea:
  la biometría real hoy es solo facial, no tiene sentido exigir un dato falso).

### C) Verificado end-to-end (sin GUI/cámara real — ver sección 4)
Con `curl` y también con el propio `smartcset_client.py` ejecutado directo en
Python (mismo código que usará la app):
- ✅ `validar_dispositivo()` — token generado con
  `scripts/tools/generate_device_token.php` validado correctamente.
- ✅ `enrolar()` con vector de 512 floats de prueba → fila real en
  `tab_biometria_facial` con `usr_insert` = usuario auditado del dispositivo
  (no `postgres`).
- ✅ `identificar()` con el mismo vector → distancia `0`, match correcto.
- ✅ `identificar()` con vector distinto → `None` (rechazado por el umbral).
- ✅ Ciclo completo `consultar_acceso` → `registrar_ingreso` (metodo_aut=4,
  origen `'biometrico'` en `tab_log_ingresos.val_datos_origen`) →
  `registrar_salida` → `consultar_acceso` vuelve a `puede_ingresar: true`.

---

## 4. Pendiente inmediato

### 🔲 Prueba con cámara real + GUI Tkinter
No verificado en esta sesión (sin entorno gráfico ni cámara disponible aquí).
La lógica de negocio (todo lo que no es Tkinter/OpenCV) sí quedó probada
directamente vía `smartcset_client.py`. Falta:
1. Correr `motor_biometrico.py` local y `app_desktop.py` en el PC real de
   portería con cámara.
2. Confirmar que el diálogo de login (`simpledialog`) se ve bien y guarda
   `.device_config.json` correctamente.
3. Enrolar un rostro real, luego identificarlo, confirmar ingreso/salida real.

### 🔲 Hardening pendiente (según lo ya documentado, sigue vigente)
1. **Huella dactilar real**: sigue simulada (`app_desktop.py` envía un hex
   fijo si se simula, pero ya no se guarda en ningún lado — no hay columna de
   huella en `tab_biometria_facial`, se quitó por YAGNI hasta que haya lector
   real). Falta el SDK/lector físico si se decide implementarlo.
2. **Cifrado en reposo** del vector facial y las fotos — depende de la
   decisión pendiente de E2 (cifrado en reposo, bloqueado por diseño de PK en
   `tab_personas`). No resuelto en esta sesión, riesgo heredado documentado.
3. **API key del motor**: seguir usando el valor por defecto
   (`cambiar-api-key-segura`) es inseguro — cambiarla antes de producción
   (variable de entorno `BIOMETRIA_API_KEY`, debe coincidir entre
   `motor_biometrico.py` y `app_desktop.py`/`Config.MOTOR_API_KEY`).
4. **Empaquetado `.exe`** (`build_exe.bat`) — no probado con los cambios de
   esta sesión, solo ajustado el texto de instrucciones.

---

## 5. Datos de referencia

| Ítem | Valor |
|---|---|
| Backend SmartCSET | `https://localhost/smartcset` (dev) o el servidor SENA real |
| Token de dispositivo de prueba | generado en esta sesión, id_dispositivo=1, `id_usuario_audit=porteria` — **rotar/borrar antes de producción** |
| Umbral de distancia coseno | `0.35` (`BIOMETRIA_UMBRAL_DISTANCIA` en `biometria_service.php`) |
| Puerto motor IA local | 5000 (FastAPI/uvicorn, sin cambios) |
| Modelo facial | Facenet512 (512 dimensiones, distancia coseno) |
| `id_metodo_aut` biométrico | `4` en `tab_metodos_aut` |
| Config local del PC | `Desktop/.device_config.json` (gitignored) |

---

## 6. Cómo arrancar todo (manual, en terminal, en el PC de portería)

```bash
cd reconocimientio_facial/Desktop
python -m venv .venv && .venv/bin/pip install -r requirements_desktop.txt

# 1) Motor IA local (dejar corriendo en su propia terminal)
BIOMETRIA_API_KEY=<clave-real> .venv/bin/python motor_biometrico.py
#    verificar: curl http://127.0.0.1:5000/health

# 2) App desktop (primera vez pide URL de SmartCSET + token de dispositivo)
BIOMETRIA_API_KEY=<misma-clave-real> .venv/bin/python app_desktop.py
```

Generar el token de dispositivo (una vez, desde el repo principal de
SmartCSET, con acceso a la BD):
```bash
php scripts/tools/generate_device_token.php "PC Portería Biométrico" porteria
```

---

## 7. Próximos pasos sugeridos (en orden)

1. Probar la app completa con cámara real en el PC de portería (sección 4).
2. Cambiar la API key del motor a un valor real antes de dejarla en uso diario.
3. Decidir si se implementa huella real (lector físico) o se retira
   definitivamente la UI simulada de huella.
4. Cuando se resuelva E2 (cifrado en reposo) en el proyecto principal,
   extender la decisión a `tab_biometria_facial.vector_facial` y `uri_foto`.
5. Rotar/borrar el token de dispositivo de prueba generado en esta sesión
   antes de llevar esto a producción.
