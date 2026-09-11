# Checklist de Documentación — App Desktop SmartCSET

Índice maestro y checklist vivo del módulo `app_desktop`. Un ítem se marca `[x]`
cuando el documento correspondiente existe bajo `docs/` y está revisado as-built.

**Última actualización:** 2026-09-03  
**Responsable:** Equipo de Desarrollo  
**Alcance:** solo módulo app_desktop (cliente de portería + endpoints/tablas que consume)

---

## Estándares de referencia

- **arc42** — documentación de arquitectura (12 secciones lite)
- **C4 Model** — Contexto → Contenedores → Componentes
- **Diátaxis** — Tutoriales, Guías, Referencia, Explicación
- **ADR** — Architecture Decision Records
- **MSPI** — cada documento indica ejes aplicables en cabecera

---

## 1. Arquitectura (arc42-lite)

- [x] [01-Introducción y objetivos](arquitectura/01-introduccion-y-objetivos.md)
- [x] [02-Restricciones](arquitectura/02-restricciones.md)
- [x] [03-Contexto y alcance (C4 nivel 1)](arquitectura/03-contexto-y-alcance.md)
- [x] [04-Estrategia de solución](arquitectura/04-estrategia-de-solucion.md)
- [x] [05-Vista de bloques (C4 nivel 2-3)](arquitectura/05-vista-de-bloques.md)
- [x] [06-Vista de runtime](arquitectura/06-vista-de-runtime.md)
- [x] [07-Vista de despliegue](arquitectura/07-vista-de-despliegue.md)
- [x] [08-Conceptos transversales](arquitectura/08-conceptos-transversales.md)
- [x] [09-Decisiones (índice de ADRs)](arquitectura/09-decisiones-indice-adr.md)
- [x] [10-Requisitos de calidad](arquitectura/10-requisitos-de-calidad.md)
- [x] [11-Riesgos y deuda técnica](arquitectura/11-riesgos-y-deuda-tecnica.md)
- [x] [12-Glosario](arquitectura/12-glosario.md)

## 2. API

- [ ] OpenAPI/Swagger generado automáticamente — **no aplica:** [`api/openapi-desktop.yaml`](api/openapi-desktop.yaml) es **manual**
- [x] [Ejemplos request/response](api/ejemplos-request-response.md) + [Contrato HTTP](api/contrato-http.md)

## 3. Base de datos

- [x] [Diagrama ER (alcance desktop)](base_de_datos/diagrama-er.md)
- [x] [Catálogo de funciones PL/pgSQL](base_de_datos/catalogo-funciones.md)
- [x] [Diccionario de datos](base_de_datos/diccionario-de-datos.md)

## 4. Operación (runbooks)

- [x] [Instalación desde cero](operacion/instalacion.md)
- [x] [Backup y restauración](operacion/backup-restauracion.md) (alcance cliente; BD remite a servidor)
- [x] [Incidente de seguridad](operacion/incidentes-seguridad.md) (MSPI Eje 8)
- [x] [Checklist despliegue producción](operacion/despliegue-produccion.md)

## 5. Usuario (Diátaxis)

- [x] [Tutorial: primer uso portería](usuario/tutorial-primer-uso.md)
- [x] Guías prácticas: [facial](usuario/guias/registrar-ingreso-facial.md), [manual](usuario/guias/registrar-ingreso-manual.md), [enrolar](usuario/guias/enrolar-rostro.md), [pistola](usuario/guias/lectura-pistola.md)
- [x] [Referencia roles/permisos](usuario/referencia-roles.md)
- [x] [Explicación (porqués)](usuario/explicacion.md)

## 6. Historial

- [x] [Changelog navegable](historial/CHANGELOG.md)

## 7. Trazabilidad MSPI

- [x] Cada documento indica ejes MSPI en cabecera
- [x] Anexo: [matriz de trazabilidad](anexos/matriz-trazabilidad.md)

## 8. Calidad de la documentación

- [x] Markdown plano (diff-friendly)
- [x] Fechas absolutas
- [x] Diagramas Mermaid embebidos
- [x] Responsable y fecha de última revisión en cabecera
- [x] Espejo Word (`.docx`) en [`word/`](word/) vía [`_tools/export_to_docx.py`](_tools/export_to_docx.py)

## Anexos

- [x] [Qué debe contener un proyecto de software](anexos/que-debe-contener-un-proyecto.md)

---

## Log de avance

| Fecha | Qué se hizo |
|-------|-------------|
| 2026-09-03 | Reorganización docs/ según checklist arc42/C4/Diátaxis; migración as-built desde paquete 00–11; generación `.docx` con python-docx |
