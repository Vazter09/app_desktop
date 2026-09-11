# Qué debe contener un proyecto de software

**Módulo:** app_desktop  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 7

**Tipo:** Anexo — checklist de ingeniería vs estado real del módulo

---

## Propósito

Describe los **artefactos estándar** que un proyecto profesional debe incluir. Cada sección explica **qué es**, **para qué sirve** y **cómo se materializa (o no) en `app_desktop`**.

Usos:

1. Checklist genérico de buenas prácticas.
2. Autoevaluación as-built del módulo frente a ese estándar.

---

## 1. Identidad y gobernanza

| Artefacto | Ubicación | Estado |
|-----------|-----------|--------|
| README principal | [`../../README.md`](../../README.md) | **Presente** |
| Índice de entrega / checklist | [`../CHECKLIST_DOCUMENTACION.md`](../CHECKLIST_DOCUMENTACION.md), [`../README.md`](../README.md) | **Presente** |
| Changelog | [`../historial/CHANGELOG.md`](../historial/CHANGELOG.md) | **Presente** |
| Licencia | — | **Ausente** — decisión legal del SENA |
| Versión semver en código | — | **Ausente** |
| Responsables / contacto | [`../../HANDOFF.md`](../../HANDOFF.md) | **Parcial** |

---

## 2. Definición del producto

| Artefacto | Ubicación | Estado |
|-----------|-----------|--------|
| Visión y alcance | [`../01-vision-y-alcance.md`](../01-vision-y-alcance.md) | **Presente** (paquete fuente) |
| Especificación de requisitos | [`../02-especificacion-requisitos.md`](../02-especificacion-requisitos.md) | **Presente** |
| Casos de uso / diseño | [`../04-diseno-detallado.md`](../04-diseno-detallado.md) | **Presente** |
| Matriz de trazabilidad | [`matriz-trazabilidad.md`](matriz-trazabilidad.md) | **Presente** |
| Arquitectura arc42-lite | [`../arquitectura/`](../arquitectura/) | Según checklist |

---

## 3. Código fuente y estructura

| Aspecto | Detalle | Estado |
|---------|---------|--------|
| Punto de entrada | [`../../src/main.py`](../../src/main.py) | **Presente** |
| Cliente HTTP | [`../../src/smartcset_client.py`](../../src/smartcset_client.py) | **Presente** |
| UI (Tkinter) | [`../../src/ui/`](../../src/ui/) | **Presente** |
| Motor biométrico | [`../../src/motor/`](../../src/motor/) | **Presente** (in-process, 128 dims) |
| Estándar Python | PEP8, `snake_case`, ≤79 chars | **Presente** |
| Reglas de arquitectura | [`../../REGLAS_APP_ESCRITORIO_SGI.md`](../../REGLAS_APP_ESCRITORIO_SGI.md) | **Parcial** (diseño vs as-built) |

```
app_desktop/
├── src/          ← código fuente
├── tests/        ← pruebas automatizadas
├── packaging/    ← build PyInstaller
├── docs/         ← documentación (Diátaxis / arc42 / runbooks)
│   ├── operacion/
│   ├── usuario/
│   ├── historial/
│   ├── anexos/
│   └── …
└── runtime/      ← config, logs, venv (no versionado)
```

---

## 4. Configuración y secretos

| Artefacto | Ubicación | Estado |
|-----------|-----------|--------|
| Config local | `runtime/app_config.json` (`base_url`, `verify_tls`) | **Presente** — no versionado |
| Seed empaquetado | [`../../packaging/app_config.porteria.json`](../../packaging/app_config.porteria.json) | **Presente** |
| Credenciales en repo | — | **Correcto** — no se versionan |
| `.env` para tests | Raíz monorepo (solo `tests/common.py`) | **Presente** |

---

## 5. Dependencias

| Artefacto | Ubicación | Estado |
|-----------|-----------|--------|
| `requirements.txt` | [`../../requirements.txt`](../../requirements.txt) | **Presente** |
| Versiones fijadas (`==`) | opencv, numpy, Pillow | **Presente** |
| Excepción `>=` | `tzdata>=2024.1` | **Parcial** |
| Bootstrap automático | [`../../src/bootstrap.py`](../../src/bootstrap.py) | **Presente** |

Permitidas: `opencv-python-headless`, `numpy`, `Pillow`, `tzdata`. HTTP con stdlib (`urllib`).

---

## 6. Build y empaquetado

| Artefacto | Ubicación | Estado |
|-----------|-----------|--------|
| Spec PyInstaller | [`../../packaging/SmartCSET_Porteria.spec`](../../packaging/SmartCSET_Porteria.spec) | **Presente** |
| Scripts de build | `packaging/build_exe.ps1`, `build_exe_to_desktop.ps1` | **Presente** |
| Guía empaquetado | [`../../packaging/README.md`](../../packaging/README.md) | **Presente** |
| Firma de código | — | **Ausente** |

Resultado: `dist/SmartCSET_Porteria.exe` (onefile, sin consola).  
Runbook: [`../operacion/despliegue-produccion.md`](../operacion/despliegue-produccion.md).

---

## 7. Pruebas

| Tipo | Ubicación | Estado |
|------|-----------|--------|
| Integración HTTP | [`../../tests/test_smartcset_client.py`](../../tests/test_smartcset_client.py) | **Presente** |
| Unitarios escáner | [`../../tests/test_scan_capture.py`](../../tests/test_scan_capture.py) | **Presente** |
| Sin mocks de BD | Política monorepo | **Presente** |
| Cobertura / tests UI | — | **Ausente** |

Plan fuente: [`../08-plan-y-evidencia-pruebas.md`](../08-plan-y-evidencia-pruebas.md).

---

## 8. Integración continua (CI/CD)

| Aspecto | Estado |
|---------|--------|
| Pipeline CI para el módulo | **Ausente** |
| Pre-commit a nivel `app_desktop` | **Ausente** |

Las pruebas se ejecutan manualmente contra un backend accesible.

---

## 9. Documentación

| Documento | Audiencia | Estado |
|-----------|-----------|--------|
| Tutorial / guías usuario | Operario | [`../usuario/`](../usuario/) — **Presente** |
| Runbooks instalación / prod | TI | [`../operacion/`](../operacion/) — **Presente** |
| Arquitectura | Desarrollador | [`../03-arquitectura.md`](../03-arquitectura.md) + `arquitectura/` |
| Contrato API | Integrador | [`../07-contrato-integracion.md`](../07-contrato-integracion.md) / `api/` |
| Seguridad MSPI | Auditor | [`../09-seguridad-mspi.md`](../09-seguridad-mspi.md), [`../operacion/incidentes-seguridad.md`](../operacion/incidentes-seguridad.md) |
| Mockups HTML / video capacitación | — | **Ausente** |

---

## 10. Seguridad y cumplimiento

| Aspecto | Estado |
|---------|--------|
| Mapeo MSPI Fase 0-1 | Fuente + runbooks — **Presente** |
| TLS tránsito (E8) | **Parcial** — configurable; lab usa `false` |
| Cifrado reposo fotos (E2) | **Ausente** — diferido institucionalmente |
| Consentimiento biométrico UI | **Ausente** |
| Rate limiting (E3) | **Presente** — heredado del servidor |
| Validación uploads (E6) | **Presente** — servidor |
| Auditoría `usr_insert` | **Presente** |

---

## 11. Operación y soporte

| Aspecto | Estado |
|---------|--------|
| Logs rotativos | **Presente** |
| Runbooks operación | [`../operacion/`](../operacion/) — **Presente** |
| Backup alcance cliente | [`../operacion/backup-restauracion.md`](../operacion/backup-restauracion.md) |
| Monitoreo / SLA formal | **Ausente** |

---

## 12. Entrega final

| Entregable | Estado |
|------------|--------|
| Ejecutable Windows | `SmartCSET_Porteria.exe` — **Presente** (build manual) |
| Documentación Markdown | `app_desktop/docs/` — **Presente** |
| Evidencia de pruebas | unittest manual — **Parcial** |
| Acta de aceptación | **Ausente** |

---

## Matriz resumen

| # | Área | Estado global |
|---|------|---------------|
| 1 | Identidad y gobernanza | **Parcial** |
| 2 | Definición del producto | **Presente** |
| 3 | Código fuente | **Presente** |
| 4 | Configuración y secretos | **Presente** |
| 5 | Dependencias | **Presente** |
| 6 | Build y empaquetado | **Presente** |
| 7 | Pruebas | **Parcial** |
| 8 | CI/CD | **Ausente** |
| 9 | Documentación | **Presente** |
| 10 | Seguridad y cumplimiento | **Parcial** |
| 11 | Operación | **Parcial** |
| 12 | Entrega final | **Parcial** |

---

## Lectura recomendada

| Rol | Siguiente documento |
|-----|---------------------|
| Revisor / auditor | [`../CHECKLIST_DOCUMENTACION.md`](../CHECKLIST_DOCUMENTACION.md) |
| Operario | [`../usuario/tutorial-primer-uso.md`](../usuario/tutorial-primer-uso.md) |
| TI | [`../operacion/instalacion.md`](../operacion/instalacion.md) |
| Auditor MSPI | [`../operacion/incidentes-seguridad.md`](../operacion/incidentes-seguridad.md) |
| Trazabilidad RF | [`matriz-trazabilidad.md`](matriz-trazabilidad.md) |
