# 06 — Vista de runtime

**Módulo:** app_desktop  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3, 5, 6, 8

---

## 6.1 Arranque

```mermaid
sequenceDiagram
  participant User as Operario_TI
  participant Main as main.py
  participant Boot as bootstrap
  participant Cfg as AppConfig
  participant UI as LoginView
  participant Shell as AppShell

  User->>Main: python main.py / .exe
  Main->>Boot: ensure_venv()
  Note over Boot: frozen: no-op; else runtime/.venv
  Main->>Cfg: load app_config.json
  Main->>Main: setup_logging + SmartcsetClient
  Main->>UI: mostrar login
  UI->>Shell: on_success
  Shell->>Shell: navigate ingreso
```

Orden efectivo:

1. `bootstrap.ensure_venv()` (crea venv e instala deps si hace falta).
2. `AppConfig.load()` → `base_url`, `verify_tls`.
3. Logging rotativo (`smartcset_desktop.log`).
4. `SmartcsetClient(base_url, verify_tls)`.
5. `tk.Tk()` + tema + responsive.
6. `LoginView` → éxito → `AppShell.navigate("ingreso")`.

## 6.2 Login y sesión

1. Operario envía usuario/clave.
2. `POST /routers/auth/v1/login.php` con `origen: "desktop"`.
3. Servidor valida bcrypt, emite `Set-Cookie: PHPSESSID`.
4. Cliente exige cookie de sesión antes de continuar.
5. Errores: `SmartcsetApiError` (negocio) o `SmartcsetConnectionError` (red/TLS/URL).

## 6.3 Identificación facial y registro

```mermaid
sequenceDiagram
  participant Op as Operario
  participant UI as FacialRecognitionPanel
  participant Motor as FaceEmbedder
  participant Client as SmartcsetClient
  participant API as Backend_PHP
  participant DB as PostgreSQL

  Op->>UI: Identificar
  UI->>Motor: extraer frame
  Motor-->>UI: embedding 128
  UI->>Client: biometria_identificar
  Client->>API: POST biometria/identificar.php
  API->>DB: fun_identificar_persona_por_rostro
  DB-->>API: id_persona + distancia
  API-->>Client: persona + foto_base64
  Client-->>UI: match
  UI->>UI: IdentificationConfirmationPanel
  Note over UI: foto servidor primero; auto 2.5s
  UI->>Client: resolver modo + registrar
  Client->>API: ingreso/salida registrar.php
  API->>DB: fun_registrar_*
```

Notas runtime:

- Cámara corre en loop OpenCV; identificación usa el último frame.
- `_resolver_modo_acceso()` consulta backend para decidir ingreso vs salida.
- Registro facial usa `id_metodo_aut = 4`.
- Cancelar en confirmación **no** registra.

## 6.4 Enrolamiento

1. Documento en formulario + “Enrolar” (o flujo post-manual según UI).
2. `FaceEmbedder` → embedding + calidad; frame → JPG base64.
3. `POST biometria/enrolar.php`.
4. Servidor valida MIME (E6), guarda JPG, `fun_guardar_enrolamiento_facial` (4 args: incluye `ruta_foto_enrolamiento`).
5. `forzar=True` solo desde captura explícita de reemplazo.

## 6.5 Captura manual / pistola

1. Campos en `IngresoFormPanel` o escaneo HID.
2. `parse_captura_escaneo()` clasifica método 2 (QR) o 3 (barras/PDF417).
3. Consultar → confirmar → registrar con `metodo_aut` correspondiente (1 si teclado puro).

## 6.6 Cierre

- `WM_DELETE_WINDOW` / señales → `client.logout()` → destroy.
- `atexit` también intenta logout si no se hizo.
- Objetivo: no dejar sesión colgada en `tab_sesiones`.

## 6.7 Concurrencia

| Recurso | Protección |
|---------|------------|
| Opener + cookie jar | `threading.RLock` en cliente |
| Modelos ONNX | Singleton del embedder |
| UI Tkinter | Actualizaciones desde hilo principal (patrón de la app) |

## 6.8 Fallos y degradación

| Fallo | Comportamiento runtime |
|-------|------------------------|
| Sin cámara / motor caído | Formulario manual permanece |
| Sin match facial | Operario usa documento |
| Timeout HTTP (15 s) | Error de conexión visible |
| TLS inválido | Falla salvo `verify_tls: false` explícito |
| 403 portería | Usuario sin menú en servidor |
