# Changelog — App de Escritorio SGI

Formato basado en [Keep a Changelog](https://keepachangelog.com/).  
Versiones lógicas del módulo `app_desktop` (no necesariamente tags de git).

---

## [Sin publicar] — 2026-10-15

### Corregido

- **Lector de cédulas cerraba la sesión** (incidente 2026-10-15): la cola
  de la trama PDF417 (espacios de relleno, Tab, binario) pulsaba «Salir» /
  «Portería» y el resto se escribía en el login. Nueva guardia de teclado
  `ui/scan_guard.py` (bindtag antepuesto al widget con foco: ve cada tecla
  antes que botones, Entries y la navegación por Tab) y detector de ráfagas
  `ui/scan_burst.py` (descarte deslizante de la cola completa).
- Escaneos hechos con una confirmación abierta (o durante identificación
  facial) se descartaban sin aviso: ahora esperan en cola (máx. 5).
- Tecleo manual en el formulario perdía el primer carácter y los tecleados
  despacio (>400 ms): ahora se retienen y se devuelven al Entry.
- **Cédula leída con número equivocado**: con cédulas cuya trama no trae
  `PubDSK_`, el binario de la huella (`|`, `;`) la hacía pasar por QR y se
  tomaba el número de tarjeta del inicio como documento. Ahora la cédula se
  reconoce por su estructura (campo NUIP de 10 dígitos pegado al primer
  apellido), antes que las reglas de QR; si parece cédula pero no hay NUIP
  legible, se pide reintentar en vez de inventar un número.
- **Cédulas de 8–9 dígitos no se encontraban**: el NUIP llega relleno con
  ceros (`00…`) y se buscaba así en la BD. Ahora se quitan los ceros (con y
  sin `PubDSK_`). Ya no se descarta un NUIP en esa posición por "parecer
  fecha".
- Foco en «Documento» al abrir Portería y al cerrar la confirmación (antes
  quedaba en la ventana raíz).
- Apertura de cámara: el hilo ya no llama a Tk; si la página se cierra
  mientras abre, la cámara se libera (error `invalid command name`).

### Cambiado

- «Salir» sin foco por teclado y con confirmación (por defecto «No»).
- Log en nivel INFO: escaneos, cola, ingresos/salidas (`id_ingreso`) y
  logout — sin datos personales.
- Eliminados `bind_intercept_escaneo`, `es_entry_escaneo`,
  `set_antes_documento_enter` (formulario) y `_revertir_insercion_entry`
  (panel), reemplazados por la guardia.

### Eliminado

- Botones «Portería» y «Salida manual» de la topbar (no estaban en
  `cdb8021`). «Portería» solo recargaba la página actual (reiniciaba
  cámara y descartaba la confirmación pendiente).
- Página `ui/pages/salida.py` (tabla «Salidas de hoy», «+ Nueva salida»
  por documento escrito a mano, `metodo_aut=1`), `FacialRecognitionModal`,
  `ui/window_utils.py` y el estilo `NavActive.TButton`, que solo usaba esa
  página. Las salidas se siguen registrando en Portería con lector, rostro
  o huella; la salida tecleando el documento queda solo en la web.

## [1.1.0] — 2026-09-03

### Documentación

- Reorganización de `docs/` según checklist (arc42, C4, Diátaxis, runbooks, ADR, API, BD).
- Eliminado el paquete plano `00`–`11`; contenido migrado a carpetas temáticas.
- Espejo Word (`.docx`) en `docs/word/` vía `_tools/export_to_docx.py` (python-docx).
- Checklist maestro: `docs/CHECKLIST_DOCUMENTACION.md`.

## [1.0.0] — 2026-09-01

### Documentación

- Primer paquete documental profesional en `docs/` (plano 00–11; supersedido en 1.1.0).
- README as-built; avisos en HANDOFF y REGLAS.

---

## [0.9.0] — 2026-07-09

### Añadido

- Foto de enrolamiento (Opción A): servidor guarda JPG, app envía base64.
- `IdentificationConfirmationPanel`: confirmación visual antes de registrar.
- Columna `ruta_foto_enrolamiento` en `tab_enrolamiento_facial`.
- `BiometriaPhotoService` con validación MIME (E6).
- 3 tests nuevos de foto de enrolamiento.
- Modal de reconocimiento facial con cámara en vivo, enrolar e identificar.
- Motor YuNet + SFace (128 dimensiones) in-process.
- Endpoints `biometria/enrolar.php` e `identificar.php`.
- Empaquetado PyInstaller onefile (`SmartCSET_Porteria.exe`).

### Corregido

- `prepare.php`: statement de 4 parámetros para `fun_guardar_enrolamiento_facial`.
- Firma PL/pgSQL duplicada (DROP explícito de firma vieja).
- Modal mostraba frame en vivo en lugar de foto de enrolamiento del servidor.
- Whitelist `id_metodo_aut=4` en `parse_captura_service.php` (Bug 19).
- Dimensión vector 512 → 128 antes de datos reales.

### Pendiente explícito

- Cifrado E2 de fotos en reposo (decisión institucional diferida).
- Motor biométrico en proceso HTTPS separado (Fase 2).
- Consentimiento biométrico en UI (Fase 0 MSPI).
- Validación con persona real frente a cámara en entorno de desarrollo.

---

## [0.8.0] — 2026-07-09 (temprano)

### Añadido

- Biometría facial end-to-end sin foto: enrolar → identificar → ingreso/salida.
- `tab_enrolamiento_facial` con pgvector HNSW.
- `SmartcsetClient` con métodos de biometría.
- Validación TLS contra servidor institucional 10.5.213.103.

---

## [0.7.0] — 2026-07-01

### Añadido

- Login real con sesión PHP (usuario/contraseña).
- Dashboard KPIs (`InicioPage` — código presente).
- Flujo ingreso/salida manual probado end-to-end.
- CRUD entradas (`EntradasPage` — código presente).
- Suite inicial de tests contra backend real (6 casos).
- `bootstrap.py` con auto-venv.
- Tema corporativo SmartCSET en Tkinter.

### Cambiado

- `catalogos.php` ampliado a sesión web (no solo dispositivo móvil).

---

## [0.1.0] — 2026-06

### Añadido

- Estructura inicial del módulo `app_desktop`.
- Cliente HTTP stdlib (`urllib` + cookie jar).
- Pantallas login y shell básico.
- Documento de diseño `REGLAS_APP_ESCRITORIO_SGI.md`.
