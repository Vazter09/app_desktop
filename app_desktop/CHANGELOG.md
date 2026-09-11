# Changelog — App de Escritorio SGI

Formato basado en [Keep a Changelog](https://keepachangelog.com/).  
Versiones lógicas del módulo `app_desktop` (no necesariamente tags de git).

---

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
