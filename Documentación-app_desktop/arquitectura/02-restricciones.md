# 02 — Restricciones

**Módulo:** app_desktop  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3, 7, 8

---

## 2.1 Restricciones técnicas

| Restricción | Implicación as-built |
|-------------|---------------------|
| Sin frameworks web en cliente | UI = Tkinter + ttk (stdlib) |
| HTTP sin `requests` | `urllib` + `http.cookiejar` |
| Dependencias mínimas | Solo `opencv-python-headless`, `numpy`, `Pillow`, `tzdata` |
| Python 3.11+ con Tkinter | Desarrollo y bootstrap de `runtime/.venv` |
| Código en `src/` | Punto de entrada `src/main.py`; tests en `tests/` |
| Motor facial in-process | YuNet + SFace en el mismo proceso; **no** HTTPS loopback |
| Webcam requerida para facial | Flujo manual no depende de cámara |
| HTTPS al backend | Obligatorio; `verify_tls` configurable en JSON |
| Intranet SENA | Sin garantía de internet tras instalación |
| Empaquetado Windows | PyInstaller onefile → `SmartCSET_Porteria.exe` |

## 2.2 Restricciones organizativas / de proceso

- Misma consigna MSPI + Fase 0/1 que backend/web (desde 2026-07-09); no hay excepción “porque es desktop”.
- La app **no redefine** reglas de negocio: las hereda del backend (ingreso abierto, scope de entrada, menú portería).
- Operario **no** configura la URL del servidor; TI edita `app_config.json` una vez.
- Seed de laboratorio puede usar `verify_tls: false` (cert autofirmado); producción institucional exige `true` con cert válido.

## 2.3 Restricciones de convención (monorepo)

| Norma | Aplicación |
|-------|------------|
| PEP8 / `ruff check` | Código Python nuevo |
| Tests sin mocks de BD | Integración contra PostgreSQL + PHP reales |
| Sin Composer / sin deps PHP nuevas desde desktop | Cliente puro HTTP |
| Whitelist `id_metodo_aut` en servidor | 1 manual, 2 QR, 3 barras, 4 facial, 5 huella (placeholder) |

## 2.4 Restricciones de seguridad heredadas

- Autenticación = sesión web PHP (`PHPSESSID`), no token de `tab_dispositivos_porteria`.
- Rate limiting de login (E3) y hardening de sesión (E4) viven en el servidor.
- Validación MIME de fotos (E6) en `BiometriaPhotoService` del backend.
- Cifrado en reposo de fotos/vectores (E2) **diferido** institucionalmente.

## 2.5 Restricciones de UI actuales

- Post-login: navegación fija a pantalla de **ingreso** (sin sidebar).
- Páginas `Inicio`, `Salida` y `Entradas` tienen código pero están **huérfanas** (no menú / no registro completo).
- Área de huella = placeholder visual; `motor/huella.py` genera templates sintéticos.

## 2.6 Entorno de despliegue asumido

| Elemento | Valor típico |
|----------|--------------|
| SO portería | Windows 10/11 |
| Servidor lab | `https://10.5.213.111/smartcset` |
| Servidor institucional | `https://10.5.213.103/smartcset` |
| RAM mínima | 4 GB (8 GB recomendado) |
| Disco | ~500 MB (app + ONNX + venv en modo desarrollo) |
