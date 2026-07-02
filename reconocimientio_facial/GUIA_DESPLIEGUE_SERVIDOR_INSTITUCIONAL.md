# Guía de despliegue — Reconocimiento facial contra el servidor institucional

> Este entorno local (`db_smartcset2`, Apache local) es una **copia** del servidor
> real del SENA. El servidor institucional no tiene automáticamente lo que
> instalamos aquí a mano (pgvector, la tabla/funciones nuevas, el token de
> dispositivo). Esta guía cubre exactamente qué falta en cada lado.

Hay **dos máquinas distintas** involucradas:

1. **El servidor institucional** (donde vive `db_smartcset2`/Apache reales) — necesita los cambios de base de datos y backend.
2. **El PC de portería** (equipo físico donde corre la app de escritorio) — necesita Python, la cámara, y apuntar al servidor institucional en vez de `localhost`.

---

## 1. Lado servidor institucional (una sola vez)

### 1.1 Instalar pgvector en PostgreSQL del servidor
La extensión `vector` (pgvector) **no viene por defecto** en PostgreSQL. Hay que instalarla en el paquete del sistema operativo del servidor, con la versión que corresponda a su PostgreSQL:

```bash
# Ejemplo Ubuntu/Debian (ajustar versión de PostgreSQL del servidor):
sudo apt install postgresql-<version>-pgvector
```

Sin esto, el paso 1.2 falla en `CREATE EXTENSION vector;`.

### 1.2 Aplicar la migración y funciones nuevas contra la BD real
**No correr `setup_smartcset.sh` completo contra producción** (ese script recrea el schema desde cero). Aplicar solo lo nuevo, en este orden, con `psql` contra `db_smartcset2` del servidor:

```bash
psql -h <host_servidor> -U <usuario> -d db_smartcset2 -f database/migrations/add_tab_biometria_facial.sql
psql -h <host_servidor> -U <usuario> -d db_smartcset2 -f database/functions/porteria/fun_guardar_biometria_facial.sql
psql -h <host_servidor> -U <usuario> -d db_smartcset2 -f database/functions/porteria/fun_identificar_persona_por_rostro.sql
psql -h <host_servidor> -U <usuario> -d db_smartcset2 -f database/functions/porteria/fun_registrar_ingreso_manual.sql
psql -h <host_servidor> -U <usuario> -d db_smartcset2 -f database/seeds/seed_acceso_dev.sql
```
(El seed usa `ON CONFLICT DO NOTHING`, es seguro reaplicarlo — no duplica ni pisa los métodos de auth ya existentes.)

### 1.3 Desplegar el código PHP nuevo
Los archivos nuevos/modificados de este cambio (llevar todo `feat/seguridad` o al menos estos):
- `backend/routers/porteria/v1/biometria/{enrolar,identificar}.php`
- `backend/services/porteria/biometria_service.php`
- `backend/services/porteria/parse_captura_service.php` (modificado)
- `backend/core/prepare.php` (modificado)
- `backend/routers/porteria/prepare.php` (modificado)

### 1.4 Confirmar HTTPS real (no autofirmado)
En local usamos `SMARTCSET_TLS_INSECURE=1` porque el certificado es autofirmado.
**El servidor institucional ya tiene certificado válido** (documentado en
`HANDOFF.md`), así que en el PC de portería **NO se debe activar esa
variable** — debe validar el certificado real normalmente.

### 1.5 Generar el token de dispositivo real
Desde el servidor (o cualquier máquina con acceso directo a la BD vía el script CLI):
```bash
php scripts/tools/generate_device_token.php "PC Portería Biométrico" porteria <id_entrada_centro>
```
- Reemplazar `<id_entrada_centro>` por el número real de la puerta física donde va a estar el PC (`SELECT id_entrada_centro, nom_entrada_centro FROM tab_entradas_centro;`).
- El token se imprime **una sola vez** — copiarlo, no queda guardado en texto plano en ningún lado.
- `porteria` es el usuario de auditoría (`id_usuario_audit`) que se registrará como responsable de los movimientos de ese dispositivo; puede ser otro usuario real si se prefiere.

---

## 2. Lado PC de portería (el equipo físico con la cámara)

Este PC **no necesita PHP, ni PostgreSQL, ni el repo completo de SmartCSET** — solo la carpeta `reconocimientio_facial/Desktop/` y Python.

### 2.1 Requisitos
- Python 3.10+ instalado y en el PATH
- Webcam conectada
- Conectividad de red al servidor institucional (mismo edificio/VPN/red del centro)
- ~2GB de espacio libre (TensorFlow + modelos de DeepFace)

### 2.2 Instalar dependencias
```bash
cd reconocimientio_facial/Desktop
python -m venv .venv

# Linux/macOS:
.venv/bin/pip install -r requirements_desktop.txt
.venv/bin/pip install -r requirements_motor.txt

# Windows:
.venv\Scripts\pip install -r requirements_desktop.txt
.venv\Scripts\pip install -r requirements_motor.txt
```
La primera vez que corra el motor, DeepFace descarga los pesos del modelo
(`Facenet512` + `retinaface`, ~150MB combinados) — requiere internet esa
primera vez, después queda cacheado en `~/.deepface/weights/`.

### 2.3 Configurar `.env.local`
Crear el archivo `reconocimientio_facial/Desktop/.env.local` (no se versiona, cada PC tiene el suyo):
```
BIOMETRIA_API_KEY=<generar-una-clave-real-unica-para-este-pc>
```
**No** agregar `SMARTCSET_TLS_INSECURE=1` aquí — eso es solo para el certificado autofirmado de desarrollo local.

### 2.4 Arrancar los dos procesos
```bash
# Terminal 1 — motor local (Linux):
./iniciar_motor.sh
# Terminal 1 — motor local (Windows):
iniciar_motor_python_desktop.bat

# Terminal 2 — app (Linux):
./iniciar_app.sh
# Terminal 2 — app (Windows):
iniciar_app.bat
```

### 2.5 Login (primera vez que abre la app)
- **URL del servidor**: la del servidor institucional real, ej. `https://10.5.213.111/smartcset` (confirmar la IP/dominio actual con el admin de red — puede diferir de la usada en desarrollo local).
- **Token de dispositivo**: el generado en el paso 1.5.

Queda guardado en `.device_config.json` (local, no versionado) para no pedirlo cada vez.

---

## 3. Checklist final de verificación

- [ ] `SELECT * FROM pg_extension WHERE extname='vector';` devuelve una fila en el servidor
- [ ] `SELECT * FROM tab_metodos_aut WHERE id_metodo_aut=4;` devuelve "Biométrico facial"
- [ ] `curl -X POST https://<servidor>/smartcset/routers/porteria/v1/device/validate.php -H "Authorization: Bearer <token>"` responde `"ok":true`
- [ ] El PC de portería tiene cámara funcional y `curl http://127.0.0.1:5000/health` responde `"estado":"ok"`
- [ ] Enrolar una persona real de prueba → verificar fila en `tab_biometria_facial`
- [ ] Identificar esa misma persona → confirmar ingreso real en `tab_log_ingresos` con `id_metodo_aut=4`
- [ ] `BIOMETRIA_API_KEY` en `.env.local` es un valor único generado para ese PC, no el default `cambiar-api-key-segura`

---

## 4. ¿Qué archivos de `Desktop/` se usan realmente?

| Archivo | ¿Se usa? | Rol |
|---|---|---|
| `app_desktop.py` | ✅ Sí, principal | App Tkinter: cámara, login, enrolar/identificar |
| `smartcset_client.py` | ✅ Sí | Cliente HTTP contra el backend real (importado por `app_desktop.py`) |
| `config_desktop.py` | ✅ Sí | Guarda/lee `.device_config.json` (importado por `app_desktop.py`) |
| `motor_biometrico.py` | ✅ Sí, principal | Motor FastAPI que extrae el vector facial (Facenet512 + retinaface) |
| `motor_biometrico_desktop.py` | ✅ Sí (solo Windows) | Launcher alternativo del motor, usado por `iniciar_motor_python_desktop.bat` |
| `config_motor_desktop.py` | ✅ Sí | Usado por `motor_biometrico_desktop.py` para leer config (recortado — se le quitó `ConfigWeb`, `get_database_url()`, `init_config()` y demás código muerto del prototipo viejo) |
| `requirements_desktop.txt` | ✅ Sí | Dependencias de la app (Tkinter/OpenCV/Pillow) |
| `requirements_motor.txt` | ✅ Sí | Dependencias del motor (FastAPI/DeepFace/TensorFlow) |
| `iniciar_app.sh` / `iniciar_app.bat` | ✅ Sí | Arranque corto de la app leyendo `.env.local` |
| `iniciar_motor.sh` | ✅ Sí (Linux) | Arranque corto del motor leyendo `.env.local` |
| `iniciar_motor_python_desktop.bat` | ✅ Sí (Windows) | Arranque del motor en Windows |
| `detener_servicios.bat` | 🟡 Opcional | Utilidad para matar el proceso del motor en Windows si queda colgado |
| `build_exe.bat` | 🟡 Opcional | Solo se usa si se quiere empaquetar `app_desktop.py` como `.exe` con PyInstaller |
| `DESKTOP_README.md` | 📄 Documentación | Guía rápida de uso, no es código |
| `.venv/` | ⚙️ Generado | Se crea en cada PC, nunca se versiona |
| `.env.local` | ⚙️ Generado | Config local (API key), nunca se versiona |
| `.device_config.json` | ⚙️ Generado | Se crea solo tras el primer login exitoso |

**En resumen:** todo lo que queda en `Desktop/` se usa. Se eliminó lo que no:
la carpeta `storage/` (las fotos ahora se envían directo al servidor
institucional, no se guardan localmente en este PC) y el código muerto dentro
de `config_motor_desktop.py` (conexión directa a BD del prototipo viejo,
`ConfigWeb`, `init_config()` — nada de eso se llamaba desde ningún lado).
