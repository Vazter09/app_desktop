# Aplicación Desktop - Reconocimiento Biométrico (portería SmartCSET)

## ¿Qué es esto?

App de escritorio (Tkinter + OpenCV) para el **PC dedicado de portería**. Enrola e
identifica personas por rostro y, al identificar, registra el ingreso/salida real
en SmartCSET — reutilizando el backend, la BD y los endpoints reales del sistema
(no es un módulo aparte con su propia base de datos).

No requiere navegador, no pide permiso de cámara en cada uso (se activa directo
al abrir la app), y no corre ningún servidor PHP local: solo dos procesos en
este PC:

1. **Motor biométrico local** (`motor_biometrico.py`, FastAPI, puerto 5000) —
   extrae el vector facial (Facenet512) de la imagen capturada. Se queda 100%
   local: nunca sale de este equipo.
2. **App Tkinter** (`app_desktop.py`) — captura, orquesta, y habla por HTTPS
   directo con el backend central de SmartCSET (mismo mecanismo de auth por
   token de dispositivo que usa la app móvil de portería).

## Requisitos

- Python 3.10+
- Webcam conectada
- Backend de SmartCSET accesible por red (local o el servidor SENA)
- Un **token de dispositivo** generado por un administrador desde el backend:
  ```bash
  php scripts/tools/generate_device_token.php "PC Portería Biométrico" porteria
  ```

## Instalación

```bash
python -m venv .venv
.venv/bin/pip install -r requirements_desktop.txt
```

## Uso

1. Iniciar el motor biométrico local (en su propia terminal):
   ```bash
   BIOMETRIA_API_KEY=<clave-real-no-la-default> iniciar_motor_python_desktop.bat
   # o en Linux/dev: .venv/bin/python motor_biometrico.py
   ```
2. Iniciar la app:
   ```bash
   .venv/bin/python app_desktop.py
   ```
3. **Primera vez**: pide la URL del servidor SmartCSET y el token de
   dispositivo (6 caracteres) — esto **es el login** del PC de portería, se
   valida contra `/routers/porteria/v1/device/validate.php` (el mismo
   endpoint que usa la app móvil). Se guarda en `.device_config.json`
   (no versionado, fuera del repo, ver `.gitignore`).
4. Para **enrolar**: ingresar documento (debe ya existir en `tab_personas`),
   capturar rostro, clic en "Enrolar en el Sistema".
5. Para **identificar** (uso diario): capturar rostro, clic en "Identificar
   (ingreso/salida)" — la app decide automáticamente si corresponde ingreso o
   salida (consulta `ingreso/consultar.php`) y registra el movimiento real en
   `tab_log_ingresos` con `metodo_aut = 4` (Biométrico facial).

## Arquitectura

```
┌────────────────────────────────────────────┐
│         PC dedicado de portería             │
│                                              │
│  ┌──────────────┐      ┌─────────────────┐  │
│  │ app_desktop  │◄────►│ motor_biometrico│  │
│  │ (Tkinter)    │ HTTP │ (FastAPI, local)│  │
│  │              │ 5000 │ Facenet512      │  │
│  └──────┬───────┘      └─────────────────┘  │
└─────────┼────────────────────────────────────┘
          │ HTTPS (Bearer token de dispositivo)
┌─────────▼────────────────────────────────────┐
│         Backend SmartCSET (real)              │
│  /device/validate.php                         │
│  /biometria/{enrolar,identificar}.php  (nuevo)│
│  /ingreso|salida/{consultar,registrar}.php    │
│                    │                          │
│                    ▼                          │
│         PostgreSQL: tab_biometria_facial,     │
│         tab_log_ingresos, tab_personas...     │
└────────────────────────────────────────────────┘
```

## Solución de problemas

### "Cámara no disponible"
Verificar que la webcam esté conectada y que ninguna otra app la esté usando.

### "Motor biométrico local no responde"
Confirmar que `motor_biometrico.py` esté corriendo en este PC (`curl
http://127.0.0.1:5000/health`).

### "No se pudo conectar al servidor SmartCSET" / token inválido
Verificar la URL guardada y que el token siga activo (`ind_activo = TRUE` en
`tab_dispositivos_porteria`). Para reconfigurar, borrar `.device_config.json`
y volver a abrir la app.

## Archivos

- `app_desktop.py` — app principal (captura, login, enrolar/identificar)
- `smartcset_client.py` — cliente HTTP contra el backend real de SmartCSET
- `config_desktop.py` — persistencia local de URL + token de dispositivo
- `motor_biometrico.py` / `motor_biometrico_desktop.py` / `config_motor_desktop.py` — motor IA local
- `build_exe.bat` — generar `.exe` (Windows)
- `requirements_desktop.txt` — dependencias Python
