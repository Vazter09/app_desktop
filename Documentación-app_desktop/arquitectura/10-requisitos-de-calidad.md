# 10 — Requisitos de calidad

**Módulo:** app_desktop  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3, 5, 6, 7, 8

---

## 10.1 Árbol de calidad (as-built)

| Atributo | Meta operativa | Evidencia actual |
|----------|----------------|------------------|
| Funcionalidad | RF-01…RF-11 operativos | SRS + matriz trazabilidad |
| Disponibilidad operativa | Portería usable sin facial | Fallback manual RF-09 |
| Seguridad | Sesión + HTTPS + validación E6 | docs/09, tests biometría |
| Fiabilidad | Sin crashes por excepción no manejada | Hooks en `main.py`; logout al cerrar |
| Auditoría | Usuario real en BD | `usr_insert` = sesión |
| Mantenibilidad | PEP8, deps fijadas, código en `src/` | Política monorepo + `ruff` |
| Desplegabilidad | Un `.exe` + JSON | PyInstaller + manual instalación |
| Observabilidad | Logs rotativos sin PII biométrica | `app_log.py` |
| Rendimiento percibido | Cámara usable; ID facial interactiva | Manual M2/M3; sin bench formal |
| Usabilidad | Una pantalla post-login | Sin sidebar; topbar Salir |

## 10.2 Escenarios de calidad

### Q-01 — Continuidad ante fallo biométrico

- **Estímulo:** cámara ausente o sin match.
- **Respuesta:** formulario y pistola siguen disponibles.
- **Medida:** M5 manual; no hay test UI automatizado.

### Q-02 — Integridad del método de autenticación

- **Estímulo:** ingreso tras identificación facial.
- **Respuesta:** `id_metodo_aut = 4` en `tab_log_ingresos`.
- **Medida:** `test_ingreso_por_identificacion_usa_metodo_aut_biometrico`.

### Q-03 — Confidencialidad en tránsito

- **Estímulo:** login e identificación.
- **Respuesta:** canal HTTPS; con `verify_tls: true` se valida el certificado.
- **Medida:** configuración + prueba manual M8; lab puede relajar.

### Q-04 — Sesión no colgada

- **Estímulo:** cierre de ventana.
- **Respuesta:** `logout` + cookie clear.
- **Medida:** checklist post-install; tests de relogin.

### Q-05 — Rechazo de foto inválida (E6)

- **Estímulo:** enrolar con base64 basura / sin foto.
- **Respuesta:** error servidor; no archivo corrupto.
- **Medida:** tests `test_enrolar_sin_foto_*`, `test_enrolar_foto_invalida_*`.

### Q-06 — Parseo robusto de pistola

- **Estímulo:** PDF417 / QR / barras / basura RH.
- **Respuesta:** campos saneados; RH no como nombre/documento.
- **Medida:** 17 tests en `test_scan_capture.py`.

## 10.3 Requisitos no funcionales (mapa)

| ID | Requisito | Estado |
|----|-----------|--------|
| RNF-01 | HTTPS + TLS configurable | ✅ |
| RNF-02 | Timeout HTTP 15 s | ✅ |
| RNF-03 | Cliente HTTP thread-safe | ✅ |
| RNF-04 | No follow redirects | ✅ |
| RNF-05 | Logs rotativos 2 MiB × 5 | ✅ |
| RNF-06 | PEP8 | ✅ política |
| RNF-07 | Deps `==` en requirements | ✅ |
| RNF-08 | Tests sin mocks BD | ✅ |
| RNF-09 | Tema corporativo | ✅ |
| RNF-10 | Responsive básico | ✅ |

## 10.4 Metas de prueba

| Suite | Casos | Rol calidad |
|-------|------:|-------------|
| `test_smartcset_client.py` | 17 | Integración auth/portería/biometría/huella placeholder |
| `test_scan_capture.py` | 17 | Integridad de parseo y validadores |
| **Total** | **34** | Gate local pre-commit recomendado |

Ejecución: `cd app_desktop/tests && python -m unittest discover -v`.

## 10.5 Deudas que afectan calidad

- Sin CI → regresiones no bloquean merge automáticamente.
- Sin tests UI Tkinter → Q-01 y layouts dependen de prueba manual.
- Sin medición formal de latencia facial.
- `verify_tls: false` en seeds de lab debilita Q-03 si se copia a producción.
- Páginas huérfanas: código no ejercitado por operarios reales.

Trazabilidad RF↔tests↔MSPI: [`../11-matriz-trazabilidad.md`](../11-matriz-trazabilidad.md).
