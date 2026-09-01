# 04 — Diseño detallado

**Módulo:** App de Escritorio SGI — SmartCSET  
**Versión documental:** 1.0.0  
**Fecha:** 2026-09-01

---

## 1. Mapa de módulos

### 1.1 Núcleo de aplicación

| Archivo | Clase / función principal | Responsabilidad |
|---------|--------------------------|-----------------|
| [`src/main.py`](../src/main.py) | `SmartcsetDesktopApp` | Ciclo de vida: login → shell → logout |
| [`src/bootstrap.py`](../src/bootstrap.py) | `ensure_venv()` | Crea venv, instala deps, re-ejecuta proceso |
| [`src/config.py`](../src/config.py) | `AppConfig` | `base_url`, `verify_tls` desde JSON |
| [`src/app_paths.py`](../src/app_paths.py) | `resource_root()`, `writable_root()`, `is_frozen()` | Rutas dev vs empaquetado |
| [`src/app_log.py`](../src/app_log.py) | `setup_logging()`, `get_logger()` | Log rotativo, flush en errores |
| [`src/smartcset_client.py`](../src/smartcset_client.py) | `SmartcsetClient` | Cliente HTTP con sesión PHP |

### 1.2 Interfaz de usuario

| Archivo | Clase principal | Responsabilidad |
|---------|-----------------|-----------------|
| [`src/ui/login_view.py`](../src/ui/login_view.py) | `LoginView` | Formulario login |
| [`src/ui/shell.py`](../src/ui/shell.py) | `AppShell` | Topbar, navegación, logout |
| [`src/ui/pages/ingreso.py`](../src/ui/pages/ingreso.py) | `IngresoPage` | Contenedor de reconocimiento |
| [`src/ui/pages/inicio.py`](../src/ui/pages/inicio.py) | `InicioPage` | KPIs (huérfano en UI) |
| [`src/ui/pages/salida.py`](../src/ui/pages/salida.py) | `SalidaPage` | Salidas del día (huérfano en UI) |
| [`src/ui/pages/entradas.py`](../src/ui/pages/entradas.py) | `EntradasPage` | CRUD puertas (no registrada) |
| [`src/ui/facial_modal.py`](../src/ui/facial_modal.py) | `FacialRecognitionPanel` | Núcleo biométrico + registro |
| [`src/ui/ingreso_form_panel.py`](../src/ui/ingreso_form_panel.py) | `IngresoFormPanel` | Formulario manual/pistola |
| [`src/ui/identification_confirmation_modal.py`](../src/ui/identification_confirmation_modal.py) | `IdentificationConfirmationPanel` | Confirmación post-match |
| [`src/ui/camera.py`](../src/ui/camera.py) | `CameraSource` | Captura OpenCV |
| [`src/ui/huella_scan.py`](../src/ui/huella_scan.py) | `HuellaScanCanvas` | Animación huella (placeholder) |
| [`src/ui/scan_capture.py`](../src/ui/scan_capture.py) | `parse_captura_escaneo()` | Parser pistola |
| [`src/ui/field_validators.py`](../src/ui/field_validators.py) | `sanear_documento()`, etc. | Validación campos |
| [`src/ui/theme.py`](../src/ui/theme.py) | `apply_theme()` | Colores corporativos |
| [`src/ui/responsive.py`](../src/ui/responsive.py) | `sx()`, `sfont()`, `init()` | Escalado responsive |
| [`src/ui/format_utils.py`](../src/ui/format_utils.py) | `format_db_timestamp()` | Formato fechas BD |
| [`src/ui/window_utils.py`](../src/ui/window_utils.py) | `centrar_ventana()` | Utilidad ventanas |

### 1.3 Motor biométrico

| Archivo | Clase / constante | Responsabilidad |
|---------|-------------------|-----------------|
| [`src/motor/embeddings.py`](../src/motor/embeddings.py) | `FaceEmbedder`, `EMBEDDING_DIMENSION=128` | YuNet + SFace |
| [`src/motor/huella.py`](../src/motor/huella.py) | `capturar_template_prueba()` | Template sintético SHA-256 |
| [`src/motor/models/*.onnx`](../src/motor/models/) | — | Modelos vendorizados |

---

## 2. Flujo: arranque de la aplicación

```
1. python main.py (o doble clic en .exe)
2. bootstrap.ensure_venv()
   ├─ Si frozen → continúa
   └─ Si no frozen → crea runtime/.venv si falta, re-ejecuta con ese Python
3. AppConfig.load() → lee/crea app_config.json
4. setup_logging()
5. SmartcsetClient(base_url, verify_tls)
6. tk.Tk() + init_responsive() + apply_theme()
7. LoginView → on_success → AppShell
8. AppShell.navigate("ingreso") → IngresoPage → FacialRecognitionPanel
```

---

## 3. Flujo: login

```
Operario ingresa usuario/clave
  → LoginView._on_submit()
  → client.login(usuario, clave)
  → POST /routers/auth/v1/login.php {usuario, clave, origen: "desktop"}
  → Servidor valida bcrypt, crea sesión, Set-Cookie PHPSESSID
  → Cliente verifica has_session_cookie()
  → Callback on_success(usuario_data)
  → AppShell reemplaza LoginView
```

**Errores:**
- `SmartcsetApiError` → mensaje del servidor (clave incorrecta, usuario inactivo).
- `SmartcsetConnectionError` → red caída, TLS inválido, URL incorrecta.

---

## 4. Flujo: identificación y registro automático

```
1. FacialRecognitionPanel inicia loop de cámara (CameraSource)
2. Operario presiona "Identificar"
3. FaceEmbedder.extraer(ultimo_frame) → embedding[128]
4. client.biometria_identificar(embedding)
5. Si match:
   a. Priorizar foto_base64 del servidor (enrolamiento real)
   b. Mostrar IdentificationConfirmationPanel embebido
   c. AUTO_REGISTRO_MS = 2500 ms → registro automático si no cancela
6. _resolver_modo_acceso(documento) → "ingreso" | "salida"
7. client.ingreso_consultar() o salida_consultar()
8. client.ingreso_registrar() o salida_registrar() con metodo_aut=4
```

**Constantes relevantes en `facial_modal.py`:**
- Ventana de 5 minutos post-ingreso para re-captura.
- Prioridad servidor-primero para foto (fix Bug UX 2026-07-09).

---

## 5. Flujo: enrolamiento

```
1. Operario ingresa documento en formulario
2. Presiona "Enrolar" (o enrolamiento tras registro manual)
3. FaceEmbedder extrae embedding + calidad
4. Último frame → JPG → base64
5. client.biometria_enrolar(documento, embedding, calidad, foto_base64, forzar?)
6. Servidor:
   a. BiometriaPhotoService valida MIME y guarda JPG
   b. fun_guardar_enrolamiento_facial(id, vector, calidad, ruta_foto)
7. Retorna id_enrolamiento
```

**Parámetro `forzar=True`:** solo desde "Capturar Rostro"; reemplaza enrolamiento existente.

---

## 6. Flujo: captura manual

```
1. Operario completa tipo doc + documento + datos en IngresoFormPanel
2. Opcional: pistola escanea → parse_captura_escaneo() rellena campos
3. client.ingreso_consultar(documento) → datos persona + estado acceso
4. Operario confirma → client.ingreso_registrar(payload)
   - metodo_aut = 1 (manual), 2 (QR), 3 (barras) según origen
5. Si persona nueva → flujo de novedad según respuesta servidor
```

---

## 7. Flujo: cierre de aplicación

```
WM_DELETE_WINDOW / señal SIGTERM
  → _on_close()
  → client.logout()  (GET logout.php, clear cookies)
  → root.destroy()
atexit también invoca logout si no se hizo
```

---

## 8. Diseño de `SmartcsetClient`

### Excepciones

| Clase | Cuándo |
|-------|--------|
| `SmartcsetApiError` | `ok: false` en JSON o HTTP 4xx/5xx con mensaje |
| `SmartcsetConnectionError` | Red, timeout, JSON inválido, redirect |

### Contrato de respuesta

```json
{
  "ok": true,
  "data": { ... }
}
```

o

```json
{
  "ok": false,
  "error": "Mensaje legible en español"
}
```

### Thread safety

Todas las operaciones HTTP usan `self._lock` (RLock) para serializar acceso al opener y cookie jar.

---

## 9. Diseño de `FaceEmbedder`

| Parámetro | Valor |
|-----------|-------|
| Detector | YuNet (`face_detection_yunet_2023mar.onnx`) |
| Reconocedor | SFace (`face_recognition_sface_2021dec.onnx`) |
| Dimensión salida | 128 floats |
| Umbral detección | `YUNET_SCORE_THRESHOLD = 0.22` (ajustado para webcams de portería) |
| Max lado imagen | 640 px |

**Singleton:** `_get_embedder()` en `facial_modal.py` evita recargar modelos ONNX en cada captura.

**Ruta modelos en Windows empaquetado:** `%ProgramData%\SmartCSET\models\` (evita paths con caracteres no-ASCII).

---

## 10. Diseño de UI — layout post-login

```
┌─────────────────────────────────────────────────────────────┐
│ TOPBAR: SMARTCSET | breadcrumb | usuario | [Salir]          │
├──────────────┬──────────────────────────┬─────────────────────┤
│              │                          │                     │
│   CÁMARA     │   FORMULARIO CENTRAL     │   HUELLA (UI)       │
│   en vivo    │   documento, nombres,    │   placeholder       │
│   botones:   │   tipo persona, entrada  │   animación PNG     │
│   Identificar│   botones registrar      │                     │
│   Enrolar    │                          │                     │
│              │                          │                     │
│   [Panel confirmación embebido tras match]                  │
└──────────────┴──────────────────────────┴─────────────────────┘
```

**No hay sidebar** en la implementación actual. Páginas `inicio`, `salida` y `entradas` existen en código pero no tienen entrada de menú visible.

---

## 11. Páginas huérfanas (código sin exposición UI)

| Página | Registrada en `_pages` | Navegable desde UI | Notas |
|--------|------------------------|-------------------|-------|
| `inicio` | Sí | No | KPIs implementados |
| `ingreso` | Sí | **Sí** (default post-login) | Pantalla principal |
| `salida` | Sí | No | Salida se resuelve desde ingreso |
| `entradas` | **No** | No | CRUD completo pero sin registro |

Para exponer estas páginas en el futuro, agregar controles de navegación en `AppShell` y registrar `entradas` en `_pages`.

---

## 12. Empaquetado — hook de runtime

[`packaging/pyi_runtime_hook_config.py`](../packaging/pyi_runtime_hook_config.py) siembra `app_config.json` desde `app_config.porteria.json` si no existe junto al `.exe`.

Valores por defecto del seed:

```json
{
  "base_url": "https://10.5.213.111/smartcset",
  "verify_tls": false
}
```

---

## Documentos relacionados

- Arquitectura general: [`03-arquitectura.md`](03-arquitectura.md)
- Contrato API: [`07-contrato-integracion.md`](07-contrato-integracion.md)
- Manual de usuario: [`06-manual-usuario.md`](06-manual-usuario.md)
