# 05 — Manual de instalación

**Módulo:** App de Escritorio SGI — SmartCSET  
**Versión documental:** 1.0.0  
**Fecha:** 2026-09-01  
**Audiencia:** TI, instalador, desarrollador

---

## 1. Requisitos del sistema

### 1.1 Hardware

| Componente | Requisito |
|------------|-----------|
| Procesador | x64, 2+ núcleos recomendado |
| RAM | 4 GB mínimo; 8 GB recomendado |
| Disco | 500 MB libres (app + modelos ONNX + venv) |
| Webcam | USB o integrada; reconocida por el SO |
| Red | Conectividad HTTPS al servidor SmartCSET (intranet SENA) |

### 1.2 Software

| Componente | Versión |
|------------|---------|
| Sistema operativo | Windows 10/11 (empaquetado) o Linux/macOS (desarrollo) |
| Python (solo desarrollo) | 3.11+ con Tkinter |
| Backend SmartCSET | Desplegado y accesible por HTTPS |
| PostgreSQL | 14+ con extensión `vector` (pgvector) |

### 1.3 Credenciales y permisos

- Usuario SmartCSET con permiso de menú de portería (ej. `porteria`).
- Para desarrollo: acceso a `.env` del monorepo con credenciales de BD (solo tests).
- Para empaquetado: PowerShell con permisos de ejecución.

---

## 2. Instalación en modo desarrollo

### 2.1 Clonar o ubicar el repositorio

```bash
cd smartcset_and/app_desktop/src
```

### 2.2 Ejecutar (bootstrap automático)

```bash
python main.py
```

En el **primer arranque**, `bootstrap.py` automáticamente:

1. Crea `app_desktop/runtime/.venv/` si no existe.
2. Instala dependencias de [`requirements.txt`](../requirements.txt).
3. Re-ejecuta el proceso con el intérprete del venv.

No es necesario activar el venv manualmente.

### 2.3 Configuración local

Tras el primer arranque se crea:

```
app_desktop/runtime/app_config.json
```

Contenido por defecto (desarrollo):

```json
{
  "base_url": "https://localhost/smartcset"
}
```

**Editar si el servidor no es localhost:**

```json
{
  "base_url": "https://10.5.213.111/smartcset",
  "verify_tls": false
}
```

| Campo | Descripción |
|-------|-------------|
| `base_url` | URL base del backend (sin barra final) |
| `verify_tls` | `true` = verificar certificado; `false` = laboratorio con cert autofirmado |

### 2.4 Verificar backend accesible

Antes de usar la app, confirmar que el backend responde:

```bash
curl -k https://localhost/smartcset/routers/porteria/v1/catalogos.php
# Debe retornar 401/403 sin sesión (no 404 ni timeout)
```

### 2.5 Usuario de prueba

| Campo | Valor |
|-------|-------|
| Usuario | `porteria` |
| Contraseña | `Porteria2026!` |

(Prellenado en el campo de usuario de la pantalla de login.)

---

## 3. Instalación en PC de portería (ejecutable)

### 3.1 Generar el ejecutable

Desde `app_desktop/` en Windows con PowerShell:

```powershell
# Solo build (queda en dist/)
powershell -ExecutionPolicy Bypass -File packaging\build_exe.ps1

# Build + copia al Escritorio
powershell -ExecutionPolicy Bypass -File packaging\build_exe_to_desktop.ps1
```

**Resultado:** `app_desktop/dist/SmartCSET_Porteria.exe`

**Requisitos para build:**
- Python 3.11+ instalado
- PyInstaller (`pip install pyinstaller`)
- Dependencias de `requirements.txt` instaladas

### 3.2 Desplegar en el PC de portería

1. Copiar `SmartCSET_Porteria.exe` al PC destino.
2. Doble clic para primer arranque.
3. Se crean automáticamente junto al `.exe`:
   - `app_config.json` (desde seed de portería)
   - `logs/smartcset_desktop.log`

### 3.3 Configurar URL del servidor

Editar `app_config.json` junto al `.exe`:

**Laboratorio:**
```json
{
  "base_url": "https://10.5.213.111/smartcset",
  "verify_tls": false
}
```

**Producción institucional (cuando certificado sea válido):**
```json
{
  "base_url": "https://10.5.213.103/smartcset",
  "verify_tls": true
}
```

> El operario de portería **no configura la URL** desde la pantalla de login. Solo TI edita este archivo una vez por instalación.

### 3.4 Arranque sin consola

Alternativa con VBScript (desarrollo):

```
app_desktop/src/iniciar.vbs
```

Lanza `pythonw main.py` sin ventana de consola.

---

## 4. Checklist de verificación post-instalación

| # | Verificación | Cómo |
|---|-------------|------|
| 1 | App abre sin error | Doble clic en `.exe` o `python main.py` |
| 2 | Login exitoso | Usuario `porteria` + contraseña |
| 3 | Cámara detectada | Vista en vivo en panel izquierdo |
| 4 | Catálogos cargan | Formulario muestra tipos doc/persona/entradas |
| 5 | Identificación facial | Persona enrolada es reconocida |
| 6 | Ingreso manual | Documento manual registra en BD |
| 7 | Logout al cerrar | Sesión no queda colgada en `tab_sesiones` |
| 8 | Log sin errores críticos | Revisar `logs/smartcset_desktop.log` |

### Verificación en base de datos (opcional)

```sql
-- Último ingreso biométrico del día
SELECT id_log_ingreso, id_metodo_aut, usr_insert, fec_insert
FROM tab_log_ingresos
WHERE id_metodo_aut = 4
ORDER BY fec_insert DESC
LIMIT 5;
```

`usr_insert` debe ser el usuario real (ej. `porteria`), no `postgres`.

---

## 5. Dependencias del servidor (prerrequisitos backend)

La app **no funciona** sin estos componentes desplegados en el servidor:

| Componente | Verificación |
|------------|--------------|
| Extensión `vector` en PostgreSQL | `SELECT extversion FROM pg_extension WHERE extname = 'vector';` |
| Tabla `tab_enrolamiento_facial` | `\d tab_enrolamiento_facial` |
| Funciones biométricas | `\df fun_*enrolamiento*` |
| Endpoints biometría | `curl` a `/biometria/enrolar.php` (401 sin sesión) |
| `id_metodo_aut = 4` en catálogo | `SELECT * FROM tab_metodos_aut WHERE id_metodo_aut = 4;` |
| Directorio uploads | `frontend/web/public/uploads/biometria/` con permisos de escritura |

Desplegar con los scripts del monorepo:

```bash
bash database/setup_smartcset.sh
# o despliegue selectivo de funciones/migraciones
```

---

## 6. Solución de problemas en instalación

| Problema | Causa | Solución |
|----------|-------|----------|
| "No module named cv2" | venv no creado | Ejecutar `python main.py` (bootstrap lo crea) |
| Ventana negra y cierra | Error de import | Ejecutar desde consola: `python main.py` para ver traceback |
| "No se pudo conectar" | URL o red | Verificar `base_url` y firewall |
| SSL certificate verify failed | Cert autofirmado | `"verify_tls": false` en config |
| Cámara no detectada | Drivers / permisos | Verificar en app de cámara del SO; probar otro índice |
| Login OK pero 403 en portería | Sin menú asignado | Asignar menú portería en `tab_menu_usuarios` |
| Modelos ONNX no encontrados | Build incompleto | Regenerar `.exe` con `packaging/build_exe.ps1` |

---

## 7. Actualización de la aplicación

### Modo desarrollo

```bash
cd app_desktop/src
# Actualizar código (git pull)
python main.py
# bootstrap reinstala deps si requirements.txt cambió
```

### Modo ejecutable

1. Generar nuevo `.exe` con `build_exe.ps1`.
2. Reemplazar el `.exe` en el PC de portería.
3. **Conservar** `app_config.json` existente (no sobrescribir).
4. Verificar con checklist de §4.

---

## Documentos relacionados

- Manual de usuario: [`06-manual-usuario.md`](06-manual-usuario.md)
- Operación: [`10-operacion-y-mantenimiento.md`](10-operacion-y-mantenimiento.md)
- Empaquetado: [`packaging/README.md`](../packaging/README.md)
