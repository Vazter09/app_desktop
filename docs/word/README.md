# Word — espejo de la documentación Markdown

**Última generación:** 2026-09-03

Esta carpeta refleja los `.md` de `docs/` (excepto `_tools/` y `mockups/`) en formato **`.docx`**.

Regenerar:

```powershell
cd app_desktop/docs
pip install python-docx
python _tools/export_to_docx.py
```

Nota: los diagramas Mermaid se exportan como bloques de código (Word no los renderiza).
El archivo OpenAPI (`api/openapi-desktop.yaml`) no tiene espejo Word; ábralo en un editor de texto o Swagger UI.
