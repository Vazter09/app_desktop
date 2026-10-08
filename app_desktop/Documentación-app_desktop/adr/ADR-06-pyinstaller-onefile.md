# ADR-06 — Empaquetado PyInstaller onefile

**Módulo:** `app_desktop`  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 5 (activo desplegable controlado), 7 (instalación repetible), 8 (modelos y binarios embebidos, sin descarga en runtime)

**Estado:** Aceptada (as-built)

---

## Contexto

Los PCs de portería deben recibir un entregable único, sin instalar Python ni clonar el monorepo. El motor necesita modelos ONNX y assets (logo, icono) junto al código. Alternativas: `onedir`, instalador MSI/Inno con venv, o portable ZIP con `.venv`.

---

## Decisión

Empaquetar con **PyInstaller en modo onefile**:

- Spec: [`../packaging/SmartCSET_Porteria.spec`](../../packaging/SmartCSET_Porteria.spec)
- Artefacto: `dist/SmartCSET_Porteria.exe` (sin consola: `console=False`)
- Datas embebidos: logos, modelos YuNet/SFace ONNX, seed `app_config.porteria.json`
- Runtime hook de config cuando exista (`pyi_runtime_hook_config.py`)
- Rutas frozen vs desarrollo: [`../src/app_paths.py`](../../src/app_paths.py)

No se descarga el modelo biométrico en runtime desde Internet.

---

## Consecuencias

**Positivas**

- Un solo archivo para copiar/actualizar en el puesto.
- Modelos y assets versionados con el build (cadena de suministro más clara).
- Experiencia de “aplicación Windows” sin consola negra.

**Negativas / trade-offs**

- Arranque más lento (extracción a temp) frente a `onedir`.
- Antivirus a veces marca onefile; puede requerir allowlist institucional.
- Tamaño del `.exe` grande (OpenCV + ONNX + Tk).
- Debugging en campo es más difícil que con fuente + venv; logs en `runtime/logs/` siguen siendo la vía operativa.
