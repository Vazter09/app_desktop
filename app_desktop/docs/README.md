# Documentación — App de Escritorio SGI (SmartCSET)

**Módulo:** `app_desktop`  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-14  
**Ejes MSPI:** 3, 5, 6, 7, 8

---

## Empezar aquí

1. **Entrega técnica monolítica:** [`../DOCUMENTACION_TECNICA.md`](../DOCUMENTACION_TECNICA.md) (todas las categorías en un solo `.md`)
2. Índice vivo modular: [`CHECKLIST_DOCUMENTACION.md`](CHECKLIST_DOCUMENTACION.md)
3. Visión rápida: [`arquitectura/01-introduccion-y-objetivos.md`](arquitectura/01-introduccion-y-objetivos.md)
4. Manual operario: [`usuario/tutorial-primer-uso.md`](usuario/tutorial-primer-uso.md)

Entrega Word (espejo de los Markdown modulares): carpeta [`word/`](word/).

### Regenerar `.docx`

```powershell
cd app_desktop/docs
pip install python-docx
python _tools/export_to_docx.py
```

---

## Lectura por rol

| Rol | Ruta recomendada |
|-----|------------------|
| Revisor / auditor | [`DOCUMENTACION_TECNICA.md`](../DOCUMENTACION_TECNICA.md) (completo) |
| Operario portería | Monolítico §G · o usuario/tutorial + guias/ |
| TI / instalador | Monolítico §F · o operacion/instalacion + despliegue-produccion |
| Desarrollador | Monolítico PARTES A–E · o arquitectura/ + api/ + adr/ |
| Auditor MSPI | Monolítico §8 / §11 / PARTE I |

---

## Estructura

```
docs/
├── CHECKLIST_DOCUMENTACION.md
├── arquitectura/     ← arc42-lite 01..12
├── adr/              ← decisiones técnicas
├── api/              ← contrato HTTP + OpenAPI manual
├── base_de_datos/    ← ER / funciones / diccionario (alcance desktop)
├── operacion/        ← runbooks
├── usuario/          ← Diátaxis
├── historial/
├── anexos/
├── word/             ← .docx
└── _tools/           ← export_to_docx.py
```

**Fuente de verdad del código:** `app_desktop/src/` (as-built).  
Notas internas de ingeniería (pueden divergir): `HANDOFF.md`, `REGLAS_APP_ESCRITORIO_SGI.md`.

---

## Estado as-built (resumen)

| Tema | Realidad |
|------|----------|
| Código | `src/` (no `app/`) |
| Motor facial | In-process YuNet+SFace, 128 dims |
| UI post-login | Solo pantalla de ingreso (sin sidebar) |
| Huella | Placeholder UI |
| TLS | Configurable (`verify_tls` en `app_config.json`) |
