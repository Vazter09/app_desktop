# 08 — Conceptos transversales

**Módulo:** app_desktop  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3, 5, 6, 7, 8

---

## 8.1 Seguridad y sesión

- Autenticación: sesión PHP compartida con la web; cookie solo en memoria (`CookieJar`).
- Logout al cerrar ventana y en `atexit`.
- HTTPS obligatorio; verificación de certificado gobernada por `verify_tls` (override explícito en JSON, no silencioso).
- No se loguean documentos, embeddings ni fotos en texto plano.
- Confirmación visual post-match reduce registros erróneos (E1/E4).

Detalle: [`../09-seguridad-mspi.md`](../09-seguridad-mspi.md).

## 8.2 Datos sensibles (tratamiento transversal)

| Dato | En cliente | En servidor |
|------|------------|-------------|
| Embedding 128 | RAM + HTTPS | `tab_enrolamiento_facial` (pgvector) |
| Foto enrolamiento | Base64 en tránsito / UI | Filesystem `uploads/biometria/` |
| Documento | Formulario + payloads | `tab_personas` / logs |
| Sesión | Memoria | `tab_sesiones` |
| Huella | Placeholder sintético | Campo / endpoints de prueba |

Cifrado E2 en reposo: **no** implementado (diferido).

## 8.3 Logging y observabilidad

- Archivo: `smartcset_desktop.log`.
- Rotación: 2 MiB × 5.
- Nivel default: WARNING.
- Auditoría de negocio: canal servidor (`usr_insert`, SIEM/KPIs web) — la app no mantiene SIEM propio.

## 8.4 Manejo de errores

| Capa | Patrón |
|------|--------|
| HTTP | `SmartcsetApiError` / `SmartcsetConnectionError` |
| UI | Mensajes legibles al operario |
| Proceso | Hooks de excepción global en `main.py` |
| Biometría | Fallback a captura manual (RF-09) |

## 8.5 Validación e integridad de entrada

- Cliente: `field_validators` + parseo defensivo de pistola.
- Servidor: validación de payloads, MIME real en fotos (E6), reglas PL/pgSQL.
- Defensa en profundidad: la app **nunca** es la única barrera.

## 8.6 Identidad visual y UX

- Colores en `ui/theme.py` alineados con tokens corporativos del backend.
- Escalado básico por resolución (`responsive.py`).
- Layout post-login fijo de tres columnas (cámara | formulario | huella UI).
- Sin sidebar; topbar con usuario y Salir.

## 8.7 Empaquetado y rutas

Concepto transversal: el mismo código distingue:

- Recursos embebidos (`resource_root`) vs
- Datos escribibles (`writable_root`: config y logs).

Evita escribir dentro de `_MEIPASS` en modo frozen.

## 8.8 Pruebas como concepto de calidad

- Integración real sin mocks de BD.
- Limpieza en `tearDown` (`tests/common.py`).
- 34 casos: HTTP/biometría + parseo/validación.
- Sin CI ni tests UI Tkinter (deuda conocida).

## 8.9 Configuración

Único archivo de runtime relevante para TI: `app_config.json` (`base_url`, `verify_tls`). No hay feature flags locales para biometría o menús; el alcance de UI lo fija el código de `AppShell`.

## 8.10 I18N / mensajes

Mensajes de error de negocio vienen del servidor en español; la UI desktop también está en español. No hay capa i18n multi-idioma.
