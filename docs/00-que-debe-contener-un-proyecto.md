# 00 — Qué debe contener un proyecto de software

**Módulo:** App de Escritorio SGI — SmartCSET  
**Versión documental:** 1.0.0  
**Fecha:** 2026-09-01

---

## Propósito de este documento

Esta guía describe los **artefactos estándar** que un proyecto de software profesional debe incluir para ser entregable, auditable y mantenible. Cada sección explica **qué es**, **para qué sirve** y **cómo se materializa (o no) en `app_desktop`**, el cliente de escritorio de portería de SmartCSET.

El lector puede usar este documento de dos formas:

1. Como **checklist genérico** de buenas prácticas de ingeniería de software.
2. Como **autoevaluación** del estado real del módulo `app_desktop` frente a ese estándar.

---

## 1. Identidad y gobernanza del proyecto

### Qué es

Información que identifica el producto, su versión, responsables, repositorio y políticas de contribución.

### Para qué sirve

Permite a revisores, auditores y nuevos integrantes ubicar el proyecto sin depender del conocimiento oral del equipo.

### En `app_desktop`

| Artefacto | Ubicación | Estado |
|-----------|-----------|--------|
| README principal | [`README.md`](../README.md) | **Presente** — descripción, requisitos, ejecución |
| Índice de entrega | [`docs/README.md`](README.md) | **Presente** (este paquete) |
| Changelog | [`CHANGELOG.md`](../CHANGELOG.md) | **Presente** |
| Licencia | — | **Ausente** — decisión legal del SENA, no definida en el módulo |
| Versión semver en código | — | **Ausente** — no hay `__version__` ni etiqueta formal |
| Responsables / contacto | [`HANDOFF.md`](../HANDOFF.md) | **Parcial** — nota interna de ingeniería, no documento de entrega |

---

## 2. Definición del producto

### Qué es

Documentos que responden: qué problema resuelve, para quién, qué incluye y qué queda fuera.

### Para qué sirve

Evita ambigüedad entre lo prometido y lo entregado; base para pruebas de aceptación.

### En `app_desktop`

| Artefacto | Ubicación | Estado |
|-----------|-----------|--------|
| Visión y alcance | [`01-vision-y-alcance.md`](01-vision-y-alcance.md) | **Presente** |
| Especificación de requisitos (SRS) | [`02-especificacion-requisitos.md`](02-especificacion-requisitos.md) | **Presente** |
| Casos de uso / flujos | [`04-diseno-detallado.md`](04-diseno-detallado.md) | **Presente** |
| Matriz de trazabilidad | [`11-matriz-trazabilidad.md`](11-matriz-trazabilidad.md) | **Presente** |

---

## 3. Código fuente y estructura

### Qué es

El software ejecutable, organizado en módulos con responsabilidades claras, convenciones de nombrado y estándares de estilo.

### Para qué sirve

Facilita mantenimiento, revisión de código y onboarding técnico.

### En `app_desktop`

| Aspecto | Detalle | Estado |
|---------|---------|--------|
| Punto de entrada | [`src/main.py`](../src/main.py) | **Presente** |
| Cliente HTTP | [`src/smartcset_client.py`](../src/smartcset_client.py) | **Presente** |
| UI (Tkinter) | [`src/ui/`](../src/ui/) | **Presente** |
| Motor biométrico | [`src/motor/`](../src/motor/) | **Presente** (in-process, 128 dims) |
| Estándar Python | PEP8, `snake_case`, líneas ≤79 chars | **Presente** (regla del monorepo) |
| Reglas de arquitectura | [`REGLAS_APP_ESCRITORIO_SGI.md`](../REGLAS_APP_ESCRITORIO_SGI.md) | **Parcial** — diseño original vs as-built divergen en motor 2 procesos |

Estructura real (no usar la carpeta histórica `app/`):

```
app_desktop/
├── src/          ← código fuente
├── tests/        ← pruebas automatizadas
├── packaging/    ← build PyInstaller
├── docs/         ← este paquete de entrega
└── runtime/      ← config, logs, venv (no versionado)
```

---

## 4. Configuración y secretos

### Qué es

Parámetros de entorno, archivos de configuración local y política de no versionar credenciales.

### Para qué sirve

Separa lo configurable por instalación de lo que viaja en el repositorio; reduce fugas de secretos.

### En `app_desktop`

| Artefacto | Ubicación | Estado |
|-----------|-----------|--------|
| Config local | `runtime/app_config.json` (`base_url`, `verify_tls`) | **Presente** — no versionado |
| Seed de empaquetado | [`packaging/app_config.porteria.json`](../packaging/app_config.porteria.json) | **Presente** |
| Credenciales en repo | — | **Correcto** — no se versionan |
| `.env` para tests | Raíz del monorepo (solo `tests/common.py`) | **Presente** — fuera de `app_desktop` |

---

## 5. Dependencias

### Qué es

Inventario explícito de librerías de terceros con versiones fijadas.

### Para qué sirve

Reproducibilidad entre PCs de portería sin acceso constante a internet.

### En `app_desktop`

| Artefacto | Ubicación | Estado |
|-----------|-----------|--------|
| `requirements.txt` | [`requirements.txt`](../requirements.txt) | **Presente** |
| Versiones fijadas (`==`) | opencv, numpy, Pillow | **Presente** |
| Excepción `>=` | `tzdata>=2024.1` | **Parcial** — una dependencia con rango abierto |
| Bootstrap automático | [`src/bootstrap.py`](../src/bootstrap.py) | **Presente** — crea `runtime/.venv` |

Dependencias permitidas: `opencv-python-headless`, `numpy`, `Pillow`, `tzdata`. HTTP con stdlib (`urllib`), sin `requests`.

---

## 6. Build y empaquetado

### Qué es

Scripts y configuración para generar un artefacto instalable (`.exe` en Windows).

### Para qué sirve

Permite desplegar en PCs de portería sin exigir que el operario instale Python manualmente.

### En `app_desktop`

| Artefacto | Ubicación | Estado |
|-----------|-----------|--------|
| Spec PyInstaller | [`packaging/SmartCSET_Porteria.spec`](../packaging/SmartCSET_Porteria.spec) | **Presente** |
| Script de build | [`packaging/build_exe.ps1`](../packaging/build_exe.ps1) | **Presente** |
| Build a Escritorio | [`packaging/build_exe_to_desktop.ps1`](../packaging/build_exe_to_desktop.ps1) | **Presente** |
| Guía de empaquetado | [`packaging/README.md`](../packaging/README.md) | **Presente** |
| Firma de código / notarización | — | **Ausente** |

Resultado: `dist/SmartCSET_Porteria.exe` (onefile, sin consola).

---

## 7. Pruebas

### Qué es

Suite automatizada que valida comportamiento funcional, integración y regresiones.

### Para qué sirve

Evidencia objetiva de calidad; gate antes de despliegue.

### En `app_desktop`

| Tipo | Ubicación | Estado |
|------|-----------|--------|
| Integración HTTP (backend real) | [`tests/test_smartcset_client.py`](../tests/test_smartcset_client.py) | **Presente** — 17 casos |
| Unitarios (parseo escáner) | [`tests/test_scan_capture.py`](../tests/test_scan_capture.py) | **Presente** — 17 casos |
| Sin mocks de BD | Política del monorepo | **Presente** |
| Cobertura de código | — | **Ausente** |
| Tests de UI (Tkinter) | — | **Ausente** |

Ver [`08-plan-y-evidencia-pruebas.md`](08-plan-y-evidencia-pruebas.md).

---

## 8. Integración continua (CI/CD)

### Qué es

Pipeline automático que ejecuta tests, lint y build en cada cambio.

### Para qué sirve

Detecta regresiones antes de merge; estandariza el proceso de release.

### En `app_desktop`

| Aspecto | Estado |
|---------|--------|
| GitHub Actions / Jenkins / similar | **Ausente** para este módulo |
| Pre-commit hooks (ruff, etc.) | **Ausente** a nivel `app_desktop` |

**Hueco explícito:** las pruebas se ejecutan manualmente contra un backend accesible.

---

## 9. Documentación

### Qué es

Manuales para distintas audiencias: usuario final, instalador, desarrollador, auditor.

### Para qué sirve

Reduce dependencia del equipo de desarrollo para operación y soporte.

### En `app_desktop`

| Documento | Audiencia | Estado |
|-----------|-----------|--------|
| Manual de usuario | Operario de portería | [`06-manual-usuario.md`](06-manual-usuario.md) — **Presente** |
| Manual de instalación | TI / instalador | [`05-manual-instalacion.md`](05-manual-instalacion.md) — **Presente** |
| Arquitectura | Desarrollador / revisor | [`03-arquitectura.md`](03-arquitectura.md) — **Presente** |
| Contrato API | Integrador | [`07-contrato-integracion.md`](07-contrato-integracion.md) — **Presente** |
| Operación | Soporte L1/L2 | [`10-operacion-y-mantenimiento.md`](10-operacion-y-mantenimiento.md) — **Presente** |
| Mockups HTML | Diseño / UX | **Ausente** — carpeta `docs/mockups/` vacía |
| Video de capacitación | Operarios | **Ausente** |

---

## 10. Seguridad y cumplimiento normativo

### Qué es

Análisis de riesgos, controles técnicos y alineación con marcos legales (MSPI, Ley 1581, OWASP).

### Para qué sirve

Obligatorio en sistemas que manejan datos sensibles (identidad, biometría) en el SENA.

### En `app_desktop`

| Aspecto | Estado |
|---------|--------|
| Mapeo MSPI Fase 0-1 | [`09-seguridad-mspi.md`](09-seguridad-mspi.md) — **Presente** |
| TLS en tránsito (E8) | **Parcial** — configurable; laboratorio usa `verify_tls: false` |
| Cifrado en reposo fotos (E2) | **Ausente** — diferido institucionalmente |
| Consentimiento biométrico (Ley 1581) | **Ausente** en UI |
| Rate limiting (E3) | **Presente** — heredado del login del servidor |
| Validación uploads (E6) | **Presente** — servidor valida MIME de fotos |
| Auditoría (`usr_insert`) | **Presente** — usuario real de sesión |

---

## 11. Operación y soporte

### Qué es

Runbooks, logs, procedimientos de actualización y escalación.

### Para qué sirve

Mantiene el sistema en producción sin el desarrollador original.

### En `app_desktop`

| Aspecto | Estado |
|---------|--------|
| Logs rotativos | **Presente** — `runtime/logs/smartcset_desktop.log` |
| Manual de operación | [`10-operacion-y-mantenimiento.md`](10-operacion-y-mantenimiento.md) — **Presente** |
| Monitoreo / alertas | **Ausente** — no hay agente de telemetría |
| SLA / soporte formal | **Ausente** |

---

## 12. Entrega final

### Qué es

Paquete que el cliente o institución recibe: binario, documentación, evidencias de prueba.

### Para qué sirve

Cierra el ciclo de proyecto con artefactos verificables.

### En `app_desktop`

| Entregable | Estado |
|------------|--------|
| Ejecutable Windows | `SmartCSET_Porteria.exe` — **Presente** (build manual) |
| Documentación Markdown | `app_desktop/docs/` — **Presente** (este paquete) |
| Evidencia de pruebas | Ejecución manual de `unittest` — **Parcial** |
| Acta de aceptación | **Ausente** — plantilla no incluida |

---

## Matriz resumen — Estado del módulo `app_desktop`

| # | Área | Estado global |
|---|------|---------------|
| 1 | Identidad y gobernanza | **Parcial** |
| 2 | Definición del producto | **Presente** |
| 3 | Código fuente | **Presente** |
| 4 | Configuración y secretos | **Presente** |
| 5 | Dependencias | **Presente** |
| 6 | Build y empaquetado | **Presente** |
| 7 | Pruebas | **Parcial** (sin CI, sin cobertura UI) |
| 8 | CI/CD | **Ausente** |
| 9 | Documentación | **Presente** (este paquete) |
| 10 | Seguridad y cumplimiento | **Parcial** (E2 y consentimiento pendientes) |
| 11 | Operación | **Parcial** |
| 12 | Entrega final | **Parcial** |

---

## Lectura recomendada

| Rol | Siguiente documento |
|-----|---------------------|
| Revisor académico / institucional | [`01-vision-y-alcance.md`](01-vision-y-alcance.md) |
| Desarrollador | [`03-arquitectura.md`](03-arquitectura.md) |
| Operario de portería | [`06-manual-usuario.md`](06-manual-usuario.md) |
| Auditor MSPI | [`09-seguridad-mspi.md`](09-seguridad-mspi.md) |
