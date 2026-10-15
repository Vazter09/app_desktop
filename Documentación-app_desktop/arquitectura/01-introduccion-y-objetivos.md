# 01 — Introducción y objetivos

**Módulo:** app_desktop  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3, 5, 6, 7, 8

---

## 1.1 Propósito de este documento

Describe, en estilo arc42-lite, la arquitectura **as-built** del cliente de escritorio de portería SmartCSET (`app_desktop/`). Refleja el código en `src/` (no `app/`), no un diseño aspiracional.

## 1.2 Qué es el sistema

SmartCSET App de Escritorio es un **cliente de portería** para centros de formación SENA. El personal de control de acceso registra ingresos y salidas mediante:

- Reconocimiento facial (YuNet + SFace 128, in-process)
- Captura manual de documento
- Lectura por pistola (QR / barras / PDF417)

**No es un sistema independiente.** Es un cliente del ecosistema SmartCSET (junto a web y móvil): habla HTTPS con el backend PHP y persiste en la misma PostgreSQL institucional.

## 1.3 Objetivos de negocio

| Objetivo | Cómo lo cumple hoy |
|----------|-------------------|
| Flujo dedicado en portería | App Tkinter a pantalla completa, sin pestañas de navegador |
| Acelerar identificación en horas pico | Facial + confirmación visual + auto-registro (~2,5 s) |
| Biometría en el PC de portería | Enrolamiento e identificación con cámara local; vector en pgvector |
| Un solo puesto operativo | Cámara + formulario + pistola en una pantalla; huella solo UI placeholder |

## 1.4 Objetivos de calidad (resumen)

- **Disponibilidad operativa:** si falla cámara o match facial, el formulario manual sigue usable.
- **Auditoría real:** `usr_insert` = usuario de sesión PHP (no genérico).
- **Misma regla de negocio que web:** ingreso único por día, catálogos y permisos del servidor.
- **Despliegue simple en Windows:** `SmartCSET_Porteria.exe` (PyInstaller onefile).

Detalle en [`10-requisitos-de-calidad.md`](10-requisitos-de-calidad.md).

## 1.5 Stakeholders

| Stakeholder | Interés |
|-------------|---------|
| Operario de portería | Login, identificar/enrolar, registrar ingreso/salida, captura manual |
| Administrador del sistema | CRUD de entradas (código existe; **no expuesto** en UI actual) |
| Backend SmartCSET | Autenticación, reglas, persistencia, biometría |
| TI / instalador | URL en `app_config.json`, `.exe`, cámara y red |
| Cumplimiento MSPI / SENA | Datos biométricos sensibles; ejes 3, 5, 6, 7, 8 |

## 1.6 Criterios de éxito (as-built)

1. Login contra `/auth/v1/login.php` con sesión PHP real.
2. Ciclo facial enrolar → identificar → ingreso/salida con `metodo_aut=4`.
3. Sin match facial, captura manual operativa.
4. Fallo de cámara no bloquea portería (fallback manual).
5. Suite `python -m unittest` en `tests/` contra backend real (34 casos).

## 1.7 Fuera de alcance (explícito)

Base de datos propia; token de dispositivo móvil; motor biométrico en proceso HTTPS separado; SDK de huella real; cifrado E2 de fotos; consentimiento biométrico en UI; caché offline; dashboard/salida/entradas navegables en menú.

## 1.8 Documentos fuente

Visión, SRS, arquitectura y diseño detallado en `docs/01`–`04`; seguridad y trazabilidad en `docs/09` y `docs/11`.
